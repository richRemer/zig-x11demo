const std = @import("std");
const assert = std.debug.assert;
const endian = @import("builtin").cpu.arch.endian();

const Connection = struct {
    protocol: Protocol,
    stream: std.net.Stream,
    display: u8,
    screen: u8,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    connection: Connection,
    success: XSetupSuccess,
    buffer: []u8,
    global_id: u32 = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        connection: Connection,
        success: XSetupSuccess,
        data: []u8,
    ) !Server {
        const buffer = try allocator.dupe(u8, data);

        return .{
            .allocator = allocator,
            .connection = connection,
            .success = success,
            .buffer = buffer,
        };
    }

    pub fn deinit(this: Server) void {
        this.allocator.free(this.buffer);
    }

    pub fn createWindow(
        this: *Server,
        x: i16,
        y: i16,
        width: u16,
        height: u16,
    ) !u32 {
        const flag_count = 2;
        const request_len = @sizeOf(XCreateWindow) / 4 + flag_count;
        const window_id = this.getNextId();
        const writer = this.connection.stream.writer();

        // basic request info
        try writer.writeStruct(XCreateWindow{
            .depth = 32, // TODO: default to root window depth
            .request_len = request_len,
            .window_id = window_id,
            .parent_id = 0, // TODO: use actual root window ID
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .value_mask = .{
                .background_pixel = true,
                .event_mask = true,
            },
        });

        // background_pixel
        try writer.writeInt(u32, 0xff000000, endian);

        // event_mask
        try writer.writeStruct(Events{ .exposure = true, .key_press = true });

        return window_id;
    }

    pub fn getNextId(this: *Server) u32 {
        const mask = this.success.resource_id_mask;
        const base = this.success.resource_id_base;
        const id: u32 = (mask & this.global_id) | base;

        this.global_id += 1;

        return id;
    }
};

pub fn connect(
    protocol: Protocol,
    name: []const u8,
    display: u8,
    screen: u8,
) !Connection {
    return switch (protocol) {
        .unix => connectUnix(name, display, screen),
        .tcp, .inet, .inet6 => connectTCP(name, display, screen),
        else => return error.X11UnknownProtocol,
    };
}

pub fn connectUnix(path: []const u8, display: u8, screen: u8) !Connection {
    var buffer: [std.fs.max_path_bytes]u8 = undefined;
    const sock = try std.fmt.bufPrintZ(&buffer, "{s}{d}", .{ path, display });

    return .{
        .protocol = .unix,
        .stream = try std.net.connectUnixSocket(sock),
        .display = display,
        .screen = screen,
    };
}

pub fn connectTCP(host: []const u8, display: u8, screen: u8) !Connection {
    _ = host;
    _ = display;
    _ = screen;
    return error.X11NotImplemented;
}

pub fn setup(allocator: std.mem.Allocator, connection: Connection) !Server {
    const reader = connection.stream.reader();
    const writer = connection.stream.writer();

    try writer.writeStruct(XSetupRequest{});

    const header = try reader.readStruct(XSetupHeader);
    const data = try allocator.alloc(u8, header.data_len * 4);
    defer allocator.free(data);

    _ = try reader.readAll(data);

    switch (header.state) {
        .authenticate => {
            // TODO: figure out length of reason
            log.err("X11 access denied: {s}", .{data[0..]});
            return error.X11AccessDenied;
        },
        .failure => {
            const address = @intFromPtr(&header);
            const failure = @as(*XSetupFailure, @ptrFromInt(address)).*;
            const reason = data[0..failure.reason_len];

            log.err("X{d} (rev. {d}) connection setup failed: {s}", .{
                failure.protocol_major_version,
                failure.protocol_minor_version,
                reason,
            });

            return error.X11ProtocolError;
        },
        .success => {
            const header_len = @sizeOf(XSetupHeader);
            const success_len = @sizeOf(XSetupSuccess);
            const body_len = success_len - header_len;
            const header_address = @intFromPtr(&header);
            const header_ptr = @as([*]u8, @ptrFromInt(header_address));
            const success_buffer = try allocator.alloc(u8, success_len);
            defer allocator.free(success_buffer);

            assert(header_len == 8);
            assert(body_len == 32);
            assert(success_len == 40);

            // copy header bytes to success struct
            @memcpy(success_buffer[0..header_len], header_ptr);
            // copy data bytes to success struct
            @memcpy(success_buffer[header_len..success_len], data[0..body_len]);

            const success = copyStruct(XSetupSuccess, success_buffer);
            const server_data = data[body_len..];

            log.debug("connected to X{d} (rev. {d})", .{
                success.protocol_major_version,
                success.protocol_minor_version,
            });

            return Server.init(allocator, connection, success, server_data);
        },
    }
}

// protocol structs

const XSetupRequest = extern struct {
    byte_order: u8 = if (endian == .big) 0x42 else 0x6c,
    pad0: u8 = 0,
    protocol_major_version: u16 = Protocol.version,
    protocol_minor_version: u16 = Protocol.revision,
    authorization_protocol_name_len: u16 = 0,
    authorization_protocol_data_len: u16 = 0,
    pad1: u16 = 0,
};

const XSetupHeader = extern struct {
    state: SetupState,
    field_1: u8,
    field_2: u16,
    field_3: u16,
    data_len: u16,
};

const XSetupAuthenticate = extern struct {
    state: SetupState = .authenticate,
    pad: [5]u8 = [_]u8{0} ** 5,
    data_len: u16,
};

const XSetupFailure = extern struct {
    state: SetupState = .failure,
    reason_len: u8,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    data_len: u16,
};

const XSetupSuccess = extern struct {
    state: SetupState = .success,
    pad0: u8 = 0,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    data_len: u16,
    release_number: u32,
    resource_id_base: u32,
    resource_id_mask: u32,
    motion_buffer_size: u32,
    vendor_len: u16,
    maximum_request_len: u16,
    num_screens: u8,
    num_formats: u8,
    image_byte_order: u8,
    bitmap_format_bit_order: u8,
    bitmap_format_scanline_unit: u8,
    bitmap_format_scanline_pad: u8,
    min_keycode: u8,
    max_keycode: u8,
    pad1: u32 = 0,
};

const XCreateWindow = extern struct {
    opcode: RequestOpcode = .create_window,
    depth: u8,
    request_len: u16,
    window_id: u32,
    parent_id: u32,
    x: i16 = 50,
    y: i16 = 50,
    width: u16 = 200,
    height: u16 = 300,
    border_width: u16 = 0,
    class: WindowClass = .copy_from_parent,
    visual: u32 = Visual.copy_from_parent,
    value_mask: WindowAttributes,
};

// enums

pub const ErrorCode = enum(u8) {
    request = 1,
    value,
    window,
    pixmap,
    atom,
    cursor,
    font,
    match,
    drawable,
    access,
    alloc,
    colormap,
    gcontext,
    idchoice,
    name,
    length,
    implementation,
};

pub const Protocol = enum(u8) {
    unknown,
    unix,
    tcp,
    inet,
    inet6,

    pub const version: u16 = 11;
    pub const revision: u16 = 0;

    pub fn getDelimiter(protocol: Protocol) u8 {
        return switch (protocol) {
            .unknown => 0,
            .unix => ':',
            .tcp, .inet, .inet6 => '/',
        };
    }
};

pub const RequestOpcode = enum(u8) {
    create_window = 1,
    change_window_attributes,
    get_window_attributes,
    destroy_window,
    destroy_subwindows,
    change_save_set,
    reparent_window,
    map_window,
    map_subwindows,
    unmap_window,
    unmap_subwindows,
    configure_window,
    circulate_window,
    get_geometry,
    query_tree,
    intern_atom,
    get_atom_name,
    change_property,
    delete_property,
    get_property,
    list_properties,
    set_selection_owner,
    get_selection_owner,
    convert_selection,
    send_event,
    grab_pointer,
    ungrab_pointer,
    grab_button,
    ungrab_button,
    change_active_pointer_grab,
    grab_keyboard,
    ungrab_keyboard,
    grab_key,
    ungrab_key,
    allow_events,
    grab_server,
    ungrab_server,
    query_pointer,
    get_motion_events,
    translate_coordinates,
    warp_pointer,
    set_input_focus,
    get_input_focus,
    query_keymap,
    open_font,
    close_font,
    query_font,
    query_text_extents,
    list_fonts,
    list_fonts_with_info,
    set_font_path,
    get_font_path,
    create_pixmap,
    free_pixmap,
    create_gc,
    change_gc,
    copy_gc,
    set_dashes,
    set_clip_rectangles,
    free_gc,
    clear_area,
    copy_area,
    copy_plane,
    poly_point,
    poly_line,
    poly_segment,
    poly_rectangle,
    poly_arc,
    fill_poly,
    poly_fill_rectangle,
    poly_fill_arc,
    put_image,
    get_image,
    poly_text_8,
    poly_text_16,
    image_text_8,
    image_text_16,
    create_colormap,
    free_colormap,
    copy_colormap_and_free,
    install_colormap,
    uninstall_colotmap,
    list_installed_colormaps,
    alloc_color,
    alloc_named_color,
    alloc_color_cells,
    alloc_color_plances,
    free_colors,
    store_colors,
    store_named_color,
    query_colors,
    lookup_color,
    create_cursor,
    create_glyph_cursor,
    free_cursor,
    recolor_cursor,
    query_best_size,
    query_extension,
    list_extensions,
    change_keyboard_mapping,
    get_keyboard_mapping,
    change_keyboard_control,
    get_keyboard_control,
    bell,
    change_pointer_control,
    get_pointer_control,
    set_screen_saver,
    get_screen_saver,
    change_hosts,
    list_hosts,
    set_access_control,
    set_close_down_mode,
    kill_client,
    rotate_properties,
    force_screen_saver,
    set_pointer_mapping,
    get_pointer_mapping,
    set_modifier_mapping,
    get_modifier_mapping,
    no_operation = 127,
};

pub const SetupState = enum(u8) {
    failure,
    success,
    authenticate,
};

pub const WindowClass = enum(u16) {
    copy_from_parent,
    input_output,
    input_only,
};

// namespaces?

pub const Visual = struct {
    pub const copy_from_parent: u32 = 0;
};

// bit fields

pub const Events = packed struct(u32) {
    key_press: bool = true,
    key_release: bool = true,
    button_press: bool = true,
    button_release: bool = true,
    enter_window: bool = true,
    leave_window: bool = true,
    pointer_motion: bool = true,
    pointer_motion_hint: bool = true,
    button_1_motion: bool = true,
    button_2_motion: bool = true,
    button_3_motion: bool = true,
    button_4_motion: bool = true,
    button_5_motion: bool = true,
    button_motion: bool = true,
    keymap_state: bool = true,
    exposure: bool = true,
    visibility_change: bool = true,
    structure_notify: bool = true,
    resize_redirect: bool = true,
    substructure_notify: bool = true,
    substructure_redirect: bool = true,
    focus_change: bool = true,
    property_change: bool = true,
    colormap_change: bool = true,
    owner_grab_button: bool = true,
    unused: u7 = 0,
};

pub const WindowAttributes = packed struct(u32) {
    background_pixmap: bool = false,
    background_pixel: bool = false,
    border_pixmap: bool = false,
    border_pixel: bool = false,
    bit_gravity: bool = false,
    win_gravity: bool = false,
    backing_store: bool = false,
    backing_planes: bool = false,
    backing_pixel: bool = false,
    override_redirect: bool = false,
    save_under: bool = false,
    event_mask: bool = false,
    do_not_propogate_mask: bool = false,
    colormap: bool = false,
    cursor: bool = false,
    unused: u17 = 0,
};

// buffer reading helpers

inline fn read16(buffer: *const [@divExact(@typeInfo(u16).int.bits, 8)]u8) u16 {
    return std.mem.readInt(u16, buffer, endian);
}

inline fn read32(buffer: *const [@divExact(@typeInfo(u32).int.bits, 8)]u8) u32 {
    return std.mem.readInt(u32, buffer, endian);
}

fn copyStruct(comptime T: type, buffer: []const u8) T {
    if (buffer.len >= @sizeOf(T)) {
        return @as(*T, @ptrFromInt(@intFromPtr(buffer.ptr))).*;
    } else {
        @panic("buffer not large enough for type");
    }
}

// X11 logger

pub const log = std.log.scoped(.x11);

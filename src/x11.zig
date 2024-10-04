const std = @import("std");
const setup = @import("x11-setup.zig");
const event = @import("x11-event.zig");
const res = @import("x11-resource.zig");
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
    global_id: u32 = 0,
    root_window_id: u32,
    root_visual_id: u32,
    vendor: []u8,
    formats: []res.PixelFormat,
    success_data: []u8,
    success: *setup.Success,
    // TODO: move these to Connection
    read_mutex: std.Thread.Mutex = .{},
    write_mutex: std.Thread.Mutex = .{},

    pub fn init(
        allocator: std.mem.Allocator,
        connection: Connection,
        data: []u8,
    ) !Server {
        const success_data = try allocator.dupe(u8, data);
        errdefer allocator.free(success_data);

        const success_address = @intFromPtr(success_data.ptr);
        const success = @as(*setup.Success, @ptrFromInt(success_address));
        const vendor_data = success_data[@sizeOf(setup.Success)..];
        const vendor = vendor_data[0..success.vendor_len];
        const formats_data = vendor_data[x_pad(u16, success.vendor_len)..];
        const formats_address = @intFromPtr(formats_data.ptr);
        const formats_ptr: [*]res.PixelFormat = @ptrFromInt(formats_address);
        const formats = formats_ptr[0..success.num_formats];

        const screen = first_success_screen(success) orelse {
            log.err("success has no screens", .{});
            return error.X11ProtocolError;
        };

        const depth = first_screen_depth(screen) orelse {
            log.err("screen has no depths", .{});
            return error.X11ProtocolError;
        };

        const visual = first_depth_visual(depth) orelse {
            log.err("depth has no visuals", .{});
            return error.X11ProtocolError;
        };

        log.debug("{s} [vendor]", .{vendor});

        return .{
            .allocator = allocator,
            .connection = connection,
            .root_window_id = screen.root,
            .root_visual_id = visual.visual_id,
            .vendor = vendor,
            .formats = formats,
            .success_data = success_data,
            .success = success,
        };
    }

    pub fn deinit(this: Server) void {
        this.allocator.free(this.success_data);
    }

    pub fn createWindow(
        this: *Server,
        x: i16,
        y: i16,
        width: u16,
        height: u16,
    ) !u32 {
        // TODO: lookup/manage Atoms
        // TODO: e.g., WM_DELETE_WINDOW is an Atom
        // TODO: must be set in "WM_PROTOCOLS" (also an Atom)
        // TODO: q.v., https://stackoverflow.com/questions/10792361/how-do-i-gracefully-exit-an-x11-event-loop
        // TODO: q.v., XInternAtom
        // TODO: q.v., XSetWMProtocols

        const flag_count = 2;
        const request_len = @sizeOf(XCreateWindow) / 4 + flag_count;
        const window_id = this.getNextId();
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        // basic request info
        try writer.writeStruct(XCreateWindow{
            .depth = 0, // TODO: figure out root window depth
            .request_len = request_len,
            .window_id = window_id,
            .parent_id = this.root_window_id,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .class = WindowClass.input_output,
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

    pub fn mapWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(XMapWindow{
            .window_id = window_id,
        });
    }

    pub fn readMessage(this: *Server) !void {
        var buffer: [32]u8 = undefined;
        var name: [:0]const u8 = "";

        const address = @intFromPtr(&buffer);
        const reader = this.connection.stream.reader();

        this.read_mutex.lock();
        defer this.read_mutex.unlock();

        _ = try reader.readAll(buffer[0..]);

        if (buffer[0] > 1 and buffer[0] <= 35) {
            name = @tagName(@as(MessageCode, @enumFromInt(buffer[0])));
        }

        switch (buffer[0]) {
            @intFromEnum(MessageCode.@"error") => {
                const err = @as(*XMessageError, @ptrFromInt(address)).*;
                const code = @tagName(err.error_code);
                const major = err.major_opcode;
                const minor = err.minor_opcode;
                const seq = err.sequence_number;
                const op = @tagName(@as(RequestOpcode, @enumFromInt(major)));

                log.err("[{d}] {s}/{d} {s} error", .{ seq, op, minor, code });
                return error.X11ErrorMessage;
            },
            @intFromEnum(MessageCode.focus_in) => {
                const evt = @as(*event.FocusIn, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const wid = evt.window_id;

                log.debug("[{d}] {s} (wid: {d})", .{ seq, name, wid });
            },
            @intFromEnum(MessageCode.focus_out) => {
                const evt = @as(*event.FocusOut, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const wid = evt.window_id;

                log.debug("[{d}] {s} (wid: {d})", .{ seq, name, wid });
            },
            @intFromEnum(MessageCode.keymap_notify) => {
                const evt = @as(*event.KeymapNotify, @ptrFromInt(address)).*;

                log.debug("[x] {s}: {any}", .{ name, evt.keys });
            },
            @intFromEnum(MessageCode.expose) => {
                const evt = @as(*event.Expose, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const wid = evt.window_id;
                const x = evt.x;
                const y = evt.y;
                const w = evt.width;
                const h = evt.height;

                log.debug("[{d}] {s} (wid: {d}) {d},{d};{d}x{d}", .{ seq, name, wid, x, y, w, h });
            },
            @intFromEnum(MessageCode.visbility_notify) => {
                const evt = @as(*event.VisibilityNotify, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const wid = evt.window_id;

                log.debug("[{d}] {s} (wid: {d})", .{ seq, name, wid });
            },
            @intFromEnum(MessageCode.map_notify) => {
                const evt = @as(*event.MapNotify, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const eid = evt.event_window_id;
                const wid = evt.window_id;

                log.debug("[{d}] {s} (wid: {d} eid: {d})", .{ seq, name, wid, eid });
            },
            @intFromEnum(MessageCode.reparent_notify) => {
                const evt = @as(*event.ReparentNotify, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const eid = evt.event_window_id;
                const wid = evt.window_id;
                const pid = evt.parent_window_id;

                log.debug("[{d}] {s} (wid: {d} eid: {d} pid: {d})", .{ seq, name, wid, eid, pid });
            },
            @intFromEnum(MessageCode.property_notify) => {
                const evt = @as(*event.PropertyNotify, @ptrFromInt(address)).*;
                const seq = evt.sequence_number;
                const state = @tagName(evt.state);
                const wid = evt.window_id;
                const aid = evt.atom_id;

                log.debug("[{d}] {s} (wid: {d} aid: {d}) {s}", .{ seq, name, wid, aid, state });
            },
            else => {},
        }
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

pub fn handshake(
    allocator: std.mem.Allocator,
    connection: Connection,
) !Server {
    const reader = connection.stream.reader();
    const writer = connection.stream.writer();

    try writer.writeStruct(setup.Request{});

    // first couple bytes of response have status and length of data
    const header_len = @sizeOf(setup.Header);
    const header_data = try allocator.alloc(u8, header_len);
    defer allocator.free(header_data);

    _ = try reader.readAll(header_data);

    const header_address = @intFromPtr(header_data.ptr);
    const header = @as(*setup.Header, @ptrFromInt(header_address)).*;
    const success_len = header_len + header.data_len * 4;
    const success_data = try allocator.alloc(u8, success_len);
    defer allocator.free(success_data);

    // write header to data and copy remaining bytes from socket
    @memcpy(success_data[0..header_len], header_data);
    _ = try reader.readAll(success_data[header_len..]);
    // data now contains full setup success with all related data

    switch (header.state) {
        .authenticate => {
            // TODO: figure out length of reason
            log.err("X11 access denied: {s}", .{success_data[header_len..]});
            return error.X11AccessDenied;
        },
        .failure => {
            const failure = @as(*setup.Failure, @ptrFromInt(header_address));
            const reason_data = success_data[header_len..];
            const reason = reason_data[0..failure.reason_len];

            log.err("X{d} (rev. {d}) connection setup failed: {s}", .{
                failure.protocol_major_version,
                failure.protocol_minor_version,
                reason,
            });

            return error.X11ProtocolError;
        },
        .success => {
            const success_address = @intFromPtr(success_data.ptr);
            const success = @as(*setup.Success, @ptrFromInt(success_address));

            log.debug("connected to X{d} (rev. {d})", .{
                success.protocol_major_version,
                success.protocol_minor_version,
            });

            return Server.init(allocator, connection, success_data);
        },
    }
}

pub fn verify_atoms(comptime atoms: anytype) void {
    const name_buffer: [32]u8 = [1]u8{0} ** 32;
    const Atoms = @TypeOf(atoms);
    const atoms_info = @typeInfo(Atoms);

    if (atoms_info != .@"struct" or !atoms_info.@"struct".is_tuple) {
        @compileError("expected tuple argument, found " ++ @typeName(Atoms));
    }

    inline for (atoms_info.@"struct".fields) |field| {
        if (field.type != @Type(.enum_literal)) {
            @compileError("'" ++ field.name ++ "' is not an enum literal");
        } else if (field.name.len > name_buffer.len) {
            @compileError("atom name '" ++ field.name ++ "' is too long");
        }
    }

    // inline for (atoms_info.@"struct".fields) |field| {
    //     _ = std.ascii.upperString(name, field.name);
    // }
}

// protocol structs

const XMessageError = extern struct {
    code: MessageCode = .@"error",
    error_code: ErrorCode,
    sequence_number: u16,
    data: u32,
    minor_opcode: u16,
    major_opcode: u8,
    unused: [21]u8 = [1]u8{0} ** 21,
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

const XInternAtom = extern struct {
    opcode: RequestOpcode = .intern_atom,
    only_if_exists: Bool,
    request_len: u16,
    name_len: u16,
    unused: u16,
};

const XMapWindow = extern struct {
    opcode: RequestOpcode = .map_window,
    unused: u8 = 0,
    request_len: u16 = 2,
    window_id: u32,
};

// enums

pub const BackingStores = enum(u8) {
    never,
    when_mapped,
    always,
};

pub const Bool = enum(u8) {
    no,
    yes,
};

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

pub const FocusDetail = enum(u8) {
    ancestor,
    virtual,
    inferior,
    nonlinear,
    nonlinear_virtual,
    pointer,
    pointer_root,
    none,
};

pub const FocusMode = enum(u8) {
    normal,
    grab,
    ungrab,
    while_grabbed,
};

pub const MessageCode = enum(u8) {
    // XMessageError, 32 bytes
    @"error" = 0,
    // generic reply, 32 bytes + additional data
    reply = 1,
    // events, 32 bytes each
    key_press = 2,
    key_release,
    button_press,
    button_release,
    motion_notify,
    enter_notify,
    leave_notify,
    focus_in,
    focus_out,
    keymap_notify,
    expose,
    graphics_exposure,
    no_exposure,
    visbility_notify,
    create_notify,
    destroy_notify,
    unmap_notify,
    map_notify,
    map_request,
    reparent_notify,
    configure_notify,
    configure_request,
    gravity_notify,
    resize_request,
    circulate_notify,
    circulate_request,
    property_notify,
    selection_clear,
    selection_request,
    selection_notify,
    colormap_notify,
    client_message,
    mapping_notify,
};

pub const PropertyChangeState = enum(u8) {
    new_value,
    deleted,
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

pub const VisibilityChangeState = enum(u8) {
    unobscured,
    partially_obscured,
    fully_obscured,
};

pub const VisualClass = enum(u8) {
    static_gray,
    gray_scale,
    static_color,
    pseudo_color,
    true_color,
    direct_color,
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

inline fn first_success_screen(success: *setup.Success) ?*res.Screen {
    if (success.num_screens > 0) {
        var address = @intFromPtr(success);

        address += @sizeOf(setup.Success);
        address += x_pad(u16, success.vendor_len);
        address += success.num_formats * @sizeOf(res.PixelFormat);

        return @ptrFromInt(address);
    } else {
        return null;
    }
}

inline fn first_screen_depth(screen: *res.Screen) ?*res.Depth {
    if (screen.num_depths > 0) {
        return @ptrFromInt(@intFromPtr(screen) + @sizeOf(res.Screen));
    } else {
        return null;
    }
}

inline fn first_depth_visual(depth: *res.Depth) ?*res.Visual {
    if (depth.num_visuals > 0) {
        return @ptrFromInt(@intFromPtr(depth) + @sizeOf(res.Depth));
    } else {
        return null;
    }
}

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

inline fn x_pad(comptime T: type, len: T) T {
    return len + ((4 - (len % 4)) % 4);
}

// X11 logger

pub const log = std.log.scoped(.x11);

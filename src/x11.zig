const std = @import("std");
const setup = @import("x11-setup.zig");
const arch = @import("builtin").cpu.arch;
const assert = std.debug.assert;

pub const protocol = @import("x11/protocol.zig");
pub const log = std.log.scoped(.x11);

const UnknownEvent = protocol.UnknownEvent;
const UnknownMessage = protocol.UnknownMessage;
const UnknownReply = protocol.UnknownReply;

/// Used by X11 to specify a missing resource ID.
pub const none: u32 = 0;

const Connection = struct {
    scheme: Protocol,
    stream: std.net.Stream,
    display: u8,
    screen: u8,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    connection: Connection,
    // TODO: add context parameter
    handler: ?*const fn (Message, ?*anyopaque) void = null,
    handler_context: ?*anyopaque = null,
    global_id: u32 = 0,
    root_window_id: u32,
    root_visual_id: u32,
    reply_data: ?[]u8 = null,

    // TODO: move these to Connection
    read_mutex: std.Thread.Mutex = .{},
    write_mutex: std.Thread.Mutex = .{},

    vendor: []u8,
    formats: []protocol.PixelFormat,
    success_data: []u8,
    success: *setup.Success,

    pub const Atom = struct {
        allocator: std.mem.Allocator,
        buffer: []u8,
        name: []u8,
        atom_id: u32,

        pub fn deinit(this: Atom) void {
            this.allocator.free(this.buffer);
        }
    };

    pub const Property = struct {
        allocator: std.mem.Allocator,
        buffer: []u8,
        type_id: u32,
        format: u8,
        more: u32,

        pub fn deinit(this: Property) void {
            this.allocator.free(this.buffer);
        }

        pub fn valueData(this: Property, comptime T: type) []T {
            switch (this.format) {
                0 => @panic("property has no data"),
                8 => if (T != u8) @panic("property data is u8"),
                16 => if (T != u16) @panic("property data is u16"),
                32 => if (T != u32) @panic("property data is u32"),
                else => @panic("property format is not valid"),
            }

            const reply = fromPtr(protocol.GetPropertyReply, this.buffer.ptr);
            const data = this.buffer[@sizeOf(protocol.GetPropertyReply)..];
            const address = @intFromPtr(data.ptr);

            return @as([*]T, @ptrFromInt(address))[0..reply.value_len];
        }
    };

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
        const formats_data = vendor_data[pad(u16, success.vendor_len)..];
        const formats_address = @intFromPtr(formats_data.ptr);
        const formats_ptr: [*]protocol.PixelFormat = @ptrFromInt(formats_address);
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
        if (this.reply_data != null) {
            @panic("did not clean up last reply");
        }

        this.allocator.free(this.success_data);
    }

    pub fn changeProperty(
        this: *Server,
        comptime T: type,
        window_id: u32,
        property_id: u32,
        value: []const T,
    ) !void {
        if (T != u8 and T != u16 and T != u32) {
            @compileError("type must be u8, u16, or u32");
        }

        const format = @sizeOf(T) * 8;
        const data_len: u32 = @intCast(value.len);
        const mode = protocol.ChangePropertyMode.replace; // TOOD: support all modes
        const writer = this.connection.stream.writer();
        const data_size = data_len * @sizeOf(T);
        const data = @as([*]const u8, @ptrCast(value.ptr))[0..data_size];
        const padded = pad(usize, data.len);

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.ChangePropertyRequest{
            .mode = mode,
            .request_len = protocol.ChangePropertyRequest.requestLen(format, data_len),
            .window_id = window_id,
            .property_id = property_id,
            .type_id = none, // ignored? (docs say "uninterpreted")
            .format = format,
            .data_len = data_len,
        });

        try writer.writeAll(data);
        try writer.writeByteNTimes(0, padded - data.len);
    }

    pub fn createWindow(this: *Server) !u32 {
        const num_flags = 2;
        const window_id = this.getNextId();
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.CreateWindowRequest{
            .depth = 0, // TODO: figure out root window depth
            .request_len = protocol.CreateWindowRequest.requestLen(num_flags),
            .window_id = window_id,
            .parent_id = this.root_window_id,
            .class = protocol.CreateWindowClass.input_output,
            .value_mask = .{
                .background_pixel = true,
                .event_mask = true,
            },
        });

        try writer.writeInt(u32, 0xff000000, arch.endian());
        try writer.writeStruct(protocol.EventSet.all);

        return window_id;
    }

    pub fn destroyWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.DestroyWindowRequest{
            .window_id = window_id,
        });
    }

    pub fn getAtomName(this: *Server, atom_id: u32) !Atom {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.GetAtomNameRequest{
            .atom_id = atom_id,
        });

        while (this.reply_data == null) {
            try this.readMessage();
        }

        const reply_data = this.reply_data.?;
        const buffer = try this.allocator.dupe(u8, reply_data);
        errdefer this.allocator.free(buffer);

        this.allocator.free(reply_data);
        this.reply_data = null;

        const reply = fromPtr(protocol.GetAtomNameReply, buffer.ptr);
        const name = buffer[@sizeOf(protocol.GetAtomNameReply)..][0..reply.name_len];

        return Atom{
            .allocator = this.allocator,
            .buffer = buffer,
            .name = name,
            .atom_id = atom_id,
        };
    }

    pub fn getProperty(
        this: *Server,
        window_id: u32,
        property_id: u32,
    ) !Property {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.GetPropertyRequest{
            .delete = false,
            .window_id = window_id,
            .property_id = property_id,
            .long_offset = 0,
            .long_length = 1, // TODO: make this an argument
        });

        while (this.reply_data == null) {
            try this.readMessage();
        }

        const reply_data = this.reply_data.?;
        const buffer = try this.allocator.dupe(u8, reply_data);
        errdefer this.allocator.free(buffer);

        this.allocator.free(reply_data);
        this.reply_data = null;

        const reply = fromPtr(protocol.GetPropertyReply, buffer.ptr);
        const size = switch (reply.format) {
            0, 8, 16, 32 => |bits| bits / 8,
            else => return error.X11ProtocolError,
        };

        return Property{
            .allocator = this.allocator,
            .buffer = buffer,
            .type_id = reply.type_id,
            .format = reply.format,
            .more = if (size == 0) 0 else reply.bytes_after / size,
        };
    }

    pub fn internAtom(this: *Server, name: []const u8, must_exist: bool) !u32 {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.InternAtomRequest{
            .only_if_exists = must_exist,
            .request_len = protocol.InternAtomRequest.requestLen(name.len),
            .name_len = @intCast(name.len),
        });

        try writer.writeAll(name);
        try writer.writeByteNTimes(0, pad(usize, name.len) - name.len);

        while (this.reply_data == null) {
            try this.readMessage();
        }

        const reply_data = this.reply_data.?;
        const reply = fromPtr(protocol.InternAtomReply, reply_data.ptr);

        this.allocator.free(reply_data);
        this.reply_data = null;

        return reply.atom;
    }

    pub fn mapWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(protocol.MapWindowRequest{
            .window_id = window_id,
        });
    }

    /// Register a handler to be called when the server sends an error or an
    /// event.  If a context is provided, the context will also be passed to
    /// the handler.
    pub fn registerHandler(
        this: *Server,
        handler: fn (Message, ?*anyopaque) void,
        context: ?*anyopaque,
    ) void {
        if (this.handler == null) {
            this.handler = handler;
            this.handler_context = context;
        } else {
            @panic("only one handler can be registered");
        }
    }

    /// Produce a unique (within reason) ID that can be used to initialize a
    /// resource, such as a Window.
    /// TODO: deal with wrapping in some way
    pub fn getNextId(this: *Server) u32 {
        const mask = this.success.resource_id_mask;
        const base = this.success.resource_id_base;
        const id: u32 = (mask & this.global_id) | base;

        this.global_id += 1;

        return id;
    }

    /// Read all pending messages and return the number of messages read.
    pub fn readAll(this: *Server) !u32 {
        var count: u32 = 0;
        while (try this.readOne()) count += 1;
        return count;
    }

    /// Read the next message, if one is available.  Return true if a message
    /// was not available.
    pub fn readOne(this: *Server) !bool {
        return this.readOneWithTimeout(0);
    }

    /// Read the next message, if one is available, or wait until one becomes
    /// available.
    pub fn readOneWait(this: *Server) !void {
        _ = try this.readOneWithTimeout(-1); // unlimited
    }

    /// Read the next message, if one is available or becomes available before
    /// the timeout.  A negative timeout will wait forever.  If a message is
    /// read, the return value will be true.
    pub fn readOneWithTimeout(this: *Server, timeout: i32) !bool {
        const pollfd = std.os.linux.pollfd;
        const POLL = std.os.linux.POLL;

        var pollfds = [1]pollfd{pollfd{
            .fd = this.connection.stream.handle,
            .events = POLL.IN | POLL.ERR | POLL.HUP,
            .revents = 0,
        }};

        if (std.os.linux.poll(&pollfds, pollfds.len, timeout) == 0) {
            return false;
        } else {
            if (pollfds[0].revents & std.os.linux.POLL.ERR > 0) {
                log.err("socket poll error", .{});
                return error.X11SocketError;
            }

            if (pollfds[0].revents & std.os.linux.POLL.HUP > 0) {
                log.err("socket poll error", .{});
                return error.X11SocketError;
            }

            this.readMessage() catch {
                log.err("could not read message from socket", .{});
                return error.X11SocketError;
            };

            return true;
        }
    }

    /// Read the next pending message from the X11 server.  If the message is a
    /// reply, the .reply_data field will be set.  If it is an error or event
    /// and a handler has been registered, the message will be passed to the
    /// handler.
    /// TODO: confirm behavior when no data is available
    fn readMessage(this: *Server) !void {
        const reader = this.connection.stream.reader();

        this.read_mutex.lock();
        defer this.read_mutex.unlock();

        const info = try reader.readStruct(UnknownMessage);
        const code: protocol.Code = @enumFromInt(@intFromEnum(info.code) & 0x7f);
        const message: ?Message = switch (code) {
            .@"error" => Message{
                .@"error" = fromPtr(protocol.Error, &info),
            },
            .reply => blk: {
                const generic = fromPtr(UnknownReply, &info);
                const generic_data = std.mem.asBytes(&generic);
                const data = try this.allocator.alloc(u8, generic.sizeOf());
                errdefer this.allocator.free(data);

                // write generic to data; copy extended bytes from socket
                @memcpy(data[0..@sizeOf(UnknownReply)], generic_data);
                _ = try reader.readAll(data[@sizeOf(UnknownReply)..]);
                // data now contains full reply with all related data

                if (this.reply_data != null) {
                    @panic("did not clean up last reply");
                }

                this.reply_data = data;
                break :blk null; // null result won't trigger handler
            },
            .focus_in => Message{
                .focus_in = fromPtr(protocol.FocusInEvent, &info),
            },
            .focus_out => Message{
                .focus_out = fromPtr(protocol.FocusOutEvent, &info),
            },
            .keymap_notify => Message{
                .keymap_notify = fromPtr(protocol.KeymapNotifyEvent, &info),
            },
            .expose => Message{
                .expose = fromPtr(protocol.ExposeEvent, &info),
            },
            .visibility_notify => Message{
                .visibility_notify = fromPtr(protocol.VisibilityNotifyEvent, &info),
            },
            .map_notify => Message{
                .map_notify = fromPtr(protocol.MapNotifyEvent, &info),
            },
            .reparent_notify => Message{
                .reparent_notify = fromPtr(protocol.ReparentNotifyEvent, &info),
            },
            .property_notify => Message{
                .property_notify = fromPtr(protocol.PropertyNotifyEvent, &info),
            },
            .client_message => Message{
                .client_message = fromPtr(protocol.ClientMessageEvent, &info),
            },
            else => null,
        };

        if (message != null and this.handler != null) {
            this.handler.?(message.?, this.handler_context);
        }
    }
};

/// Union of the three basic X11 message types: Error, Reply, and Event.
/// Error and Event messages are simple 32-byte structs. Reply messages are
/// each different structures and may contain additional data.
pub const Message = union(protocol.Code) {
    @"error": protocol.Error,
    reply: Reply,
    key_press: protocol.UnknownEvent,
    key_release: protocol.UnknownEvent,
    button_press: protocol.UnknownEvent,
    button_release: protocol.UnknownEvent,
    motion_notify: protocol.UnknownEvent,
    enter_notify: protocol.UnknownEvent,
    leave_notify: protocol.UnknownEvent,
    focus_in: protocol.FocusInEvent,
    focus_out: protocol.FocusOutEvent,
    keymap_notify: protocol.KeymapNotifyEvent,
    expose: protocol.ExposeEvent,
    graphics_exposure: protocol.UnknownEvent,
    no_exposure: protocol.UnknownEvent,
    visibility_notify: protocol.VisibilityNotifyEvent,
    create_notify: protocol.UnknownEvent,
    destroy_notify: protocol.UnknownEvent,
    unmap_notify: protocol.UnknownEvent,
    map_notify: protocol.MapNotifyEvent,
    map_request: protocol.UnknownEvent,
    reparent_notify: protocol.ReparentNotifyEvent,
    configure_notify: protocol.UnknownEvent,
    configure_request: protocol.UnknownEvent,
    gravity_notify: protocol.UnknownEvent,
    resize_request: protocol.UnknownEvent,
    circulate_notify: protocol.UnknownEvent,
    circulate_request: protocol.UnknownEvent,
    property_notify: protocol.PropertyNotifyEvent,
    selection_clear: protocol.UnknownEvent,
    selection_request: protocol.UnknownEvent,
    selection_notify: protocol.UnknownEvent,
    colormap_notify: protocol.UnknownEvent,
    client_message: protocol.ClientMessageEvent,
    mapping_notify: protocol.UnknownEvent,
};

/// Union of the various X11 Reply structures.  Some requests do not have a
/// Reply; these are of type void.
pub const Reply = union(protocol.Opcode) {
    create_window: void,
    change_window_attributes: void,
    get_window_attributes: protocol.GetWindowAttributesReply,
    destroy_window: void,
    destroy_subwindows: void,
    change_save_set: void,
    reparent_window: void,
    map_window: void,
    map_subwindows: void,
    unmap_window: void,
    unmap_subwindows: void,
    configure_window: void,
    circulate_window: void,
    get_geometry: protocol.GetGeometryReply,
    query_tree: protocol.QueryTreeReply,
    intern_atom: protocol.InternAtomReply,
    get_atom_name: protocol.GetAtomNameReply,
    change_property: void,
    delete_property: void,
    get_property: protocol.GetPropertyReply,
    list_properties: protocol.ListPropertiesReply,
    set_selection_owner: void,
    get_selection_owner: protocol.GetSelectionOwnerReply,
    convert_selection: void,
    send_event: void,
    grab_pointer: protocol.GrabPointerReply,
    ungrab_pointer: void,
    grab_button: void,
    ungrab_button: void,
    change_active_pointer_grab: void,
    grab_keyboard: protocol.GrabKeyboardReply,
    ungrab_keyboard: void,
    grab_key: void,
    ungrab_key: void,
    allow_events: void,
    grab_server: void,
    ungrab_server: void,
    query_pointer: protocol.QueryPointerReply,
    get_motion_events: protocol.GetMotionEventsReply,
    translate_coordinates: protocol.TranslateCoordinatesReply,
    warp_pointer: void,
    set_input_focus: void,
    get_input_focus: protocol.GetInputFocusReply,
    query_keymap: protocol.QueryKeymapReply,
    open_font: void,
    close_font: void,
    query_font: protocol.QueryFontReply,
    query_text_extents: protocol.QueryTextExtentsReply,
    list_fonts: protocol.ListFontsReply,
    // TODO: ListFontsWithInfoReply | ListFontsWithInfoReplySentinel
    list_fonts_with_info: void,
    set_font_path: void,
    get_font_path: protocol.GetFontPathReply,
    create_pixmap: void,
    free_pixmap: void,
    create_gc: void,
    change_gc: void,
    copy_gc: void,
    set_dashes: void,
    set_clip_rectangles: void,
    free_gc: void,
    clear_area: void,
    copy_area: void,
    copy_plane: void,
    poly_point: void,
    poly_line: void,
    poly_segment: void,
    poly_rectangle: void,
    poly_arc: void,
    fill_poly: void,
    poly_fill_rectangle: void,
    poly_fill_arc: void,
    put_image: void,
    get_image: protocol.GetImageReply,
    poly_text_8: void,
    poly_text_16: void,
    image_text_8: void,
    image_text_16: void,
    create_colormap: void,
    free_colormap: void,
    copy_colormap_and_free: void,
    install_colormap: void,
    uninstall_colotmap: void,
    list_installed_colormaps: protocol.ListInstalledColormapsReply,
    alloc_color: protocol.AllocColorReply,
    alloc_named_color: protocol.AllocNamedColorReply,
    alloc_color_cells: protocol.AllocColorCellsReply,
    alloc_color_planes: protocol.AllocColorPlanesReply,
    free_colors: void,
    store_colors: void,
    store_named_color: void,
    query_colors: protocol.QueryColorsReply,
    lookup_color: protocol.LookupColorReply,
    create_cursor: void,
    create_glyph_cursor: void,
    free_cursor: void,
    recolor_cursor: void,
    query_best_size: protocol.QueryBestSizeReply,
    query_extension: protocol.QueryExtensionReply,
    list_extensions: protocol.ListExtensionsReply,
    change_keyboard_mapping: void,
    get_keyboard_mapping: protocol.GetKeyboardMappingReply,
    change_keyboard_control: void,
    get_keyboard_control: protocol.GetKeyboardControlReply,
    bell: void,
    change_pointer_control: void,
    get_pointer_control: protocol.GetPointerControlReply,
    set_screen_saver: void,
    get_screen_saver: protocol.GetScreenSaverReply,
    change_hosts: void,
    list_hosts: protocol.ListHostsReply,
    set_access_control: void,
    set_close_down_mode: void,
    kill_client: void,
    rotate_properties: void,
    force_screen_saver: void,
    set_pointer_mapping: protocol.SetPointerMappingReply,
    get_pointer_mapping: protocol.GetPointerMappingReply,
    set_modifier_mapping: protocol.SetModifierMappingReply,
    get_modifier_mapping: protocol.GetModifierMappingReply,
    no_operation: void,
};

pub fn connect(
    scheme: Protocol,
    name: []const u8,
    display: u8,
    screen: u8,
) !Connection {
    return switch (scheme) {
        .unix => connectUnix(name, display, screen),
        .tcp, .inet, .inet6 => connectTCP(name, display, screen),
        else => return error.X11UnknownProtocol,
    };
}

pub fn connectUnix(path: []const u8, display: u8, screen: u8) !Connection {
    var buffer: [std.fs.max_path_bytes]u8 = undefined;
    const sock = try std.fmt.bufPrintZ(&buffer, "{s}{d}", .{ path, display });

    return .{
        .scheme = .unix,
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

    const header = fromPtr(setup.Header, header_data.ptr);
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
            const failure = fromPtr(setup.Failure, header_data.ptr);
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
            const success = fromPtr(setup.Success, success_data.ptr);

            log.debug("connected to X{d} (rev. {d})", .{
                success.protocol_major_version,
                success.protocol_minor_version,
            });

            return Server.init(allocator, connection, success_data);
        },
    }
}

pub const Protocol = enum(u8) {
    unknown,
    unix,
    tcp,
    inet,
    inet6,

    pub const version: u16 = 11;
    pub const revision: u16 = 0;

    pub fn getDelimiter(scheme: Protocol) u8 {
        return switch (scheme) {
            .unknown => 0,
            .unix => ':',
            .tcp, .inet, .inet6 => '/',
        };
    }
};

// **************************************************************************
// * Helper functions                                                       *
// **************************************************************************

// TOOD: make this a static method of some type
inline fn first_success_screen(success: *setup.Success) ?*protocol.Screen {
    if (success.num_screens > 0) {
        var address = @intFromPtr(success);

        address += @sizeOf(setup.Success);
        address += pad(u16, success.vendor_len);
        address += success.num_formats * @sizeOf(protocol.PixelFormat);

        return @ptrFromInt(address);
    } else {
        return null;
    }
}

// TOOD: make this a static method of some type
inline fn first_screen_depth(screen: *protocol.Screen) ?*protocol.Depth {
    if (screen.num_depths > 0) {
        return @ptrFromInt(@intFromPtr(screen) + @sizeOf(protocol.Screen));
    } else {
        return null;
    }
}

// TOOD: make this a static method of some type
inline fn first_depth_visual(depth: *protocol.Depth) ?*protocol.Visual {
    if (depth.num_visuals > 0) {
        return @ptrFromInt(@intFromPtr(depth) + @sizeOf(protocol.Depth));
    } else {
        return null;
    }
}

inline fn pad(comptime T: type, len: T) T {
    return len + ((4 - (len % 4)) % 4);
}

fn fromPtr(comptime T: type, ptr: anytype) T {
    const address = @intFromPtr(ptr);
    return @as(*T, @ptrFromInt(address)).*;
}

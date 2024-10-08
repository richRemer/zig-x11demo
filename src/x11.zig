const std = @import("std");
const setup = @import("x11-setup.zig");
const io = @import("x11-io.zig");
const util = @import("x11-util.zig");
const arch = @import("builtin").cpu.arch;
const assert = std.debug.assert;
const fromPtr = util.fromPtr;
const pad = util.pad;

pub const log = std.log.scoped(.x11);
pub const Message = io.Message;

const GenericEvent = io.GenericEvent;
const GenericMessage = io.GenericMessage;
const GenericReply = io.GenericReply;

/// Used by X11 to specify a missing resource ID.
pub const none: u32 = 0;

const Connection = struct {
    protocol: Protocol,
    stream: std.net.Stream,
    display: u8,
    screen: u8,
};

pub const Server = struct {
    allocator: std.mem.Allocator,
    connection: Connection,
    // TODO: add context parameter
    handler: ?*const fn (*Server, Message) void = null,
    global_id: u32 = 0,
    root_window_id: u32,
    root_visual_id: u32,
    reply_data: ?[]u8 = null,

    // TODO: move these to Connection
    read_mutex: std.Thread.Mutex = .{},
    write_mutex: std.Thread.Mutex = .{},

    vendor: []u8,
    formats: []io.PixelFormat,
    success_data: []u8,
    success: *setup.Success,

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

            const reply = fromPtr(io.GetPropertyReply, this.buffer.ptr);
            const data = this.buffer[@sizeOf(io.GetPropertyReply)..];
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
        const formats_ptr: [*]io.PixelFormat = @ptrFromInt(formats_address);
        const formats = formats_ptr[0..success.num_formats];

        const screen = util.first_success_screen(success) orelse {
            log.err("success has no screens", .{});
            return error.X11ProtocolError;
        };

        const depth = util.first_screen_depth(screen) orelse {
            log.err("screen has no depths", .{});
            return error.X11ProtocolError;
        };

        const visual = util.first_depth_visual(depth) orelse {
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
        window_id: u32,
        property_id: u32,
        value: u32,
    ) !void {
        const format = 32; // TODO: make format configurable
        const data_len = 1; // TODO: support multiple values
        const mode = io.ChangePropertyMode.replace; // TOOD: support all modes
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(io.ChangePropertyRequest{
            .mode = mode,
            .request_len = io.ChangePropertyRequest.requestLen(format, data_len),
            .window_id = window_id,
            .property_id = property_id,
            .type_id = none, // ignored? (docs say "uninterpreted")
            .format = format,
            .data_len = data_len,
        });

        try writer.writeInt(u32, value, arch.endian());
    }

    pub fn createWindow(this: *Server) !u32 {
        const num_flags = 2;
        const window_id = this.getNextId();
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(io.CreateWindowRequest{
            .depth = 0, // TODO: figure out root window depth
            .request_len = io.CreateWindowRequest.requestLen(num_flags),
            .window_id = window_id,
            .parent_id = this.root_window_id,
            .class = io.CreateWindowClass.input_output,
            .value_mask = .{
                .background_pixel = true,
                .event_mask = true,
            },
        });

        try writer.writeInt(u32, 0xff000000, arch.endian());
        try writer.writeStruct(io.EventSet.all);

        return window_id;
    }

    pub fn destroyWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(io.DestroyWindowRequest{
            .window_id = window_id,
        });
    }

    pub fn getProperty(
        this: *Server,
        window_id: u32,
        property_id: u32,
    ) !Property {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(io.GetPropertyRequest{
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

        const reply = fromPtr(io.GetPropertyReply, buffer.ptr);
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

        try writer.writeStruct(io.InternAtomRequest{
            .only_if_exists = must_exist,
            .request_len = io.InternAtomRequest.requestLen(name.len),
            .name_len = @intCast(name.len),
        });

        try writer.writeAll(name);
        try writer.writeByteNTimes(0, pad(usize, name.len) - name.len);

        while (this.reply_data == null) {
            try this.readMessage();
        }

        const reply_data = this.reply_data.?;
        const reply = fromPtr(io.InternAtomReply, reply_data.ptr);

        this.allocator.free(reply_data);
        this.reply_data = null;

        return reply.atom;
    }

    pub fn mapWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(io.MapWindowRequest{
            .window_id = window_id,
        });
    }

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

        var pollfds = [1]pollfd{pollfd{
            .fd = this.connection.stream.handle,
            .events = std.os.linux.POLL.IN,
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
    /// and a .handler has been setup, the message will be passed to the
    /// handler.
    /// TODO: confirm behavior when no data is available
    fn readMessage(this: *Server) !void {
        const reader = this.connection.stream.reader();

        this.read_mutex.lock();
        defer this.read_mutex.unlock();

        const info = try reader.readStruct(GenericMessage);
        const code: io.Code = @enumFromInt(@intFromEnum(info.code) & 0x7f);
        const message: ?Message = switch (code) {
            .@"error" => Message{
                .@"error" = fromPtr(io.Error, &info),
            },
            .reply => blk: {
                const generic = fromPtr(GenericReply, &info);
                const generic_data = std.mem.asBytes(&generic);
                const data = try this.allocator.alloc(u8, generic.sizeOf());
                errdefer this.allocator.free(data);

                // write generic to data; copy extended bytes from socket
                @memcpy(data[0..@sizeOf(GenericReply)], generic_data);
                _ = try reader.readAll(data[@sizeOf(GenericReply)..]);
                // data now contains full reply with all related data

                if (this.reply_data != null) {
                    @panic("did not clean up last reply");
                }

                this.reply_data = data;
                break :blk null; // null result won't trigger handler
            },
            .focus_in => Message{
                .focus_in = fromPtr(io.FocusInEvent, &info),
            },
            .focus_out => Message{
                .focus_out = fromPtr(io.FocusOutEvent, &info),
            },
            .keymap_notify => Message{
                .keymap_notify = fromPtr(io.KeymapNotifyEvent, &info),
            },
            .expose => Message{
                .expose = fromPtr(io.ExposeEvent, &info),
            },
            .visibility_notify => Message{
                .visibility_notify = fromPtr(io.VisibilityNotifyEvent, &info),
            },
            .map_notify => Message{
                .map_notify = fromPtr(io.MapNotifyEvent, &info),
            },
            .reparent_notify => Message{
                .reparent_notify = fromPtr(io.ReparentNotifyEvent, &info),
            },
            .property_notify => Message{
                .property_notify = fromPtr(io.PropertyNotifyEvent, &info),
            },
            .client_message => Message{
                .client_message = fromPtr(io.ClientMessageEvent, &info),
            },
            else => null,
        };

        if (message != null and this.handler != null) {
            this.handler.?(this, message.?);
        }
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

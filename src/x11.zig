const std = @import("std");
const setup = @import("x11-setup.zig");
const event = @import("x11-event.zig");
const res = @import("x11-resource.zig");
const req = @import("x11-request.zig");
const msg = @import("x11-message.zig");
const util = @import("x11-util.zig");
const assert = std.debug.assert;
const endian = @import("builtin").cpu.arch.endian();

pub const log = std.log.scoped(.x11);

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
        const formats_data = vendor_data[util.pad(u16, success.vendor_len)..];
        const formats_address = @intFromPtr(formats_data.ptr);
        const formats_ptr: [*]res.PixelFormat = @ptrFromInt(formats_address);
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
        const request_len = @sizeOf(req.CreateWindow) / 4 + flag_count;
        const window_id = this.getNextId();
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        // basic request info
        try writer.writeStruct(req.CreateWindow{
            .depth = 0, // TODO: figure out root window depth
            .request_len = request_len,
            .window_id = window_id,
            .parent_id = this.root_window_id,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .class = req.WindowClass.input_output,
            .value_mask = .{
                .background_pixel = true,
                .event_mask = true,
            },
        });

        // background_pixel
        try writer.writeInt(u32, 0xff000000, endian);

        // enable all events
        try writer.writeStruct(res.EventSet.all);

        return window_id;
    }

    pub fn mapWindow(this: *Server, window_id: u32) !void {
        const writer = this.connection.stream.writer();

        this.write_mutex.lock();
        defer this.write_mutex.unlock();

        try writer.writeStruct(req.MapWindow{
            .window_id = window_id,
        });
    }

    pub fn readMessage(this: *Server) !?msg.Message {
        var buffer: [32]u8 = undefined;
        var name: [:0]const u8 = "";

        const address = @intFromPtr(&buffer);
        const reader = this.connection.stream.reader();

        this.read_mutex.lock();
        defer this.read_mutex.unlock();

        _ = try reader.readAll(buffer[0..]);

        if (buffer[0] > 1 and buffer[0] <= 35) {
            name = @tagName(@as(msg.Code, @enumFromInt(buffer[0])));
        }

        switch (buffer[0]) {
            @intFromEnum(msg.Code.@"error") => {
                return msg.Message{
                    .@"error" = @as(*msg.Error, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.focus_in) => {
                return msg.Message{
                    .focus_in = @as(*event.FocusIn, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.focus_out) => {
                return msg.Message{
                    .focus_out = @as(*event.FocusOut, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.keymap_notify) => {
                return msg.Message{
                    .keymap_notify = @as(*event.KeymapNotify, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.expose) => {
                return msg.Message{
                    .expose = @as(*event.Expose, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.visbility_notify) => {
                return msg.Message{
                    .visbility_notify = @as(*event.VisibilityNotify, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.map_notify) => {
                return msg.Message{
                    .map_notify = @as(*event.MapNotify, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.reparent_notify) => {
                return msg.Message{
                    .reparent_notify = @as(*event.ReparentNotify, @ptrFromInt(address)).*,
                };
            },
            @intFromEnum(msg.Code.property_notify) => {
                return msg.Message{
                    .property_notify = @as(*event.PropertyNotify, @ptrFromInt(address)).*,
                };
            },
            else => {
                return null;
            },
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

const std = @import("std");
const x11 = @import("x11.zig");
const TagPayload = std.meta.TagPayload;

var atoms = struct {
    WM_DELETE_WINDOW: u32 = x11.none,
    WM_PROTOCOLS: u32 = x11.none,
    WM_STATE: u32 = x11.none,
    _NET_FRAME_EXTENTS: u32 = x11.none,
    _NET_WM_NAME: u32 = x11.none,
    _NET_WM_STATE: u32 = x11.none,
}{};

const AppContext = struct {
    server: *x11.Server,
    running: bool = true,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.handshake(allocator, connection);
    defer server.deinit();

    var context = AppContext{ .server = &server };
    server.registerHandler(handleMessage, @ptrCast(&context));
    try internAtoms(&server);

    const window_id = try server.createWindow();
    const protocols = try server.getProperty(window_id, atoms.WM_PROTOCOLS);
    defer protocols.deinit();

    try server.mapWindow(window_id);
    while (context.running) try server.readOneWait();

    std.process.exit(0);
}

fn handleMessage(message: x11.Message, context: ?*anyopaque) void {
    const ctx = @as(*AppContext, @ptrCast(@alignCast(context.?)));

    switch (message) {
        .@"error" => |err| std.log.err("server sent: {any}", .{err}),
        .reply => unreachable,
        .client_message => |evt| handleClientMessage(evt, ctx),
        else => {},
    }
}

fn handleClientMessage(
    evt: TagPayload(x11.Message, .client_message),
    context: *AppContext,
) void {
    if (evt.type == atoms.WM_PROTOCOLS) handleWMProtocols(evt, context);
}

fn handleWMProtocols(
    evt: TagPayload(x11.Message, .client_message),
    context: *AppContext,
) void {
    const datum = @as(*u32, @ptrFromInt(@intFromPtr(&evt.data))).*;
    if (datum == atoms.WM_DELETE_WINDOW) handleDeleteWindow(evt, context);
}

fn handleDeleteWindow(
    evt: TagPayload(x11.Message, .client_message),
    context: *AppContext,
) void {
    context.server.destroyWindow(evt.window_id) catch |err| {
        std.log.err("could not destroy window {d}: {any}", .{
            evt.window_id,
            err,
        });

        return;
    };

    context.running = false;
}

fn internAtoms(server: *x11.Server) !void {
    inline for (@typeInfo(@TypeOf(atoms)).@"struct".fields) |field| {
        @field(atoms, field.name) = try server.internAtom(field.name, true);
    }
}

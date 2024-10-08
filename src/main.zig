const std = @import("std");
const x11 = @import("x11.zig");

var atoms = struct {
    WM_PROTOCOLS: u32 = x11.none,
    WM_DELETE_WINDOW: u32 = x11.none,
}{};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.handshake(allocator, connection);
    defer server.deinit();

    server.handler = handleMessage;
    try internAtoms(&server);

    const window_id = try server.createWindow();
    const protocols = try server.getProperty(window_id, atoms.WM_PROTOCOLS);
    defer protocols.deinit();

    try server.mapWindow(window_id);
    while (true) try server.readOneWait();

    std.process.exit(0);
}

fn handleMessage(server: *x11.Server, message: x11.Message) void {
    switch (message) {
        .@"error" => |err| std.log.err("{any}", .{err}),
        .reply => unreachable,
        .client_message => |evt| {
            if (evt.type == atoms.WM_PROTOCOLS) {
                const datum = @as(*u32, @ptrFromInt(@intFromPtr(&evt.data))).*;

                if (datum == atoms.WM_DELETE_WINDOW) {
                    server.destroyWindow(evt.window_id) catch unreachable;
                }
            }
        },
        else => {},
    }
}

fn internAtoms(server: *x11.Server) !void {
    inline for (@typeInfo(@TypeOf(atoms)).@"struct".fields) |field| {
        @field(atoms, field.name) = try server.internAtom(field.name, true);
    }
}

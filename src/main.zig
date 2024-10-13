const std = @import("std");
const app = @import("app.zig");
const handle = @import("handle.zig");
const x11 = @import("x11.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};

    defer if (gpa.deinit() == .leak) {
        std.log.err("memory leak detected\n", .{});
    };

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.handshake(allocator, connection);
    defer server.deinit();

    var context = app.Context{ .server = &server };
    server.registerHandler(handle.message, @ptrCast(&context));
    try internAtoms(&server, &context);

    const window_id = try server.createWindow();
    const protocols = try server.getProperty(window_id, context.atoms.WM_PROTOCOLS);
    defer protocols.deinit();

    try server.mapWindow(window_id);
    while (context.running) try server.readOneWait();

    std.process.exit(0);
}

fn internAtoms(server: *x11.Server, context: *app.Context) !void {
    inline for (@typeInfo(app.Atoms).@"struct".fields) |field| {
        @field(context.atoms, field.name) = try server.internAtom(field.name, true);
    }
}

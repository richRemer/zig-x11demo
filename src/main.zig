const std = @import("std");
const x11 = @import("x11.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.handshake(allocator, connection);
    defer server.deinit();
    _ = server.attachHandler(handleMessage);

    const window_id = try server.createWindow(0, 0, 100, 100);
    _ = try server.mapWindow(window_id);

    const status = eventLoop(&server);
    std.process.exit(status);
}

fn handleMessage(message: x11.Message) void {
    switch (message) {
        .@"error" => |err| std.log.err("{any}", .{err}),
        .reply => unreachable,
        else => {},
    }
}

fn eventLoop(server: *x11.Server) u8 {
    const fd_count = 1;
    const unlimited_timeout: i32 = -1;

    var running = true;
    var pollfds: [1]std.os.linux.pollfd = undefined;

    pollfds[0] = std.os.linux.pollfd{
        .fd = server.connection.stream.handle,
        .events = 0x1, // POLLIN (from poll.h)
        .revents = 0,
    };

    while (running) {
        _ = std.os.linux.poll(&pollfds, fd_count, unlimited_timeout);

        if (pollfds[0].revents & 0x8 == 0x8) { // POLERR (from poll.h)
            x11.log.err("poll error", .{});
        }

        if (pollfds[0].revents & 0x10 == 0x10) { // POLLHUP (from poll.h)
            x11.log.debug("connection closed", .{});
            running = false;
        }

        server.readMessage() catch {
            x11.log.err("could not read message from X11 server", .{});
        };
    }

    return 0;
}

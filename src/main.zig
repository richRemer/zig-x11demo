const std = @import("std");
const x11 = @import("x11.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.setup(allocator, connection);
    defer server.deinit();

    const wid = try server.createWindow(0, 0, 100, 100);
    std.debug.print("wid: {d}\n", .{wid});

    const status = eventLoop(server);
    std.process.exit(status);
}

fn eventLoop(server: x11.Server) u8 {
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

        // get reply messages
    }

    return 0;
}

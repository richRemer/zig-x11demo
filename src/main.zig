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
    _ = server.attachHandler(handleMessage);

    atoms.WM_PROTOCOLS = try server.internAtom("WM_PROTOCOLS", true);
    atoms.WM_DELETE_WINDOW = try server.internAtom("WM_DELETE_WINDOW", true);

    std.debug.print("Atoms: {any}\n", .{atoms});

    const window_id = try server.createWindow(0, 0, 100, 100);
    _ = try server.mapWindow(window_id);

    const status = eventLoop(&server);
    std.process.exit(status);
}

fn handleMessage(message: x11.Message) void {
    switch (message) {
        .@"error" => |err| std.log.err("{any}", .{err}),
        .reply => unreachable,
        .client_message => |evt| std.log.debug("{any}", .{evt}),
        else => {},
    }
}

fn eventLoop(server: *x11.Server) u8 {
    const linux = std.os.linux;
    const fd_count = 1;
    const unlimited_timeout: i32 = -1;

    var running = true;
    var pollfds: [1]linux.pollfd = undefined;

    pollfds[0] = linux.pollfd{
        .fd = server.connection.stream.handle,
        .events = linux.POLL.IN,
        .revents = 0,
    };

    while (running) {
        _ = linux.poll(&pollfds, fd_count, unlimited_timeout);

        if (pollfds[0].revents & linux.POLL.ERR == linux.POLL.ERR) {
            x11.log.err("poll error", .{});
        }

        if (pollfds[0].revents & linux.POLL.HUP == linux.POLL.HUP) {
            x11.log.debug("connection closed", .{});
            running = false;
        }

        server.readMessage() catch {
            x11.log.err("could not read message from X11 server", .{});
        };
    }

    return 0;
}

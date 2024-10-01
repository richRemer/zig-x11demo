const std = @import("std");
const Protocol = @import("x11.zig").Protocol;

fn validInt(string: []const u8) bool {
    for (string) |ch| if (ch < '0' or ch > '9') return false;
    return true;
}

fn parseDisplayNumbers(string: []const u8) ParsedDisplay {
    // TODO: limit scan to reasonable number of bytes
    if (std.mem.lastIndexOfScalar(u8, string, ':')) |colon| {
        if (std.mem.lastIndexOfScalar(u8, string[colon..], '.')) |index| {
            const dot = colon + index;

            if (validInt(string[dot + 1 ..]) and validInt(string[colon + 1 .. dot])) {
                return .{
                    .string = string,
                    .display = string[colon + 1 .. dot],
                    .screen = string[dot + 1 ..],
                };
            }
        } else {
            if (validInt(string[colon + 1 ..])) {
                return .{
                    .string = string,
                    .display = string[colon + 1 ..],
                };
            }
        }
    }

    return .{ .string = string };
}

fn parseDisplay(string: []const u8) ParsedDisplay {
    if (string.len == 0) {
        return .{ .string = string };
    }

    var display = parseDisplayNumbers(string);
    var rest = string[0..];

    if (display.display.len > 0) {
        const display_ptr: [*]const u8 = @ptrCast(display.display);
        const string_ptr: [*]const u8 = @ptrCast(display.string);
        rest = string[0..(display_ptr - string_ptr - 1)];
    }

    inline for (std.meta.fields(Protocol)) |field| {
        const ch = @as(Protocol, @enumFromInt(field.value)).getDelimiter();
        const delim = &[1:0]u8{ch};

        if (field.value == 0) {
            continue;
        } else if (std.mem.startsWith(u8, string, field.name ++ delim)) {
            display.protocol = string[0..field.name.len];
            rest = rest[field.name.len + 1 ..];
            break;
        }
    }

    if (rest.len > 0 and rest[0] == '/' and display.protocol.len == 0) {
        display.path = rest[0..];
    } else if (std.mem.eql(u8, "unix", display.protocol)) {
        display.path = rest[0..];
    } else {
        display.host = rest[0..];
    }

    return display;
}

const ParsedDisplay = struct {
    string: []const u8,
    protocol: []const u8 = "",
    path: []const u8 = "",
    host: []const u8 = "",
    display: []const u8 = "",
    screen: []const u8 = "",
};

pub const Display = struct {
    name: []const u8,
    protocol: Protocol = .unknown,
    path: ?[]const u8 = null,
    host: ?[]const u8 = null,
    display: u8 = 0,
    screen: u8 = 0,

    pub fn init(display: ?[]const u8) !Display {
        //log.debug("initializing X11 display", .{});

        const name = display orelse std.posix.getenv("DISPLAY") orelse "";

        if (name.len == 0) {
            //log.err("no DISPLAY environment variable", .{});
            return error.X11NoDisplay;
        }

        const parsed = parseDisplay(name);
        var this = Display{ .name = name };

        // TODO: xauth (copy from ~/.Xauthority maybe? q.v., man 1 xauth)
        if (parsed.path.len > 0 or std.mem.eql(u8, "unix", parsed.protocol)) {
            // TODO: use something better than .statFile to check if exists
            _ = try std.fs.cwd().statFile(parsed.path);
            this.protocol = .unix;
            this.path = parsed.path;
        }

        if (parsed.host.len > 0) {
            this.protocol = p: inline for (std.meta.fields(Protocol)) |field| {
                if (std.mem.eql(u8, field.name, parsed.protocol)) {
                    break :p @as(Protocol, @enumFromInt(field.value));
                }
            } else Protocol.tcp;
            this.host = parsed.host;
        }

        if (parsed.display.len > 0) {
            this.display = try std.fmt.parseInt(u8, parsed.display, 10);
        }

        if (parsed.screen.len > 0) {
            this.screen = try std.fmt.parseInt(u8, parsed.screen, 10);
        }

        return this;
    }

    pub fn connect(this: *Display) !void {
        // TODO: support multi-threaded apps with a Mutex wrapping connect
        // TODO: q.v., std/Thread/Mutex.zig

        try switch (this.protocol) {
            .unix => this.connectUnix(),
            .tcp => this.connectTCP(),
            .inet => this.connectTCP(),
            .inet6 => this.connectTCP(),
            else => return error.X11UnknownProtocol,
        };
    }

    fn connectUnix(this: *Display) !void {
        _ = this;
        // TODO: q.v. notes.md for resource links
        // TODO: verify stat of path is necessary; Apple - for example - does
        // TODO: not stat anything, but also does not appear to support paths
        // TODO: other than the default
        // TODO: on the other hand, Apple appears to support non-0 displays,
        // TODO: while XOrg does not appear to
    }

    fn connectTCP(this: *Display) !void {
        _ = this;
    }

    fn handshake(this: *Display) !void {
        _ = this;

        // pairs of (int)len, (void*)data, followed by XCB_PAD(message.len)
        //  * xcb_setup_request_t (q.v., github:corngood/libxcb)
        //  * XCB_PAD(sizeof(xcb_setup_request_t))
        //  * auth info (q.v., xcb_conn.c:151)
        // ultimately seems to come down to writing to socket (TCP/Unix)
        //  * xcb_setup_request_t + PAD
        // q.v., std.posix for socket-related functions
    }
};

test "parseDisplayNumbers with empty string" {
    const display = parseDisplayNumbers("");

    try std.testing.expectEqualSlices(u8, "", display.string);
    try std.testing.expectEqualSlices(u8, "", display.display);
    try std.testing.expectEqualSlices(u8, "", display.screen);
}

test "parseDisplayNumbers with no display or screen" {
    const display = parseDisplayNumbers("C:/foo.txt");

    try std.testing.expectEqualSlices(u8, "C:/foo.txt", display.string);
    try std.testing.expectEqualSlices(u8, "", display.display);
    try std.testing.expectEqualSlices(u8, "", display.screen);
}

test "parseDisplayNumbers with display only" {
    const display = parseDisplayNumbers(":1");

    try std.testing.expectEqualSlices(u8, ":1", display.string);
    try std.testing.expectEqualSlices(u8, "1", display.display);
    try std.testing.expectEqualSlices(u8, "", display.screen);
}

test "parseDisplayNumbers with display and screen only" {
    const display = parseDisplayNumbers(":2.3");

    try std.testing.expectEqualSlices(u8, ":2.3", display.string);
    try std.testing.expectEqualSlices(u8, "2", display.display);
    try std.testing.expectEqualSlices(u8, "3", display.screen);
}

test "parseDisplayNumbers with display" {
    const display = parseDisplayNumbers("C:/foo.txt:4");

    try std.testing.expectEqualSlices(u8, "C:/foo.txt:4", display.string);
    try std.testing.expectEqualSlices(u8, "4", display.display);
    try std.testing.expectEqualSlices(u8, "", display.screen);
}

test "parseDisplayNumbers with display and screen" {
    const display = parseDisplayNumbers("C:/foo.txt:5.6");

    try std.testing.expectEqualSlices(u8, "C:/foo.txt:5.6", display.string);
    try std.testing.expectEqualSlices(u8, "5", display.display);
    try std.testing.expectEqualSlices(u8, "6", display.screen);
}

test "parseDisplay with display" {
    const display = parseDisplay(":0");

    try std.testing.expectEqualSlices(u8, ":0", display.string);
    try std.testing.expectEqualSlices(u8, "", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "", display.host);
    try std.testing.expectEqualSlices(u8, "0", display.display);
    try std.testing.expectEqualSlices(u8, "", display.screen);
}

test "parseDisplay with display and screen" {
    const display = parseDisplay(":1.2");

    try std.testing.expectEqualSlices(u8, ":1.2", display.string);
    try std.testing.expectEqualSlices(u8, "", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "", display.host);
    try std.testing.expectEqualSlices(u8, "1", display.display);
    try std.testing.expectEqualSlices(u8, "2", display.screen);
}

test "parseDisplay with absolute path" {
    const display = parseDisplay("/foo:3.4");

    try std.testing.expectEqualSlices(u8, "/foo:3.4", display.string);
    try std.testing.expectEqualSlices(u8, "", display.protocol);
    try std.testing.expectEqualSlices(u8, "/foo", display.path);
    try std.testing.expectEqualSlices(u8, "", display.host);
    try std.testing.expectEqualSlices(u8, "3", display.display);
    try std.testing.expectEqualSlices(u8, "4", display.screen);
}

test "parseDisplay with 'unix' protocol" {
    const display = parseDisplay("unix:/foo:5.6");

    try std.testing.expectEqualSlices(u8, "unix:/foo:5.6", display.string);
    try std.testing.expectEqualSlices(u8, "unix", display.protocol);
    try std.testing.expectEqualSlices(u8, "/foo", display.path);
    try std.testing.expectEqualSlices(u8, "", display.host);
    try std.testing.expectEqualSlices(u8, "5", display.display);
    try std.testing.expectEqualSlices(u8, "6", display.screen);
}

test "parseDisplay with 'tcp' protocol" {
    const display = parseDisplay("tcp/example.com:9.10");

    try std.testing.expectEqualSlices(u8, "tcp/example.com:9.10", display.string);
    try std.testing.expectEqualSlices(u8, "tcp", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "example.com", display.host);
    try std.testing.expectEqualSlices(u8, "9", display.display);
    try std.testing.expectEqualSlices(u8, "10", display.screen);
}

test "parseDisplay with 'inet' protocol" {
    const display = parseDisplay("inet/2.3.4.5:11.12");

    try std.testing.expectEqualSlices(u8, "inet/2.3.4.5:11.12", display.string);
    try std.testing.expectEqualSlices(u8, "inet", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "2.3.4.5", display.host);
    try std.testing.expectEqualSlices(u8, "11", display.display);
    try std.testing.expectEqualSlices(u8, "12", display.screen);
}

test "parseDisplay with 'inet6' protocol" {
    const display = parseDisplay("inet6/[::1]:13.14");

    try std.testing.expectEqualSlices(u8, "inet6/[::1]:13.14", display.string);
    try std.testing.expectEqualSlices(u8, "inet6", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "[::1]", display.host);
    try std.testing.expectEqualSlices(u8, "13", display.display);
    try std.testing.expectEqualSlices(u8, "14", display.screen);
}

test "parseDisplay with host" {
    const display = parseDisplay("foo:7.8");

    try std.testing.expectEqualSlices(u8, "foo:7.8", display.string);
    try std.testing.expectEqualSlices(u8, "", display.protocol);
    try std.testing.expectEqualSlices(u8, "", display.path);
    try std.testing.expectEqualSlices(u8, "foo", display.host);
    try std.testing.expectEqualSlices(u8, "7", display.display);
    try std.testing.expectEqualSlices(u8, "8", display.screen);
}

test "initialize Display with empty display" {
    const display = Display.init("");
    try std.testing.expectError(error.X11NoDisplay, display);
}

test "initialize Display with 'unix' protocol but no file path" {
    try std.testing.expectError(error.FileNotFound, Display.init("unix:"));
}

test "initialize Display with absolute path" {
    var buffer: [std.fs.max_path_bytes]u8 = undefined;
    var tmpdir = std.testing.tmpDir(.{});
    defer tmpdir.cleanup();

    const file = try tmpdir.dir.createFile("mocket", .{});
    const path = try tmpdir.dir.realpath("mocket", &buffer);

    var display = try Display.init(path);
    file.close();
    try display.connect();

    try std.testing.expectEqual(.unix, display.protocol);
    try std.testing.expect(null != display.path);
    try std.testing.expectEqualSlices(u8, path, display.path.?);
    try std.testing.expectEqual(0, display.screen);
}

test "initialize Display with 'unix' protocol and absolute path" {
    var buffer: [std.fs.max_path_bytes * 2 + 5]u8 = undefined;
    var tmpdir = std.testing.tmpDir(.{});
    defer tmpdir.cleanup();

    const slice = buffer[std.fs.max_path_bytes..];
    const file = try tmpdir.dir.createFile("mocket", .{});
    const path = try tmpdir.dir.realpath("mocket", &buffer);
    const init = try std.fmt.bufPrint(slice, "unix:{s}", .{path});

    var display = try Display.init(init);
    file.close();
    try display.connect();

    try std.testing.expectEqual(.unix, display.protocol);
    try std.testing.expect(null != display.path);
    try std.testing.expectEqualSlices(u8, path, display.path.?);
    try std.testing.expectEqual(0, display.screen);
}

test "initialize Display with absolute path and display" {
    var buffer: [std.fs.max_path_bytes * 2 + 2]u8 = undefined;
    var tmpdir = std.testing.tmpDir(.{});
    defer tmpdir.cleanup();

    const slice = buffer[std.fs.max_path_bytes..];
    const file = try tmpdir.dir.createFile("mocket", .{});
    const path = try tmpdir.dir.realpath("mocket", &buffer);
    const init = try std.fmt.bufPrint(slice, "{s}:2", .{path});

    var display = try Display.init(init);
    file.close();
    try display.connect();

    try std.testing.expectEqual(.unix, display.protocol);
    try std.testing.expect(null != display.path);
    try std.testing.expectEqualSlices(u8, path, display.path.?);
    try std.testing.expectEqual(2, display.display);
}

test "initialize Display with 'unix' protocol, absolute path, and display" {
    var buffer: [std.fs.max_path_bytes * 2 + 7]u8 = undefined;
    var tmpdir = std.testing.tmpDir(.{});
    defer tmpdir.cleanup();

    const slice = buffer[std.fs.max_path_bytes..];
    const file = try tmpdir.dir.createFile("mocket", .{});
    const path = try tmpdir.dir.realpath("mocket", &buffer);
    const init = try std.fmt.bufPrint(slice, "unix:{s}:4", .{path});

    var display = try Display.init(init);
    file.close();
    try display.connect();

    try std.testing.expectEqual(.unix, display.protocol);
    try std.testing.expect(null != display.path);
    try std.testing.expectEqualSlices(u8, path, display.path.?);
    try std.testing.expectEqual(4, display.display);
}

const std = @import("std");
const setup = @import("x11-setup.zig");
const io = @import("x11-io.zig");
const endian = @import("builtin").cpu.arch.endian();

pub inline fn first_success_screen(success: *setup.Success) ?*io.Screen {
    if (success.num_screens > 0) {
        var address = @intFromPtr(success);

        address += @sizeOf(setup.Success);
        address += pad(u16, success.vendor_len);
        address += success.num_formats * @sizeOf(io.PixelFormat);

        return @ptrFromInt(address);
    } else {
        return null;
    }
}

pub inline fn first_screen_depth(screen: *io.Screen) ?*io.Depth {
    if (screen.num_depths > 0) {
        return @ptrFromInt(@intFromPtr(screen) + @sizeOf(io.Screen));
    } else {
        return null;
    }
}

pub inline fn first_depth_visual(depth: *io.Depth) ?*io.Visual {
    if (depth.num_visuals > 0) {
        return @ptrFromInt(@intFromPtr(depth) + @sizeOf(io.Depth));
    } else {
        return null;
    }
}

pub inline fn pad(comptime T: type, len: T) T {
    return len + ((4 - (len % 4)) % 4);
}

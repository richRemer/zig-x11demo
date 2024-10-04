const std = @import("std");
const setup = @import("x11-setup.zig");
const res = @import("x11-resource.zig");
const endian = @import("builtin").cpu.arch.endian();

pub inline fn first_success_screen(success: *setup.Success) ?*res.Screen {
    if (success.num_screens > 0) {
        var address = @intFromPtr(success);

        address += @sizeOf(setup.Success);
        address += x_pad(u16, success.vendor_len);
        address += success.num_formats * @sizeOf(res.PixelFormat);

        return @ptrFromInt(address);
    } else {
        return null;
    }
}

pub inline fn first_screen_depth(screen: *res.Screen) ?*res.Depth {
    if (screen.num_depths > 0) {
        return @ptrFromInt(@intFromPtr(screen) + @sizeOf(res.Screen));
    } else {
        return null;
    }
}

pub inline fn first_depth_visual(depth: *res.Depth) ?*res.Visual {
    if (depth.num_visuals > 0) {
        return @ptrFromInt(@intFromPtr(depth) + @sizeOf(res.Depth));
    } else {
        return null;
    }
}

pub inline fn x_pad(comptime T: type, len: T) T {
    return len + ((4 - (len % 4)) % 4);
}

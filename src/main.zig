const std = @import("std");
const x11 = @import("x11.zig");

pub fn main() void {
  std.log.info("X11 version {}.", .{x11.protocolVersion()});
  //std.log.info("X11 Display {}.", .{x11.openDisplay()});
}

const std = @import("std");
const c = @cImport({
  @cInclude("X11/X.h");
});

pub fn protocolVersion() u8 {
  return c.X_PROTOCOL;
}

pub fn openDisplay(display: ?[:0] const u8) !u8 {
  log.debug("opening X11 display", .{});

  const display_name = display orelse std.posix.getenv("DISPLAY");

  if (display_name == null) {
    log.err("no DISPLAY environment variable", .{});
    return error.X11NoDisplay;
  }

  return c.X_PROTOCOL;
}

pub const log = std.log.scoped(.x11);

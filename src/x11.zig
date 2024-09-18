const std = @import("std");
const c = @cImport({
  @cInclude("X11/X.h");
});

pub export fn protocolVersion() u8 {
  return c.X_PROTOCOL;
}

pub export fn openDisplay() u8 {
  log.debug("opening X11 display", .{});
  return c.X_PROTOCOL;
}

pub const log = std.log.scoped(.x11);

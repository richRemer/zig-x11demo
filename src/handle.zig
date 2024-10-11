const std = @import("std");
const app = @import("app.zig");
const x11 = @import("x11.zig");

pub fn message(msg: x11.Message, context: ?*anyopaque) void {
    const ctx = @as(*app.Context, @ptrCast(@alignCast(context.?)));

    switch (msg) {
        .@"error" => |err| std.log.err("server sent: {any}", .{err}),
        .reply => unreachable,
        .client_message => |evt| clientMessage(evt, ctx),
        .expose => |evt| expose(evt, ctx),
        .focus_in => |evt| focusIn(evt, ctx),
        .focus_out => |evt| focusOut(evt, ctx),
        .keymap_notify => |evt| keymapNotify(evt, ctx),
        .map_notify => |evt| mapNotify(evt, ctx),
        .property_notify => |evt| propertyNotify(evt, ctx),
        .reparent_notify => |evt| reparentNotify(evt, ctx),
        .visibility_notify => |evt| visibilityNotify(evt, ctx),
        .button_press,
        .button_release,
        .circulate_notify,
        .circulate_request,
        .colormap_notify,
        .configure_notify,
        .configure_request,
        .create_notify,
        .destroy_notify,
        .enter_notify,
        .graphics_exposure,
        .gravity_notify,
        .key_press,
        .key_release,
        .leave_notify,
        .map_request,
        .mapping_notify,
        .motion_notify,
        .no_exposure,
        .resize_request,
        .selection_clear,
        .selection_notify,
        .selection_request,
        .unmap_notify,
        => |evt| unknownEvent(evt, ctx),
    }
}

fn clientMessage(
    evt: x11.protocol.ClientMessageEvent,
    context: *app.Context,
) void {
    if (evt.type == context.atoms.WM_PROTOCOLS) wmProtocols(evt, context);
}

fn expose(evt: x11.protocol.ExposeEvent, context: *app.Context) void {
    _ = context;

    const wid = evt.window_id;
    const x = evt.x;
    const y = evt.y;
    const w = evt.width;
    const h = evt.height;

    x11.log.debug("wid:{d} expose {d},{d}({d}x{d})", .{ wid, x, y, w, h });
}

fn focusIn(evt: x11.protocol.FocusInEvent, context: *app.Context) void {
    _ = context;

    const wid = evt.window_id;
    const mode = @tagName(evt.mode);
    const detail = @tagName(evt.detail);

    x11.log.debug("wid:{d} focus {s} {s}", .{ wid, mode, detail });
}

fn focusOut(evt: x11.protocol.FocusOutEvent, context: *app.Context) void {
    _ = context;

    const wid = evt.window_id;
    const mode = @tagName(evt.mode);
    const detail = @tagName(evt.detail);

    x11.log.debug("wid:{d} blur {s} {s}", .{ wid, mode, detail });
}

fn keymapNotify(
    evt: x11.protocol.KeymapNotifyEvent,
    context: *app.Context,
) void {
    _ = context;
    x11.log.debug("keymap update: {any}", .{evt.keys});
}

fn mapNotify(evt: x11.protocol.MapNotifyEvent, context: *app.Context) void {
    _ = context;

    const wid = evt.window_id;
    const eid = evt.event_window_id;
    const override = if (evt.override_redirect) " (override redirect)" else "";

    x11.log.debug("wid:{d} mapped {d}{s}", .{ wid, eid, override });
}

fn propertyNotify(
    evt: x11.protocol.PropertyNotifyEvent,
    context: *app.Context,
) void {
    const wid = evt.window_id;
    const atom = context.atoms.lookup(evt.atom_id);
    const timestamp = evt.timestamp;
    const state = @tagName(evt.state);

    x11.log.debug("wid:{d} {s} {s} @ {d}", .{ wid, state, atom, timestamp });
}

fn reparentNotify(
    evt: x11.protocol.ReparentNotifyEvent,
    context: *app.Context,
) void {
    _ = context;

    const wid = evt.window_id;
    const pid = evt.parent_window_id;
    const eid = evt.event_window_id;
    const override = if (evt.override_redirect) " (override redirect)" else "";

    x11.log.debug("wid:{d} reparent {d}/{d}{s}", .{ wid, pid, eid, override });
}

fn visibilityNotify(
    evt: x11.protocol.VisibilityNotifyEvent,
    context: *app.Context,
) void {
    _ = context;

    const wid = evt.window_id;
    const state = @tagName(evt.state);

    x11.log.debug("wid:{d} visibility {s}", .{ wid, state });
}

fn unknownEvent(
    evt: x11.protocol.UnknownEvent,
    context: *app.Context,
) void {
    _ = context;
    const event = @tagName(evt.code);
    x11.log.debug("{s}", .{event});
}

fn wmProtocols(
    evt: x11.protocol.ClientMessageEvent,
    context: *app.Context,
) void {
    const datum = @as(*u32, @ptrFromInt(@intFromPtr(&evt.data))).*;
    if (datum == context.atoms.WM_DELETE_WINDOW) deleteWindow(evt, context);
}

fn deleteWindow(
    evt: x11.protocol.ClientMessageEvent,
    context: *app.Context,
) void {
    const wid = evt.window_id;

    context.server.destroyWindow(wid) catch |err| {
        std.log.err("could not destroy window {d}: {any}", .{ wid, err });
        return;
    };

    context.running = false;
}

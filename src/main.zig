const std = @import("std");
const x11 = @import("x11.zig");
const TagPayload = std.meta.TagPayload;

var atoms = struct {
    WM_DELETE_WINDOW: u32 = x11.none,
    WM_PROTOCOLS: u32 = x11.none,
    WM_STATE: u32 = x11.none,
    _NET_FRAME_EXTENTS: u32 = x11.none,
    _NET_WM_NAME: u32 = x11.none,
    _NET_WM_STATE: u32 = x11.none,

    pub fn lookup(this: @This(), atom_id: u32) []const u8 {
        if (atom_id == this.WM_DELETE_WINDOW) return "WM_DELETE_WINDOW";
        if (atom_id == this.WM_PROTOCOLS) return "WM_PROTOCOLS";
        if (atom_id == this.WM_STATE) return "WM_STATE";
        if (atom_id == this._NET_FRAME_EXTENTS) return "_NET_FRAME_EXTENTS";
        if (atom_id == this._NET_WM_NAME) return "_NET_WM_NAME";
        if (atom_id == this._NET_WM_STATE) return "_NET_WM_STATE";
        return "unknown";
    }
}{};

const AppContext = struct {
    server: *x11.Server,
    running: bool = true,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();
    const connection = try x11.connect(.unix, "/tmp/.X11-unix/X", 0, 0);

    var server = try x11.handshake(allocator, connection);
    defer server.deinit();

    var context = AppContext{ .server = &server };
    server.registerHandler(handleMessage, @ptrCast(&context));
    try internAtoms(&server);

    const window_id = try server.createWindow();
    const protocols = try server.getProperty(window_id, atoms.WM_PROTOCOLS);
    defer protocols.deinit();

    try server.mapWindow(window_id);
    while (context.running) try server.readOneWait();

    std.process.exit(0);
}

fn handleMessage(message: x11.Message, context: ?*anyopaque) void {
    const ctx = @as(*AppContext, @ptrCast(@alignCast(context.?)));

    switch (message) {
        .@"error" => |err| std.log.err("server sent: {any}", .{err}),
        .reply => unreachable,
        .client_message => |evt| handleClientMessage(evt, ctx),
        .expose => |evt| handleExpose(evt, ctx),
        .property_notify => |evt| handlePropertyNotify(evt, ctx),
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
        => |evt| handleUnknownEvent(evt, ctx),
        else => {},
    }
}

fn handleClientMessage(
    evt: x11.protocol.ClientMessageEvent,
    context: *AppContext,
) void {
    if (evt.type == atoms.WM_PROTOCOLS) handleWMProtocols(evt, context);
}

fn handleExpose(evt: x11.protocol.ExposeEvent, context: *AppContext) void {
    _ = context;

    const window_id = evt.window_id;
    const x = evt.x;
    const y = evt.y;
    const w = evt.width;
    const h = evt.height;

    x11.log.debug(
        "wid:{d} expose {d},{d}({d}x{d})",
        .{ window_id, x, y, w, h },
    );
}

fn handlePropertyNotify(
    evt: x11.protocol.PropertyNotifyEvent,
    context: *AppContext,
) void {
    _ = context;

    const window_id = evt.window_id;
    const atom = atoms.lookup(evt.atom_id);
    const timestamp = evt.timestamp;
    const state = @tagName(evt.state);

    x11.log.debug(
        "wid:{d} {s} {s} @ {d}",
        .{ window_id, state, atom, timestamp },
    );
}

fn handleUnknownEvent(
    evt: x11.protocol.UnknownEvent,
    context: *AppContext,
) void {
    _ = context;
    const event = @tagName(evt.code);
    x11.log.debug("{s}", .{event});
}

fn handleWMProtocols(
    evt: x11.protocol.ClientMessageEvent,
    context: *AppContext,
) void {
    const datum = @as(*u32, @ptrFromInt(@intFromPtr(&evt.data))).*;
    if (datum == atoms.WM_DELETE_WINDOW) handleDeleteWindow(evt, context);
}

fn handleDeleteWindow(
    evt: x11.protocol.ClientMessageEvent,
    context: *AppContext,
) void {
    context.server.destroyWindow(evt.window_id) catch |err| {
        std.log.err("could not destroy window {d}: {any}", .{
            evt.window_id,
            err,
        });

        return;
    };

    context.running = false;
}

fn internAtoms(server: *x11.Server) !void {
    inline for (@typeInfo(@TypeOf(atoms)).@"struct".fields) |field| {
        @field(atoms, field.name) = try server.internAtom(field.name, true);
    }
}

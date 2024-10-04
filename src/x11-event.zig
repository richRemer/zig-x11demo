const x11 = @import("x11.zig");

pub const FocusIn = extern struct {
    code: x11.MessageCode = .focus_in,
    detail: x11.FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: x11.FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const FocusOut = extern struct {
    code: x11.MessageCode = .focus_out,
    detail: x11.FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: x11.FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const KeymapNotify = extern struct {
    code: x11.MessageCode = .keymap_notify,
    keys: [31]u8 = [1]u8{0} ** 31,
};

pub const Expose = extern struct {
    code: x11.MessageCode = .expose,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    x: u16,
    y: u16,
    width: u16,
    height: u16,
    count: u16,
    unused_2: [14]u8 = [1]u8{0} ** 14,
};

pub const VisibilityNotify = extern struct {
    code: x11.MessageCode = .visbility_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    state: x11.VisibilityChangeState,
    unused_2: [23]u8 = [1]u8{0} ** 23,
};

pub const MapNotify = extern struct {
    code: x11.MessageCode = .map_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    override_redirect: x11.Bool,
    unused_2: [19]u8 = [1]u8{0} ** 19,
};

pub const ReparentNotify = extern struct {
    code: x11.MessageCode = .reparent_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    parent_window_id: u32,
    x: i16,
    y: i16,
    override_redirect: x11.Bool,
    unused_2: [11]u8 = [1]u8{0} ** 11,
};

pub const PropertyNotify = extern struct {
    code: x11.MessageCode = .property_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    atom_id: u32,
    timestamp: u32,
    state: x11.PropertyChangeState,
    unused_2: [15]u8 = [1]u8{0} ** 15,
};

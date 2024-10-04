const msg = @import("x11-message.zig");

pub const FocusIn = extern struct {
    code: msg.Code = .focus_in,
    detail: FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const FocusOut = extern struct {
    code: msg.Code = .focus_out,
    detail: FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const KeymapNotify = extern struct {
    code: msg.Code = .keymap_notify,
    keys: [31]u8 = [1]u8{0} ** 31,
};

pub const Expose = extern struct {
    code: msg.Code = .expose,
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
    code: msg.Code = .visbility_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    state: VisibilityChangeState,
    unused_2: [23]u8 = [1]u8{0} ** 23,
};

pub const MapNotify = extern struct {
    code: msg.Code = .map_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    override_redirect: bool,
    unused_2: [19]u8 = [1]u8{0} ** 19,
};

pub const ReparentNotify = extern struct {
    code: msg.Code = .reparent_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    parent_window_id: u32,
    x: i16,
    y: i16,
    override_redirect: bool,
    unused_2: [11]u8 = [1]u8{0} ** 11,
};

pub const PropertyNotify = extern struct {
    code: msg.Code = .property_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    atom_id: u32,
    timestamp: u32,
    state: PropertyChangeState,
    unused_2: [15]u8 = [1]u8{0} ** 15,
};

pub const FocusDetail = enum(u8) {
    ancestor,
    virtual,
    inferior,
    nonlinear,
    nonlinear_virtual,
    pointer,
    pointer_root,
    none,
};

pub const FocusMode = enum(u8) {
    normal,
    grab,
    ungrab,
    while_grabbed,
};

pub const PropertyChangeState = enum(u8) {
    new_value,
    deleted,
};

pub const VisibilityChangeState = enum(u8) {
    unobscured,
    partially_obscured,
    fully_obscured,
};

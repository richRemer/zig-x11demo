const x11 = @import("x11.zig");

pub const CharInfo = extern struct {
    left_side_bearing: i16,
    right_side_bearing: i16,
    character_width: i16,
    ascent: i16,
    descent: i16,
    attributes: u16,
};

pub const Depth = extern struct {
    depth: u8,
    unused_1: u8,
    num_visuals: u16,
    unused_2: u32,
};

pub const FontProp = extern struct {
    name: u32,
    value: u32,
};

pub const PixelFormat = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    unused: [5]u8 = [1]u8{0} ** 5,
};

pub const RGB = extern struct {
    red: u16,
    green: u16,
    blue: u16,
    unused: u16,
};

pub const Screen = extern struct {
    root: u32,
    default_colormap: u32,
    white_pixel: u32,
    black_pixel: u32,
    current_input_masks: EventSet,
    width_in_pixels: u16,
    height_in_pixels: u16,
    width_in_millimeters: u16,
    height_in_millimeters: u16,
    min_installed_maps: u16,
    max_installed_maps: u16,
    root_visual: u32,
    backing_stores: BackingStores,
    save_unders: bool,
    root_depth: u8,
    num_depths: u8,
};

pub const String = extern struct {
    name_len: u8,
};

pub const TimeCoord = extern struct {
    timestamp: u32,
    x: i16,
    y: i16,
};

pub const Visual = extern struct {
    visual_id: u32,
    class: VisualClass,
    bits_per_rgb_value: u8,
    colormap_entries: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    unused: u32,
};

pub const DeviceEventSet = packed struct(u32) {
    key_press: bool = false,
    key_release: bool = false,
    button_press: bool = false,
    button_release: bool = false,
    unused_1: u2 = 0,
    pointer_motion: bool = false,
    unused_2: u1 = 0,
    button_1_motion: bool = false,
    button_2_motion: bool = false,
    button_3_motion: bool = false,
    button_4_motion: bool = false,
    button_5_motion: bool = false,
    button_motion: bool = false,
    unused_3: u18 = 0,

    pub const all: DeviceEventSet = .{
        .key_press = true,
        .key_release = true,
        .button_press = true,
        .button_release = true,
        .pointer_motion = true,
        .button_1_motion = true,
        .button_2_motion = true,
        .button_3_motion = true,
        .button_4_motion = true,
        .button_5_motion = true,
        .button_motion = true,
    };
};

pub const EventSet = packed struct(u32) {
    key_press: bool = false,
    key_release: bool = false,
    button_press: bool = false,
    button_release: bool = false,
    enter_window: bool = false,
    leave_window: bool = false,
    pointer_motion: bool = false,
    pointer_motion_hint: bool = false,
    button_1_motion: bool = false,
    button_2_motion: bool = false,
    button_3_motion: bool = false,
    button_4_motion: bool = false,
    button_5_motion: bool = false,
    button_motion: bool = false,
    keymap_state: bool = false,
    exposure: bool = false,
    visibility_change: bool = false,
    structure_notify: bool = false,
    resize_redirect: bool = false,
    substructure_notify: bool = false,
    substructure_redirect: bool = false,
    focus_change: bool = false,
    property_change: bool = false,
    colormap_change: bool = false,
    owner_grab_button: bool = false,
    unused: u7 = 0,

    pub const all: EventSet = .{
        .key_press = true,
        .key_release = true,
        .button_press = true,
        .button_release = true,
        .enter_window = true,
        .leave_window = true,
        .pointer_motion = true,
        .pointer_motion_hint = true,
        .button_1_motion = true,
        .button_2_motion = true,
        .button_3_motion = true,
        .button_4_motion = true,
        .button_5_motion = true,
        .button_motion = true,
        .keymap_state = true,
        .exposure = true,
        .visibility_change = true,
        .structure_notify = true,
        .resize_redirect = true,
        .substructure_notify = true,
        .substructure_redirect = true,
        .focus_change = true,
        .property_change = true,
        .colormap_change = true,
        .owner_grab_button = true,
    };
};

pub const KeyButtonSet = packed struct(u16) {
    shift: bool = false,
    lock: bool = false,
    control: bool = false,
    mod_1: bool = false,
    mod_2: bool = false,
    mod_3: bool = false,
    mod_4: bool = false,
    mod_5: bool = false,
    button_1: bool = false,
    button_2: bool = false,
    button_3: bool = false,
    button_4: bool = false,
    button_5: bool = false,
    unused: u3 = 0,

    pub const KeyButtonSet = .{
        .shift = true,
        .lock = true,
        .control = true,
        .mod_1 = true,
        .mod_2 = true,
        .mod_3 = true,
        .mod_4 = true,
        .mod_5 = true,
        .button_1 = true,
        .button_2 = true,
        .button_3 = true,
        .button_4 = true,
        .button_5 = true,
    };
};

pub const KeySet = packed struct(u16) {
    shift: bool = false,
    lock: bool = false,
    control: bool = false,
    mod_1: bool = false,
    mod_2: bool = false,
    mod_3: bool = false,
    mod_4: bool = false,
    mod_5: bool = false,
    unused: u8 = 0,

    pub const all: KeySet = .{
        .shift = true,
        .lock = true,
        .control = true,
        .mod_1 = true,
        .mod_2 = true,
        .mod_3 = true,
        .mod_4 = true,
        .mod_5 = true,
    };
};

pub const PointerEventSet = packed struct(u32) {
    unused_1: u2 = 0,
    button_press: bool = false,
    button_release: bool = false,
    enter_window: bool = false,
    leave_window: bool = false,
    pointer_motion: bool = false,
    pointer_motion_hint: bool = false,
    button_1_motion: bool = false,
    button_2_motion: bool = false,
    button_3_motion: bool = false,
    button_4_motion: bool = false,
    button_5_motion: bool = false,
    button_motion: bool = false,
    keymap_state: bool = false,
    unused_2: u17 = 0,

    pub const all: PointerEventSet = .{
        .button_press = true,
        .button_release = true,
        .enter_window = true,
        .leave_window = true,
        .pointer_motion = true,
        .pointer_motion_hint = true,
        .button_1_motion = true,
        .button_2_motion = true,
        .button_3_motion = true,
        .button_4_motion = true,
        .button_5_motion = true,
        .button_motion = true,
        .keymap_state = true,
    };
};

pub const BackingStores = enum(u8) {
    never,
    when_mapped,
    always,
};

pub const VisualClass = enum(u8) {
    static_gray,
    gray_scale,
    static_color,
    pseudo_color,
    true_color,
    direct_color,
};

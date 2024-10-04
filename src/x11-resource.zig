const x11 = @import("x11.zig");

pub const PixelFormat = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    unused: [5]u8 = [1]u8{0} ** 5,
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

pub const Depth = extern struct {
    depth: u8,
    unused_1: u8,
    num_visuals: u16,
    unused_2: u32,
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

pub const EventSet = packed struct(u32) {
    key_press: bool = true,
    key_release: bool = true,
    button_press: bool = true,
    button_release: bool = true,
    enter_window: bool = true,
    leave_window: bool = true,
    pointer_motion: bool = true,
    pointer_motion_hint: bool = true,
    button_1_motion: bool = true,
    button_2_motion: bool = true,
    button_3_motion: bool = true,
    button_4_motion: bool = true,
    button_5_motion: bool = true,
    button_motion: bool = true,
    keymap_state: bool = true,
    exposure: bool = true,
    visibility_change: bool = true,
    structure_notify: bool = true,
    resize_redirect: bool = true,
    substructure_notify: bool = true,
    substructure_redirect: bool = true,
    focus_change: bool = true,
    property_change: bool = true,
    colormap_change: bool = true,
    owner_grab_button: bool = true,
    unused: u7 = 0,
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

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
    current_input_masks: x11.Events,
    width_in_pixels: u16,
    height_in_pixels: u16,
    width_in_millimeters: u16,
    height_in_millimeters: u16,
    min_installed_maps: u16,
    max_installed_maps: u16,
    root_visual: u32,
    backing_stores: x11.BackingStores,
    save_unders: x11.Bool,
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
    class: x11.VisualClass,
    bits_per_rgb_value: u8,
    colormap_entries: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    unused: u32,
};

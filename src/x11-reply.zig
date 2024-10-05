const res = @import("x11-resource.zig");
const msg = @import("x11-message.zig");

pub const GetWindowAttributesReply = extern struct {
    code: msg.Code = .reply,
    backing_store: BackingStore,
    sequence_number: u16,
    reply_len: u32 = 3,
    visual: u32,
    class: WindowClass,
    bit_gravity: BitGravity,
    win_gravity: WindowGravity,
    backing_planes: u32,
    backing_pixel: u32,
    save_under: bool,
    map_is_installed: bool,
    map_state: MapState,
    override_redirect: bool,
    colormap: u32,
    all_event_masks: res.EventSet,
    your_event_mask: res.EventSet,
    do_not_propogate_mask: res.DeviceEventSet,
    unused: u16 = 0,
};

pub const GetGeometryReply = extern struct {
    code: msg.Code = .reply,
    depth: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    root: u32,
    x: i16,
    y: i16,
    width: u16,
    height: u16,
    border_width: u16,
    unused: [10]u8 = [1]u8{0} ** 10,
};

pub const QueryTreeReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    root: u32,
    parent: u32,
    num_children: u16,
    unused_2: [14]u8 = [1]u8{0} ** 14,
};

pub const InternAtomReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    atom: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GetAtomNameReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    name_len: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetPropertyReply = extern struct {
    code: msg.Code = .reply,
    format: u8,
    sequence_number: u16,
    reply_len: u32,
    type: u32,
    bytes_after: u32,
    value_len: u32,
    unused: [12]u8 = [1]u8{0} ** 12,
};

pub const ListPropertiesReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_atoms: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetSelectionOwnerReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    owner: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GrabPointerReply = extern struct {
    code: msg.Code = .reply,
    status: GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GrabKeyboardReply = extern struct {
    code: msg.Code = .reply,
    status: GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const QueryPointerReply = extern struct {
    code: msg.Code = .reply,
    same_screen: bool,
    sequence_number: u16,
    reply_len: u32 = 0,
    root: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    win_x: i16, // TODO: should this be child_x?
    win_y: i16, // TODO: should this be child_y?
    mask: res.KeyButtonSet,
    unused: [6]u8 = [1]u8{0} ** 6,
};

pub const GetMotionEventsReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_events: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const TranslateCoordinatesReply = extern struct {
    code: msg.Code = .reply,
    same_screen: bool,
    sequence_number: u16,
    reply_len: u32 = 0,
    child: u32,
    dst_x: i16,
    dst_y: i16,
    unused: [16]u8 = [1]u8{0} ** 16,
};

pub const GetInputFocusReply = extern struct {
    code: msg.Code = .reply,
    revert_to: FocusRevertTo,
    sequence_number: u16,
    reply_len: u32 = 0,
    focus: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryKeymapReply = extern struct {
    code: msg.Code = .reply,
    unused: u8,
    sequence_number: u16,
    reply_len: u32 = 2,
    keys: [32]u8 = [1]u8{0} ** 32,
};

pub const QueryFontReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    min_bounds: res.CharInfo,
    unused_2: u32,
    max_bounds: res.CharInfo,
    unused_3: u32,
    min_char_or_byte2: u16,
    max_char_or_byte2: u16,
    default_char: u16,
    num_properties: u16,
    draw_direction: DrawDirection,
    min_byte1: u8,
    max_byte1: u8,
    all_chars_exist: bool,
    font_ascent: i16,
    font_descent: i16,
    num_char_infos: u32,
};

pub const QueryTextExtentsReply = extern struct {
    code: msg.Code = .reply,
    draw_direction: DrawDirection,
    sequence_number: u16,
    reply_len: u32 = 0,
    font_ascent: i16,
    font_descent: i16,
    overall_ascent: i16,
    overall_descent: i16,
    overall_width: i32,
    overall_left: i32,
    overall_right: i32,
    unused: u32,
};

pub const ListFontsReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_names: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const ListFontsWithInfoReply = extern struct {
    code: msg.Code = .reply,
    name_len: u8,
    sequence_number: u16,
    reply_len: u32,
    min_bounds: res.CharInfo,
    unused_1: u32,
    max_bounds: res.CharInfo,
    unused_2: u32,
    min_char_or_byte2: u16,
    max_char_or_byte2: u16,
    default_char: u16,
    num_properties: u16,
    draw_direction: DrawDirection,
    min_byte1: u8,
    max_byte1: u8,
    all_chars_exist: bool,
    font_ascent: i16,
    font_descent: i16,
    replies_hint: u32,
};

// TODO: determine naming for sentinel

pub const ListFontsWithInfoReplySentinel = extern struct {
    code: msg.Code = .reply,
    last_reply_indicator: u8 = 0,
    sequence_number: u16,
    reply_len: u32 = 7,
    unused: [52]u8 = [1]u8{0} ** 52,
};

pub const GetFontPathReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_paths: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetImageReply = extern struct {
    code: msg.Code = .reply,
    depth: u8,
    sequence_number: u16,
    reply_len: u32,
    visual: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const ListInstalledColormapsReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_cmaps: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const AllocColorReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    red: u16,
    green: u16,
    blue: u16,
    unused_2: u16,
    pixel: u32,
    unused_3: [12]u8 = [1]u8{0} ** 12,
};

pub const AllocNamedColorReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    pixel: u32,
    exact_red: u16,
    exact_green: u16,
    exact_blue: u16,
    visual_red: u16,
    visual_green: u16,
    visual_blue: u16,
    unused_2: u64,
};

pub const AllocColorCellsReply = extern struct {
    code: msg.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_pixels: u16,
    num_masks: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const AllocColorPlanesReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u16,
    num_pixels: u16,
    unused_2: u16,
    red_mask: u32,
    green_mask: u32,
    blue_mask: u32,
    unused_3: u64,
};

pub const QueryColorsReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_rgbs: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const LookupColorReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    exact_red: u16,
    exact_green: u16,
    exact_blue: u16,
    visual_red: u16,
    visual_green: u16,
    visual_blue: u16,
    unused_2: [12]u8 = [1]u8{0} ** 12,
};

pub const QueryBestSizeReply = extern struct {
    code: msg.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    width: u16,
    height: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryExtensionReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    present: bool,
    major_opcode: u8,
    first_event: u8,
    first_error: u8,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const ListExtensionsReply = extern struct {
    code: msg.Code = .reply,
    num_names: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardMappingReply = extern struct {
    code: msg.Code = .reply,
    keysyms_per_keycode: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardControlReply = extern struct {
    code: msg.Code = .reply,
    global_auto_repeat: AutoRepeat,
    sequence_number: u16,
    reply_len: u32 = 5,
    led_mask: u32,
    key_click_percent: u8,
    bell_percent: u8,
    bell_pitch: u16,
    bell_duration: u16,
    unused: u16,
};

pub const GetPointerControlReply = extern struct {
    code: msg.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    acceleration_numerator: u16,
    acceleration_denominator: u16,
    threshold: u16,
    unused_2: [18]u8 = [1]u8{0} ** 18,
};

pub const GetScreenSaverReply = extern struct {
    code: msg.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    timeout: u16,
    interval: u16,
    prefer_blanking: ScreenSaverBlanking,
    allow_exposures: ScreenSaverExposures,
    unused_2: [18]u8 = [1]u8{0} ** 18,
};

pub const ListHostsReply = extern struct {
    code: msg.Code = .reply,
    mode: ListHostsMode,
    sequence_number: u16,
    reply_len: u32,
    num_hosts: u16,
    unused: [22]u8 = [1]u8{0} ** 22,
};

pub const SetPointerMappingReply = extern struct {
    code: msg.Code = .reply,
    status: PointerMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetPointerMappingReply = extern struct {
    code: msg.Code = .reply,
    map_len: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const SetModifierMappingReply = extern struct {
    code: msg.Code = .reply,
    status: ModifierMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetModifierMappingReply = extern struct {
    code: msg.Code = .reply,
    keycodes_per_modifier: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const AutoRepeat = enum(u8) {
    off,
    on,
};

pub const BackingStore = enum(u8) {
    not_useful,
    when_mapped,
    always,
};

pub const BitGravity = enum(u8) {
    forget,
    north_west,
    north,
    north_east,
    west,
    center,
    east,
    south_west,
    south,
    south_east,
    static,
};

pub const DrawDirection = enum(u8) {
    left_to_right,
    right_to_left,
};

pub const FocusRevertTo = enum(u8) {
    none,
    pointer_root,
    parent,
};

pub const GrabStatus = enum(u8) {
    success,
    already_grabbed,
    invalid_time,
    not_viewable,
    frozen,
};

pub const ListHostsMode = enum(u8) {
    disabled,
    enabled,
};

pub const MapState = enum(u8) {
    unmapped,
    unviewable,
    viewable,
};

pub const ModifierMappingStatus = enum(u8) {
    success,
    busy,
    failed,
};

pub const PointerMappingStatus = enum(u8) {
    success,
    busy,
};

pub const ScreenSaverBlanking = enum(u8) {
    no,
    yes,
};

pub const ScreenSaverExposures = enum(u8) {
    no,
    yes,
};

pub const WindowClass = enum(u16) {
    input_output = 1,
    input_only,
};

pub const WindowGravity = enum(u8) {
    unmap,
    north_west,
    north,
    north_east,
    west,
    center,
    east,
    south_west,
    south,
    south_east,
    static,
};

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

/// Information about X11 screen sent by the initial connection handshake.
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
    backing_stores: x11.protocol.BackingStores,
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
    class: x11.protocol.VisualClass,
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

pub const WindowAttributes = packed struct(u32) {
    background_pixmap: bool = false,
    background_pixel: bool = false,
    border_pixmap: bool = false,
    border_pixel: bool = false,
    bit_gravity: bool = false,
    win_gravity: bool = false,
    backing_store: bool = false,
    backing_planes: bool = false,
    backing_pixel: bool = false,
    override_redirect: bool = false,
    save_under: bool = false,
    event_mask: bool = false,
    do_not_propogate_mask: bool = false,
    colormap: bool = false,
    cursor: bool = false,
    unused: u17 = 0,

    pub const all: WindowAttributes = .{
        .background_pixmap = true,
        .background_pixel = true,
        .border_pixmap = true,
        .border_pixel = true,
        .bit_gravity = true,
        .win_gravity = true,
        .backing_store = true,
        .backing_planes = true,
        .backing_pixel = true,
        .override_redirect = true,
        .save_under = true,
        .event_mask = true,
        .do_not_propogate_mask = true,
        .colormap = true,
        .cursor = true,
    };
};

/// Union of the three basic X11 message types: Error, Reply, and Event.
/// Error and Event messages are simple 32-byte structs. Reply messages are
/// each different structures and may contain additional data.
pub const Message = union(x11.protocol.Code) {
    @"error": Error,
    reply: Reply,
    key_press: GenericEvent,
    key_release: GenericEvent,
    button_press: GenericEvent,
    button_release: GenericEvent,
    motion_notify: GenericEvent,
    enter_notify: GenericEvent,
    leave_notify: GenericEvent,
    focus_in: FocusInEvent,
    focus_out: FocusOutEvent,
    keymap_notify: KeymapNotifyEvent,
    expose: ExposeEvent,
    graphics_exposure: GenericEvent,
    no_exposure: GenericEvent,
    visibility_notify: VisibilityNotifyEvent,
    create_notify: GenericEvent,
    destroy_notify: GenericEvent,
    unmap_notify: GenericEvent,
    map_notify: MapNotifyEvent,
    map_request: GenericEvent,
    reparent_notify: ReparentNotifyEvent,
    configure_notify: GenericEvent,
    configure_request: GenericEvent,
    gravity_notify: GenericEvent,
    resize_request: GenericEvent,
    circulate_notify: GenericEvent,
    circulate_request: GenericEvent,
    property_notify: PropertyNotifyEvent,
    selection_clear: GenericEvent,
    selection_request: GenericEvent,
    selection_notify: GenericEvent,
    colormap_notify: GenericEvent,
    client_message: ClientMessageEvent,
    mapping_notify: GenericEvent,
};

/// Generic Message structure that can be used when reading messages from an
/// X11 server.  Should only be used internally before being cast to a more
/// suitable type.
pub const GenericMessage = extern struct {
    code: x11.protocol.Code,
    data_1: u8,
    /// This maps to sequence_number for all errors and replies, and MOST
    /// events, but KeymapNotifyEvent is the odd man out.
    data_2: u16,
    data_3: u32,
    data_4: u64,
    data_5: u64,
    data_6: u64,
};

/// X11 Error messages all follow the same basic structure.  Use .error_code
/// to find more information about the error.  Use .sequence_number to match
/// the Error to the most recent Request.
pub const Error = extern struct {
    code: x11.protocol.Code = .@"error",
    error_code: x11.protocol.ErrorCode,
    sequence_number: u16,
    data: u32,
    minor_opcode: u16,
    major_opcode: u8,
    unused: [21]u8 = [1]u8{0} ** 21,
};

/// Union of the various X11 Reply structures.  Some requests do not have a
/// Reply; these are of type void.
pub const Reply = union(x11.protocol.Opcode) {
    create_window: void,
    change_window_attributes: void,
    get_window_attributes: GetWindowAttributesReply,
    destroy_window: void,
    destroy_subwindows: void,
    change_save_set: void,
    reparent_window: void,
    map_window: void,
    map_subwindows: void,
    unmap_window: void,
    unmap_subwindows: void,
    configure_window: void,
    circulate_window: void,
    get_geometry: GetGeometryReply,
    query_tree: QueryTreeReply,
    intern_atom: InternAtomReply,
    get_atom_name: GetAtomNameReply,
    change_property: void,
    delete_property: void,
    get_property: GetPropertyReply,
    list_properties: ListPropertiesReply,
    set_selection_owner: void,
    get_selection_owner: GetSelectionOwnerReply,
    convert_selection: void,
    send_event: void,
    grab_pointer: GrabPointerReply,
    ungrab_pointer: void,
    grab_button: void,
    ungrab_button: void,
    change_active_pointer_grab: void,
    grab_keyboard: GrabKeyboardReply,
    ungrab_keyboard: void,
    grab_key: void,
    ungrab_key: void,
    allow_events: void,
    grab_server: void,
    ungrab_server: void,
    query_pointer: QueryPointerReply,
    get_motion_events: GetMotionEventsReply,
    translate_coordinates: TranslateCoordinatesReply,
    warp_pointer: void,
    set_input_focus: void,
    get_input_focus: GetInputFocusReply,
    query_keymap: QueryKeymapReply,
    open_font: void,
    close_font: void,
    query_font: QueryFontReply,
    query_text_extents: QueryTextExtentsReply,
    list_fonts: ListFontsReply,
    // TODO: ListFontsWithInfoReply | ListFontsWithInfoReplySentinel
    list_fonts_with_info: void,
    set_font_path: void,
    get_font_path: GetFontPathReply,
    create_pixmap: void,
    free_pixmap: void,
    create_gc: void,
    change_gc: void,
    copy_gc: void,
    set_dashes: void,
    set_clip_rectangles: void,
    free_gc: void,
    clear_area: void,
    copy_area: void,
    copy_plane: void,
    poly_point: void,
    poly_line: void,
    poly_segment: void,
    poly_rectangle: void,
    poly_arc: void,
    fill_poly: void,
    poly_fill_rectangle: void,
    poly_fill_arc: void,
    put_image: void,
    get_image: GetImageReply,
    poly_text_8: void,
    poly_text_16: void,
    image_text_8: void,
    image_text_16: void,
    create_colormap: void,
    free_colormap: void,
    copy_colormap_and_free: void,
    install_colormap: void,
    uninstall_colotmap: void,
    list_installed_colormaps: ListInstalledColormapsReply,
    alloc_color: AllocColorReply,
    alloc_named_color: AllocNamedColorReply,
    alloc_color_cells: AllocColorCellsReply,
    alloc_color_planes: AllocColorPlanesReply,
    free_colors: void,
    store_colors: void,
    store_named_color: void,
    query_colors: QueryColorsReply,
    lookup_color: LookupColorReply,
    create_cursor: void,
    create_glyph_cursor: void,
    free_cursor: void,
    recolor_cursor: void,
    query_best_size: QueryBestSizeReply,
    query_extension: QueryExtensionReply,
    list_extensions: ListExtensionsReply,
    change_keyboard_mapping: void,
    get_keyboard_mapping: GetKeyboardMappingReply,
    change_keyboard_control: void,
    get_keyboard_control: GetKeyboardControlReply,
    bell: void,
    change_pointer_control: void,
    get_pointer_control: GetPointerControlReply,
    set_screen_saver,
    get_screen_saver: GetScreenSaverReply,
    change_hosts: void,
    list_hosts: ListHostsReply,
    set_access_control: void,
    set_close_down_mode: void,
    kill_client: void,
    rotate_properties: void,
    force_screen_saver: void,
    set_pointer_mapping: SetPointerMappingReply,
    get_pointer_mapping: GetPointerMappingReply,
    set_modifier_mapping: SetModifierMappingReply,
    get_modifier_mapping: GetModifierMappingReply,
    no_operation: void,
};

/// Generic Reply structure that can be used when reading messages from an X11
/// server.  Should only be used internally before being cast to a more
/// suitable type.
pub const GenericReply = extern struct {
    code: x11.protocol.Code = .reply,
    data_1: u8,
    sequence_number: u16,
    reply_len: u32, // number of extra u32s
    data_2: u64,
    data_3: u64,
    data_4: u64,

    /// Return the size of this reply in bytes, including any additional data
    /// specified by .reply_len (which will not be included by @sizeOf).
    pub fn sizeOf(this: GenericReply) usize {
        return this.reply_len * 4 + @sizeOf(GenericReply);
    }
};

/// Generic Event structure that can be used when reading messages from an X11
/// server.  Should only be used internally before being cast to a more
/// suitable type.
pub const GenericEvent = extern struct {
    code: x11.protocol.Code,
    data_1: u8,
    /// This maps to sequence_number for MOST events, but KeymapNotifyEvent is
    /// the odd man out.
    data_2: u16,
    data_3: u32,
    data_4: u64,
    data_5: u64,
    data_6: u64,
};

// **************************************************************************
// * X11 requests                                                           *
// **************************************************************************

pub const ChangePropertyRequest = extern struct {
    opcode: x11.protocol.Opcode = .change_property,
    mode: x11.protocol.ChangePropertyMode,
    request_len: u16,
    window_id: u32,
    property_id: u32,
    type_id: u32,
    format: u8,
    unused: [3]u8 = [1]u8{0} ** 3,
    data_len: u32,

    /// Calculate .request_len for request with given format and data length.
    pub fn requestLen(format: u8, data_len: u32) u16 {
        const datum_size = switch (format) {
            8, 16, 32 => |bits| bits / 8,
            else => @panic("format must be 8, 16, or 32 bits"),
        };

        const data_size = data_len * datum_size;
        const padded_size = data_size + ((4 - (data_size % 4)) % 4);

        return @intCast(@sizeOf(ChangePropertyRequest) + padded_size);
    }
};

pub const CreateWindowRequest = extern struct {
    opcode: x11.protocol.Opcode = .create_window,
    depth: u8,
    request_len: u16,
    window_id: u32,
    parent_id: u32,
    x: i16 = 50,
    y: i16 = 50,
    width: u16 = 200,
    height: u16 = 300,
    border_width: u16 = 0,
    class: x11.protocol.CreateWindowClass = .copy_from_parent,
    visual: u32 = CreateWindowRequest.visual_copy_from_parent,
    value_mask: WindowAttributes,

    /// Default value for .visual.
    pub const visual_copy_from_parent: u32 = 0;

    /// Calculate .request_len for request with given number of flags.
    pub fn requestLen(num_flags: u8) u16 {
        return @sizeOf(CreateWindowRequest) / 4 + num_flags;
    }
};

pub const DestroyWindowRequest = extern struct {
    opcode: x11.protocol.Opcode = .destroy_window,
    unused: u8 = 0,
    request_len: u16 = 2,
    window_id: u32,
};

pub const GetAtomNameRequest = extern struct {
    opcode: x11.protocol.Opcode = .get_atom_name,
    unused: u8 = 0,
    request_len: u16 = 2,
    atom_id: u32,
};

pub const GetPropertyRequest = extern struct {
    opcode: x11.protocol.Opcode = .get_property,
    delete: bool,
    request_len: u16 = 6,
    window_id: u32,
    property_id: u32,
    type_id: u32 = GetPropertyRequest.type_any,
    long_offset: u32,
    long_length: u32,

    pub const type_any: u32 = 0;
};

pub const InternAtomRequest = extern struct {
    opcode: x11.protocol.Opcode = .intern_atom,
    only_if_exists: bool,
    request_len: u16,
    name_len: u16,
    unused: u16 = 0,

    /// Calculate .request_len for request with the given name length.
    pub fn requestLen(name_len: usize) u16 {
        const pad = name_len + ((4 - (name_len % 4)) % 4);
        return @intCast((@sizeOf(InternAtomRequest) + pad) / 4);
    }
};

pub const MapWindowRequest = extern struct {
    opcode: x11.protocol.Opcode = .map_window,
    unused: u8 = 0,
    request_len: u16 = 2,
    window_id: u32,
};

// **************************************************************************
// * X11 replies                                                            *
// **************************************************************************

pub const GetWindowAttributesReply = extern struct {
    code: x11.protocol.Code = .reply,
    backing_store: x11.protocol.BackingStore,
    sequence_number: u16,
    reply_len: u32 = 3,
    visual: u32,
    class: x11.protocol.WindowClass,
    bit_gravity: x11.protocol.BitGravity,
    win_gravity: x11.protocol.WindowGravity,
    backing_planes: u32,
    backing_pixel: u32,
    save_under: bool,
    map_is_installed: bool,
    map_state: x11.protocol.MapState,
    override_redirect: bool,
    colormap: u32,
    all_event_masks: EventSet,
    your_event_mask: EventSet,
    do_not_propogate_mask: DeviceEventSet,
    unused: u16 = 0,
};

pub const GetGeometryReply = extern struct {
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    root: u32,
    parent: u32,
    num_children: u16,
    unused_2: [14]u8 = [1]u8{0} ** 14,
};

pub const InternAtomReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    atom: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GetAtomNameReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    name_len: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetPropertyReply = extern struct {
    code: x11.protocol.Code = .reply,
    format: u8,
    sequence_number: u16,
    reply_len: u32,
    type_id: u32,
    bytes_after: u32,
    value_len: u32,
    unused: [12]u8 = [1]u8{0} ** 12,
};

pub const ListPropertiesReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_atoms: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetSelectionOwnerReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    owner: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GrabPointerReply = extern struct {
    code: x11.protocol.Code = .reply,
    status: x11.protocol.GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GrabKeyboardReply = extern struct {
    code: x11.protocol.Code = .reply,
    status: x11.protocol.GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const QueryPointerReply = extern struct {
    code: x11.protocol.Code = .reply,
    same_screen: bool,
    sequence_number: u16,
    reply_len: u32 = 0,
    root: u32,
    child: u32,
    root_x: i16,
    root_y: i16,
    win_x: i16, // TODO: should this be child_x?
    win_y: i16, // TODO: should this be child_y?
    mask: KeyButtonSet,
    unused: [6]u8 = [1]u8{0} ** 6,
};

pub const GetMotionEventsReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_events: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const TranslateCoordinatesReply = extern struct {
    code: x11.protocol.Code = .reply,
    same_screen: bool,
    sequence_number: u16,
    reply_len: u32 = 0,
    child: u32,
    dst_x: i16,
    dst_y: i16,
    unused: [16]u8 = [1]u8{0} ** 16,
};

pub const GetInputFocusReply = extern struct {
    code: x11.protocol.Code = .reply,
    revert_to: x11.protocol.FocusRevertTo,
    sequence_number: u16,
    reply_len: u32 = 0,
    focus: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryKeymapReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused: u8,
    sequence_number: u16,
    reply_len: u32 = 2,
    keys: [32]u8 = [1]u8{0} ** 32,
};

pub const QueryFontReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    min_bounds: CharInfo,
    unused_2: u32,
    max_bounds: CharInfo,
    unused_3: u32,
    min_char_or_byte2: u16,
    max_char_or_byte2: u16,
    default_char: u16,
    num_properties: u16,
    draw_direction: x11.protocol.DrawDirection,
    min_byte1: u8,
    max_byte1: u8,
    all_chars_exist: bool,
    font_ascent: i16,
    font_descent: i16,
    num_char_infos: u32,
};

pub const QueryTextExtentsReply = extern struct {
    code: x11.protocol.Code = .reply,
    draw_direction: x11.protocol.DrawDirection,
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
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_names: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const ListFontsWithInfoReply = extern struct {
    code: x11.protocol.Code = .reply,
    name_len: u8,
    sequence_number: u16,
    reply_len: u32,
    min_bounds: CharInfo,
    unused_1: u32,
    max_bounds: CharInfo,
    unused_2: u32,
    min_char_or_byte2: u16,
    max_char_or_byte2: u16,
    default_char: u16,
    num_properties: u16,
    draw_direction: x11.protocol.DrawDirection,
    min_byte1: u8,
    max_byte1: u8,
    all_chars_exist: bool,
    font_ascent: i16,
    font_descent: i16,
    replies_hint: u32,
};

// TODO: determine naming for sentinel

pub const ListFontsWithInfoReplySentinel = extern struct {
    code: x11.protocol.Code = .reply,
    last_reply_indicator: u8 = 0,
    sequence_number: u16,
    reply_len: u32 = 7,
    unused: [52]u8 = [1]u8{0} ** 52,
};

pub const GetFontPathReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_paths: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetImageReply = extern struct {
    code: x11.protocol.Code = .reply,
    depth: u8,
    sequence_number: u16,
    reply_len: u32,
    visual: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const ListInstalledColormapsReply = extern struct {
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_cmaps: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const AllocColorReply = extern struct {
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_pixels: u16,
    num_masks: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const AllocColorPlanesReply = extern struct {
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_rgbs: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const LookupColorReply = extern struct {
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    width: u16,
    height: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryExtensionReply = extern struct {
    code: x11.protocol.Code = .reply,
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
    code: x11.protocol.Code = .reply,
    num_names: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardMappingReply = extern struct {
    code: x11.protocol.Code = .reply,
    keysyms_per_keycode: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardControlReply = extern struct {
    code: x11.protocol.Code = .reply,
    global_auto_repeat: x11.protocol.AutoRepeat,
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
    code: x11.protocol.Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    acceleration_numerator: u16,
    acceleration_denominator: u16,
    threshold: u16,
    unused_2: [18]u8 = [1]u8{0} ** 18,
};

pub const GetScreenSaverReply = extern struct {
    code: x11.protocol.Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    timeout: u16,
    interval: u16,
    prefer_blanking: x11.protocol.ScreenSaverBlanking,
    allow_exposures: x11.protocol.ScreenSaverExposures,
    unused_2: [18]u8 = [1]u8{0} ** 18,
};

pub const ListHostsReply = extern struct {
    code: x11.protocol.Code = .reply,
    mode: x11.protocol.ListHostsMode,
    sequence_number: u16,
    reply_len: u32,
    num_hosts: u16,
    unused: [22]u8 = [1]u8{0} ** 22,
};

pub const SetPointerMappingReply = extern struct {
    code: x11.protocol.Code = .reply,
    status: x11.protocol.PointerMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetPointerMappingReply = extern struct {
    code: x11.protocol.Code = .reply,
    map_len: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const SetModifierMappingReply = extern struct {
    code: x11.protocol.Code = .reply,
    status: x11.protocol.ModifierMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetModifierMappingReply = extern struct {
    code: x11.protocol.Code = .reply,
    keycodes_per_modifier: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

// **************************************************************************
// * X11 events                                                             *
// **************************************************************************

pub const FocusInEvent = extern struct {
    code: x11.protocol.Code = .focus_in,
    detail: x11.protocol.FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: x11.protocol.FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const FocusOutEvent = extern struct {
    code: x11.protocol.Code = .focus_out,
    detail: x11.protocol.FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: x11.protocol.FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const KeymapNotifyEvent = extern struct {
    code: x11.protocol.Code = .keymap_notify,
    keys: [31]u8 = [1]u8{0} ** 31,
};

pub const ExposeEvent = extern struct {
    code: x11.protocol.Code = .expose,
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

pub const VisibilityNotifyEvent = extern struct {
    code: x11.protocol.Code = .visibility_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    state: x11.protocol.VisibilityChangeState,
    unused_2: [23]u8 = [1]u8{0} ** 23,
};

pub const MapNotifyEvent = extern struct {
    code: x11.protocol.Code = .map_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    override_redirect: bool,
    unused_2: [19]u8 = [1]u8{0} ** 19,
};

pub const ReparentNotifyEvent = extern struct {
    code: x11.protocol.Code = .reparent_notify,
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

pub const PropertyNotifyEvent = extern struct {
    code: x11.protocol.Code = .property_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    atom_id: u32,
    timestamp: u32,
    state: x11.protocol.PropertyChangeState,
    unused_2: [15]u8 = [1]u8{0} ** 15,
};

pub const ClientMessageEvent = extern struct {
    code: x11.protocol.Code = .client_message,
    format: u8,
    sequence_number: u16,
    window_id: u32,
    type: u32,
    data: [20]u8,

    pub const Int8 = extern struct {
        code: x11.protocol.Code = .client_message,
        format: u8 = 8,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [20]u8,
    };

    pub const Int16 = extern struct {
        code: x11.protocol.Code = .client_message,
        format: u8 = 16,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [10]u16,
    };

    pub const Int32 = extern struct {
        code: x11.protocol.Code = .client_message,
        format: u8 = 32,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [5]u32,
    };
};

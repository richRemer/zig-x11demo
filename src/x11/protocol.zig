//! Network protocol definitions for X11 protocol.

// SECTION 1
// ENUMS

/// Global keyboard auto-repeat mode.  When .on, multiple key press and key
/// release events will be generated while a key is held down.
pub const AutoRepeat = enum(u8) {
    off,
    on,
};

/// Backing store mode requested when sending a CreateWindow request.  A mode
/// of .not_useful tells the server this window will not benefit from backing
/// store.  A mode of .when_mapped tells the server the window would benefit
/// from having a backing store for obscured regions when mapped, while a mode
/// of .always indicates the window would benefit from preserving the backing
/// store even when the window is unmapped.
pub const BackingStore = enum(u8) {
    not_useful,
    when_mapped,
    always,
};

/// Support for backing stores declared by X11 server for a screen specified
/// during handshake.
pub const BackingStores = enum(u8) {
    never,
    when_mapped,
    always,
};

/// Indicates which region of a window should be retained when the window is
/// resized.
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

/// Keyboard auto-repeat mode requested when sending a ChangeKeyboardControl
/// request.  When .on, multiple key press and key release events will be
/// generated while a key is held down.  The .default is determined by the
/// specific key being held down.
pub const ChangeAutoRepeat = enum(u8) {
    off,
    on,
    default,
};

/// How existing property values should be merged with new ones when sending a
/// ChangePropertyRequest.  Use .replace to overwrite existing values with new
/// ones.  Use .prepend or .append to add new values before or after existing
/// values, respectively.
pub const ChangePropertyMode = enum(u8) {
    replace,
    prepend,
    append,
};

/// Message code used to distinguish between the different types of data sent
/// by an X11 server.  Each message starts with a Code.  Messages with a code
/// of .reply are at least 32 bytes, but may contain additional data.  All
/// other Message types are exactly 32 bytes.
pub const Code = enum(u8) {
    // XMessageError, 32 bytes
    @"error" = 0,
    // generic reply, 32 bytes + additional data
    reply = 1,
    // events, 32 bytes each
    key_press = 2,
    key_release,
    button_press,
    button_release,
    motion_notify,
    enter_notify,
    leave_notify,
    focus_in,
    focus_out,
    keymap_notify,
    expose,
    graphics_exposure,
    no_exposure,
    visibility_notify,
    create_notify,
    destroy_notify,
    unmap_notify,
    map_notify,
    map_request,
    reparent_notify,
    configure_notify,
    configure_request,
    gravity_notify,
    resize_request,
    circulate_notify,
    circulate_request,
    property_notify,
    selection_clear,
    selection_request,
    selection_notify,
    colormap_notify,
    client_message,
    mapping_notify,
    _,
};

/// The types of events a newly created window is expected to handle.  Windows
/// that are .input_only cannot be shown, but may capture keyboard and other
/// input events.  Windows that are .input_output can also be shown.  If a new
/// window is a subwindow of another, .copy_from_parent can be used to inherit
/// the behavior of the superwindow.
pub const CreateWindowClass = enum(u16) {
    copy_from_parent,
    input_output,
    input_only,
};

/// The direction text flows for font.  This value is returned by a variety of
/// font-related requests.
pub const DrawDirection = enum(u8) {
    left_to_right,
    right_to_left,
};

/// Error code returned by a Message with code .@"error".  This can be used to
/// distinguish different types of Error messages.
pub const ErrorCode = enum(u8) {
    request = 1,
    value,
    window,
    pixmap,
    atom,
    cursor,
    font,
    match,
    drawable,
    access,
    alloc,
    colormap,
    gcontext,
    idchoice,
    name,
    length,
    implementation,
};

/// Details about a change in input focus.
/// TODO: provide more detail (what is an inferior window?)
/// https://www.x.org/releases/X11R7.7/doc/xproto/x11protocol.html#id2664378
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

/// Context for focus change events.  For .normal or .while_grabbed mode, the
/// keyboard is either not grabbed or grabbed, respetively, while changes in
/// keyboard grabbing are indicated with .grab and .ungrab.
pub const FocusMode = enum(u8) {
    normal,
    grab,
    ungrab,
    while_grabbed,
};

/// Indicates what happens to focus when focused window becomes invisible.
/// Focus may revert to the window parent with .parent, to the current screen
/// root with .pointer_root, or to nothing with .none.
pub const FocusRevertTo = enum(u8) {
    none,
    pointer_root,
    parent,
};

/// Resulting state when attempting to grab a window or pointer.  If another
/// resource is grabbed, the grab fails with .already_grabed.  If timestamp
/// ordering indicates the grab request is stale, it fails with .invalid_time.
/// Attempt to grab a window that is not viewable or a pointer to a window or
/// confined region that is not viewable fails with .not_viewable.  When the
/// resource is frozen by another client, it fails with .frozen.
pub const GrabStatus = enum(u8) {
    success,
    already_grabbed,
    invalid_time,
    not_viewable,
    frozen,
};

/// Whether a list of hosts can be used at connection setup.
pub const ListHostsMode = enum(u8) {
    disabled,
    enabled,
};

/// Current state of window map.  An unmapped window will be .unmapped, while
/// a mapped window may be .unviewable if an ancestor is unmapped or .viewable
/// otherwise.
pub const MapState = enum(u8) {
    unmapped,
    unviewable,
    viewable,
};

/// Resulting state when attempting to set modifier mapping for keys.  Some
/// keys may not allow mapping due to server restrictions and will result in
/// .failed state.  Attempt to set modifier mapping for keys which are pressed
/// results in .busy state.
pub const ModifierMappingStatus = enum(u8) {
    success,
    busy,
    failed,
};

/// The code used to identify a message's type.  Each code corresponds to a
/// well-defined request struct.  For example, Opcode.destroy_window is the
/// message code set for a DetroyWindowRequest message.
pub const Opcode = enum(u8) {
    create_window = 1,
    change_window_attributes,
    get_window_attributes,
    destroy_window,
    destroy_subwindows,
    change_save_set,
    reparent_window,
    map_window,
    map_subwindows,
    unmap_window,
    unmap_subwindows,
    configure_window,
    circulate_window,
    get_geometry,
    query_tree,
    intern_atom,
    get_atom_name,
    change_property,
    delete_property,
    get_property,
    list_properties,
    set_selection_owner,
    get_selection_owner,
    convert_selection,
    send_event,
    grab_pointer,
    ungrab_pointer,
    grab_button,
    ungrab_button,
    change_active_pointer_grab,
    grab_keyboard,
    ungrab_keyboard,
    grab_key,
    ungrab_key,
    allow_events,
    grab_server,
    ungrab_server,
    query_pointer,
    get_motion_events,
    translate_coordinates,
    warp_pointer,
    set_input_focus,
    get_input_focus,
    query_keymap,
    open_font,
    close_font,
    query_font,
    query_text_extents,
    list_fonts,
    list_fonts_with_info,
    set_font_path,
    get_font_path,
    create_pixmap,
    free_pixmap,
    create_gc,
    change_gc,
    copy_gc,
    set_dashes,
    set_clip_rectangles,
    free_gc,
    clear_area,
    copy_area,
    copy_plane,
    poly_point,
    poly_line,
    poly_segment,
    poly_rectangle,
    poly_arc,
    fill_poly,
    poly_fill_rectangle,
    poly_fill_arc,
    put_image,
    get_image,
    poly_text_8,
    poly_text_16,
    image_text_8,
    image_text_16,
    create_colormap,
    free_colormap,
    copy_colormap_and_free,
    install_colormap,
    uninstall_colotmap,
    list_installed_colormaps,
    alloc_color,
    alloc_named_color,
    alloc_color_cells,
    alloc_color_planes,
    free_colors,
    store_colors,
    store_named_color,
    query_colors,
    lookup_color,
    create_cursor,
    create_glyph_cursor,
    free_cursor,
    recolor_cursor,
    query_best_size,
    query_extension,
    list_extensions,
    change_keyboard_mapping,
    get_keyboard_mapping,
    change_keyboard_control,
    get_keyboard_control,
    bell,
    change_pointer_control,
    get_pointer_control,
    set_screen_saver,
    get_screen_saver,
    change_hosts,
    list_hosts,
    set_access_control,
    set_close_down_mode,
    kill_client,
    rotate_properties,
    force_screen_saver,
    set_pointer_mapping,
    get_pointer_mapping,
    set_modifier_mapping,
    get_modifier_mapping,
    no_operation = 127,
};

pub const PointerMappingStatus = enum(u8) {
    success,
    busy,
};

pub const PropertyChangeState = enum(u8) {
    new_value,
    deleted,
};

pub const ScreenSaverBlanking = enum(u8) {
    no,
    yes,
};

pub const ScreenSaverExposures = enum(u8) {
    no,
    yes,
};

pub const VisibilityChangeState = enum(u8) {
    unobscured,
    partially_obscured,
    fully_obscured,
};

pub const VisualClass = enum(u8) {
    static_gray,
    gray_scale,
    static_color,
    pseudo_color,
    true_color,
    direct_color,
};

/// The types of events a window handles.  Windows that are .input_only cannot
/// be shown, but may capture keyboard and other input events.  Windows that
/// are .input_output can also be shown.
pub const WindowClass = enum(u16) {
    input_output = 1,
    input_only,
};

/// Indicates which region of a subwindow should be repositioned when its
/// parent window is resized.
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

// SECTION 2
// RESOURCES

/// Description
pub const CharInfo = extern struct {
    left_side_bearing: i16,
    right_side_bearing: i16,
    character_width: i16,
    ascent: i16,
    descent: i16,
    attributes: u16,
};

/// Descriptor of supported screen depth.
pub const Depth = extern struct {
    depth: u8,
    unused_1: u8,
    num_visuals: u16,
    unused_2: u32,
    // [num_visuals]Visual
};

/// Atom name and value for a font property.
pub const FontProp = extern struct {
    name: u32,
    value: u32,
};

/// Descriptor of screen pixel format.
pub const PixelFormat = extern struct {
    depth: u8,
    bits_per_pixel: u8,
    scanline_pad: u8,
    unused: [5]u8 = [1]u8{0} ** 5,
};

/// Color components.
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
    backing_stores: BackingStores,
    save_unders: bool,
    root_depth: u8,
    num_depths: u8,
    // [num_depths]Depth
};

/// Length-prefixed string.
pub const String = extern struct {
    name_len: u8,
    // [name_len]u8
};

/// Position where pointer was located at a specific timestamp.
pub const TimeCoord = extern struct {
    timestamp: u32,
    x: i16,
    y: i16,
};

/// Descriptor of display format.  The root window visual is the default visual.
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

// SECTION 3
// BIT FIELDS

/// 32-bit set of flags for selecting device events.
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

/// 32-bit set of flags for selecting events.
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

/// 16-bit set of flags for describing which keys and buttons are pressed.
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

/// 16-bit set of flags for describing which keys are pressed.
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

/// 32-bit set of flags for selecting pointer events.
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

/// 32-bit set of flags for selecting window attributes.
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

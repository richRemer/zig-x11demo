//! Network protocol definitions for X11 protocol.

const arch = @import("builtin").cpu.arch;

// ***************************************************************************
// SECTION 1
// ENUMS
// ***************************************************************************

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

/// The reply status when attempting to map the pointer.
pub const PointerMappingStatus = enum(u8) {
    success,
    busy,
};

/// The nature of a property change reported by the server.
pub const PropertyChangeState = enum(u8) {
    new_value,
    deleted,
};

/// The state used to identify the nature of a connection setup reply.  Each
/// state corresponds to a different well-defined setup reply struct.
pub const SetupState = enum(u8) {
    failure,
    success,
    authenticate,
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

// ***************************************************************************
// SECTION 2
// RESOURCES
// ***************************************************************************

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
    // visuals: [num_visuals]Visual
};

/// Atom name and value for a font property.
pub const FontProp = extern struct {
    name: u32,
    value: u32,
};

/// Descriptor of screen pixmap format.
pub const PixmapFormat = extern struct {
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
    // depths: [num_depths]Depth
};

/// Length-prefixed string.
pub const String = extern struct {
    name_len: u8,
    // name: [name_len]u8
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

// ***************************************************************************
// SECTION 3
// BIT FIELDS
// ***************************************************************************

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

// ***************************************************************************
// SECTION 4
// MESSAGES - ERRORS, REPLIES, AND EVENTS
// ***************************************************************************

/// Generic message structure that can be used when reading messages from an
/// X11 server.  Should only be used internally before being cast to a more
/// suitable type.
pub const UnknownMessage = extern struct {
    code: Code,
    data_1: u8,
    /// This maps to sequence_number for all errors and replies, and MOST
    /// events, but KeymapNotifyEvent is the odd man out.
    data_2: u16,
    data_3: u32,
    data_4: u64,
    data_5: u64,
    data_6: u64,
};

// ***************************************************************************
// SECTION 4.1
// ERRORS
// ***************************************************************************

/// X11 Error messages all follow the same basic structure.  Use .error_code
/// to find more information about the error.  Use .sequence_number to match
/// the Error to the most recent Request.
pub const Error = extern struct {
    code: Code = .@"error",
    error_code: ErrorCode,
    sequence_number: u16,
    data: u32,
    minor_opcode: u16,
    major_opcode: u8,
    unused: [21]u8 = [1]u8{0} ** 21,
};

// ***************************************************************************
// SECTION 4.2
// REPLIES
// ***************************************************************************

/// Generic reply structure used only once during connection setup.
pub const UnknownSetupReply = extern struct {
    state: SetupState,
    field_1: u8,
    field_2: u16,
    field_3: u16,
    data_len: u16,
};

/// Connection setup reply sent by X11 server to indicate missing or invalid
/// authentication.
pub const SetupAuthenticateReply = extern struct {
    state: SetupState = .authenticate,
    pad: [5]u8 = [_]u8{0} ** 5,
    data_len: u16,
    // reason: [data_len*4]u8
    // padding: [0]u8 (protocol doesn't distinguish data/padding)
};

/// Connection setup reply sent by X11 server to indicate a failure.
pub const SetupFailureReply = extern struct {
    state: SetupState = .failure,
    reason_len: u8,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    data_len: u16,
    // reason: [reason_len]u8
    // padding: [data_len*4-reason_len]u8
};

/// Connection setup reply sent by X11 server to indicate success.
pub const SetupSuccessReply = extern struct {
    state: SetupState = .success,
    pad0: u8 = 0,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    data_len: u16,
    release_number: u32,
    resource_id_base: u32,
    resource_id_mask: u32,
    motion_buffer_size: u32,
    vendor_len: u16,
    maximum_request_len: u16,
    num_screens: u8,
    num_formats: u8,
    image_byte_order: u8,
    bitmap_format_bit_order: u8,
    bitmap_format_scanline_unit: u8,
    bitmap_format_scanline_pad: u8,
    min_keycode: u8,
    max_keycode: u8,
    pad1: u32 = 0,
    // vendor: [vendor_len]u8 + padding to multiple of 4 bytes
    // formats: [num_formats]PixmapFormat
    // screens: [num_screens]Screen
};

/// Generic reply structure that can be used when reading messages from an X11
/// server.  Should only be used internally before being cast to a more
/// suitable type.
pub const UnknownReply = extern struct {
    code: Code = .reply,
    data_1: u8,
    sequence_number: u16,
    reply_len: u32, // number of extra u32s
    data_2: u64,
    data_3: u64,
    data_4: u64,

    /// Return the size of this reply in bytes, including any additional data
    /// specified by .reply_len (which will not be included by @sizeOf).
    pub fn sizeOf(this: UnknownReply) usize {
        return this.reply_len * 4 + @sizeOf(UnknownReply);
    }
};

pub const GetWindowAttributesReply = extern struct {
    code: Code = .reply,
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
    all_event_masks: EventSet,
    your_event_mask: EventSet,
    do_not_propogate_mask: DeviceEventSet,
    unused: u16 = 0,
};

pub const GetGeometryReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    root: u32,
    parent: u32,
    num_children: u16,
    unused_2: [14]u8 = [1]u8{0} ** 14,
};

pub const InternAtomReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    atom: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GetAtomNameReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    name_len: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetPropertyReply = extern struct {
    code: Code = .reply,
    format: u8,
    sequence_number: u16,
    reply_len: u32,
    type_id: u32,
    bytes_after: u32,
    value_len: u32,
    unused: [12]u8 = [1]u8{0} ** 12,
};

pub const ListPropertiesReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_atoms: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetSelectionOwnerReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    owner: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const GrabPointerReply = extern struct {
    code: Code = .reply,
    status: GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GrabKeyboardReply = extern struct {
    code: Code = .reply,
    status: GrabStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const QueryPointerReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_events: u32,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const TranslateCoordinatesReply = extern struct {
    code: Code = .reply,
    same_screen: bool,
    sequence_number: u16,
    reply_len: u32 = 0,
    child: u32,
    dst_x: i16,
    dst_y: i16,
    unused: [16]u8 = [1]u8{0} ** 16,
};

pub const GetInputFocusReply = extern struct {
    code: Code = .reply,
    revert_to: FocusRevertTo,
    sequence_number: u16,
    reply_len: u32 = 0,
    focus: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryKeymapReply = extern struct {
    code: Code = .reply,
    unused: u8,
    sequence_number: u16,
    reply_len: u32 = 2,
    keys: [32]u8 = [1]u8{0} ** 32,
};

pub const QueryFontReply = extern struct {
    code: Code = .reply,
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
    draw_direction: DrawDirection,
    min_byte1: u8,
    max_byte1: u8,
    all_chars_exist: bool,
    font_ascent: i16,
    font_descent: i16,
    num_char_infos: u32,
};

pub const QueryTextExtentsReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_names: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const ListFontsWithInfoReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    last_reply_indicator: u8 = 0,
    sequence_number: u16,
    reply_len: u32 = 7,
    unused: [52]u8 = [1]u8{0} ** 52,
};

pub const GetFontPathReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_paths: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const GetImageReply = extern struct {
    code: Code = .reply,
    depth: u8,
    sequence_number: u16,
    reply_len: u32,
    visual: u32,
    unused: [20]u8 = [1]u8{0} ** 20,
};

pub const ListInstalledColormapsReply = extern struct {
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_cmaps: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const AllocColorReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
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
    code: Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_pixels: u16,
    num_masks: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const AllocColorPlanesReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32,
    num_rgbs: u16,
    unused_2: [22]u8 = [1]u8{0} ** 22,
};

pub const LookupColorReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unsued_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    width: u16,
    height: u16,
    unused_2: [20]u8 = [1]u8{0} ** 20,
};

pub const QueryExtensionReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    num_names: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardMappingReply = extern struct {
    code: Code = .reply,
    keysyms_per_keycode: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetKeyboardControlReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    unused_1: u8,
    sequence_number: u16,
    reply_len: u32 = 0,
    acceleration_numerator: u16,
    acceleration_denominator: u16,
    threshold: u16,
    unused_2: [18]u8 = [1]u8{0} ** 18,
};

pub const GetScreenSaverReply = extern struct {
    code: Code = .reply,
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
    code: Code = .reply,
    mode: ListHostsMode,
    sequence_number: u16,
    reply_len: u32,
    num_hosts: u16,
    unused: [22]u8 = [1]u8{0} ** 22,
};

pub const SetPointerMappingReply = extern struct {
    code: Code = .reply,
    status: PointerMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetPointerMappingReply = extern struct {
    code: Code = .reply,
    map_len: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const SetModifierMappingReply = extern struct {
    code: Code = .reply,
    status: ModifierMappingStatus,
    sequence_number: u16,
    reply_len: u32 = 0,
    unused: [24]u8 = [1]u8{0} ** 24,
};

pub const GetModifierMappingReply = extern struct {
    code: Code = .reply,
    keycodes_per_modifier: u8,
    sequence_number: u16,
    reply_len: u32,
    unused: [24]u8 = [1]u8{0} ** 24,
};

// ***************************************************************************
// SECTION 4.3
// EVENTS
// ***************************************************************************

/// Generic event structure that can be used when reading messages from an X11
/// server.  Should only be used internally before being cast to a more
/// suitable type.
pub const UnknownEvent = extern struct {
    code: Code,
    data_1: u8,
    /// This maps to sequence_number for MOST events, but KeymapNotifyEvent is
    /// the odd man out.
    data_2: u16,
    data_3: u32,
    data_4: u64,
    data_5: u64,
    data_6: u64,
};

pub const FocusInEvent = extern struct {
    code: Code = .focus_in,
    detail: FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const FocusOutEvent = extern struct {
    code: Code = .focus_out,
    detail: FocusDetail,
    sequence_number: u16,
    window_id: u32,
    mode: FocusMode,
    unused: [23]u8 = [1]u8{0} ** 23,
};

pub const KeymapNotifyEvent = extern struct {
    code: Code = .keymap_notify,
    keys: [31]u8 = [1]u8{0} ** 31,
};

pub const ExposeEvent = extern struct {
    code: Code = .expose,
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
    code: Code = .visibility_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    state: VisibilityChangeState,
    unused_2: [23]u8 = [1]u8{0} ** 23,
};

pub const MapNotifyEvent = extern struct {
    code: Code = .map_notify,
    unused_1: u8,
    sequence_number: u16,
    event_window_id: u32,
    window_id: u32,
    override_redirect: bool,
    unused_2: [19]u8 = [1]u8{0} ** 19,
};

pub const ReparentNotifyEvent = extern struct {
    code: Code = .reparent_notify,
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
    code: Code = .property_notify,
    unused_1: u8,
    sequence_number: u16,
    window_id: u32,
    atom_id: u32,
    timestamp: u32,
    state: PropertyChangeState,
    unused_2: [15]u8 = [1]u8{0} ** 15,
};

pub const ClientMessageEvent = extern struct {
    code: Code = .client_message,
    format: u8,
    sequence_number: u16,
    window_id: u32,
    type: u32,
    data: [20]u8,

    pub const Int8 = extern struct {
        code: Code = .client_message,
        format: u8 = 8,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [20]u8,
    };

    pub const Int16 = extern struct {
        code: Code = .client_message,
        format: u8 = 16,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [10]u16,
    };

    pub const Int32 = extern struct {
        code: Code = .client_message,
        format: u8 = 32,
        sequence_number: u16,
        window_id: u32,
        type: u32,
        data: [5]u32,
    };
};

// ***************************************************************************
// SECTION 5
// REQUESTS
// ***************************************************************************

pub const SetupRequest = extern struct {
    byte_order: u8 = if (arch.endian() == .big) 0x42 else 0x6c,
    pad0: u8 = 0,
    protocol_major_version: u16 = 11,
    protocol_minor_version: u16 = 0,
    authorization_protocol_name_len: u16 = 0,
    authorization_protocol_data_len: u16 = 0,
    pad1: u16 = 0,
};

pub const BellRequest = extern struct {
    opcode: Opcode = .bell,
    percent: i8,
    request_len: u16 = 1,
};

pub const ChangePropertyRequest = extern struct {
    opcode: Opcode = .change_property,
    mode: ChangePropertyMode,
    request_len: u16,
    window_id: u32,
    property_id: u32,
    type_id: u32,
    format: u8,
    unused: [3]u8 = [1]u8{0} ** 3,
    data_len: u32,

    /// Calculate .request_len for request with given format and data length.
    pub fn requestLen(format: u8, data_len: usize) u16 {
        const datum_size = switch (format) {
            8, 16, 32 => |bits| bits / 8,
            else => @panic("format must be 8, 16, or 32 bits"),
        };

        const data_size = data_len * datum_size;
        const padded_size = data_size + ((4 - (data_size % 4)) % 4);

        return @intCast(@sizeOf(ChangePropertyRequest) + padded_size);
    }
};

pub const ChangeWindowAttributesRequest = extern struct {
    opcode: Opcode = .change_window_attributes,
    unused: u8 = 0,
    request_len: u16,
    window_id: u32,
    value_mask: WindowAttributes,
    // values: [bits_set(value_mask)]u32 (sort of)

    /// Calculate .request_len for request with given number of values.
    pub fn requestLen(value_len: usize) u16 {
        return @intCast(3 + value_len);
    }
};

pub const CreateWindowRequest = extern struct {
    opcode: Opcode = .create_window,
    depth: u8,
    request_len: u16,
    window_id: u32,
    parent_id: u32,
    x: i16 = 50,
    y: i16 = 50,
    width: u16 = 200,
    height: u16 = 300,
    border_width: u16 = 0,
    class: CreateWindowClass = .copy_from_parent,
    visual: u32 = CreateWindowRequest.visual_copy_from_parent,
    value_mask: WindowAttributes,
    // values: [bits set in value_mask]u32

    /// Default value for .visual.
    pub const visual_copy_from_parent: u32 = 0;

    /// Calculate .request_len for request with given number of flags.
    pub fn requestLen(num_flags: u8) u16 {
        return @sizeOf(CreateWindowRequest) / 4 + num_flags;
    }
};

pub const DestroyWindowRequest = extern struct {
    opcode: Opcode = .destroy_window,
    unused: u8 = 0,
    request_len: u16 = 2,
    window_id: u32,
};

pub const GetAtomNameRequest = extern struct {
    opcode: Opcode = .get_atom_name,
    unused: u8 = 0,
    request_len: u16 = 2,
    atom_id: u32,
};

pub const GetPropertyRequest = extern struct {
    opcode: Opcode = .get_property,
    delete: bool,
    request_len: u16 = 6,
    window_id: u32,
    property_id: u32,
    type_id: u32 = GetPropertyRequest.type_any,
    long_offset: u32,
    long_length: u32,

    pub const type_any: u32 = 0;
};

pub const GetWindowAttributesRequest = extern struct {
    opcode: Opcode = .get_window_attributes,
    unused: u8 = 0,
    request_len: u16 = 3,
    window_id: u32,
};

pub const InternAtomRequest = extern struct {
    opcode: Opcode = .intern_atom,
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
    opcode: Opcode = .map_window,
    unused: u8 = 0,
    request_len: u16 = 2,
    window_id: u32,
};

const Protocol = @import("x11.zig").Protocol;
const arch = @import("builtin").cpu.arch;

pub const Request = extern struct {
    byte_order: u8 = if (arch.endian() == .big) 0x42 else 0x6c,
    pad0: u8 = 0,
    protocol_major_version: u16 = Protocol.version,
    protocol_minor_version: u16 = Protocol.revision,
    authorization_protocol_name_len: u16 = 0,
    authorization_protocol_data_len: u16 = 0,
    pad1: u16 = 0,
};

pub const Header = extern struct {
    state: State,
    field_1: u8,
    field_2: u16,
    field_3: u16,
    data_len: u16,
};

pub const Authenticate = extern struct {
    state: State = .authenticate,
    pad: [5]u8 = [_]u8{0} ** 5,
    data_len: u16,
};

pub const Failure = extern struct {
    state: State = .failure,
    reason_len: u8,
    protocol_major_version: u16,
    protocol_minor_version: u16,
    data_len: u16,
};

pub const Success = extern struct {
    state: State = .success,
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
};

pub const State = enum(u8) {
    failure,
    success,
    authenticate,
};

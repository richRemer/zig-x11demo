const x11 = @import("x11.zig");

pub const Atoms = struct {
    WM_DELETE_WINDOW: u32 = x11.none,
    WM_PROTOCOLS: u32 = x11.none,
    WM_STATE: u32 = x11.none,
    _NET_FRAME_EXTENTS: u32 = x11.none,
    _NET_WM_NAME: u32 = x11.none,
    _NET_WM_STATE: u32 = x11.none,

    pub fn lookup(this: @This(), atom_id: u32) []const u8 {
        if (atom_id == this.WM_DELETE_WINDOW) return "WM_DELETE_WINDOW";
        if (atom_id == this.WM_PROTOCOLS) return "WM_PROTOCOLS";
        if (atom_id == this.WM_STATE) return "WM_STATE";
        if (atom_id == this._NET_FRAME_EXTENTS) return "_NET_FRAME_EXTENTS";
        if (atom_id == this._NET_WM_NAME) return "_NET_WM_NAME";
        if (atom_id == this._NET_WM_STATE) return "_NET_WM_STATE";
        return "unknown";
    }
};

pub const Context = struct {
    server: *x11.Server,
    atoms: Atoms = Atoms{},
    running: bool = true,
};

pub const Menu_StartGame = @import("Menu_StartGame.zig").Do;
pub const Menu_Settings = @import("Menu_Settings.zig").Do;
pub const Menu_Information = @import("Menu_Information.zig").Do;
pub const HandleEvents = @import("Events.zig").HandleEvents;

pub const E_MAIN_MENU = enum(u8) {
    START_GAME = 0,
    SETTINGS = 1,
    INFORMATION = 2,
    QUIT = 3,

    var _current: i32 = 0;
    
    pub fn Reset() void {
        _current = 0;
    }

    pub fn Up() void {
        _current -= 1;
        if (_current == -1) {
            _current = 3;
        }
    }

    pub fn Down() void {
        _current += 1;
        if (_current == 4) {
            _current = 0;
        }
    }

    pub fn Current() E_MAIN_MENU {
        return @enumFromInt(_current);
    }

    pub fn Is(e: E_MAIN_MENU) bool {
        return E_MAIN_MENU.Current() == e;
    }
};

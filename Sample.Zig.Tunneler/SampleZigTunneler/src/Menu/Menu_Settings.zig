const std = @import("std");
const sdl = @import("../sdl.zig").sdl;

const HandleEvents = @import("Events.zig").HandleEvents;

const game = @import("../Game.zig");
const Graphics = @import("../Graphics.zig");
const Tunneler = @import("../Tunneler.zig");
const Terrain = @import("../Terrain.zig");
const Key = @import("../Key.zig");
const Timer = @import("../Timer.zig");

pub fn Do() void {
    var vmode: usize = GetCurrentVMode();

    var buff1: [22]u8 = undefined;
    var buff2: [22]u8 = undefined;

    E_MENU_SETTING.Reset();

    while (!Key.is_key_quit) {
        _ = HandleEvents();

        if (Key.is_key_menu_up) {
            E_MENU_SETTING.Up();
        } else if (Key.is_key_menu_down) {
            E_MENU_SETTING.Down();
        }

        if (E_MENU_SETTING.IsTANK_1() and (Key.is_key_menu_left or Key.is_key_menu_right)) {
            E_MENU_SETTING.Add(5);
        } else if (E_MENU_SETTING.IsTANK_2() and (Key.is_key_menu_left or Key.is_key_menu_right)) {
            E_MENU_SETTING.Add(-5);
        }

        Key.is_key_menu_up = false;
        Key.is_key_menu_down = false;
        Key.is_key_menu_left = false;
        Key.is_key_menu_right = false;

        _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);

        Graphics.PutStr(6 * 8, 2 * 8, "Settings", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 4 * 8, "Fullscreen:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 5 * 8, "Mode:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 7 * 8, "       Tank1 Tank2", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 8 * 8, "Up:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 9 * 8, "Down:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 10 * 8, "Left:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 11 * 8, "Right:", Graphics.color[12]);
        Graphics.PutStr(1 * 8, 12 * 8, "Fire:", Graphics.color[12]);

        const slice = std.fmt.bufPrint(&buff1, "{s:>6}", .{if (Graphics.isVideo_fullscreen) "true" else "false"}) catch unreachable;
        Graphics.PutStr(13 * 8, 4 * 8, slice, Graphics.color[if (E_MENU_SETTING.FULL_SCREEN.Is()) 12 else 13]);

        const s1 = std.fmt.bufPrint(&buff1, "{d}x{d}", .{ Graphics.Video_X, Graphics.Video_Y }) catch unreachable;
        const str = std.fmt.bufPrint(&buff2, "{s:>9}", .{s1}) catch unreachable;
        Graphics.PutStr(10 * 8, 5 * 8, str, Graphics.color[if (E_MENU_SETTING.MODE.Is()) 12 else 13]);

        PrintKey(8 * 8, 8 * 8, Key.sym_pl[0].up, Graphics.color[if (E_MENU_SETTING.TANK_1_UP.Is()) 12 else 13]);
        PrintKey(8 * 8, 9 * 8, Key.sym_pl[0].down, Graphics.color[if (E_MENU_SETTING.TANK_1_DOWN.Is()) 12 else 13]);
        PrintKey(8 * 8, 10 * 8, Key.sym_pl[0].left, Graphics.color[if (E_MENU_SETTING.TANK_1_LEFT.Is()) 12 else 13]);
        PrintKey(8 * 8, 11 * 8, Key.sym_pl[0].right, Graphics.color[if (E_MENU_SETTING.TANK_1_RIGHT.Is()) 12 else 13]);
        PrintKey(8 * 8, 12 * 8, Key.sym_pl[0].fire, Graphics.color[if (E_MENU_SETTING.TANK_1_FIRE.Is()) 12 else 13]);

        PrintKey(14 * 8, 8 * 8, Key.sym_pl[1].up, Graphics.color[if (E_MENU_SETTING.TANK_2_UP.Is()) 12 else 13]);
        PrintKey(14 * 8, 9 * 8, Key.sym_pl[1].down, Graphics.color[if (E_MENU_SETTING.TANK_2_DOWN.Is()) 12 else 13]);
        PrintKey(14 * 8, 10 * 8, Key.sym_pl[1].left, Graphics.color[if (E_MENU_SETTING.TANK_2_LEFT.Is()) 12 else 13]);
        PrintKey(14 * 8, 11 * 8, Key.sym_pl[1].right, Graphics.color[if (E_MENU_SETTING.TANK_2_RIGHT.Is()) 12 else 13]);
        PrintKey(14 * 8, 12 * 8, Key.sym_pl[1].fire, Graphics.color[if (E_MENU_SETTING.TANK_2_FIRE.Is()) 12 else 13]);

        if (Key.is_key_menu_enter) {
            switch (E_MENU_SETTING.Current()) {
                E_MENU_SETTING.FULL_SCREEN => {
                    Graphics.isVideo_fullscreen = !Graphics.isVideo_fullscreen;

                    vmode = 0;
                    if (Graphics.isVideo_fullscreen) {
                        Graphics.Video_X = Graphics.fs_modes[vmode].w;
                        Graphics.Video_Y = Graphics.fs_modes[vmode].h;
                    } else {
                        Graphics.Video_X = Graphics.win_modes[vmode].w;
                        Graphics.Video_Y = Graphics.win_modes[vmode].h;
                    }
                },
                E_MENU_SETTING.MODE => {
                    if (Graphics.isVideo_fullscreen) {
                        vmode += 1;
                        if (vmode >= Graphics.fs_modes.len) {
                            vmode = 0;
                        }
                        Graphics.Video_X = Graphics.fs_modes[vmode].w;
                        Graphics.Video_Y = Graphics.fs_modes[vmode].h;
                    } else {
                        vmode += 1;
                        if (vmode >= Graphics.win_modes.len) {
                            vmode = 0;
                        }
                        Graphics.Video_X = Graphics.win_modes[vmode].w;
                        Graphics.Video_Y = Graphics.win_modes[vmode].h;
                    }
                },
                E_MENU_SETTING.TANK_1_UP => {
                    PrintKey(8 * 8, 8 * 8, Key.sym_pl[0].up, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 8 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[0].up = GetKeyPress();
                },
                E_MENU_SETTING.TANK_1_DOWN => {
                    PrintKey(8 * 8, 9 * 8, Key.sym_pl[0].down, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 9 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 9 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[0].down = GetKeyPress();
                },
                E_MENU_SETTING.TANK_1_LEFT => {
                    PrintKey(8 * 8, 10 * 8, Key.sym_pl[0].left, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 10 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 10 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[0].left = GetKeyPress();
                },
                E_MENU_SETTING.TANK_1_RIGHT => {
                    PrintKey(8 * 8, 11 * 8, Key.sym_pl[0].right, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 11 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 11 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[0].right = GetKeyPress();
                },
                E_MENU_SETTING.TANK_1_FIRE => {
                    PrintKey(8 * 8, 12 * 8, Key.sym_pl[0].fire, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 12 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(8 * 8, 12 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[0].fire = GetKeyPress();
                },
                E_MENU_SETTING.TANK_2_UP => {
                    PrintKey(14 * 8, 8 * 8, Key.sym_pl[1].up, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 8 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 8 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[1].up = GetKeyPress();
                },
                E_MENU_SETTING.TANK_2_DOWN => {
                    PrintKey(14 * 8, 9 * 8, Key.sym_pl[1].down, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 9 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 9 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[1].down = GetKeyPress();
                },
                E_MENU_SETTING.TANK_2_LEFT => {
                    PrintKey(14 * 8, 10 * 8, Key.sym_pl[1].left, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 10 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 10 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[1].left = GetKeyPress();
                },
                E_MENU_SETTING.TANK_2_RIGHT => {
                    PrintKey(14 * 8, 11 * 8, Key.sym_pl[1].right, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 11 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 11 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[1].right = GetKeyPress();
                },
                E_MENU_SETTING.TANK_2_FIRE => {
                    PrintKey(14 * 8, 12 * 8, Key.sym_pl[1].fire, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 12 * 8, str, Graphics.color[0]);
                    Graphics.PutStr(14 * 8, 12 * 8, "key", Graphics.color[12]);
                    _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);

                    Key.sym_pl[1].fire = GetKeyPress();
                },
            }

            if (E_MENU_SETTING.FULL_SCREEN.Is() or E_MENU_SETTING.MODE.Is()) {
                // TODO(pyoung): maybe. replace surface  to renderer
                // TODO(pyoung): add logical surface to support fullscreen

                const display_id = sdl.SDL_GetDisplayForWindow(Graphics.screen);
                const mode = sdl.SDL_GetCurrentDisplayMode(display_id).*;

                if (Graphics.isVideo_fullscreen) {
                    _ = sdl.SDL_SetWindowBordered(Graphics.screen, false);
                    _ = sdl.SDL_SetWindowPosition(Graphics.screen, 0, 0);
                    _ = sdl.SDL_SetWindowSize(Graphics.screen, mode.w, mode.h);
                } else {
                    _ = sdl.SDL_SetWindowBordered(Graphics.screen, true);
                    _ = sdl.SDL_SetWindowPosition(Graphics.screen, @divTrunc(mode.w - Graphics.Video_X, 2), @divTrunc(mode.h - Graphics.Video_Y, 2));
                    _ = sdl.SDL_SetWindowSize(Graphics.screen, Graphics.Video_X, Graphics.Video_Y);
                }

                Graphics.surface = sdl.SDL_GetWindowSurface(Graphics.screen);
                _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);
            }

            Key.is_key_menu_enter = false;
        }

        _ = sdl.SDL_UpdateWindowSurface(Graphics.screen);
        sdl.SDL_Delay(16);
    }

    Key.is_key_quit = false;
}

const E_MENU_SETTING = enum(u8) {
    FULL_SCREEN = 0,
    MODE = 1,
    TANK_1_UP = 2,
    TANK_1_DOWN = 3,
    TANK_1_LEFT = 4,
    TANK_1_RIGHT = 5,
    TANK_1_FIRE = 6,
    TANK_2_UP = 7,
    TANK_2_DOWN = 8,
    TANK_2_LEFT = 9,
    TANK_2_RIGHT = 10,
    TANK_2_FIRE = 11,

    var _current: i32 = 0;

    pub fn IsTANK_1() bool {
        return (2 <= _current and _current <= 6);
    }

    pub fn IsTANK_2() bool {
        return (7 <= _current and _current <= 11);
    }

    pub fn Reset() void {
        _current = 0;
    }

    pub fn Add(v: i32) void {
        _current += v;
        if (_current == -1) {
            _current = 11;
        } else if (_current == 12) {
            _current = 0;
        }
    }

    pub fn Up() void {
        Add(-1);
    }

    pub fn Down() void {
        Add(1);
    }

    pub fn Current() E_MENU_SETTING {
        return @enumFromInt(_current);
    }

    pub fn Is(e: E_MENU_SETTING) bool {
        return E_MENU_SETTING.Current() == e;
    }
};

fn PrintKey(x: usize, y: usize, key: u32, color: u32) void {
    var buff: [22]u8 = undefined;
    const str: []u8 =
        switch (key) {
            sdl.SDLK_UP => std.fmt.bufPrint(&buff, "{s:>5}", .{"up"}),
            sdl.SDLK_DOWN => std.fmt.bufPrint(&buff, "{s:>5}", .{"down"}),
            sdl.SDLK_LEFT => std.fmt.bufPrint(&buff, "{s:>5}", .{"left"}),
            sdl.SDLK_RIGHT => std.fmt.bufPrint(&buff, "{s:>5}", .{"right"}),
            sdl.SDLK_RSHIFT => std.fmt.bufPrint(&buff, "{s:>5}", .{"rshft"}),
            sdl.SDLK_LSHIFT => std.fmt.bufPrint(&buff, "{s:>5}", .{"lshft"}),
            sdl.SDLK_RCTRL => std.fmt.bufPrint(&buff, "{s:>5}", .{"rctrl"}),
            sdl.SDLK_LCTRL => std.fmt.bufPrint(&buff, "{s:>5}", .{"lctrl"}),
            sdl.SDLK_RETURN => std.fmt.bufPrint(&buff, "{s:>5}", .{"rtrn"}),
            sdl.SDLK_TAB => std.fmt.bufPrint(&buff, "{s:>5}", .{"tab"}),
            sdl.SDLK_BACKSPACE => std.fmt.bufPrint(&buff, "{s:>5}", .{"bspc"}),
            sdl.SDLK_SPACE => std.fmt.bufPrint(&buff, "{s:>5}", .{"spc"}),
            sdl.SDLK_SLASH => std.fmt.bufPrint(&buff, "{s:>5}", .{"slash"}),
            sdl.SDLK_PLUS => std.fmt.bufPrint(&buff, "{s:>5}", .{"+"}),
            sdl.SDLK_MINUS => std.fmt.bufPrint(&buff, "{s:>5}", .{"-"}),
            sdl.SDLK_COMMA => std.fmt.bufPrint(&buff, "{s:>5}", .{","}),
            sdl.SDLK_PERIOD => std.fmt.bufPrint(&buff, "{s:>5}", .{"."}),
            sdl.SDLK_COLON => std.fmt.bufPrint(&buff, "{s:>5}", .{":"}),
            sdl.SDLK_SEMICOLON => std.fmt.bufPrint(&buff, "{s:>5}", .{";"}),
            sdl.SDLK_LESS => std.fmt.bufPrint(&buff, "{s:>5}", .{"<"}),
            sdl.SDLK_EQUALS => std.fmt.bufPrint(&buff, "{s:>5}", .{"="}),
            sdl.SDLK_GREATER => std.fmt.bufPrint(&buff, "{s:>5}", .{">"}),
            sdl.SDLK_AT => std.fmt.bufPrint(&buff, "{s:>5}", .{"@"}),
            sdl.SDLK_LEFTBRACKET => std.fmt.bufPrint(&buff, "{s:>5}", .{"["}),
            sdl.SDLK_BACKSLASH => std.fmt.bufPrint(&buff, "{s:>5}", .{"\\"}),
            sdl.SDLK_RIGHTBRACKET => std.fmt.bufPrint(&buff, "{s:>5}", .{"]"}),
            sdl.SDLK_0 => std.fmt.bufPrint(&buff, "{s:>5}", .{"0"}),
            sdl.SDLK_1 => std.fmt.bufPrint(&buff, "{s:>5}", .{"1"}),
            sdl.SDLK_2 => std.fmt.bufPrint(&buff, "{s:>5}", .{"2"}),
            sdl.SDLK_3 => std.fmt.bufPrint(&buff, "{s:>5}", .{"3"}),
            sdl.SDLK_4 => std.fmt.bufPrint(&buff, "{s:>5}", .{"4"}),
            sdl.SDLK_5 => std.fmt.bufPrint(&buff, "{s:>5}", .{"5"}),
            sdl.SDLK_6 => std.fmt.bufPrint(&buff, "{s:>5}", .{"6"}),
            sdl.SDLK_7 => std.fmt.bufPrint(&buff, "{s:>5}", .{"7"}),
            sdl.SDLK_8 => std.fmt.bufPrint(&buff, "{s:>5}", .{"8"}),
            sdl.SDLK_9 => std.fmt.bufPrint(&buff, "{s:>5}", .{"9"}),
            sdl.SDLK_A => std.fmt.bufPrint(&buff, "{s:>5}", .{"a"}),
            sdl.SDLK_B => std.fmt.bufPrint(&buff, "{s:>5}", .{"b"}),
            sdl.SDLK_C => std.fmt.bufPrint(&buff, "{s:>5}", .{"c"}),
            sdl.SDLK_D => std.fmt.bufPrint(&buff, "{s:>5}", .{"d"}),
            sdl.SDLK_E => std.fmt.bufPrint(&buff, "{s:>5}", .{"e"}),
            sdl.SDLK_F => std.fmt.bufPrint(&buff, "{s:>5}", .{"f"}),
            sdl.SDLK_G => std.fmt.bufPrint(&buff, "{s:>5}", .{"g"}),
            sdl.SDLK_H => std.fmt.bufPrint(&buff, "{s:>5}", .{"h"}),
            sdl.SDLK_I => std.fmt.bufPrint(&buff, "{s:>5}", .{"i"}),
            sdl.SDLK_J => std.fmt.bufPrint(&buff, "{s:>5}", .{"j"}),
            sdl.SDLK_K => std.fmt.bufPrint(&buff, "{s:>5}", .{"k"}),
            sdl.SDLK_L => std.fmt.bufPrint(&buff, "{s:>5}", .{"l"}),
            sdl.SDLK_M => std.fmt.bufPrint(&buff, "{s:>5}", .{"m"}),
            sdl.SDLK_N => std.fmt.bufPrint(&buff, "{s:>5}", .{"n"}),
            sdl.SDLK_O => std.fmt.bufPrint(&buff, "{s:>5}", .{"o"}),
            sdl.SDLK_P => std.fmt.bufPrint(&buff, "{s:>5}", .{"p"}),
            sdl.SDLK_Q => std.fmt.bufPrint(&buff, "{s:>5}", .{"q"}),
            sdl.SDLK_R => std.fmt.bufPrint(&buff, "{s:>5}", .{"r"}),
            sdl.SDLK_S => std.fmt.bufPrint(&buff, "{s:>5}", .{"s"}),
            sdl.SDLK_T => std.fmt.bufPrint(&buff, "{s:>5}", .{"t"}),
            sdl.SDLK_U => std.fmt.bufPrint(&buff, "{s:>5}", .{"u"}),
            sdl.SDLK_V => std.fmt.bufPrint(&buff, "{s:>5}", .{"v"}),
            sdl.SDLK_W => std.fmt.bufPrint(&buff, "{s:>5}", .{"w"}),
            sdl.SDLK_X => std.fmt.bufPrint(&buff, "{s:>5}", .{"x"}),
            sdl.SDLK_Y => std.fmt.bufPrint(&buff, "{s:>5}", .{"y"}),
            sdl.SDLK_Z => std.fmt.bufPrint(&buff, "{s:>5}", .{"z"}),
            else => std.fmt.bufPrint(&buff, "k_{d:0>3}", .{key}),
        } catch unreachable;

    Graphics.PutStr(x, y, str, color);
}

fn GetKeyPress() u32 {
    var key: *sdl.SDL_KeyboardEvent = undefined;
    var event: sdl.SDL_Event = undefined;

    while (true) {
        while (sdl.SDL_PollEvent(&event)) {
            switch (event.type) {
                sdl.SDL_EVENT_KEY_DOWN => {
                    key = &event.key;
                    return key.key;
                },
                sdl.SDL_EVENT_WINDOW_RESIZED => {
                    Graphics.surface = sdl.SDL_GetWindowSurface(Graphics.screen);
                },
                sdl.SDL_EVENT_QUIT => {
                    std.process.exit(0);
                    return 0;
                },
                else => {},
            }
        }

        sdl.SDL_Delay(50);
    }

    return 0;
}

fn GetCurrentVMode() usize {
    var vmode: usize = 0;
    if (Graphics.isVideo_fullscreen) {
        for (&Graphics.fs_modes, 0..) |*fs_mode, i| {
            vmode = i;
            if (fs_mode.w == Graphics.Video_X and fs_mode.h == Graphics.Video_Y) {
                break;
            }
        }
    } else {
        for (&Graphics.win_modes, 0..) |*win_mode, i| {
            vmode = i;
            if (win_mode.w == Graphics.Video_X and win_mode.h == Graphics.Video_Y) {
                break;
            }
        }
    }
    return vmode;
}

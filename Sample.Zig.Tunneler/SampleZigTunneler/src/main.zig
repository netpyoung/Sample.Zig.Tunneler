const std = @import("std");
const builtin = @import("builtin");

const sdl = @import("sdl.zig").sdl;

const game = @import("Game.zig");
const Graphics = @import("Graphics.zig");
const Key = @import("Key.zig");
const Types = @import("Types.zig");
const Menu = @import("Menu/Menu.zig");
// const Ai = @import("Ai.zig");
// const Tunneler = @import("Tunneler.zig");

pub fn main() void {
    if (!Graphics.Init_Video()) { // sdl init
        return;
    }
    defer Graphics.Deinit_Video(); // sdd quit

    // Tunneler.Tank[1].mode = Types.E_PLAYER_MODE.TANK_AI;
    // Ai.Init_AI();

    while (!Key.is_key_quit) {
        if (!Menu.HandleEvents()) {
            return;
        }

        if (Key.is_key_menu_up) {
            Menu.E_MAIN_MENU.Up();
            Key.is_key_menu_up = false;
        } else if (Key.is_key_menu_down) {
            Menu.E_MAIN_MENU.Down();
            Key.is_key_menu_down = false;
        }

        _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);
        {
            ShowTitle();

            if (Key.is_key_menu_enter) {
                Key.is_key_menu_enter = false;

                switch (Menu.E_MAIN_MENU.Current()) {
                    Menu.E_MAIN_MENU.START_GAME => {
                        Menu.Menu_StartGame();
                    },
                    Menu.E_MAIN_MENU.SETTINGS => {
                        Menu.Menu_Settings();
                    },
                    Menu.E_MAIN_MENU.INFORMATION => {
                        Menu.Menu_Information();
                    },
                    Menu.E_MAIN_MENU.QUIT => {
                        Key.is_key_quit = true;
                    },
                }

                Menu.E_MAIN_MENU.Reset();
            }
        }
        Graphics.Refresh();
        sdl.SDL_Delay(16);
    }
}

// ===========================
var gpa_instance = std.heap.GeneralPurposeAllocator(.{
    .thread_safe = true,
    .never_unmap = true,
    .retain_metadata = true,
    .stack_trace_frames = 16,
}){};

fn Deinit() void {
    if (builtin.mode == .Debug or builtin.mode == .ReleaseSafe) {
        const leaked = gpa_instance.deinit();
        if (leaked == .leak) {
            std.debug.print("\nMemory leak detected!\n", .{});
        }
    }
}

fn ShowTitle() void {
    var buff: [64]u8 = undefined;
    const version = std.fmt.bufPrint(&buff, "Tunneler v.{s}", .{game.VERSION}) catch unreachable;
    Graphics.PutStr(18, 20, version, Graphics.color[8]);
    Graphics.PutStr(50, 55, "Start Game", Graphics.color[if (Menu.E_MAIN_MENU.START_GAME.Is()) 12 else 13]);
    Graphics.PutStr(50, 65, "Settings", Graphics.color[if (Menu.E_MAIN_MENU.SETTINGS.Is()) 12 else 13]);
    Graphics.PutStr(50, 75, "Information", Graphics.color[if (Menu.E_MAIN_MENU.INFORMATION.Is()) 12 else 13]);
    Graphics.PutStr(50, 85, "Quit", Graphics.color[if (Menu.E_MAIN_MENU.QUIT.Is()) 12 else 13]);
}

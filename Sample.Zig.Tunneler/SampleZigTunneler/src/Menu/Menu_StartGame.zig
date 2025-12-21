const std = @import("std");
const HandleEvents = @import("Events.zig").HandleEvents;
const sdl = @import("../sdl.zig").sdl;

const game = @import("../Game.zig");
const Graphics = @import("../Graphics.zig");
const Tunneler = @import("../Tunneler.zig");
const Terrain = @import("../Terrain.zig");
const Key = @import("../Key.zig");
const Timer = @import("../Timer.zig");

pub fn Do() void {
    Main_Game();
    Print_Field();
    Print_Stats();
}

fn Main_Game() void {
    var dt: f64 = undefined;

    _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);

    Tunneler.DrawFrames();
    Graphics.Refresh();
    Tunneler.DrawFrames();

    Terrain.Init_Field();
    Tunneler.Init_Tanks();

    Timer.Init_Timer();

    while (!Key.is_key_quit) {
        dt = Timer.DoTimer();
        _ = HandleEvents();
        Tunneler.HandleActions(dt);

        Tunneler.Draw();
        Graphics.Refresh();
    }

    Key.is_key_quit = false;
}


fn Print_Field() void {
    Key.is_key_menu_enter = false;

    _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);
    _ = sdl.SDL_LockSurface(Graphics.surface);

    for (0..@intCast(Graphics.Video_Y)) |j| {
        for (0..@intCast(Graphics.Video_X)) |i| {
            const ii: i32 = @intCast(i);
            const jj: i32 = @intCast(j);
            const x = @divTrunc(ii * game.FIELD_SIZEX, Graphics.Video_X);
            const y = @divTrunc(jj * game.FIELD_SIZEY, Graphics.Video_Y);

            if (x < 50 or x > game.FIELD_SIZEX - 50 or
                y < 50 or y > game.FIELD_SIZEY - 50)
            {
                Graphics.PutPhysPixel(i, j, Graphics.color[2]);
            } else {
                Graphics.PutPhysPixel(i, j, Graphics.color[Terrain.field[@intCast(y)][@intCast(x)]]);
            }
        }
    }

    sdl.SDL_UnlockSurface(Graphics.surface);
    Graphics.Refresh();
    sdl.SDL_Delay(16);

    while (!Key.is_key_quit) {
        _ = HandleEvents();

        if (Key.is_key_menu_enter) {
            Key.is_key_menu_enter = false;
            break;
        }

        sdl.SDL_Delay(16);
    }

    Key.is_key_quit = false;
}

fn Print_Stats() void {
    var str: [22]u8 = undefined;

    _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);

    Graphics.PutStr(25, 20, "Victories:", Graphics.color[12]);

    var slice: []u8 = undefined;
    slice = std.fmt.bufPrint(&str, "Tank 1: {d}", .{Tunneler.Tank[1].deaths}) catch unreachable;
    Graphics.PutStr(25, 35, slice, Graphics.color[30]);

    slice = std.fmt.bufPrint(&str, "Tank 2: {d}", .{Tunneler.Tank[0].deaths}) catch unreachable;
    Graphics.PutStr(25, 43, slice, Graphics.color[40]);

    Graphics.Refresh();
    sdl.SDL_Delay(16);

    Key.is_key_menu_enter = false;
    Key.is_key_quit = false;

    while (!Key.is_key_quit) {
        _ = HandleEvents();

        if (Key.is_key_menu_enter) {
            Key.is_key_menu_enter = false;
            break;
        }

        sdl.SDL_Delay(16);
    }

    Key.is_key_quit = false;
}
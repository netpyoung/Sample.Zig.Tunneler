const std = @import("std");
const sdl = @import("../sdl.zig").sdl;
const Graphics = @import("../Graphics.zig");
const Key = @import("../Key.zig");
const HandleEvents = @import("Events.zig").HandleEvents;

const INFORMATION_TEXT =
    \\Tunneler(FOSS)
    \\
    \\
    \\This(SDL3.x w Zig)
    \\Eunpyoung Kim
    \\
    \\2003(SDL1.2 w C)
    \\Taneli Kalvas
    \\
    \\1991(original)
    \\Geoffrey Silverton
;

const INFORMATION_LINES = blk: {
    var line_count: usize = 0;
    var it = std.mem.splitScalar(u8, INFORMATION_TEXT, '\n');
    while (it.next()) |_| {
        line_count += 1;
    }

    var lines: [line_count][]const u8 = undefined;
    var i: usize = 0;
    var it2 = std.mem.splitScalar(u8, INFORMATION_TEXT, '\n');
    while (it2.next()) |line| {
        lines[i] = line;
        i += 1;
    }
    break :blk lines;
};

pub fn Do() void {
    _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[0]);
    for (INFORMATION_LINES, 0..) |line, i| {
        const ty: usize = 8 + i * 8;
        Graphics.PutStr(8, ty, line, Graphics.color[12]);
    }
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

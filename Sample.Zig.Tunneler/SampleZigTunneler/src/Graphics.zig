const std = @import("std");
const sdl = @import("sdl.zig").sdl;
const raw_font8x8 = @import("font8x8.zig").raw_font8x8;
const game = @import("Game.zig");

const printf = std.debug.print;
const assert = std.debug.assert;

pub const RES_X: i32 = 160;
pub const RES_Y: i32 = 120;
const _font8x8 = blk: {
    @setEvalBranchQuota(20000);
    var result: [8][8][256]bool = undefined;

    for (0..256) |a| {
        for (0..8) |y| {
            var c = raw_font8x8[8 * a + y];
            for (0..8) |x| {
                result[x][y][a] = (c & 128) == 128;
                c <<= 1;
            }
        }
    }
    break :blk result;
};

var _window: *sdl.SDL_Window = undefined;
var _surface_window: *sdl.SDL_Surface = undefined;
var logical_surfaceOrNull: ?*sdl.SDL_Surface = null;

pub var surface: *sdl.SDL_Surface = undefined;
pub var color: [256]u32 = undefined;

pub const fs_modes = [5]sdl.SDL_Rect{
    .{ .x = 0, .y = 0, .w = 1280, .h = 960 },
    .{ .x = 0, .y = 0, .w = 1024, .h = 768 },
    .{ .x = 0, .y = 0, .w = 800, .h = 600 },
    .{ .x = 0, .y = 0, .w = 640, .h = 480 },
    .{ .x = 0, .y = 0, .w = 320, .h = 240 },
};
pub const win_modes = [5]sdl.SDL_Rect{
    .{ .x = 0, .y = 0, .w = 1280, .h = 960 },
    .{ .x = 0, .y = 0, .w = 1024, .h = 768 },
    .{ .x = 0, .y = 0, .w = 800, .h = 600 },
    .{ .x = 0, .y = 0, .w = 640, .h = 480 },
    .{ .x = 0, .y = 0, .w = 320, .h = 240 },
};

pub var isVideo_fullscreen: bool = false;
pub var Video_X: i32 = 800;
pub var Video_Y: i32 = 600;

pub fn Deinit_Video() void {
    if (logical_surfaceOrNull) |logical_surface| {
        sdl.SDL_DestroySurface(logical_surface);
    }
    sdl.SDL_DestroyWindow(_window);
    sdl.SDL_Quit();
}

pub fn Resize(w: i32, h: i32) void {
    if (logical_surfaceOrNull != null) {
        _ = sdl.SDL_FillSurfaceRect(_surface_window, null, color[0]);
        _ = sdl.SDL_UpdateWindowSurface(_window);
        sdl.SDL_DestroySurface(logical_surfaceOrNull.?);
    }

    logical_surfaceOrNull = sdl.SDL_CreateSurface(w, h, sdl.SDL_PIXELFORMAT_RGBA32);
    surface = logical_surfaceOrNull.?;
    _surface_window = sdl.SDL_GetWindowSurface(_window);
}

pub fn Refresh() void {
    const window_w = _surface_window.*.w;
    const window_h = _surface_window.*.h;

    const rect: sdl.SDL_Rect = .{
        .x = @divTrunc((window_w - Video_X), 2),
        .y = @divTrunc((window_h - Video_Y), 2),
        .w = Video_X,
        .h = Video_Y,
    };
    _ = sdl.SDL_BlitSurfaceScaled(surface, null, _surface_window, &rect, sdl.SDL_SCALEMODE_LINEAR);
    _ = sdl.SDL_UpdateWindowSurface(_window);
}

pub fn Init_Video() bool {
    if (!sdl.SDL_Init(sdl.SDL_INIT_VIDEO)) {
        printf("Couldn't initialize SDL: {s}\n", .{sdl.SDL_GetError()});
        return false;
    }

    var buff: [64]u8 = undefined;
    const title = std.fmt.bufPrintSentinel(&buff, "Tunneler v.{s}", .{game.VERSION}, 0) catch unreachable;
    const windowOrNull = sdl.SDL_CreateWindow(title, Video_X, Video_Y, 0);
    if (windowOrNull == null) {
        printf("Couldn't set video mode {d}x{d}: {s}\n", .{ Video_X, Video_Y, sdl.SDL_GetError() });
        return false;
    }

    _window = windowOrNull.?;
    Resize(Video_X, Video_Y);

    // _ = sdl.SDL_WarpMouseGlobal(0, 0);
    // _ = sdl.SDL_HideCursor();

    //* Black and white */
    color[0] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x00, 0x00); // black
    color[1] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0xff); // white
    color[2] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x00, 0x88); //* Blue background */
    color[3] = sdl.SDL_MapSurfaceRGB(surface, 0x44, 0x44, 0x44); //* Dark gray */
    color[4] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x88, 0x88); //* Medium gray */
    color[5] = sdl.SDL_MapSurfaceRGB(surface, 0xcc, 0xcc, 0xcc); //* Light gray */
    color[6] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x00); //* Energy */
    color[7] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0xff); //* Shields */

    //* Field */
    color[8] = sdl.SDL_MapSurfaceRGB(surface, 0x99, 0x66, 0x33); //* Light brown */
    color[9] = sdl.SDL_MapSurfaceRGB(surface, 0x66, 0x44, 0x22); //* Dark brown */
    color[10] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x88, 0x88); //* Rock */
    color[11] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x00); //* Rock2 */

    //* Fire and ammo colors */
    color[12] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0x00, 0x00);
    color[13] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x00, 0x00);
    color[14] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x00);
    color[15] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);
    color[16] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);
    color[17] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);
    color[18] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);
    color[19] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);

    //* Player 0 colors */
    color[30] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xff, 0x00);
    color[31] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x88, 0x00);
    color[32] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x00);

    //* Player 1 colors */
    color[40] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x00, 0xff);
    color[41] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x00, 0x88);
    color[42] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x00);

    //* Noise */
    color[50] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x00, 0x00);
    color[51] = sdl.SDL_MapSurfaceRGB(surface, 0xaa, 0x22, 0x22);
    color[52] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0xaa, 0x22);
    color[53] = sdl.SDL_MapSurfaceRGB(surface, 0x22, 0x00, 0xaa);
    color[54] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x22, 0x22);
    color[55] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x88, 0x22);
    color[56] = sdl.SDL_MapSurfaceRGB(surface, 0x22, 0x22, 0x88);
    color[57] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xbb, 0xff);
    color[58] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0xbb, 0x88);
    color[59] = sdl.SDL_MapSurfaceRGB(surface, 0x44, 0xbb, 0x44);
    color[60] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x88, 0x22);
    color[61] = sdl.SDL_MapSurfaceRGB(surface, 0x22, 0x88, 0x88);
    color[62] = sdl.SDL_MapSurfaceRGB(surface, 0x88, 0x11, 0x88);
    color[63] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xff, 0x22);
    color[64] = sdl.SDL_MapSurfaceRGB(surface, 0x22, 0xff, 0xff);
    color[65] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0x22, 0xff);
    color[66] = sdl.SDL_MapSurfaceRGB(surface, 0x00, 0x11, 0x00);
    color[67] = sdl.SDL_MapSurfaceRGB(surface, 0xff, 0xcc, 0xff);
    color[68] = sdl.SDL_MapSurfaceRGB(surface, 0x22, 0x33, 0x22);
    color[69] = sdl.SDL_MapSurfaceRGB(surface, 0xaa, 0xaa, 0xaa);

    _ = sdl.SDL_FillSurfaceRect(surface, null, color[0]);
    Refresh();
    return true;
}

pub fn PutPhysPixel(x: usize, y: usize, coloru: u32) void {
    const details = sdl.SDL_GetPixelFormatDetails(surface.format);
    const bpp = details.*.bits_per_pixel;
    assert(bpp == 32);

    const pitch: usize = @intCast(surface.pitch);

    const pixels_ptr: [*]u8 = @ptrCast(surface.pixels);
    const offset = @as(usize, @intCast(y)) * pitch + @as(usize, @intCast(x)) * bpp / 8;

    const target_pixel: *u32 = @ptrCast(@alignCast(&pixels_ptr[offset]));
    target_pixel.* = coloru;
}

pub fn PutPixel(x: i32, y: i32, coloru: u32) void {
    DrawBox(x, y, 1, 1, coloru);
}

pub fn PutStr(x: usize, y: usize, str: []const u8, coloru: u32) void {
    var i: usize = 0;

    for (str) |c| {
        PutChar(x + i, y, c, coloru);
        i += 8;
    }
}

pub fn DrawBox(x: i32, y: i32, w: i32, h: i32, coloru: u32) void {
    const rect: sdl.SDL_Rect = .{
        .x = @divTrunc(Video_X * x, RES_X),
        .y = @divTrunc(Video_Y * y, RES_Y),
        .w = @divTrunc(Video_X * (x + w), RES_X) - @divTrunc(Video_X * x, RES_X),
        .h = @divTrunc(Video_Y * (y + h), RES_Y) - @divTrunc(Video_Y * y, RES_Y),
    };
    _ = sdl.SDL_FillSurfaceRect(surface, &rect, coloru);
}

pub fn UpdateMode() void {
    // TODO(pyoung): maybe. replace surface  to renderer

    const display_id = sdl.SDL_GetDisplayForWindow(_window);
    const mode = sdl.SDL_GetCurrentDisplayMode(display_id).*;

    if (isVideo_fullscreen) {
        _ = sdl.SDL_SetWindowBordered(_window, false);
        _ = sdl.SDL_SetWindowPosition(_window, 0, 0);
        _ = sdl.SDL_SetWindowSize(_window, mode.w, mode.h);
    } else {
        _ = sdl.SDL_SetWindowBordered(_window, true);
        _ = sdl.SDL_SetWindowPosition(_window, @divTrunc(mode.w - Video_X, 2), @divTrunc(mode.h - Video_Y, 2));
        _ = sdl.SDL_SetWindowSize(_window, Video_X, Video_Y);
    }
    Resize(Video_X, Video_Y);
    Refresh();
}
// =============================================================================================================================
// private
// =============================================================================================================================

fn PutChar(x: usize, y: usize, ch: u8, coloru: u32) void {
    for (0..8) |i| {
        for (0..8) |j| {
            if (_font8x8[j][i][ch]) {
                PutPixel(@intCast(x + j), @intCast(y + i), coloru);
            }
        }
    }
}

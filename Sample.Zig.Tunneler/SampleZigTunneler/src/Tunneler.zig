const std = @import("std");
const sdl = @import("sdl.zig").sdl;

const Types = @import("Types.zig");
const Terrain = @import("Terrain.zig");
const game = @import("Game.zig");
const Graphics = @import("Graphics.zig");
const Timer = @import("Timer.zig");
const Ai = @import("Ai.zig");
const Key = @import("Key.zig");

const DrawBox = Graphics.DrawBox;
const PutPixel = Graphics.PutPixel;
const Time_Now = Timer.Time_Now;

const Handle_AI = Ai.Handle_AI;
const E_DIR = Types.E_DIR;

// TODO(pyoung): use zig rand
const RAND_MAX = 0x7fff;
extern fn rand() i32;

const PI = std.math.pi;
const sin = std.math.sin;
const cos = std.math.cos;
const floor = std.math.floor;
const ceil = std.math.ceil;

fn TUNNEL_MACRO(X: *u8) void {
    if (X.* == 8 or X.* == 9) {
        X.* = 0;
    }
}

var noise0: i32 = 0;
var noise1: i32 = 0;
var max: i32 = undefined;

const rot_xtable: [8]f64 = .{ 1.000, 0.707, 0.000, -0.707, -1.000, -0.707, 0.000, 0.707 };
const rot_ytable: [8]f64 = .{ 0.000, 0.707, 1.000, 0.707, 0.000, -0.707, -1.000, -0.707 };

var Ammo: [2][128]Types.AMMO = undefined;
var Expl: [128]Types.EXPL = undefined;
pub var Tank: [2]Types.TANK = undefined;

const tank_spr = game.TANK_SPRITE;


pub fn Init_Tanks() void {
    for (0..2) |j| {
        Tank[j].rot = E_DIR.UP;
        Tank[j].isTunneling = true;
        Tank[j].x = @floatFromInt(Tank[j].basex);
        Tank[j].y = @floatFromInt(Tank[j].basey);
        Tank[j].Energy = 1.0;
        Tank[j].Shields = 1.0;
        Tank[j].deathc = 0.0;
        Tank[j].deaths = 0;

        for (0..128) |i| {
            Ammo[j][i].isExists = false;
        }
    }

    for (&Expl) |*expl| {
        expl.lifetime = 0.0;
    }
}


pub fn DrawFrames() void {
    _ = sdl.SDL_FillSurfaceRect(Graphics.surface, null, Graphics.color[2]);

    DrawBox(2, 2, 76, 90, Graphics.color[0]);
    DrawBox(82, 2, 76, 90, Graphics.color[0]);

    DrawStatusBox(6, 94);
    DrawStatusBox(86, 94);
}

pub fn Draw() void {
    var x: i32 = undefined;
    var y: i32 = undefined;
    var rect: sdl.SDL_Rect = undefined;

    //* Draw status */
    Graphics.DrawBox(19, 98, 49, 5, Graphics.color[0]);
    Graphics.DrawBox(19, 109, 49, 5, Graphics.color[0]);
    Graphics.DrawBox(99, 98, 49, 5, Graphics.color[0]);
    Graphics.DrawBox(99, 109, 49, 5, Graphics.color[0]);

    Graphics.DrawBox(19, 98, @intFromFloat(49.0 * Tank[1].Energy), 5, Graphics.color[6]);
    if (Tank[1].Shields > 0.0) {
        Graphics.DrawBox(19, 109, @intFromFloat(49.0 * Tank[1].Shields), 5, Graphics.color[7]);
    }

    Graphics.DrawBox(99, 98, @intFromFloat(49.0 * Tank[0].Energy), 5, Graphics.color[6]);
    if (Tank[0].Shields > 0.0) {
        Graphics.DrawBox(99, 109, @intFromFloat(49.0 * Tank[0].Shields), 5, Graphics.color[7]);
    }

    //* Draw field or noise */
    if (Tank[0].Energy >= 0.25 or NoiseProb(Tank[0].Energy)) {
        x = Round(Tank[0].x);
        y = Round(Tank[0].y);
        for (0..90) |jj| {
            for (0..76) |ii| {
                PutPixel(@intCast(82 + ii), @intCast(2 + jj), Graphics.color[Terrain.field[@as(usize, @intCast(y)) + jj - 45][@as(usize, @intCast(x)) + ii - 38]]);
            }
        }
    } else {
        noise0 = 2;
    }

    if (Tank[1].Energy >= 0.25 or NoiseProb(Tank[1].Energy)) {
        x = Round(Tank[1].x);
        y = Round(Tank[1].y);
        for (0..90) |jj| {
            for (0..76) |ii| {
                PutPixel(@intCast(2 + ii), @intCast(2 + jj), Graphics.color[Terrain.field[@as(usize, @intCast(y)) + jj - 45][@as(usize, @intCast(x)) + ii - 38]]);
            }
        }
    } else {
        noise1 = 2;
    }

    //* Draw Tanks */
    if (Tank[0].deathc <= 0.0) {
        DrawTank(120, 47, Tank[0].rot, 0);

        rect.x = @divTrunc(Graphics.Video_X * 2, Graphics.RES_X);
        rect.y = @divTrunc(Graphics.Video_Y * 2, Graphics.RES_Y);
        rect.w = @divTrunc(Graphics.Video_X * (2 + 76), Graphics.RES_X) - @divTrunc(Graphics.Video_X * 2, Graphics.RES_X);
        rect.h = @divTrunc(Graphics.Video_Y * (2 + 90), Graphics.RES_Y) - @divTrunc(Graphics.Video_Y * 2, Graphics.RES_Y);

        _ = sdl.SDL_SetSurfaceClipRect(Graphics.surface, &rect);
        DrawTank(Round(Tank[0].x) - Round(Tank[1].x) + 40, Round(Tank[0].y) - Round(Tank[1].y) + 47, Tank[0].rot, 0);
        _ = sdl.SDL_SetSurfaceClipRect(Graphics.surface, null);
    }
    if (Tank[1].deathc <= 0.0) {
        DrawTank(40, 47, Tank[1].rot, 1);

        rect.x = @divTrunc(Graphics.Video_X * 82, Graphics.RES_X);
        rect.y = @divTrunc(Graphics.Video_Y * 2, Graphics.RES_Y);
        rect.w = @divTrunc(Graphics.Video_X * (82 + 76), Graphics.RES_X) - @divTrunc(Graphics.Video_X * 82, Graphics.RES_X);
        rect.h = @divTrunc(Graphics.Video_Y * (2 + 90), Graphics.RES_Y) - @divTrunc(Graphics.Video_Y * 2, Graphics.RES_Y);

        _ = sdl.SDL_SetSurfaceClipRect(Graphics.surface, &rect);
        DrawTank(Round(Tank[1].x) - Round(Tank[0].x) + 120, Round(Tank[1].y) - Round(Tank[0].y) + 47, Tank[1].rot, 1);
        _ = sdl.SDL_SetSurfaceClipRect(Graphics.surface, null);
    }

    //* Draw Ammo */
    for (0..2) |j| {
        for (0..128) |i| {
            //* Draw ammo on screen of tank 0 */
            if (Ammo[j][i].isExists) {
                x = Round(Ammo[j][i].x) - Round(Tank[0].x);
                y = Round(Ammo[j][i].y) - Round(Tank[0].y);
                if (x < 38 and x >= -38 and y < 45 and y >= -45)
                    PutPixel(x + 120, y + 47, Graphics.color[12]);

                x = Round(Ammo[j][i].x - rot_xtable[@intFromEnum(Ammo[j][i].rot)]) - Round(Tank[0].x);
                y = Round(Ammo[j][i].y - rot_ytable[@intFromEnum(Ammo[j][i].rot)]) - Round(Tank[0].y);
                if (x < 38 and x >= -38 and y < 45 and y >= -45)
                    PutPixel(x + 120, y + 47, Graphics.color[13]);
            }

            //* Draw ammo on screen of tank 1 */
            if (Ammo[j][i].isExists) {
                x = Round(Ammo[j][i].x) - Round(Tank[1].x);
                y = Round(Ammo[j][i].y) - Round(Tank[1].y);
                if (x < 38 and x >= -38 and y < 45 and y >= -45)
                    PutPixel(x + 40, y + 47, Graphics.color[12]);

                x = Round(Ammo[j][i].x - rot_xtable[@intFromEnum(Ammo[j][i].rot)]) - Round(Tank[1].x);
                y = Round(Ammo[j][i].y - rot_ytable[@intFromEnum(Ammo[j][i].rot)]) - Round(Tank[1].y);
                if (x < 38 and x >= -38 and y < 45 and y >= -45)
                    PutPixel(x + 40, y + 47, Graphics.color[13]);
            }

            //* Draw explosion on screen of tank j */
            if (Expl[i].lifetime > 0.0 and
                Round(Expl[i].x) - Round(Tank[j].x) < 38 and
                Round(Expl[i].x) - Round(Tank[j].x) >= -38 and
                Round(Expl[i].y) - Round(Tank[j].y) < 45 and
                Round(Expl[i].y) - Round(Tank[j].y) >= -45)
            {
                PutPixel(
                    Round(Expl[i].x) - Round(Tank[j].x) + @as(i32, @intCast(120 - 80 * j)),
                    Round(Expl[i].y) - Round(Tank[j].y) + 47,
                    Graphics.color[12],
                );
            }
        }
    }

    //* Draw noise */
    if (noise0 != 0) {
        DrawNoise(82, 2, 76, 90);
        noise0 -= 1;
    }
    if (noise1 != 0) {
        DrawNoise(2, 2, 76, 90);
        noise1 -= 1;
    }
}

// =============================================================================================================================
// private
// =============================================================================================================================

fn Round(a: f64) i32 {
    if (a - floor(a) < 0.5) {
        return @intFromFloat(floor(a));
    }

    return @intFromFloat(ceil(a));
}

fn DrawTank(x: i32, y: i32, rotx: E_DIR, playerx: i32) void {
    const player = 30 + 10 * playerx - 1;

    var rot = rotx;
    var ii: i32 = 0;
    var jj: i32 = 0;

    if (rot == E_DIR.RIGHT or rot == E_DIR.DOWN_RIGHT) {
        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x + ii, y + jj, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    } else if (rot == E_DIR.DOWN) {
        rot = E_DIR.RIGHT;

        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x + jj, y + ii, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    } else if (rot == E_DIR.DOWN_LEFT or rot == E_DIR.LEFT) {
        if (rot == E_DIR.LEFT) {
            rot = E_DIR.RIGHT;
        } else {
            rot = E_DIR.DOWN_RIGHT;
        }

        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x - ii, y + jj, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    } else if (rot == E_DIR.UP_LEFT) {
        rot = E_DIR.DOWN_RIGHT;

        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x - ii, y - jj, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    } else if (rot == E_DIR.UP) {
        rot = E_DIR.RIGHT;

        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x + jj, y - ii, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    } else if (rot == E_DIR.UP_RIGHT) {
        rot = E_DIR.DOWN_RIGHT;

        jj = -3;
        while (jj <= 3) : (jj += 1) {
            ii = -3;
            while (ii <= 3) : (ii += 1) {
                if (tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)] != 0) {
                    PutPixel(x + ii, y - jj, Graphics.color[@intCast(player + tank_spr[@intFromEnum(rot)][@intCast(jj + 3)][@intCast(ii + 3)])]);
                }
            }
        }
    }
}

fn DrawShadow(x: i32, y: i32, w: i32, h: i32) void {
    DrawBox(x, y, w, 1, Graphics.color[5]);
    DrawBox(x, y, 2, h, Graphics.color[5]);

    DrawBox(x + 2, y + h - 1, w - 2, 1, Graphics.color[3]);
    DrawBox(x + w - 2, y, 2, h, Graphics.color[3]);
}

fn DrawLetter(x: i32, y: i32, ch: u8) void {
    var col: u32 = undefined;

    if (ch == 'E') {
        col = Graphics.color[6];
    } else {
        col = Graphics.color[7];
    }

    DrawBox(x, y, 5, 1, col);
    DrawBox(x, y + 2, 5, 1, col);
    DrawBox(x, y + 4, 5, 1, col);

    if (ch == 'E') {
        DrawBox(x, y, 1, 5, col);
    } else {
        DrawBox(x, y, 1, 3, col);
        DrawBox(x + 4, y + 2, 1, 3, col);
    }
}

fn DrawStatusBox(x: i32, y: i32) void {
    DrawBox(x, y, 68, 24, Graphics.color[4]);
    DrawShadow(x, y, 68, 24);

    DrawLetter(x + 4, y + 4, 'E');
    DrawShadow(x + 11, y + 3, 53, 7);
    DrawLetter(x + 4, y + 15, 'S');
    DrawShadow(x + 11, y + 14, 53, 7);
}

fn DrawNoise(x: usize, y: usize, w: usize, h: usize) void {
    var n: i32 = 0;
    DrawBox(@intCast(x), @intCast(y), @intCast(w), @intCast(h), Graphics.color[0]);

    var j: usize = 0;
    while (j < h) : (j += 1) {
        for (0..w) |i| {
            if (n == 0) {
                j += 2 + @as(usize, @intFromFloat(5.0 * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
                n = 90 + @as(i32, @intFromFloat(1400.0 * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
                break;
            } else {
                n -= 1;
            }

            PutPixel(
                @intCast(x + i),
                @intCast(y + j),
                Graphics.color[50 + @as(usize, @intFromFloat(20.0 * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)))],
            );
        }
    }
}

fn NoiseProb(E: f64) bool {
    if (1.0 / (80.0 * E) > 0.50) {
        return @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0) > 0.50;
    }
    return @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0) > 1.0 / (80.0 * E);
}

fn Explosion(x: f64, y: f64, n: usize, t: i32) void {
    var rot: f64 = undefined;

    for (0..n) |_| {
        for (0..128) |j| {
            if (Expl[j].lifetime <= 0.0 and t == 0) {
                Expl[j].x = x;
                Expl[j].y = y;
                rot = 2.0 * PI * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0);
                Expl[j].vx = sin(rot);
                Expl[j].vy = cos(rot);
                Expl[j].lifetime = 0.25;

                break;
            } else if (Expl[j].lifetime <= 0.0) {
                Expl[j].x = x;
                Expl[j].y = y;
                rot = 2.0 * PI * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0);
                Expl[j].vx = 0.5 * sin(rot);
                Expl[j].vy = 0.5 * cos(rot);
                Expl[j].lifetime = 0.7;

                break;
            }
        }
    }
}

fn CTest_Sub(y: i32, x: i32, i: usize) void {
    const y0 = Round(Tank[i].y);
    const x0 = Round(Tank[i].x);

    if (Terrain.field[@intCast(y)][@intCast(x)] > max) {
        max = Terrain.field[@intCast(y)][@intCast(x)];
    }

    if (y >= y0 - 2 and
        y <= y0 + 2 and
        x >= x0 - 2 and
        x <= x0 + 2 and
        Tank[i].deathc <= 0.0)
    {
        max = 50;
    }
}

fn ATest(y: i32, x: i32, ii: usize) u8 {
    var i: usize = ii;
    if (i == 0) {
        i = 1;
    } else if (i == 1) {
        i = 0;
    }

    const y0 = Round(Tank[i].y);
    const x0 = Round(Tank[i].x);

    if (y >= y0 - 2 and
        y <= y0 + 2 and
        x >= x0 - 2 and
        x <= x0 + 2 and
        Tank[i].deathc <= 0.0)
        return (50);

    return (Terrain.field[@intCast(y)][@intCast(x)]);
}

///*  Collision Tester
// *
// *  Returns worst of following:
// *  8,  if there is ground (field = 8 or 9) under the tank position (y,x)
// *  10, if there is rock, wall or a tank (field = 10, 30 or 40
// *       + tankcheck) under the tank position (y,x)
// *  0   otherways
// */
fn CTest(y: i32, x: i32, rot: E_DIR, ii: usize) i32 {
    var i: usize = ii;
    max = 0;

    if (i == 0) {
        i = 1;
    } else if (i == 1) {
        i = 0;
    }

    switch (rot) {
        E_DIR.RIGHT => {
            CTest_Sub(y - 2, x, i);
            CTest_Sub(y - 2, x + 1, i);
            CTest_Sub(y - 2, x + 2, i);

            CTest_Sub(y + 2, x, i);
            CTest_Sub(y + 2, x + 1, i);
            CTest_Sub(y + 2, x + 2, i);

            CTest_Sub(y - 1, x, i);
            CTest_Sub(y - 1, x + 1, i);

            CTest_Sub(y, x, i);
            CTest_Sub(y, x + 1, i);

            CTest_Sub(y + 1, x, i);
            CTest_Sub(y + 1, x + 1, i);
        },
        E_DIR.DOWN_RIGHT => {
            CTest_Sub(y - 1, x - 1, i);
            CTest_Sub(y, x - 1, i);
            CTest_Sub(y + 1, x - 1, i);
            CTest_Sub(y + 2, x - 1, i);

            CTest_Sub(y - 1, x, i);
            CTest_Sub(y, x, i);
            CTest_Sub(y + 1, x, i);
            CTest_Sub(y + 2, x, i);
            CTest_Sub(y + 3, x, i);

            CTest_Sub(y - 1, x + 1, i);
            CTest_Sub(y, x + 1, i);
            CTest_Sub(y + 1, x + 1, i);

            CTest_Sub(y - 1, x + 2, i);
            CTest_Sub(y, x + 2, i);

            CTest_Sub(y, x + 3, i);
        },
        E_DIR.DOWN => {
            CTest_Sub(y, x - 2, i);
            CTest_Sub(y + 1, x - 2, i);
            CTest_Sub(y + 2, x - 2, i);

            CTest_Sub(y, x + 2, i);
            CTest_Sub(y + 1, x + 2, i);
            CTest_Sub(y + 2, x + 2, i);

            CTest_Sub(y, x - 1, i);
            CTest_Sub(y + 1, x - 1, i);

            CTest_Sub(y, x, i);
            CTest_Sub(y + 1, x, i);

            CTest_Sub(y, x + 1, i);
            CTest_Sub(y + 1, x + 1, i);
        },
        E_DIR.DOWN_LEFT => {
            CTest_Sub(y - 1, x - 1, i);
            CTest_Sub(y - 1, x, i);
            CTest_Sub(y - 1, x + 1, i);

            CTest_Sub(y, x - 3, i);
            CTest_Sub(y, x - 2, i);
            CTest_Sub(y, x - 1, i);
            CTest_Sub(y, x, i);
            CTest_Sub(y, x + 1, i);

            CTest_Sub(y + 1, x - 2, i);
            CTest_Sub(y + 1, x - 1, i);
            CTest_Sub(y + 1, x, i);
            CTest_Sub(y + 1, x + 1, i);

            CTest_Sub(y + 2, x - 1, i);
            CTest_Sub(y + 2, x, i);

            CTest_Sub(y + 3, x, i);
        },
        E_DIR.LEFT => {
            CTest_Sub(y - 2, x, i);
            CTest_Sub(y - 2, x - 1, i);
            CTest_Sub(y - 2, x - 2, i);

            CTest_Sub(y + 2, x, i);
            CTest_Sub(y + 2, x - 1, i);
            CTest_Sub(y + 2, x - 2, i);

            CTest_Sub(y - 1, x, i);
            CTest_Sub(y - 1, x - 1, i);

            CTest_Sub(y, x - 0, i);
            CTest_Sub(y, x - 1, i);

            CTest_Sub(y + 1, x, i);
            CTest_Sub(y + 1, x - 1, i);
        },
        E_DIR.UP_LEFT => {
            CTest_Sub(y, x - 3, i);

            CTest_Sub(y, x - 2, i);
            CTest_Sub(y + 1, x - 2, i);

            CTest_Sub(y - 1, x - 1, i);
            CTest_Sub(y, x - 1, i);
            CTest_Sub(y + 1, x - 1, i);

            CTest_Sub(y - 3, x, i);
            CTest_Sub(y - 2, x, i);
            CTest_Sub(y - 1, x, i);
            CTest_Sub(y, x, i);
            CTest_Sub(y + 1, x, i);

            CTest_Sub(y - 2, x + 1, i);
            CTest_Sub(y - 1, x + 1, i);
            CTest_Sub(y, x + 1, i);
            CTest_Sub(y + 1, x + 1, i);
        },
        E_DIR.UP => {
            CTest_Sub(y, x - 2, i);
            CTest_Sub(y - 1, x - 2, i);
            CTest_Sub(y - 2, x - 2, i);

            CTest_Sub(y, x + 2, i);
            CTest_Sub(y - 1, x + 2, i);
            CTest_Sub(y - 2, x + 2, i);

            CTest_Sub(y, x - 1, i);
            CTest_Sub(y - 1, x - 1, i);

            CTest_Sub(y, x, i);
            CTest_Sub(y - 1, x, i);

            CTest_Sub(y, x + 1, i);
            CTest_Sub(y - 1, x + 1, i);
        },
        E_DIR.UP_RIGHT => {
            CTest_Sub(y - 3, x, i);

            CTest_Sub(y - 2, x, i);
            CTest_Sub(y - 2, x + 1, i);

            CTest_Sub(y - 1, x - 1, i);
            CTest_Sub(y - 1, x, i);
            CTest_Sub(y - 1, x + 1, i);
            CTest_Sub(y - 1, x + 2, i);

            CTest_Sub(y, x - 1, i);
            CTest_Sub(y, x, i);
            CTest_Sub(y, x + 1, i);
            CTest_Sub(y, x + 2, i);
            CTest_Sub(y, x + 3, i);

            CTest_Sub(y + 1, x - 1, i);
            CTest_Sub(y + 1, x, i);
            CTest_Sub(y + 1, x + 1, i);
        },
    }

    return max;
}

//* Clear earth under the tank */
fn Tank_Tunnel(y: usize, x: usize, rot: E_DIR) void {
    switch (rot) {
        E_DIR.RIGHT => {
            TUNNEL_MACRO(&Terrain.field[y - 2][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y - 2][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y - 2][x]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);

            TUNNEL_MACRO(&Terrain.field[y][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x]);

            TUNNEL_MACRO(&Terrain.field[y + 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
        },
        E_DIR.DOWN_RIGHT => {
            TUNNEL_MACRO(&Terrain.field[y][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 2]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);
            TUNNEL_MACRO(&Terrain.field[y][x]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x + 2]);
        },
        E_DIR.DOWN => {
            TUNNEL_MACRO(&Terrain.field[y - 2][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y][x - 2]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y][x + 2]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);
            TUNNEL_MACRO(&Terrain.field[y][x]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);
        },
        E_DIR.DOWN_LEFT => {
            TUNNEL_MACRO(&Terrain.field[y - 2][x]);
            TUNNEL_MACRO(&Terrain.field[y - 2][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 1]);

            TUNNEL_MACRO(&Terrain.field[y][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x + 2]);

            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 2]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x + 1]);
        },
        E_DIR.LEFT => {
            TUNNEL_MACRO(&Terrain.field[y - 2][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y - 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y - 2][x]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);

            TUNNEL_MACRO(&Terrain.field[y][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x]);

            TUNNEL_MACRO(&Terrain.field[y + 1][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
        },
        E_DIR.UP_LEFT => {
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 2]);

            TUNNEL_MACRO(&Terrain.field[y][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x]);
            TUNNEL_MACRO(&Terrain.field[y][x]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x]);

            TUNNEL_MACRO(&Terrain.field[y - 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 1]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y][x + 2]);
        },
        E_DIR.UP => {
            TUNNEL_MACRO(&Terrain.field[y + 2][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y][x - 2]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 2]);
            TUNNEL_MACRO(&Terrain.field[y][x + 2]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
            TUNNEL_MACRO(&Terrain.field[y][x]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);
        },
        E_DIR.UP_RIGHT => {
            TUNNEL_MACRO(&Terrain.field[y - 2][x - 1]);

            TUNNEL_MACRO(&Terrain.field[y - 1][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y - 1][x]);

            TUNNEL_MACRO(&Terrain.field[y][x - 2]);
            TUNNEL_MACRO(&Terrain.field[y][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y][x]);
            TUNNEL_MACRO(&Terrain.field[y][x + 1]);

            TUNNEL_MACRO(&Terrain.field[y + 1][x - 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 1]);
            TUNNEL_MACRO(&Terrain.field[y + 1][x + 2]);

            TUNNEL_MACRO(&Terrain.field[y + 2][x]);
            TUNNEL_MACRO(&Terrain.field[y + 2][x + 1]);
        },
    }
}

fn HandleKeys() void {
    for (0..2) |i| {
        Tank[i].oldrot = Tank[i].rot;
        Tank[i].isMove = false;
        Tank[i].isFire = false;

        if (Tank[i].mode == Types.E_PLAYER_MODE.TANK_AI) {
            Handle_AI(i);
            continue;
        }

        //* Get direction of movement */
        if (Key.key_pl[i].down != 0 and Key.key_pl[i].right != 0) {
            Tank[i].rot = E_DIR.DOWN_RIGHT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].down != 0 and Key.key_pl[i].left != 0) {
            Tank[i].rot = E_DIR.DOWN_LEFT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].up != 0 and Key.key_pl[i].right != 0) {
            Tank[i].rot = E_DIR.UP_RIGHT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].up != 0 and Key.key_pl[i].left != 0) {
            Tank[i].rot = E_DIR.UP_LEFT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].right != 0) {
            Tank[i].rot = E_DIR.RIGHT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].down != 0) {
            Tank[i].rot = E_DIR.DOWN;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].left != 0) {
            Tank[i].rot = E_DIR.LEFT;
            Tank[i].isMove = true;
        } else if (Key.key_pl[i].up != 0) {
            Tank[i].rot = E_DIR.UP;
            Tank[i].isMove = true;
        }
        if (Key.key_pl[i].fire != 0) {
            Tank[i].isFire = true;
        }
    }
}

pub fn HandleActions(dt: f64) void {
    var step: f64 = undefined;
    var dx: f64 = 0.0;
    var dy: f64 = 0.0;
    var val: i32 = 0;

    HandleKeys();

    for (0..2) |i| {
        //* Align when turning */
        if (Tank[i].oldrot != Tank[i].rot) {
            Tank[i].y = @floatFromInt(Round(Tank[i].y));
            Tank[i].x = @floatFromInt(Round(Tank[i].x));
        }

        //* Make movement */
        if (Tank[i].isMove and Tank[i].deathc <= 0.0) {
            if (!Tank[i].isTunneling or Tank[i].isFire) {
                step = game.TANK_SPEED * dt;
            } else {
                step = game.DIG_SPEED * dt;
            }

            var k: usize = 0;
            while (0.5 * @as(f32, @floatFromInt(k)) < step) : (k += 1) {
                const fk = @as(f32, @floatFromInt(k));
                val = CTest(
                    Round(Tank[i].y + 0.5 * fk * rot_ytable[@intFromEnum(Tank[i].rot)]),
                    Round(Tank[i].x + 0.5 * fk * rot_xtable[@intFromEnum(Tank[i].rot)]),
                    Tank[i].rot,
                    i,
                );
                if (val != 0) {
                    Tank[i].isTunneling = true;
                    if (!Tank[i].isFire) {
                        step = game.DIG_SPEED * dt;
                    }
                }

                if (val == 10 or val == 30 or val == 40 or val == 50) {
                    break;
                }
            }

            if (val == 10 or val == 30 or val == 40 or val == 50) //* Rock, wall or a tank */
            {
                if (k != 0) {
                    k -= 1;
                }
                Tank[i].y = @floatFromInt(Round(Tank[i].y + 0.5 * @as(f64, @floatFromInt(k)) * rot_ytable[@intFromEnum(Tank[i].rot)]));
                Tank[i].x = @floatFromInt(Round(Tank[i].x + 0.5 * @as(f64, @floatFromInt(k)) * rot_xtable[@intFromEnum(Tank[i].rot)]));
            } else {
                Tank[i].y += rot_ytable[@intFromEnum(Tank[i].rot)] * step;
                Tank[i].x += rot_xtable[@intFromEnum(Tank[i].rot)] * step;
            }

            if (CTest(Round(Tank[i].y), Round(Tank[i].x), Tank[i].rot, i) == 0) {
                Tank[i].isTunneling = false;
            }

            Tank_Tunnel(@intCast(Round(Tank[i].y)), @intCast(Round(Tank[i].x)), Tank[i].rot);
        }

        //* Make new ammo */
        if (Tank[i].isFire and Time_Now() - Tank[i].last > game.FIRE_DELAY and Tank[i].deathc <= 0.0) {
            for (0..128) |j| {
                if (!Ammo[i][j].isExists) {
                    Tank[i].last = Time_Now();
                    Tank[i].Energy -= game.ENERGY_SHOT;
                    Ammo[i][j].isExists = true;
                    Ammo[i][j].rot = Tank[i].rot;
                    Ammo[i][j].x = @floatFromInt(Round(Tank[i].x + rot_xtable[@intFromEnum(Ammo[i][j].rot)]));
                    Ammo[i][j].y = @floatFromInt(Round(Tank[i].y + rot_ytable[@intFromEnum(Ammo[i][j].rot)]));

                    break;
                }
            }
        }

        //* Ammo collisions */
        for (0..128) |j| {
            if (Ammo[i][j].isExists) {
                dx = rot_xtable[@intFromEnum(Ammo[i][j].rot)] * dt * game.AMMO_SPEED;
                dy = rot_ytable[@intFromEnum(Ammo[i][j].rot)] * dt * game.AMMO_SPEED;

                var k: i32 = 0;
                while (0.5 * @as(f64, @floatFromInt(k)) < dt * game.AMMO_SPEED) : (k += 1) {
                    val = ATest(
                        Round(Ammo[i][j].y + 0.5 * @as(f64, @floatFromInt(k)) * rot_ytable[@intFromEnum(Ammo[i][j].rot)]),
                        Round(Ammo[i][j].x + 0.5 * @as(f64, @floatFromInt(k)) * rot_xtable[@intFromEnum(Ammo[i][j].rot)]),
                        i,
                    );
                    if (val != 0)
                        break;
                }

                const fk: f64 = @floatFromInt(k);
                if (val == 8 or val == 9) {
                    Terrain.field[
                        @intCast(Round(Ammo[i][j].y + 0.5 * fk * rot_ytable[@intFromEnum(Ammo[i][j].rot)]))
                    ][
                        @intCast(Round(Ammo[i][j].x + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)]))
                    ] = 0;
                    Ammo[i][j].isExists = false;
                    Explosion(
                        @floatFromInt(Round(Ammo[i][j].x + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        @floatFromInt(Round(Ammo[i][j].y + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        10,
                        0,
                    );
                } else if (val == 10 or val == 30 or val == 40) {
                    k -= 1;
                    Ammo[i][j].isExists = false;
                    Explosion(
                        @floatFromInt(Round(Ammo[i][j].x + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        @floatFromInt(Round(Ammo[i][j].y + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        10,
                        0,
                    );
                } else if (val == 50) { //* Tank hit  */
                    Ammo[i][j].isExists = false;
                    if (i == 0) {
                        Tank[1].Shields -= game.SHOT_DAMAGE;
                    } else if (i == 1) {
                        Tank[0].Shields -= game.SHOT_DAMAGE;
                    }

                    Explosion(
                        @floatFromInt(Round(Ammo[i][j].x + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        @floatFromInt(Round(Ammo[i][j].y + 0.5 * fk * rot_xtable[@intFromEnum(Ammo[i][j].rot)])),
                        10,
                        0,
                    );
                } else {
                    Ammo[i][j].y += dy;
                    Ammo[i][j].x += dx;
                }
            }
        }

        //* Use energy */
        Tank[i].Energy -= game.ENERGY_DROP * dt;

        //* Rebirth */
        if (Tank[i].deathc > 0.0) {
            Tank[i].deathc -= dt;
            if (Tank[i].deathc <= 0.0) {
                Tank[i].rot = E_DIR.UP;
                Tank[i].isTunneling = true;
                Tank[i].x = @floatFromInt(Tank[i].basex);
                Tank[i].y = @floatFromInt(Tank[i].basey);
                Tank[i].Energy = 1.0;
                Tank[i].Shields = 1.0;
                Tank[i].deathc = 0.0;

                if (CTest(Round(Tank[i].y), Round(Tank[i].x), Tank[i].rot, i) == 50) {
                    if (i == 0) {
                        Tank[1].Shields = 0.0;
                    } else if (i == 1) {
                        Tank[0].Shields = 0.0;
                    }
                }
            }
        }

        //* Death */
        if (Tank[i].Shields <= 0.0 and Tank[i].deathc <= 0.0) {
            Tank[i].Shields = 0.0;
            Explosion(Tank[i].x, Tank[i].y, 30, 1);
            Tank[i].deathc = 4.0;
            Tank[i].deaths += 1;
        } else if (Tank[i].Energy <= 0.0 and Tank[i].deathc <= 0.0) {
            Tank[i].Energy = 0.0;
            Explosion(Tank[i].x, Tank[i].y, 30, 1);
            Tank[i].deathc = 4.0;
            Tank[i].deaths += 1;
        }

        //* Repair Shields and Energy */
        if (Tank[i].deathc <= 0.0 and
            Tank[i].x <= @as(f64, @floatFromInt(Tank[i].basex + game.BASE_SIZEX)) and
            Tank[i].x >= @as(f64, @floatFromInt(Tank[i].basex - game.BASE_SIZEX)) and
            Tank[i].y <= @as(f64, @floatFromInt(Tank[i].basey + game.BASE_SIZEY)) and
            Tank[i].y >= @as(f64, @floatFromInt(Tank[i].basey - game.BASE_SIZEY)))
        {
            Tank[i].Shields += game.REPAIR_SPEED_SHIELD * dt;
            Tank[i].Energy += game.REPAIR_SPEED_ENERGY * dt;

            if (Tank[i].Shields > 1.0)
                Tank[i].Shields = 1.0;
            if (Tank[i].Energy > 1.0)
                Tank[i].Energy = 1.0;
        }

        var jj: usize = undefined;
        if (i == 0) {
            jj = 1;
        } else {
            jj = 0;
        }

        if (Tank[i].deathc <= 0.0 and
            Tank[i].x <= @as(f64, @floatFromInt(Tank[jj].basex + game.BASE_SIZEX)) and
            Tank[i].x >= @as(f64, @floatFromInt(Tank[jj].basex - game.BASE_SIZEX)) and
            Tank[i].y <= @as(f64, @floatFromInt(Tank[jj].basey + game.BASE_SIZEY)) and
            Tank[i].y >= @as(f64, @floatFromInt(Tank[jj].basey - game.BASE_SIZEY)))
        {
            Tank[i].Energy += game.REPAIR_SPEED2 * dt;

            if (Tank[i].Energy > 1.0)
                Tank[i].Energy = 1.0;
        }
    }

    //* Explosion collisions */
    for (0..128) |i| {
        if (Expl[i].lifetime > 0.0) {
            dx = Expl[i].vx * dt * game.PART_SPEED;
            dy = Expl[i].vy * dt * game.PART_SPEED;

            var k: usize = 0;
            while (0.5 * @as(f64, @floatFromInt(k)) < dt * game.PART_SPEED) : (k += 1) {
                val = Terrain.field[
                    @intCast(Round(Expl[i].y + 0.5 * @as(f64, @floatFromInt(k)) * Expl[i].vy))
                ][
                    @intCast(Round(Expl[i].x + 0.5 * @as(f64, @floatFromInt(k)) * Expl[i].vx))
                ];
                if (val != 0)
                    break;
            }

            const fk: f64 = @floatFromInt(k);
            if (val == 8 or val == 9) {
                Terrain.field[
                    @intCast(Round(Expl[i].y + 0.5 * fk * Expl[i].vy))
                ][
                    @intCast(Round(Expl[i].x + 0.5 * fk * Expl[i].vx))
                ] = 0;
                Expl[i].lifetime = 0.0;
            } else if (val == 10 or val == 30 or val == 40) {
                Expl[i].lifetime = 0.0;
            } else {
                Expl[i].y += dy;
                Expl[i].x += dx;
            }

            Expl[i].lifetime -= dt;
        }
    }
}

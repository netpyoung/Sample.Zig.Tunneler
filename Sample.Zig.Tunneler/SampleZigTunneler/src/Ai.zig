const std = @import("std");
const Terrain = @import("Terrain.zig");
const Timer = @import("Timer.zig");
const game = @import("Game.zig");
const Tunneler = @import("Tunneler.zig");
const Types = @import("Types.zig");

const print = std.debug.print;

const atan2 = std.math.atan2;
const sin = std.math.sin;
const cos = std.math.cos;
const sqrt = std.math.sqrt;
const floor = std.math.floor;
const ceil = std.math.ceil;

const Time_Now = Timer.Time_Now;
const PI = std.math.pi;
const E_DIR = Types.E_DIR;

var last_turn: [2]u64 = undefined;
var evade: [2]i32 = undefined;
var evade_time: [2]u64 = undefined;

fn Round(a: f64) i32 {
    if (a - floor(a) < 0.5) {
        return @intFromFloat(floor(a));
    }
    return @intFromFloat(ceil(a));
}

pub fn Init_AI() void {
    last_turn[0] = 0;
    last_turn[1] = 0;
    evade_time[0] = 0;
    evade_time[1] = 0;
    evade[0] = 0;
    evade[1] = 0;
}

///*  Handle AI
// *
// *  Function should set tanks rot, move and fire
// *  using x and y coordinates of tanks, field and bases
// *  and the Energy and Shields
// */
pub fn Handle_AI(i: usize) void {
    var enemy: usize = undefined;
    var targetx: i32 = undefined;
    var targety: i32 = undefined;
    var dx: f64 = undefined;
    var dy: f64 = undefined;
    var t: f64 = undefined; //* Direction of movement in rad [-PI,PI] */

    if (i == 0) {
        enemy = 1;
    } else {
        enemy = 0;
    }

    targetx = @intFromFloat(Tunneler.Tank[enemy].x);
    targety = @intFromFloat(Tunneler.Tank[enemy].y);

    //* Get direction */
    dx = @as(f64, @floatFromInt(targetx)) - Tunneler.Tank[i].x;
    dy = @as(f64, @floatFromInt(targety)) - Tunneler.Tank[i].y;
    t = -1.0 * atan2(dy, dx);
    dx = cos(t);
    dy = sin(t);

    if (evade[i] == 1) {
        if (PathClear(@intFromFloat(Tunneler.Tank[i].x), @intFromFloat(Tunneler.Tank[i].y), dx, dy)) {
            print("Break evade -------------------\n", .{});
            evade[i] = 0;
        } else {
            t += PI / 2.0;
            if (evade_time[i] + 1500 < Time_Now()) {
                evade[i] = 0;
            }
        }
    } else if (PathClear(@intFromFloat(Tunneler.Tank[i].x), @intFromFloat(Tunneler.Tank[i].y), dx, dy)) {
        print("t = {d}\t ok!\n", .{t});
    } else if (@as(i32, @intFromFloat(Tunneler.Tank[i].x)) <= Tunneler.Tank[i].basex + game.BASE_SIZEX + 5 and
        @as(i32, @intFromFloat(Tunneler.Tank[i].x)) >= Tunneler.Tank[i].basex - game.BASE_SIZEX - 5 and
        @as(i32, @intFromFloat(Tunneler.Tank[i].y)) <= Tunneler.Tank[i].basey + game.BASE_SIZEY + 5 and
        @as(i32, @intFromFloat(Tunneler.Tank[i].y)) >= Tunneler.Tank[i].basey - game.BASE_SIZEY - 5)
    {
        print("out of base!\n", .{});

        if (t >= 0.0) {
            t = PI / 2.0;
        } else {
            t = -PI / 2.0;
        }
    } else {
        //* Evasive action! */
        print("start evade!\n", .{});
        evade[i] = 1;
        evade_time[i] = Timer.Time_Now();
    }

    while (t > PI) {
        t -= 2.0 * PI;
    }
    while (t < -PI) {
        t += 2.0 * PI;
    }

    if (Time_Now() > last_turn[i] + 300) {
        if (t >= -PI / 8.0 and t < PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.RIGHT;
        } else if (t >= -3.0 * PI / 8.0 and t < -PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.DOWN_RIGHT;
        } else if (t >= -5.0 * PI / 8.0 and t < -3.0 * PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.DOWN;
        } else if (t >= -7.0 * PI / 8.0 and t < -5.0 * PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.DOWN_LEFT;
        } else if (t < -7.0 * PI / 8.0 or t >= 7.0 * PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.LEFT;
        } else if (t >= 5.0 * PI / 8.0 and t < 7.0 * PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.UP_LEFT;
        } else if (t >= 3.0 * PI / 8.0 and t < 5.0 * PI / 8.0) {
            Tunneler.Tank[i].rot = E_DIR.UP;
        } else {
            Tunneler.Tank[i].rot = E_DIR.UP_RIGHT;
        }

        if (Tunneler.Tank[i].rot != Tunneler.Tank[i].oldrot) {
            last_turn[i] = Time_Now();
        }
    }

    Tunneler.Tank[i].isMove = true;

    //* Fire? */
    dx = @as(f64, @floatFromInt(targetx)) - Tunneler.Tank[i].x;
    dy = @as(f64, @floatFromInt(targety)) - Tunneler.Tank[i].y;
    if (sqrt(dx * dx + dy * dy) < 100) {
        Tunneler.Tank[i].isFire = true;
    }
}

// =============================================================================================================================
// private
// =============================================================================================================================

fn PathClear(x: i32, y: i32, dx: f64, dy: f64) bool {
    var x0: usize = undefined;
    var y0: usize = undefined;
    var k: usize = undefined;
    var r: f64 = undefined;

    r = 0.0;
    while (r < 100.0) {
        x0 = @intCast(Round(@as(f64, @floatFromInt(x)) + r * dx));
        y0 = @intCast(Round(@as(f64, @floatFromInt(y)) + r * dy));

        k = 0;
        if (Terrain.field[y0][x0] > k) {
            k = Terrain.field[y0][x0];
        }
        if (Terrain.field[y0 + 1][x0 + 1] > k) {
            k = Terrain.field[y0 + 1][x0 + 1];
        }
        if (Terrain.field[y0 - 1][x0 + 1] > k) {
            k = Terrain.field[y0 - 1][x0 + 1];
        }
        if (Terrain.field[y0 - 1][x0 - 1] > k) {
            k = Terrain.field[y0 - 1][x0 - 1];
        }
        if (Terrain.field[y0 + 1][x0 - 1] > k) {
            k = Terrain.field[y0 + 1][x0 - 1];
        }

        if (k >= 10) {
            return false;
        }

        r += 1.0;
    }

    return true;
}

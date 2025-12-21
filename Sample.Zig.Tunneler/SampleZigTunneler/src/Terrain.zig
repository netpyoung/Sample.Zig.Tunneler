const std = @import("std");
const sdl = @import("sdl.zig").sdl;
const game = @import("Game.zig");
const Tunneler = @import("Tunneler.zig");
const assert = std.debug.assert;

// TODO(pyoung): use zig rand
const RAND_MAX = 0x7fff;
extern fn rand() i32;

pub var field: [game.FIELD_SIZEY][game.FIELD_SIZEX]u8 = undefined;

const Wall = struct {
    x: i32,
    y: i32,
    next: ?*Wall,
};

pub fn Init_Field() void {
    var i: i32 = undefined;
    var j: i32 = undefined;
    var ii2: i32 = undefined;
    var jj2: i32 = undefined;

    var start: *Wall = undefined;
    var p: ?*Wall = undefined;

    //* Generate background sand */
    for (0..game.FIELD_SIZEY) |y| {
        for (0..game.FIELD_SIZEX) |x| {
            field[y][x] = 8 + @as(u8, @intFromFloat(2.0 * @as(f32, @floatFromInt(rand())) / (RAND_MAX + 1.0)));
        }
    }

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator: std.mem.Allocator = arena.allocator();

    //* Generate walls */
    j = 0;
    while (j < game.FIELD_SIZEX) : (j += 64) {
        start = Generate_Wall(allocator);

        p = start;
        while (p != null) {
            if (j + p.?.x == game.FIELD_SIZEX)
                break;

            for (0..@intCast(100 + p.?.y)) |y| {
                field[y][@intCast(j + p.?.x)] = 10;
            }

            p = p.?.next;
        }

        Free_Wall(allocator, start);
    }

    j = 0;
    while (j < game.FIELD_SIZEX) : (j += 64) {
        start = Generate_Wall(allocator);

        p = start;
        while (p != null) {
            if (j + p.?.x == game.FIELD_SIZEX)
                break;

            for (0..@intCast(100 + p.?.y)) |y| {
                field[game.FIELD_SIZEY - y - 1][@intCast(j + p.?.x)] = 10;
            }

            p = p.?.next;
        }

        Free_Wall(allocator, start);
    }

    j = 0;
    while (j < game.FIELD_SIZEY) : (j += 64) {
        start = Generate_Wall(allocator);

        p = start;
        while (p != null) : (p = p.?.next) {
            const pp = p orelse unreachable;
            if (j + pp.x == game.FIELD_SIZEY) {
                break;
            }

            for (0..@as(usize, @intCast(100 + pp.y))) |ii| {
                field[@as(usize, @intCast(j + pp.x))][ii] = 10;
            }
        }

        Free_Wall(allocator, start);
    }

    j = 0;
    while (j < game.FIELD_SIZEY) : (j += 64) {
        start = Generate_Wall(allocator);

        p = start;
        while (p != null) {
            if (j + p.?.x == game.FIELD_SIZEY)
                break;

            for (0..@as(usize, @intCast(100 + p.?.y))) |ii| {
                field[@as(usize, @intCast(j + p.?.x))][game.FIELD_SIZEX - ii - 1] = 10;
            }
            p = p.?.next;
        }

        Free_Wall(allocator, start);
    }

    for (0..50) |y| {
        for (0..game.FIELD_SIZEX) |x| {
            field[y][x] = 10;
        }
    }

    for (game.FIELD_SIZEY - 50..game.FIELD_SIZEY) |y| {
        for (0..game.FIELD_SIZEX) |x| {
            field[y][x] = 10;
        }
    }

    for (0..game.FIELD_SIZEY) |y| {
        for (0..50) |x| {
            field[y][x] = 10;
        }
    }

    for (0..game.FIELD_SIZEY) |y| {
        for (game.FIELD_SIZEX - 50..game.FIELD_SIZEX) |x| {
            field[y][x] = 10;
        }
    }

    //* Set base positions */
    i = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEY)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
    j = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEX)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));

    Init_Base(i, j, 0);

    ii2 = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEY)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
    jj2 = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEX)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
    while ((i - ii2) * (i - ii2) + (j - jj2) * (j - jj2) < 150 * 150) {
        ii2 = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEY)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
        jj2 = 150 + @as(i32, @intFromFloat((@as(f64, @floatFromInt(game.FIELD_SIZEX)) - 300.0) * @as(f64, @floatFromInt(rand())) / (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
    }

    Init_Base(ii2, jj2, 1);
}

// =============================================================================================================================
// private
// =============================================================================================================================

fn Init_Base(y: i32, x: i32, n: usize) void {
    Tunneler.Tank[n].basex = x;
    Tunneler.Tank[n].basey = y;

    var i: i32 = undefined;
    var j: i32 = undefined;

    i = -game.BASE_SIZEX;
    while (i < game.BASE_SIZEX) : (i += 1) {
        j = -game.BASE_SIZEY;
        while (j < game.BASE_SIZEY) : (j += 1) {
            field[@intCast(j + y)][@intCast(i + x)] = 0;
        }
    }

    i = -game.BASE_SIZEY;
    while (i < game.BASE_SIZEY) : (i += 1) {
        field[@intCast(i + y)][@intCast(-game.BASE_SIZEX + x)] = @intCast(30 + 10 * n);
        field[@intCast(i + y)][@intCast(game.BASE_SIZEX - 1 + x)] = @intCast(30 + 10 * n);
    }

    j = -game.BASE_SIZEX;
    while (i < -game.BASE_DOORSIZE + 1) : (j += 1) {
        field[@intCast(-game.BASE_SIZEY + y)][@intCast(j + x)] = @intCast(30 + 10 * n);
        field[@intCast(game.BASE_SIZEY - 1 + y)][@intCast(j + x)] = @intCast(30 + 10 * n);
    }
    j = game.BASE_DOORSIZE;
    while (i < game.BASE_SIZEX) : (j += 1) {
        field[@intCast(-game.BASE_SIZEY + y)][@intCast(j + x)] = @intCast(30 + 10 * n);
        field[@intCast(game.BASE_SIZEY - 1 + y)][@intCast(j + x)] = @intCast(30 + 10 * n);
    }
}

fn Generate_Wall(allocator: std.mem.Allocator) *Wall {
    var x: i32 = undefined;
    var skip: i32 = undefined;
    var range: i32 = undefined;
    var start: *Wall = undefined;
    var p: *Wall = undefined;
    var newp: *Wall = undefined;

    skip = 64;
    range = 40;

    start = allocator.create(Wall) catch unreachable;
    start.x = 0;
    start.y = 0;
    start.next = allocator.create(Wall) catch unreachable;
    p = start.next.?;
    p.x = skip;
    p.y = 0;
    p.next = null;

    while (skip > 1) {
        x = @divTrunc(skip, 2);
        p = start;

        while (true) {
            while (p.next != null and p.next.?.x < x) {
                p = p.next.?;
            }

            if (p.next == null) {
                break;
            }

            newp = allocator.create(Wall) catch unreachable;
            newp.x = x;
            newp.y = @divTrunc(p.y + p.next.?.y, 2) -
                range +
                @as(i32, @intFromFloat(2.0 *
                    @as(f64, @floatFromInt(range)) * @as(f64, @floatFromInt(rand())) /
                    (@as(f64, @floatFromInt(RAND_MAX)) + 1.0)));
            newp.next = p.next;
            p.next = newp;
            p = newp.next.?;

            x += skip;
        }

        skip = @divTrunc(skip, 2);
        range = @divTrunc(range, 2);
    }

    return (start);
}

fn Free_Wall(allocator: std.mem.Allocator, wall: ?*Wall) void {
    if (wall.?.next != null) {
        Free_Wall(allocator, wall.?.next);
    }

    allocator.destroy(wall.?);
}

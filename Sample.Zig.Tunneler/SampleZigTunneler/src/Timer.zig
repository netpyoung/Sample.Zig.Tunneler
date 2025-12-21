const sdl = @import("sdl.zig").sdl;

const InternalTimer = struct {
    now: u64,
    old: u64,
};

var GlobalTimer = InternalTimer{ .now = 0, .old = 0 };

pub fn Time_Now() u64 {
    return GlobalTimer.now;
}

pub fn Init_Timer() void {
    GlobalTimer.now = sdl.SDL_GetTicks();
}

pub fn DoTimer() f64 {
    GlobalTimer.old = GlobalTimer.now;
    GlobalTimer.now = sdl.SDL_GetTicks();

    const diff: f64 = @floatFromInt(GlobalTimer.now - GlobalTimer.old);
    return (diff / 1000.0);
}

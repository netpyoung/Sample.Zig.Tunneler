pub const VERSION = "0.0.3";

pub const FIELD_SIZEX = 800;
pub const FIELD_SIZEY = 600;

pub const TANK_SPEED = 30.0;
pub const FIRE_DELAY = 150;
pub const AMMO_SPEED = 60.0;
pub const PART_SPEED = 60.0;
pub const DIG_SPEED = 10.0;
pub const BASE_SIZEX = 16;
pub const BASE_SIZEY = 19;
pub const BASE_DOORSIZE = 5;

pub const SHOT_DAMAGE = 0.1;
pub const REPAIR_SPEED_ENERGY = 0.125;
pub const REPAIR_SPEED_SHIELD = 0.0625;
pub const ENERGY_DROP = 0.003;
pub const ENERGY_SHOT = 0.008;

pub const TANK_SPRITE = [2][7][7]i32{ .{
    .{ 0, 0, 0, 0, 0, 0, 0 },
    .{ 2, 2, 2, 2, 2, 2, 0 },
    .{ 0, 1, 1, 1, 1, 0, 0 },
    .{ 0, 1, 1, 3, 3, 3, 3 },
    .{ 0, 1, 1, 1, 1, 0, 0 },
    .{ 2, 2, 2, 2, 2, 2, 0 },
    .{ 0, 0, 0, 0, 0, 0, 0 },
}, .{
    .{ 0, 0, 0, 2, 0, 0, 0 },
    .{ 0, 0, 0, 1, 2, 0, 0 },
    .{ 0, 0, 1, 1, 1, 2, 0 },
    .{ 2, 1, 1, 3, 1, 1, 2 },
    .{ 0, 2, 1, 1, 3, 0, 0 },
    .{ 0, 0, 2, 1, 0, 3, 0 },
    .{ 0, 0, 0, 2, 0, 0, 0 },
} };

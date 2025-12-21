pub const E_PLAYER_MODE = enum(i32) {
    TANK_NORMAL = 0,
    TANK_AI = 1,
};

pub const player_keys_t = struct {
    up: u32,
    down: u32,
    left: u32,
    right: u32,
    fire: u32,
};

// TODO(pyoung): bool player_keys_t - for key_pl

pub const E_DIR = enum(usize) {
    RIGHT = 0,
    DOWN_RIGHT = 1,
    DOWN = 2,
    DOWN_LEFT = 3,
    LEFT = 4,
    UP_LEFT = 5,
    UP = 6,
    UP_RIGHT = 7,
};

pub const TANK = struct {
    basex: i32,
    basey: i32,
    x: f64,
    y: f64,

    mode: E_PLAYER_MODE,
    rot: E_DIR,
    oldrot: E_DIR,

    isTunneling: bool,
    isMove: bool,
    isFire: bool,

    Energy: f64,
    Shields: f64,
    deathc: f64,
    deaths: i32,
    last: u64,
};

pub const AMMO = struct {
    isExists: bool,
    rot: E_DIR,
    x: f64,
    y: f64,
};

pub const EXPL = struct {
    lifetime: f64,
    x: f64,
    y: f64,
    vx: f64,
    vy: f64,
};

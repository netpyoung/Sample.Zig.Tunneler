const sdl = @import("sdl.zig").sdl;

const player_keys_t = @import("Types.zig").player_keys_t;

pub var key_pl: [2]player_keys_t = undefined;
pub var sym_pl: [2]player_keys_t = .{
    .{
        .up = sdl.SDLK_UP,
        .down = sdl.SDLK_DOWN,
        .left = sdl.SDLK_LEFT,
        .right = sdl.SDLK_RIGHT,
        .fire = sdl.SDLK_RSHIFT,
    },
    .{
        .up = sdl.SDLK_W,
        .down = sdl.SDLK_S,
        .left = sdl.SDLK_A,
        .right = sdl.SDLK_D,
        .fire = sdl.SDLK_LCTRL,
    },
};

pub var is_key_quit: bool = false;
pub var is_key_menu_enter: bool = false;
pub var is_key_menu_up: bool = false;
pub var is_key_menu_down: bool = false;
pub var is_key_menu_left: bool = false;
pub var is_key_menu_right: bool = false;

pub fn HandleKeyEvent(key: *sdl.SDL_KeyboardEvent) void {
    const isKeyDown = key.type == sdl.SDL_EVENT_KEY_DOWN;
    const isKeyUp = key.type == sdl.SDL_EVENT_KEY_UP;
    if (!(isKeyDown or isKeyUp)) {
        return;
    }
    const b: u32 = if (isKeyDown) 1 else 0;

    //* Player keys */
    for (0..2) |i| {
        if (key.key == sym_pl[i].up) {
            key_pl[i].up = b;
        } else if (key.key == sym_pl[i].down) {
            key_pl[i].down = b;
        } else if (key.key == sym_pl[i].left) {
            key_pl[i].left = b;
        } else if (key.key == sym_pl[i].right) {
            key_pl[i].right = b;
        } else if (key.key == sym_pl[i].fire) {
            key_pl[i].fire = b;
        }
    }

    //* Menu keys */
    switch (key.key) {
        sdl.SDLK_ESCAPE => {
            is_key_quit = isKeyDown;
        },
        sdl.SDLK_UP => {
            is_key_menu_up = isKeyDown;
        },
        sdl.SDLK_DOWN => {
            is_key_menu_down = isKeyDown;
        },
        sdl.SDLK_LEFT => {
            is_key_menu_left = isKeyDown;
        },
        sdl.SDLK_RIGHT => {
            is_key_menu_right = isKeyDown;
        },
        sdl.SDLK_RETURN => {
            is_key_menu_enter = isKeyDown;
        },
        else => {},
    }
}

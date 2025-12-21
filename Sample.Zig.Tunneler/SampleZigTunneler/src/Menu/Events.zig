const std = @import("std");
const sdl = @import("../sdl.zig").sdl;
const Key = @import("../Key.zig");
const Graphics = @import("../Graphics.zig");

pub fn HandleEvents() bool {
    var event: sdl.SDL_Event = undefined;

    while (sdl.SDL_PollEvent(&event)) {
        switch (event.type) {
            sdl.SDL_EVENT_KEY_DOWN => {
                Key.HandleKeyEvent(&event.key);
            },
            sdl.SDL_EVENT_KEY_UP => {
                Key.HandleKeyEvent(&event.key);
            },
            sdl.SDL_EVENT_WINDOW_RESIZED => {
                Graphics.surface = sdl.SDL_GetWindowSurface(Graphics.screen);
            },
            sdl.SDL_EVENT_QUIT => {
                std.process.exit(0);
                return false;
            },
            else => {},
        }
    }
    return true;
}

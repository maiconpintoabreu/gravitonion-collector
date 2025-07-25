const rl = @import("raylib");
const std = @import("std");
const gameController = @import("game_controller.zig");

pub fn main() anyerror!void {
    rl.traceLog(rl.TraceLogLevel.info, "Initializing Game!", .{});
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameController.closeGame();

    if (gameController.initGame(true)) {
        rl.setExitKey(.null);
        std.os.emscripten.emscripten_set_main_loop(updateFrame, 0, 1);
    }
}
export fn updateFrame() callconv(.C) void {
    _ = gameController.update();
}

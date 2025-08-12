const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameController = @import("game_controller.zig");

pub fn main() anyerror!void {
    rl.setTraceLogLevel(if (buildin.mode == .Debug) .all else .err);
    rl.traceLog(
        rl.TraceLogLevel.info,
        "Initializing Game!",
        .{},
    );
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameController.closeGame();
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = false,
    });

    if (gameController.initGame(false)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(400, 225);
        std.os.emscripten.emscripten_set_main_loop(updateFrame, 0, 1);
    }
}
export fn updateFrame() callconv(.C) void {
    _ = gameController.update();
}

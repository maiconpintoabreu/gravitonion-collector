const rl = @import("raylib");
const std = @import("std");
const gameController = @import("game_controller.zig");

pub fn main() anyerror!void {
    rl.setTraceLogLevel(.warning);
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
        while (gameController.update()) {}
    }
}

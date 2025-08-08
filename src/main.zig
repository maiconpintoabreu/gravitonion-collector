const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameController = @import("game_controller.zig");

pub fn main() anyerror!void {
    // rl.setTraceLogLevel(.warning);
    rl.traceLog(
        rl.TraceLogLevel.info,
        "Initializing Game!",
        .{},
    );
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameController.closeGame();
    const isRelease = buildin.mode != std.builtin.Mode.Debug;
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
    });

    if (gameController.initGame(false)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(400, 225);
        if (isRelease) {
            rl.toggleBorderlessWindowed();
        }
        const fps = if (rl.getMonitorRefreshRate(rl.getCurrentMonitor()) != 0)
            rl.getMonitorRefreshRate(rl.getCurrentMonitor())
        else
            60;
        rl.setTargetFPS(fps);
        while (gameController.update()) {}
    }
}

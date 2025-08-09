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
    const isFullScreen = buildin.os.tag == .windows or buildin.os.tag == .linux;
    const isBorderlessWindowed = buildin.mode != std.builtin.OptimizeMode.Debug;
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = isFullScreen or isBorderlessWindowed,
    });

    if (gameController.initGame(false)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(400, 225);
        if (isFullScreen) {
            rl.toggleFullscreen();
        } else if (isBorderlessWindowed) {
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

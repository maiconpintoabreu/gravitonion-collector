const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameController = @import("game_controller.zig");
const configZig = @import("config.zig");

const MIN_WINDOW_SIZE_WIDTH = 400;
const MIN_WINDOW_SIZE_HEIGHT = 225;

pub fn main() anyerror!void {
    rl.setTraceLogLevel(if (buildin.mode == .Debug) .all else .err);
    configZig.IS_TESTING = false;
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
        .window_highdpi = true,
    });

    if (gameController.initGame(isFullScreen)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(MIN_WINDOW_SIZE_WIDTH, MIN_WINDOW_SIZE_HEIGHT);
        if (isFullScreen) {
            rl.toggleFullscreen();
        } else if (isBorderlessWindowed) {
            rl.toggleBorderlessWindowed();
        }
        // const fps = if (rl.getMonitorRefreshRate(rl.getCurrentMonitor()) != 0)
        //     rl.getMonitorRefreshRate(rl.getCurrentMonitor())
        // else
        //     60;
        // rl.setTargetFPS(fps);
        while (gameController.update()) {}
    }
}

const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameManager = @import("game_manager.zig");
const configZig = @import("config.zig");
const GameZig = @import("game_logic/game_play.zig");
const Game = GameZig.Game;
const PhysicsZig = @import("game_logic/physics.zig");
const PhysicSystem = PhysicsZig.PhysicsSystem;

pub fn main() anyerror!void {
    var game: Game = .{};
    rl.setTraceLogLevel(if (buildin.mode == .Debug) .all else .err);
    rl.traceLog(
        rl.TraceLogLevel.info,
        "Initializing Game!",
        .{},
    );
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameManager.closeGame(&game);
    const isFullScreen = buildin.os.tag == .windows or buildin.os.tag == .linux;
    const isBorderlessWindowed = buildin.mode != std.builtin.OptimizeMode.Debug;
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = isFullScreen or isBorderlessWindowed,
        .window_highdpi = true,
    });

    if (gameManager.initGame(&game, isFullScreen)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(configZig.MIN_WINDOW_SIZE_WIDTH, configZig.MIN_WINDOW_SIZE_HEIGHT);
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
        while (gameManager.update(&game)) {}
    }
}

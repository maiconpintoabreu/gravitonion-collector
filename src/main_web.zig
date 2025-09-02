const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameManager = @import("game_manager.zig");
const configZig = @import("config.zig");
const gameZig = @import("game_logic/game_play.zig");
const Game = gameZig.Game;

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
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
    });

    if (gameManager.initGame(&game, false)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(configZig.MIN_WINDOW_SIZE_WIDTH, configZig.MIN_WINDOW_SIZE_HEIGHT);
        std.os.emscripten.emscripten_set_main_loop_arg(updateFrame, &game, 0, 1);
    }
}
export fn updateFrame(optionalPtr: ?*anyopaque) void {
    if (optionalPtr) |ptr| {
        const game: *Game = @ptrCast(@alignCast(ptr));
        _ = gameManager.update(game);
    }
}

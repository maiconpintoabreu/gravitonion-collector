const rl = @import("raylib");
const std = @import("std");
const buildin = @import("builtin");
const gameManager = @import("game_manager.zig");
const configZig = @import("config.zig");
const gameZig = @import("game_logic/game_play.zig");
const Game = gameZig.Game;
const PhysicsZig = @import("game_logic/physics.zig");
const PhysicSystem = PhysicsZig.PhysicsSystem;

var game: Game = .{};
var physics: PhysicSystem = .{};

pub fn main() anyerror!void {
    rl.setTraceLogLevel(if (buildin.mode == .Debug) .all else .err);
    rl.traceLog(
        rl.TraceLogLevel.info,
        "Initializing Game!",
        .{},
    );
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameManager.closeGame(&game);
    const newScreen = game.screen.toVector2().scale(@as(f32, @floatCast(std.os.emscripten.emscripten_get_device_pixel_ratio())));
    game.screen.x = @as(i32, @intFromFloat(newScreen.x));
    game.screen.y = @as(i32, @intFromFloat(newScreen.y));
    rl.setConfigFlags(rl.ConfigFlags{
        .window_resizable = true,
    });

    if (gameManager.initGame(&game, &physics, false)) {
        rl.setExitKey(.null);
        rl.setWindowMinSize(configZig.MIN_WINDOW_SIZE_WIDTH, configZig.MIN_WINDOW_SIZE_HEIGHT);
        std.os.emscripten.emscripten_set_main_loop(updateFrame, 0, 1);
    }
}
export fn updateFrame() void {
    if (game.gameState == .Quit) {
        rl.beginDrawing();
        rl.clearBackground(.black);
        const fontSize: i32 = @divFloor(game.screen.y, 10);
        rl.drawText("Thanks!", 10, @divFloor(game.screen.y, 2) - @divFloor(fontSize, 2), fontSize, .white);
        rl.endDrawing();
        return;
    }
    if (!gameManager.update(&game, &physics)) game.gameState = .Quit;
}

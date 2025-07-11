const rl = @import("raylib");
const gameController = @import("game_controller.zig");

pub fn main() anyerror!void {
    rl.traceLog(rl.TraceLogLevel.info, "Initializing Game!", .{});
    defer rl.closeWindow(); // Close window and OpenGL context
    defer gameController.closeGame();

    rl.setTargetFPS(60);
    rl.setConfigFlags(rl.ConfigFlags{ .window_resizable = true });

    if (gameController.startGame()) {
        while (gameController.updateFrame()) {}
    }
}

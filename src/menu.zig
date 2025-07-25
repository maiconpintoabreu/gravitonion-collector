const rl = @import("raylib");
const rg = @import("raygui");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;

var game: *Game = undefined;

pub fn initMenu(inGame: *Game) bool {
    game = inGame;
    return true;
}

pub fn updateFrame() void {
    if (rl.isKeyReleased(.escape) and game.gameState == GameState.Pause) {
        game.gameState = GameState.Playing;
    }
}

pub fn drawFrame() void {
    const width = 120 * game.virtualRatio;
    const xPosition = game.nativeSizeScaled.x - width / 2;
    switch (game.gameState) {
        GameState.MainMenu => {
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (20 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Play")) {
                game.gameState = GameState.Playing;
            }
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (-30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Quit")) {
                game.gameState = GameState.Quit;
            }
        },
        GameState.Pause => {
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Continue")) {
                game.gameState = GameState.Playing;
            }
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (0 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Main Menu")) {
                game.gameState = GameState.MainMenu;
            }
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (-30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Quit")) {
                game.gameState = GameState.Quit;
            }
        },
        GameState.GameOver => {

            // TODO: move it out
            rg.setIconScale(@as(i32, @intFromFloat(game.virtualRatio)));

            _ = rg.label(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, rl.textFormat("Highest Score: %3.2f", .{game.highestScore}));

            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Restart")) {
                game.gameState = GameState.Playing;
            }
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (0 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Main Menu")) {
                game.gameState = GameState.MainMenu;
            }
            if (rg.button(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (-30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Quit")) {
                game.gameState = GameState.Quit;
            }
        },
        else => {
            unreachable;
        },
    }
}

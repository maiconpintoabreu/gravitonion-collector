const std = @import("std");
const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;

const BUTTON_BACKGROUND_NORMAL: rl.Color = .gray;
const BUTTON_BACKGROUND_HOVER: rl.Color = .light_gray;

var game: *Game = undefined;
var font: rl.Font = std.mem.zeroes(rl.Font);

pub fn initMenu(inGame: *Game) bool {
    game = inGame;

    font = rl.getFontDefault() catch |err| switch (err) {
        else => {
            return false;
        },
    };
    return true;
}
pub fn closeMenu() void {
    if (font.isReady()) {
        rl.unloadFont(font);
    }
}
pub fn updateFrame() void {
    if (rl.isKeyReleased(.escape) and game.gameState == GameState.Pause) {
        game.gameState = GameState.Playing;
    }
}

pub fn drawFrame() void {
    const width = 140 * game.virtualRatio;
    const xPosition = game.nativeSizeScaled.x - width / 2;
    switch (game.gameState) {
        GameState.MainMenu => {
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (20 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Play", 20 * game.virtualRatio, .black)) {
                game.gameState = GameState.Playing;
            }
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (-30 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Quit", 20 * game.virtualRatio, .black)) {
                game.gameState = GameState.Quit;
            }
        },
        GameState.Pause, GameState.GameOver => {
            rl.drawRectangle(0, 0, game.width, game.height, rl.Color{
                .r = 0,
                .g = 0,
                .b = 0,
                .a = 100,
            });
            uiText(rl.Rectangle{
                .x = xPosition,
                .y = game.nativeSizeScaled.y - (80 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, rl.textFormat("Highest Score: %3.3f", .{game.highestScore}), 10 * game.virtualRatio, .white);
            if (game.gameState == GameState.Pause) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Continue", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (0 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Main Menu", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (-40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Quit", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Quit;
                }
            } else if (game.gameState == GameState.GameOver) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Restart", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (0 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Main Menu", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = game.nativeSizeScaled.y - (-40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Quit", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Quit;
                }
            }
        },
        else => {
            // Draw menu should not be called while playing
            unreachable;
        },
    }
}

fn uiTextButtom(buttom: rl.Rectangle, text: [:0]const u8, fontSize: f32, color: rl.Color) bool {
    if (rl.checkCollisionPointRec(rl.getMousePosition(), buttom)) {
        rl.drawRectangleRec(buttom, BUTTON_BACKGROUND_HOVER);
    } else {
        rl.drawRectangleRec(buttom, BUTTON_BACKGROUND_NORMAL);
    }
    rl.drawTextEx(font, text, rl.Vector2{
        .x = buttom.x + 5,
        .y = (buttom.y + buttom.height / 2) - (fontSize / 2),
    }, fontSize, 5, color);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointRec(rl.getMousePosition(), buttom)) {
        return true;
    }

    return false;
}
fn uiText(buttom: rl.Rectangle, text: [:0]const u8, fontSize: f32, color: rl.Color) void {
    rl.drawTextEx(font, text, rl.Vector2{
        .x = buttom.x + 5,
        .y = (buttom.y + buttom.height / 2) - (fontSize / 2),
    }, fontSize, 5, color);
}

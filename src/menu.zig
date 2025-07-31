const std = @import("std");
const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;

const IS_DEBUG_MENU: bool = true;
const BUTTON_BACKGROUND_NORMAL: rl.Color = .gray;
const BUTTON_BACKGROUND_HOVER: rl.Color = .light_gray;

var game: *Game = undefined;
var font: rl.Font = std.mem.zeroes(rl.Font);
var controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

pub fn initMenu(inGame: *Game) bool {
    game = inGame;

    var controlImage: rl.Image = rl.genImageColor(16 * 4, 16, rl.Color.blank);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 9, .y = 2 }, rl.Vector2{ .x = 9, .y = 12 }, rl.Vector2{ .x = 4, .y = 7 }, rl.Color.white);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 16 + 7, .y = 2 }, rl.Vector2{ .x = 16 + 16 - 4, .y = 7 }, rl.Vector2{ .x = 16 + 7, .y = 12 }, rl.Color.white);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 32 + 8, .y = 5 }, rl.Vector2{ .x = 32 + 13, .y = 10 }, rl.Vector2{ .x = 32 + 3, .y = 10 }, rl.Color.white);
    rl.imageDrawText(&controlImage, "x", 48 + 3, -3, 20, rl.Color.white);
    controlTexture = rl.loadTextureFromImage(controlImage) catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture controller ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    rl.unloadImage(controlImage);

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
    const centerNormalized = game.nativeSizeScaled.scale(game.virtualRatio);
    const xPosition = centerNormalized.x - width / 2;
    switch (game.gameState) {
        GameState.MainMenu => {
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = centerNormalized.y - (20 * game.virtualRatio),
                .width = width,
                .height = 30 * game.virtualRatio,
            }, "Play", 20 * game.virtualRatio, .black)) {
                game.gameState = GameState.Playing;
            }
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = centerNormalized.y - (-30 * game.virtualRatio),
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
            if (game.highestScore > 0) {
                uiText(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (80 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, rl.textFormat("Highest Score: %3.2f", .{game.highestScore}), 10 * game.virtualRatio, .white);
            }
            if (game.gameState == GameState.Pause) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Continue", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (0 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Main Menu", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (-40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Quit", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Quit;
                }
            } else if (game.gameState == GameState.GameOver) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Restart", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (0 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Main Menu", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = centerNormalized.y - (-40 * game.virtualRatio),
                    .width = width,
                    .height = 30 * game.virtualRatio,
                }, "Quit", 20 * game.virtualRatio, .black)) {
                    game.gameState = GameState.Quit;
                }
            }
        },
        GameState.Playing => {
            // UI
            if (!rl.isGamepadAvailable(0)) {
                if (uiButtomIcon(
                    .{
                        .x = 40 * game.virtualRatio,
                        .y = @as(f32, @floatFromInt(game.height)) - (50 * game.virtualRatio),
                    },
                    30 * game.virtualRatio,
                    0,
                )) {
                    game.isTouchLeft = true;
                } else {
                    game.isTouchLeft = false;
                }
                if (uiButtomIcon(
                    .{
                        .x = (100 + 30) * game.virtualRatio,
                        .y = @as(f32, @floatFromInt(game.height)) - (50 * game.virtualRatio),
                    },
                    30 * game.virtualRatio,
                    1,
                )) {
                    game.isTouchRight = true;
                } else {
                    game.isTouchRight = false;
                }
                if (uiButtomIcon(
                    .{
                        .x = @as(f32, @floatFromInt(game.width)) - ((30 + 30) * game.virtualRatio),
                        .y = @as(f32, @floatFromInt(game.height)) - (50 * game.virtualRatio),
                    },
                    30 * game.virtualRatio,
                    2,
                )) {
                    game.isTouchUp = true;
                } else {
                    game.isTouchUp = false;
                }
                if (uiButtomIcon(
                    .{
                        .x = @as(f32, @floatFromInt(game.width)) - ((30 + 30) * game.virtualRatio),
                        .y = @as(f32, @floatFromInt(game.height)) - 120 * game.virtualRatio,
                    },
                    30 * game.virtualRatio,
                    3,
                )) {
                    game.isShooting = true;
                } else {
                    game.isShooting = false;
                }
            }
            const fontSize = 15 * @as(i32, @intFromFloat(game.virtualRatio));
            rl.drawText(
                rl.textFormat("Score: %3.2f", .{game.currentScore}),
                @as(i32, @intFromFloat(xPosition + (40 * game.virtualRatio))),
                fontSize,
                fontSize,
                .white,
            );
            rl.drawFPS(10, 10);
            // Start Debug
            if (IS_DEBUG_MENU) {
                rl.drawText(rl.textFormat("--------------DEBUG--------------", .{}), 10, 40 + fontSize, fontSize, .white);
                rl.drawText(rl.textFormat("game.Projectiles: %i", .{game.projectilesCount}), 10, 40 + fontSize * 2, fontSize, .white);
                rl.drawText(rl.textFormat("game.ASteroids: %i", .{game.asteroidCount}), 10, 40 + fontSize * 3, fontSize, .white);
            }
        },
        else => {
            // Draw menu should not be called while playing
            unreachable;
        },
    }
}

fn uiButtomIcon(buttom: rl.Vector2, buttomSize: f32, icon: f32) bool {
    rl.drawCircleV(buttom, buttomSize, rl.Color.gray);
    const buttomEdge = rl.Vector2{ .x = buttom.x - buttomSize / 2, .y = buttom.y - buttomSize / 2 };
    rl.drawTexturePro(controlTexture, rl.Rectangle{ .x = 16 * icon, .y = 0, .width = 16, .height = 16 }, .{ .x = buttomEdge.x, .y = buttomEdge.y, .width = buttomSize, .height = buttomSize }, rl.Vector2.zero(), 0, rl.Color.white);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointCircle(rl.getMousePosition(), buttom, buttomSize)) {
        return true;
    }
    const touchCount = @as(usize, @intCast(rl.getTouchPointCount()));
    for (0..touchCount) |touchIndex| {
        if (rl.checkCollisionPointCircle(rl.getTouchPosition(@intCast(touchIndex)), buttom, buttomSize)) {
            return true;
        }
    }

    return false;
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

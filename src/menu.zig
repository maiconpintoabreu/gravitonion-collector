const std = @import("std");
const rl = @import("raylib");

const constantsZig = @import("game_logic/constants.zig");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;
const GameControllerType = gameZig.GameControllerType;

const IS_DEBUG_MENU: bool = false;
const BUTTON_BACKGROUND_NORMAL: rl.Color = .gray;
const BUTTON_BACKGROUND_HOVER: rl.Color = .light_gray;
const BUTTON_WIDTH = 140;

var game: *Game = undefined;
var font: rl.Font = std.mem.zeroes(rl.Font);
var controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

pub fn initMenu(inGame: *Game) bool {
    game = inGame;

    // Magic numbers to generate a triangle for the UI (I could add a file instead) TODO: Add the triangle as a file
    var controlImage: rl.Image = rl.genImageColor(
        16 * 4,
        16,
        rl.Color.blank,
    );
    rl.imageDrawTriangle(
        &controlImage,
        rl.Vector2{ .x = 9, .y = 2 },
        rl.Vector2{ .x = 9, .y = 12 },
        rl.Vector2{ .x = 4, .y = 7 },
        rl.Color.white,
    );
    rl.imageDrawTriangle(
        &controlImage,
        rl.Vector2{ .x = 16 + 7, .y = 2 },
        rl.Vector2{ .x = 16 + 16 - 4, .y = 7 },
        rl.Vector2{ .x = 16 + 7, .y = 12 },
        rl.Color.white,
    );
    rl.imageDrawTriangle(
        &controlImage,
        rl.Vector2{ .x = 32 + 8, .y = 5 },
        rl.Vector2{ .x = 32 + 13, .y = 10 },
        rl.Vector2{ .x = 32 + 3, .y = 10 },
        rl.Color.white,
    );
    rl.imageDrawText(&controlImage, "x", 48 + 3, -3, 20, rl.Color.white);
    controlTexture = controlImage.toTexture() catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture controller ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    controlImage.unload();

    font = rl.getFontDefault() catch |err| switch (err) {
        else => {
            return false;
        },
    };
    return true;
}
pub fn closeMenu() void {
    if (font.isReady()) {
        font.unload();
    }
    if (controlTexture.id > 0) {
        controlTexture.unload();
    }
}
pub fn updateFrame() void {
    if (rl.isKeyReleased(.escape) and game.gameState == GameState.Pause) {
        game.gameState = GameState.Playing;
    }
}

pub fn drawFrame() void {
    const width = BUTTON_WIDTH;
    const height = 30;
    const xPosition = constantsZig.NATIVE_CENTER.x - width / 2;
    switch (game.gameState) {
        GameState.MainMenu => {
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = constantsZig.NATIVE_CENTER.y - height,
                .width = width,
                .height = height,
            }, "Play", 20, .black)) {
                game.gameState = GameState.Playing;
            }
            if (uiTextButtom(rl.Rectangle{
                .x = xPosition,
                .y = constantsZig.NATIVE_CENTER.y - -height,
                .width = width,
                .height = height,
            }, "Quit", 20, .black)) {
                game.gameState = GameState.Quit;
            }
        },
        GameState.Pause, GameState.GameOver => {
            rl.drawRectangle(0, 0, @as(i32, @intFromFloat(game.screen.x)), @as(i32, @intFromFloat(game.screen.y)), rl.Color{
                .r = 0,
                .g = 0,
                .b = 0,
                .a = 100,
            });
            if (game.highestScore > 0) {
                uiText(rl.Rectangle{
                    .x = xPosition - 20, // -20 to make it centered
                    .y = constantsZig.NATIVE_CENTER.y - (80),
                    .width = width,
                    .height = height,
                }, rl.textFormat("Highest Score: %3.2f", .{game.highestScore}), 10, .white);
            }
            if (game.gameState == GameState.Pause) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (40),
                    .width = width,
                    .height = height,
                }, "Continue", 20, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (0),
                    .width = width,
                    .height = height,
                }, "Main Menu", 20, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (-40),
                    .width = width,
                    .height = height,
                }, "Quit", 20, .black)) {
                    game.gameState = GameState.Quit;
                }
            } else if (game.gameState == GameState.GameOver) {
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (40),
                    .width = width,
                    .height = height,
                }, "Restart", 20, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (0),
                    .width = width,
                    .height = height,
                }, "Main Menu", 20, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextButtom(rl.Rectangle{
                    .x = xPosition,
                    .y = constantsZig.NATIVE_CENTER.y - (-40),
                    .width = width,
                    .height = height,
                }, "Quit", 20, .black)) {
                    game.gameState = GameState.Quit;
                }
            }
        },
        GameState.Playing => {
            // UI
            // Set Joystick if one and it is absolute
            if (!rl.isGamepadAvailable(0)) {
                if (rl.getTouchPointCount() > 0 and rl.getTouchPosition(0).x > 0) {
                    game.gameControllerType = GameControllerType.TouchScreen;
                    if (!game.isPlaying) {
                        game.isPlaying = true;
                    }
                }
                if (game.gameControllerType == GameControllerType.TouchScreen) {
                    if (uiButtomIcon(
                        .{
                            .x = 40,
                            .y = constantsZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        0,
                    )) {
                        game.isTouchLeft = true;
                    } else {
                        game.isTouchLeft = false;
                    }
                    if (uiButtomIcon(
                        .{
                            .x = (100 + 30),
                            .y = constantsZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        1,
                    )) {
                        game.isTouchRight = true;
                    } else {
                        game.isTouchRight = false;
                    }
                    if (uiButtomIcon(
                        .{
                            .x = constantsZig.NATIVE_WIDTH - 60,
                            .y = constantsZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        2,
                    )) {
                        game.isTouchUp = true;
                    } else {
                        game.isTouchUp = false;
                    }
                    if (uiButtomIcon(
                        .{
                            .x = constantsZig.NATIVE_WIDTH - 60,
                            .y = constantsZig.NATIVE_HEIGHT - 150,
                        },
                        30,
                        3,
                    )) {
                        game.isShooting = true;
                    } else {
                        game.isShooting = false;
                    }
                }
            } else if (game.gameControllerType != GameControllerType.Joystick) {
                game.gameControllerType = GameControllerType.Joystick;
            }
            const fontSize = 15;
            rl.drawText(
                rl.textFormat("Score: %3.2f", .{game.currentScore}),
                @as(i32, @intFromFloat(xPosition + 40)),
                fontSize,
                fontSize,
                .white,
            );
            rl.drawFPS(10, 10);
            // Start Debug
            if (IS_DEBUG_MENU) {
                rl.drawText(
                    rl.textFormat("--------------DEBUG--------------", .{}),
                    10,
                    40 + fontSize,
                    fontSize,
                    .white,
                );
                rl.drawText(
                    rl.textFormat("game.blackhole.size: %3.3f", .{game.blackHole.size}),
                    10,
                    40 + fontSize * 2,
                    fontSize,
                    .white,
                );
            }
        },
        else => {
            // Draw menu should not be called while playing
            unreachable;
        },
    }
}

fn uiButtomIcon(buttom: rl.Vector2, buttomSize: f32, icon: f32) bool {
    const buttomEdge = rl.Vector2{ .x = buttom.x - buttomSize / 2, .y = buttom.y - buttomSize / 2 };
    const isHouvering = rl.checkCollisionPointCircle(rl.getMousePosition(), buttom, buttomSize);

    rl.drawCircleV(buttom, buttomSize, .{
        .r = BUTTON_BACKGROUND_NORMAL.r,
        .g = BUTTON_BACKGROUND_NORMAL.g,
        .b = BUTTON_BACKGROUND_NORMAL.b,
        .a = if (isHouvering) 100 else 200,
    });
    rl.drawTexturePro(
        controlTexture,
        rl.Rectangle{ .x = 16 * icon, .y = 0, .width = 16, .height = 16 },
        .{ .x = buttomEdge.x, .y = buttomEdge.y, .width = buttomSize, .height = buttomSize },
        rl.Vector2.zero(),
        0,
        rl.Color.white,
    );

    // remove mouse to use only touch values
    const touchCount = @as(usize, @intCast(rl.getTouchPointCount()));
    for (0..touchCount) |touchIndex| {
        if (rl.checkCollisionPointCircle(
            rl.getScreenToWorld2D(rl.getTouchPosition(@intCast(touchIndex)), game.camera),
            buttom,
            buttomSize,
        )) {
            return true;
        }
    }

    return false;
}

fn uiTextButtom(buttom: rl.Rectangle, text: [:0]const u8, fontSize: f32, color: rl.Color) bool {
    const mousePosition = rl.getMousePosition();
    if (rl.checkCollisionPointRec(mousePosition, buttom)) {
        rl.drawRectangleRec(buttom, BUTTON_BACKGROUND_HOVER);
    } else {
        rl.drawRectangleRec(buttom, BUTTON_BACKGROUND_NORMAL);
    }
    rl.drawTextEx(font, text, rl.Vector2{
        .x = buttom.x + 5,
        .y = (buttom.y + buttom.height / 2) - (fontSize / 2),
    }, fontSize, 5, color);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointRec(mousePosition, buttom)) {
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

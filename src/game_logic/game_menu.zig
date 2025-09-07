const std = @import("std");
const rl = @import("raylib");

const configZig = @import("../config.zig");
const gameZig = @import("game_play.zig");
const ResourceManagerZig = @import("../resource_manager.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;
const GameControllerType = gameZig.GameControllerType;

const BUTTON_BACKGROUND_NORMAL: rl.Color = .gray;
const BUTTON_BACKGROUND_HOVER: rl.Color = .light_gray;
const BUTTON_WIDTH = 140;

pub fn initMenu(game: *Game) bool {
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
    game.controlTexture = controlImage.toTexture() catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            rl.traceLog(.err, "LoadTexture controller ERROR", .{});
            return false;
        },
        else => {
            rl.traceLog(.err, "ERROR", .{});
            return false;
        },
    };
    controlImage.unload();

    game.font = rl.getFontDefault() catch |err| switch (err) {
        else => {
            return false;
        },
    };
    return true;
}
pub fn closeMenu(game: *Game) void {
    if (game.font.isReady()) {
        game.font.unload();
    }
    if (game.controlTexture.id > 0) {
        game.controlTexture.unload();
    }
}
pub fn updateFrame(game: *Game) void {
    if (rl.isKeyReleased(.escape)) {
        switch (game.gameState) {
            inline .Pause => game.gameState = GameState.Playing,
            inline .MainMenu => game.gameState = GameState.Quit,
            inline .GameOver => game.gameState = GameState.MainMenu,
            inline else => return,
        }
        return;
    }
    if (game.gameState == .GameOver) return;

    if (game.gameControllerType == GameControllerType.TouchScreen) {
        if (actionbutton(
            .{
                .x = 40,
                .y = configZig.NATIVE_HEIGHT - 80,
            },
            30,
            game.camera,
        )) {
            game.isTouchLeft = true;
        } else {
            game.isTouchLeft = false;
        }
        if (actionbutton(
            .{
                .x = (100 + 30),
                .y = configZig.NATIVE_HEIGHT - 80,
            },
            30,
            game.camera,
        )) {
            game.isTouchRight = true;
        } else {
            game.isTouchRight = false;
        }
        if (actionbutton(
            .{
                .x = configZig.NATIVE_WIDTH - 60,
                .y = configZig.NATIVE_HEIGHT - 80,
            },
            30,
            game.camera,
        )) {
            game.isTouchUp = true;
        } else {
            game.isTouchUp = false;
        }
        if (actionbutton(
            .{
                .x = configZig.NATIVE_WIDTH - 60,
                .y = configZig.NATIVE_HEIGHT - 150,
            },
            30,
            game.camera,
        )) {
            game.isShooting = true;
        } else {
            game.isShooting = false;
        }
    }
}

pub fn drawFrame(game: *Game) void {
    if (game.gameState == .Quit) return;

    const width = BUTTON_WIDTH;
    const height = 30;
    const xPosition = configZig.NATIVE_CENTER.x - width / 2;
    var recTextButton: rl.Rectangle = .{
        .x = xPosition,
        .y = configZig.NATIVE_CENTER.y - height,
        .width = width,
        .height = height,
    };
    const resourceManager = ResourceManagerZig.resourceManager;
    switch (game.gameState) {
        GameState.MainMenu => {
            resourceManager.backgroundTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(resourceManager.backgroundTexture.width)),
                    .height = @as(f32, @floatFromInt(resourceManager.backgroundTexture.height)),
                },
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(800)),
                    .height = @as(f32, @floatFromInt(450)),
                },
                .{ .x = 0, .y = 0 },
                0,
                .white,
            );
            recTextButton.y = configZig.NATIVE_CENTER.y - height;
            if (uiTextbutton(
                recTextButton,
                "Play",
                game.font,
                20,
                .black,
            )) {
                game.gameState = GameState.Playing;
            }
            recTextButton.y = configZig.NATIVE_CENTER.y - -height;
            if (uiTextbutton(
                recTextButton,
                "Quit",
                game.font,
                20,
                .black,
            )) {
                game.gameState = GameState.Quit;
            }
        },
        GameState.Pause, GameState.GameOver => {
            resourceManager.backgroundTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(resourceManager.backgroundTexture.width)),
                    .height = @as(f32, @floatFromInt(resourceManager.backgroundTexture.height)),
                },
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(800)),
                    .height = @as(f32, @floatFromInt(450)),
                },
                .{ .x = 0, .y = 0 },
                0,
                .white,
            );
            if (game.highestScore > 0) {
                uiText(
                    rl.Rectangle{
                        .x = xPosition - 20, // -20 to make it centered
                        .y = configZig.NATIVE_CENTER.y - (80),
                        .width = width,
                        .height = height,
                    },
                    rl.textFormat("Highest Score: %3.2f", .{game.highestScore}),
                    game.font,
                    10,
                    .white,
                );
            }
            if (game.gameState == GameState.Pause) {
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (40),
                    .width = width,
                    .height = height,
                }, "Continue", game.font, 20, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (0),
                    .width = width,
                    .height = height,
                }, "Main Menu", game.font, 20, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (-40),
                    .width = width,
                    .height = height,
                }, "Quit", game.font, 20, .black)) {
                    game.gameState = GameState.Quit;
                }
            } else if (game.gameState == GameState.GameOver) {
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (40),
                    .width = width,
                    .height = height,
                }, "Restart", game.font, 20, .black)) {
                    game.gameState = GameState.Playing;
                }
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (0),
                    .width = width,
                    .height = height,
                }, "Main Menu", game.font, 20, .black)) {
                    game.gameState = GameState.MainMenu;
                }
                if (uiTextbutton(rl.Rectangle{
                    .x = xPosition,
                    .y = configZig.NATIVE_CENTER.y - (-40),
                    .width = width,
                    .height = height,
                }, "Quit", game.font, 20, .black)) {
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
                    uibuttonIcon(
                        .{
                            .x = 40,
                            .y = configZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        game.controlTexture,
                        0,
                    );
                    uibuttonIcon(
                        .{
                            .x = (100 + 30),
                            .y = configZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        game.controlTexture,
                        1,
                    );
                    uibuttonIcon(
                        .{
                            .x = configZig.NATIVE_WIDTH - 60,
                            .y = configZig.NATIVE_HEIGHT - 80,
                        },
                        30,
                        game.controlTexture,
                        2,
                    );
                    uibuttonIcon(
                        .{
                            .x = configZig.NATIVE_WIDTH - 60,
                            .y = configZig.NATIVE_HEIGHT - 150,
                        },
                        30,
                        game.controlTexture,
                        3,
                    );
                }
            } else if (game.gameControllerType != GameControllerType.Joystick) {
                game.gameControllerType = GameControllerType.Joystick;
            }
            const fontSize = 15;
            if (!game.isPlaying) {
                if (game.gameControllerType == GameControllerType.TouchScreen) {
                    rl.drawText(
                        "Press any where to start",
                        0,
                        @as(i32, @intFromFloat(configZig.NATIVE_CENTER.y)) - 35,
                        fontSize,
                        .white,
                    );
                } else {
                    rl.drawText(
                        "Press any thing to start",
                        0,
                        @as(i32, @intFromFloat(configZig.NATIVE_CENTER.y)) - 35,
                        fontSize,
                        .white,
                    );
                }
            }
            rl.drawText(
                rl.textFormat("Score: %3.2f", .{game.currentScore}),
                @as(i32, @intFromFloat(xPosition + 40)),
                fontSize,
                fontSize,
                .white,
            );
            // Start Debug
            if (configZig.IS_DEBUG_MENU) {
                // const delta = rl.getFrameTime();
                rl.drawText(
                    rl.textFormat("--------------DEBUG--------------", .{}),
                    10,
                    40 + fontSize,
                    fontSize,
                    .white,
                );
                rl.drawText(
                    rl.textFormat("game.blackhole.size: %3.3f", .{game.blackhole.size}),
                    10,
                    40 + fontSize * 2,
                    fontSize,
                    .white,
                );
                if (game.player.isInvunerable) {
                    rl.drawText(
                        rl.textFormat("Player is: %s", .{"Invunerable"}),
                        10,
                        40 + fontSize * 3,
                        fontSize,
                        .white,
                    );
                } else {
                    rl.drawText(
                        rl.textFormat("Player is: %s", .{"Vunerable"}),
                        10,
                        40 + fontSize * 3,
                        fontSize,
                        .white,
                    );
                }
                rl.drawText(
                    rl.textFormat("Player Speed: %3.3f", .{
                        game.player.body.velocity.length(),
                    }),
                    10,
                    40 + fontSize * 4,
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
    rl.drawFPS(10, 10);
}

fn actionbutton(button: rl.Vector2, buttonSize: f32, camera: rl.Camera2D) bool {
    // remove mouse to use only touch values
    const touchCount = @as(usize, @intCast(rl.getTouchPointCount()));
    for (0..touchCount) |touchIndex| {
        if (rl.checkCollisionPointCircle(
            rl.getScreenToWorld2D(rl.getTouchPosition(@intCast(touchIndex)), camera),
            button,
            buttonSize,
        )) {
            return true;
        }
    }

    return false;
}

fn uibuttonIcon(button: rl.Vector2, buttonSize: f32, texture: rl.Texture2D, icon: f32) void {
    const buttonEdge = rl.Vector2{ .x = button.x - buttonSize / 2, .y = button.y - buttonSize / 2 };

    rl.drawCircleV(button, buttonSize, .{
        .r = BUTTON_BACKGROUND_NORMAL.r,
        .g = BUTTON_BACKGROUND_NORMAL.g,
        .b = BUTTON_BACKGROUND_NORMAL.b,
        .a = 200,
    });
    texture.drawPro(
        rl.Rectangle{ .x = 16 * icon, .y = 0, .width = 16, .height = 16 },
        .{ .x = buttonEdge.x, .y = buttonEdge.y, .width = buttonSize, .height = buttonSize },
        rl.Vector2.zero(),
        0,
        rl.Color.white,
    );
}

fn uiTextbutton(button: rl.Rectangle, text: [:0]const u8, font: rl.Font, fontSize: f32, color: rl.Color) bool {
    const mousePosition = rl.getMousePosition();
    if (rl.checkCollisionPointRec(mousePosition, button)) {
        rl.drawRectangleRec(button, BUTTON_BACKGROUND_HOVER);
    } else {
        rl.drawRectangleRec(button, BUTTON_BACKGROUND_NORMAL);
    }
    rl.drawTextEx(font, text, rl.Vector2{
        .x = button.x + 5,
        .y = (button.y + button.height / 2) - (fontSize / 2),
    }, fontSize, 5, color);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointRec(mousePosition, button)) {
        return true;
    }

    return false;
}
fn uiText(button: rl.Rectangle, text: [:0]const u8, font: rl.Font, fontSize: f32, color: rl.Color) void {
    rl.drawTextEx(font, text, rl.Vector2{
        .x = button.x + 5,
        .y = (button.y + button.height / 2) - (fontSize / 2),
    }, fontSize, 5, color);
}

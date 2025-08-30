const rl = @import("raylib");
const std = @import("std");
const builtin = @import("builtin");

const configZig = @import("config.zig");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const menuZig = @import("game_logic/game_menu.zig");
const GameState = gameZig.GameState;

pub fn initGame(game: *Game, isFullscreen: bool) bool {
    if (isFullscreen) {
        game.screen = .zero();
    }
    rl.initWindow(game.screen.x, game.screen.y, "Space Researcher");

    rl.initAudioDevice();
    updateRatio(game);
    game.gameState = GameState.MainMenu;
    const menuReady = menuZig.initMenu(game);
    game.camera.target = configZig.NATIVE_CENTER;
    // TODO: if needed start game only after the menu when player pressed `Play`
    const gameReady = playingZig.startGame(game) catch |err| switch (err) {
        rl.RaylibError.LoadShader => {
            std.debug.print("LoadShader blackhole.fs ERROR", .{});
            return false;
        },
        rl.RaylibError.LoadAudioStream => {
            std.debug.print("LoadAudioStream ERROR", .{});
            return false;
        },
        rl.RaylibError.LoadSound => {
            std.debug.print("LoadSound destruction ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    return menuReady and gameReady;
}

fn updateRatio(game: *Game) void {
    if (rl.isWindowFullscreen()) {
        if (builtin.cpu.arch.isWasm()) {
            game.screen.x = rl.getScreenWidth();
            game.screen.y = rl.getScreenHeight();
        } else {
            game.screen.x = rl.getRenderWidth();
            game.screen.y = rl.getRenderHeight();
        }
    } else {
        game.screen.x = rl.getScreenWidth();
        game.screen.y = rl.getScreenHeight();
        rl.traceLog(.info, "Window: %i x %i", .{ game.screen.x, game.screen.y });
    }
    game.virtualRatio = .{
        .x = @as(f32, @floatFromInt(game.screen.x)) / @as(f32, @floatFromInt(configZig.NATIVE_WIDTH)),
        .y = @as(f32, @floatFromInt(game.screen.y)) / @as(f32, @floatFromInt(configZig.NATIVE_HEIGHT)),
    };
    if (game.virtualRatio.y < game.virtualRatio.x) {
        game.camera.zoom = 1 * game.virtualRatio.y;
    } else {
        game.camera.zoom = 1 * game.virtualRatio.x;
    }
    game.camera.offset = .{ .x = configZig.NATIVE_CENTER.x * game.virtualRatio.x, .y = configZig.NATIVE_CENTER.y * game.virtualRatio.y };
    rl.setMouseScale(1 / game.virtualRatio.x, 1 / game.virtualRatio.y);
}

pub fn update(game: *Game) bool {
    if (rl.windowShouldClose()) {
        return false;
    }
    if (rl.isWindowResized()) {
        updateRatio(game);
    }
    if (!rl.isWindowFocused() and game.gameState == GameState.Playing) {
        game.gameState = GameState.Pause;
    }
    switch (game.gameState) {
        GameState.MainMenu => {
            menuZig.updateFrame(game);
            rl.beginDrawing();
            defer rl.endDrawing();
            {
                game.camera.begin();
                defer game.camera.end();
                rl.clearBackground(configZig.BACKGROUND_COLOR);
                menuZig.drawFrame(game);
            }
            if (game.gameState == GameState.Playing) {
                playingZig.restartGame(game);
            }
        },
        GameState.Playing => {
            menuZig.updateFrame(game);
            playingZig.updateFrame(game);
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(configZig.BACKGROUND_COLOR);
            {
                game.camera.begin();
                defer game.camera.end();
                playingZig.drawFrame(game);
                menuZig.drawFrame(game);
            }
        },
        GameState.GameOver => {
            menuZig.updateFrame(game);
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(configZig.BACKGROUND_COLOR);
            {
                game.camera.begin();
                defer game.camera.end();
                menuZig.drawFrame(game);
            }
            if (game.gameState == GameState.Playing) {
                playingZig.restartGame(game);
            }
        },
        GameState.Pause => {
            menuZig.updateFrame(game);
            if (game.gameState == GameState.Playing) {
                rl.pollInputEvents();
                return true;
            }
            playingZig.updateFrame(game);
            rl.beginDrawing();
            defer rl.endDrawing();

            {
                game.camera.begin();
                defer game.camera.end();
                rl.clearBackground(configZig.BACKGROUND_COLOR);
                playingZig.drawFrame(game);
                menuZig.drawFrame(game);
            }
        },
        else => {
            return false;
        },
    }

    return true;
}

pub fn closeGame(game: *Game) void {
    rl.closeAudioDevice();
    playingZig.closeGame(game);
    menuZig.closeMenu(game);
}

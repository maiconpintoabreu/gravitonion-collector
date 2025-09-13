const rl = @import("raylib");
const std = @import("std");
const builtin = @import("builtin");

const configZig = @import("config.zig");
const gameZig = @import("game_logic/game_play.zig");
const Game = gameZig.Game;
const menuZig = @import("game_logic/game_menu.zig");
const GameState = gameZig.GameState;
const Vector2i = gameZig.Vector2i;
const PhysicsZig = @import("game_logic/physics.zig");
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ResourceManagerZig = @import("resource_manager.zig");

pub fn initGame(game: *Game, isFullscreen: bool) bool {
    if (isFullscreen) {
        game.screen = .zero();
    }
    rl.initWindow(game.screen.x, game.screen.y, "Space Researcher");
    rl.initAudioDevice();
    updateRatio(game);
    ResourceManagerZig.resourceManager.init() catch |err| switch (err) {
        else => {
            rl.traceLog(.err, "Texture Manager init ERROR", .{});
            return false;
        },
    };
    game.init() catch |err| switch (err) {
        rl.RaylibError.LoadShader => {
            rl.traceLog(.err, "LoadShader Blackhole.fs ERROR", .{});
            return false;
        },
        rl.RaylibError.LoadAudioStream => {
            rl.traceLog(.err, "LoadAudioStream ERROR", .{});
            return false;
        },
        rl.RaylibError.LoadSound => {
            rl.traceLog(.err, "LoadSound destruction ERROR", .{});
            return false;
        },
        else => {
            rl.traceLog(.err, "ERROR", .{});
            return false;
        },
    };
    game.gameState = GameState.MainMenu;
    const menuReady = menuZig.initMenu(game);
    game.camera.target = configZig.NATIVE_CENTER;
    game.camera.offset = .{
        .x = configZig.NATIVE_CENTER.x * game.virtualRatio.x,
        .y = configZig.NATIVE_CENTER.y * game.virtualRatio.y,
    };
    return menuReady;
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
    if (game.gameState == .Quit) return false;
    if (rl.windowShouldClose()) {
        return false;
    }
    if (rl.isWindowResized()) {
        updateRatio(game);
    }
    if (!rl.isWindowFocused() and game.gameState == GameState.Playing) {
        game.gameState = GameState.Pause;
    }
    const delta = rl.getFrameTime();
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
                game.restart();
                game.currentTickLength = 0.0;
            }
        },
        GameState.Playing => {
            menuZig.updateFrame(game);
            game.tick(delta);
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(configZig.BACKGROUND_COLOR);
            {
                game.camera.begin();
                defer game.camera.end();
                game.draw();
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
                game.restart();
            }
        },
        GameState.Pause => {
            menuZig.updateFrame(game);
            if (game.gameState == GameState.Playing) {
                rl.pollInputEvents();
                return true;
            }
            rl.beginDrawing();
            defer rl.endDrawing();
            {
                game.camera.begin();
                defer game.camera.end();
                rl.clearBackground(configZig.BACKGROUND_COLOR);

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
    ResourceManagerZig.resourceManager.unload();
    game.unload();
    menuZig.closeMenu(game);
}

const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const menuZig = @import("menu.zig");
const GameState = gameZig.GameState;

// Global Variables
var game: Game = .{};

pub fn initGame(isEmscripten: bool) bool {
    rl.initWindow(@as(i32, @intFromFloat(game.screen.x)), @as(i32, @intFromFloat(game.screen.y)), "Space Researcher");
    rl.initAudioDevice();
    updateRatio();
    game.gameState = GameState.MainMenu;
    const menuReady = menuZig.initMenu(&game);
    game.camera.target = game.nativeSizeScaled;
    // TODO: if needed start game only after the menu when player pressed `Play`
    const gameReady = playingZig.startGame(&game, isEmscripten);
    return menuReady and gameReady;
}

fn updateRatio() void {
    if (rl.isWindowFullscreen()) {
        game.screen.x = @as(f32, @floatFromInt(rl.getMonitorWidth(rl.getCurrentMonitor())));
        game.screen.y = @as(f32, @floatFromInt(rl.getMonitorHeight(rl.getCurrentMonitor())));
    } else {
        game.screen.x = @as(f32, @floatFromInt(rl.getScreenWidth()));
        game.screen.y = @as(f32, @floatFromInt(rl.getScreenHeight()));
    }
    game.virtualRatio = .{
        .x = game.screen.x / @as(f32, @floatFromInt(gameZig.NATIVE_WIDTH)),
        .y = game.screen.y / @as(f32, @floatFromInt(gameZig.NATIVE_HEIGHT)),
    };
    game.nativeSizeScaled = gameZig.NATIVE_CENTER;
    if (game.virtualRatio.y < game.virtualRatio.x) {
        game.camera.zoom = 1 * game.virtualRatio.y;
    } else {
        game.camera.zoom = 1 * game.virtualRatio.x;
    }
    game.camera.offset = .{ .x = game.nativeSizeScaled.x * game.virtualRatio.x, .y = game.nativeSizeScaled.y * game.virtualRatio.y };
}

pub fn update() bool {
    if (rl.windowShouldClose()) {
        return false;
    }
    if (rl.isWindowResized()) {
        updateRatio();
    }
    if (!rl.isWindowFocused() and game.gameState == GameState.Playing) {
        game.gameState = GameState.Pause;
    }
    switch (game.gameState) {
        GameState.MainMenu => {
            menuZig.updateFrame();
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            menuZig.drawFrame();
            if (game.gameState == GameState.Playing) {
                playingZig.restartGame();
            }
        },
        GameState.Playing => {
            playingZig.updateFrame();
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            playingZig.drawFrame();
            menuZig.drawFrame();
        },
        GameState.GameOver => {
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            menuZig.drawFrame();
            if (game.gameState == GameState.Playing) {
                playingZig.restartGame();
            }
        },
        GameState.Pause => {
            menuZig.updateFrame();
            if (game.gameState == GameState.Playing) {
                rl.pollInputEvents();
                return true;
            }
            playingZig.updateFrame();
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            playingZig.drawFrame();
            menuZig.drawFrame();
        },
        else => {
            return false;
        },
    }

    return true;
}

pub fn closeGame() void {
    defer rl.closeAudioDevice();
    for (game.blackHole.textures) |blackhole| {
        if (blackhole.id > 0) {
            rl.unloadTexture(blackhole);
        }
    }
    playingZig.closeGame();
    menuZig.closeMenu();
}

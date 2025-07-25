const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const menuZig = @import("menu.zig");
const GameState = gameZig.GameState;

// Screen consts
const NATIVE_WIDTH = 160 * 3;
const NATIVE_HEIGHT = 90 * 3;
const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };

// Global Variables
var game: Game = .{};

pub fn initGame(isEmscripten: bool) bool {
    rl.initWindow(game.width, game.height, "Space Researcher");
    rl.initAudioDevice();
    updateRatio();
    game.gameState = GameState.MainMenu;
    const menuReady = menuZig.initMenu(&game);
    // TODO: if needed start game only after the menu when player pressed `Play`
    const gameReady = playingZig.startGame(&game, isEmscripten);
    return menuReady and gameReady;
}

fn updateRatio() void {
    if (rl.isWindowFullscreen()) {
        game.width = rl.getMonitorWidth(rl.getCurrentMonitor());
        game.height = rl.getMonitorHeight(rl.getCurrentMonitor());
    } else {
        game.width = rl.getScreenWidth();
        game.height = rl.getScreenHeight();
    }
    game.virtualRatio = @as(f32, @floatFromInt(game.height)) / @as(f32, @floatFromInt(NATIVE_HEIGHT));
    game.nativeSizeScaled = NATIVE_CENTER.scale(game.virtualRatio);
}

pub fn update() bool {
    if (rl.windowShouldClose()) {
        return false;
    }
    if (rl.isWindowResized()) {
        const previousScale = game.virtualRatio;
        updateRatio();
        var scaleDiff = game.virtualRatio - previousScale;
        if (scaleDiff != 0) {
            if (scaleDiff < 0) {
                scaleDiff = scaleDiff * -1;
                scaleDiff = 1 / scaleDiff;
            }
            for (0..game.projectilesCount) |projectileIndex| {
                game.projectiles[projectileIndex].position = game.projectiles[projectileIndex].position.scale(scaleDiff);
            }
            for (0..game.asteroidCount) |asteroidIndex| {
                game.asteroids[asteroidIndex].physicsObject.position = game.asteroids[asteroidIndex].physicsObject.position.scale(scaleDiff);
            }
        }
        game.player.physicsObject.position = game.player.physicsObject.position.scale(scaleDiff);
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
        },
        GameState.GameOver => {
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            menuZig.drawFrame();
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
    for (game.blackHole.textures) |blackhole| {
        if (blackhole.id > 0) {
            rl.unloadTexture(blackhole);
        }
    }
    playingZig.closeGame();
}

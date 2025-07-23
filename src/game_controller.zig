const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const GameState = gameZig.GameState;

// Screen consts
const NATIVE_WIDTH = 160 * 3;
const NATIVE_HEIGHT = 90 * 3;
const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };

// Global Variables
var game: Game = .{};

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

pub fn initGame(isEmscripten: bool) bool {
    rl.initWindow(game.width, game.height, "Space Researcher");
    rl.initAudioDevice();
    updateRatio();
    game.gameState = GameState.Playing;
    return playingZig.startGame(&game, isEmscripten);
}

pub fn update() bool {
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
    if (!rl.isWindowFocused() and !game.isPaused) {
        game.isPaused = true;
    } else if (rl.isWindowFocused() and game.isPaused) {
        game.isPaused = false;
    }
    if (game.gameState == GameState.MainMenu) {
        return true;
    }
    if (game.gameState == GameState.Playing) {
        game.isPlaying = playingZig.updateFrame();
        if (game.isPlaying) {
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(rl.Color.init(20, 20, 20, 255));
            playingZig.drawFrame();
        }
    }

    return game.isPlaying;
}

pub fn closeGame() void {
    for (game.blackHole.textures) |blackhole| {
        if (blackhole.id > 0) {
            rl.unloadTexture(blackhole);
        }
    }
    playingZig.closeGame();
}

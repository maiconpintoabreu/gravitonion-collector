const rl = @import("raylib");
const rg = @import("raygui");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const menuZig = @import("menu.zig");
const GameState = gameZig.GameState;

// Screen consts
const NATIVE_WIDTH = 480;
const NATIVE_HEIGHT = 270;
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
    game.nativeSizeScaled = NATIVE_CENTER;
    game.camera.zoom = 1 * game.virtualRatio;
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

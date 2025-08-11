const rl = @import("raylib");

const constantsZig = @import("game_logic/constants.zig");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
const playingZig = @import("game_logic/playing.zig");
const menuZig = @import("menu.zig");
const GameState = gameZig.GameState;

const BACKGROUND_COLOR = rl.Color.init(20, 20, 20, 255);
// Global Variables
var game: Game = .{};
var isWeb = false;

pub fn initGame(isEmscripten: bool, isFullscreen: bool) bool {
    isWeb = isEmscripten;
    if (isFullscreen) {
        game.screen = rl.Vector2.zero();
    }
    rl.initWindow(@as(i32, @intFromFloat(game.screen.x)), @as(i32, @intFromFloat(game.screen.y)), "Space Researcher");
    rl.initAudioDevice();
    updateRatio();
    game.gameState = GameState.MainMenu;
    const menuReady = menuZig.initMenu(&game);
    game.camera.target = constantsZig.NATIVE_CENTER;
    // TODO: if needed start game only after the menu when player pressed `Play`
    const gameReady = playingZig.startGame(&game, isEmscripten);
    return menuReady and gameReady;
}

fn updateRatio() void {
    if (rl.isWindowFullscreen()) {
        if (isWeb) {
            game.screen.x = @as(f32, @floatFromInt(rl.getScreenWidth()));
            game.screen.y = @as(f32, @floatFromInt(rl.getScreenHeight()));
        } else {
            game.screen.x = @as(f32, @floatFromInt(rl.getRenderWidth()));
            game.screen.y = @as(f32, @floatFromInt(rl.getRenderHeight()));
        }
    } else {
        game.screen.x = @as(f32, @floatFromInt(rl.getScreenWidth()));
        game.screen.y = @as(f32, @floatFromInt(rl.getScreenHeight()));
        rl.traceLog(.info, "Window: %f x %f", .{ game.screen.x, game.screen.y });
    }
    game.virtualRatio = .{
        .x = game.screen.x / @as(f32, @floatFromInt(constantsZig.NATIVE_WIDTH)),
        .y = game.screen.y / @as(f32, @floatFromInt(constantsZig.NATIVE_HEIGHT)),
    };
    if (game.virtualRatio.y < game.virtualRatio.x) {
        game.camera.zoom = 1 * game.virtualRatio.y;
    } else {
        game.camera.zoom = 1 * game.virtualRatio.x;
    }
    game.camera.offset = .{ .x = constantsZig.NATIVE_CENTER.x * game.virtualRatio.x, .y = constantsZig.NATIVE_CENTER.y * game.virtualRatio.y };
    rl.setMouseScale(1 / game.virtualRatio.x, 1 / game.virtualRatio.y);
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
    if (rl.isWindowFullscreen()) {
        updateRatio();
    }
    switch (game.gameState) {
        GameState.MainMenu => {
            menuZig.updateFrame();
            rl.beginDrawing();
            defer rl.endDrawing();
            {
                game.camera.begin();
                defer game.camera.end();
                rl.clearBackground(BACKGROUND_COLOR);
                menuZig.drawFrame();
            }
            if (game.gameState == GameState.Playing) {
                playingZig.restartGame();
            }
        },
        GameState.Playing => {
            playingZig.updateFrame();
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(BACKGROUND_COLOR);
            {
                game.camera.begin();
                defer game.camera.end();
                playingZig.drawFrame();
                menuZig.drawFrame();
            }
        },
        GameState.GameOver => {
            rl.beginDrawing();
            defer rl.endDrawing();
            rl.clearBackground(BACKGROUND_COLOR);
            {
                game.camera.begin();
                defer game.camera.end();
                menuZig.drawFrame();
            }
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

            {
                game.camera.begin();
                defer game.camera.end();
                rl.clearBackground(BACKGROUND_COLOR);
                playingZig.drawFrame();
                menuZig.drawFrame();
            }
        },
        else => {
            return false;
        },
    }

    return true;
}

pub fn closeGame() void {
    rl.closeAudioDevice();
    playingZig.closeGame();
    menuZig.closeMenu();
}

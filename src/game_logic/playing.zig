const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rl = @import("raylib");

const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const playerZig = @import("player.zig");
const Player = playerZig.Player;
const projectileZig = @import("projectile.zig");
const Projectile = projectileZig.Projectile;
const asteroidZig = @import("asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const gameZig = @import("../game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;
const GameControllerType = gameZig.GameControllerType;
const rand = std.crypto.random;

const shaderVersion = if (builtin.cpu.arch.isWasm()) "100" else "330";

pub fn startGame(game: *Game) rl.RaylibError!bool {
    try game.init();
    game.music = try rl.loadMusicStream("resources/ambient.mp3");
    game.destruction = try rl.loadSound("resources/destruction.wav");
    rl.setSoundVolume(game.destruction, 0.1);
    game.blackHole.blackholeincreasing = try rl.loadSound("resources/blackholeincreasing.mp3");
    game.blackHole.blackholeShader = try rl.loadShader(
        rl.textFormat("resources/shaders%s/blackhole.vs", .{shaderVersion}),
        rl.textFormat("resources/shaders%s/blackhole.fs", .{shaderVersion}),
    );
    game.blackHole.blackholePhaserShader = try rl.loadShader(
        null,
        rl.textFormat("resources/shaders%s/phaser.fs", .{shaderVersion}),
    );
    game.blackHole.resolutionLoc = rl.getShaderLocation(game.blackHole.blackholeShader, "resolution");
    game.blackHole.timeLoc = rl.getShaderLocation(game.blackHole.blackholeShader, "time");
    game.blackHole.radiusLoc = rl.getShaderLocation(game.blackHole.blackholeShader, "radius");
    game.blackHole.speedLoc = rl.getShaderLocation(game.blackHole.blackholeShader, "speed");
    game.blackHole.timePhaserLoc = rl.getShaderLocation(game.blackHole.blackholePhaserShader, "time");
    const blackholeImage = rl.genImageColor(configZig.NATIVE_WIDTH, configZig.NATIVE_HEIGHT, .white);
    game.blackHole.blackholeTexture = try blackholeImage.toTexture();
    blackholeImage.unload();
    rl.setShaderValue(game.blackHole.blackholeShader, game.blackHole.resolutionLoc, &game.screen, .vec2);
    const radius: f32 = 2.0;
    rl.setShaderValue(game.blackHole.blackholeShader, game.blackHole.radiusLoc, &radius, .float);

    // Start with one asteroid
    game.spawnAsteroidRandom();
    restartGame(game);
    return true;
}

pub fn restartGame(game: *Game) void {
    game.currentScore = 0;
    game.gameTime = 0;
    if (rl.isMusicValid(game.music)) {
        rl.stopMusicStream(game.music);
        rl.playMusicStream(game.music);
    }

    game.blackHole.setSize(0.6);
    game.blackHole.isPhasing = false;
    game.isPlaying = false;

    game.player.isAlive = true;
    game.player.health = 100.0;
    game.player.teleport(
        rl.Vector2{
            .x = 50,
            .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the blackhole
        },
        0.0,
    );

    PhysicsZig.getPhysicsSystem().reset(PhysicsZig.PhysicsBodyTagEnum.PlayerBullet);
    PhysicsZig.getPhysicsSystem().reset(PhysicsZig.PhysicsBodyTagEnum.Asteroid);
    for (&game.asteroids) |*asteroid| {
        asteroid.isAlive = false;
    }
    for (&game.player.bullets) |*bullets| {
        bullets.isAlive = false;
    }
    PhysicsZig.getPhysicsSystem().disableBody(game.blackHole.phaserPhysicsId);
    game.player.updateSlots(game.player.body);
}
pub fn closeGame(game: *Game) void {
    game.unload();
    if (rl.isMusicValid(game.music)) game.music.unload();
    if (rl.isSoundValid(game.destruction)) game.destruction.unload();
    if (rl.isSoundValid(game.blackHole.blackholeincreasing)) game.blackHole.blackholeincreasing.unload();

    if (game.blackHole.blackholeTexture.id > 0) {
        game.blackHole.blackholeTexture.unload();
    }
    if (game.blackHole.blackholeShader.id > 0) {
        game.blackHole.blackholeShader.unload();
    }
    if (game.blackHole.blackholePhaserShader.id > 0) {
        game.blackHole.blackholePhaserShader.unload();
    }
}
fn gameOver(game: *Game) void {
    if (game.highestScore < game.currentScore) {
        game.highestScore = game.currentScore;
    }
    game.gameState = GameState.GameOver;
}
pub fn updateFrame(game: *Game) void {
    if (rl.isKeyReleased(rl.KeyboardKey.escape)) {
        game.gameState = GameState.Pause;
    }
    rl.updateMusicStream(game.music);
    // Only change to keyboard if Touchscreen
    if (game.gameControllerType == GameControllerType.TouchScreen and rl.getKeyPressed() != .null) {
        game.gameControllerType = GameControllerType.Keyboard;
        if (!game.isPlaying) {
            game.isPlaying = true;
        }
    }
    if (!game.isPlaying and rl.getKeyPressed() != .null) {
        game.isPlaying = true;
    }

    if (game.gameState == GameState.Playing and game.isPlaying) {
        // Tick
        const delta = rl.getFrameTime();
        game.gameTime += @as(f64, delta);
        game.currentScore += 20 / game.blackHole.size * delta; // TODO: add distance on calculation
        game.asteroidSpawnCd -= delta;
        game.blackHole.setSize(game.blackHole.size + 0.05 * delta);
        game.player.shootingCd -= delta;
        const reducedTime = @as(f32, @floatCast(game.gameTime / 2));

        rl.setShaderValue(game.blackHole.blackholeShader, game.blackHole.timeLoc, &reducedTime, .float);
        rl.setShaderValue(game.blackHole.blackholePhaserShader, game.blackHole.timePhaserLoc, &reducedTime, .float);

        const rotationSpeed: f32 = game.blackHole.speed;
        rl.setShaderValue(game.blackHole.blackholeShader, game.blackHole.speedLoc, &rotationSpeed, .float);
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = rl.math.clamp(configZig.DEFAULT_ASTEROID_CD - game.blackHole.size * 2.0, 0.2, 100);
            game.spawnAsteroidRandom();
        }
        // Input
        if (rl.isKeyDown(.space) or rl.isGamepadButtonDown(0, .right_face_down) or game.isShooting) {
            if (game.player.shootingCd < 0) {
                game.player.shootingCd = configZig.DEFAULT_SHOOTING_CD;
                game.player.shotBullet();
            }
        }
        const gamepadSide = rl.getGamepadAxisMovement(0, .left_x);
        if (gamepadSide < -0.01) {
            rl.traceLog(.info, "left", .{});
            game.player.isTurningLeft = true;
            game.player.turnLeft(gamepadSide * delta);
        } else if (gamepadSide > 0.01) {
            rl.traceLog(.info, "right", .{});
            game.player.isTurningRight = true;
            game.player.turnRight(gamepadSide * delta);
        } else {
            if (rl.isKeyDown(.left) or rl.isGamepadButtonDown(0, .left_face_left) or game.isTouchLeft) {
                game.player.isTurningLeft = true;
                game.player.turnLeft(delta);
            } else {
                game.player.isTurningLeft = false;
            }
            if (rl.isKeyDown(.right) or rl.isGamepadButtonDown(0, .left_face_right) or game.isTouchRight) {
                game.player.isTurningRight = true;
                game.player.turnRight(delta);
            } else {
                game.player.isTurningRight = false;
            }
        }

        const gamepadAceleration = rl.getGamepadAxisMovement(0, .right_trigger);
        if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
            game.player.isAccelerating = true;
            if (builtin.cpu.arch.isWasm()) {
                game.player.accelerate(delta);
            } else {
                game.player.accelerate(gamepadAceleration * delta);
            }
        } else if (rl.isKeyDown(.up) or game.isTouchUp) {
            game.player.isAccelerating = true;
            game.player.accelerate(delta);
        } else {
            game.player.isAccelerating = false;
        }

        game.currentTickLength += delta;
        while (game.currentTickLength > configZig.PHYSICS_TICK_SPEED) {
            game.currentTickLength -= configZig.PHYSICS_TICK_SPEED;
            const gravityScale: f32 = if (game.blackHole.isDisturbed) 100.0 else 0.4;
            PhysicsZig.getPhysicsSystem().tick(configZig.PHYSICS_TICK_SPEED, gravityScale);

            game.tick(delta);

            game.blackHole.tick(delta);

            for (&game.player.bullets) |*bullet| {
                bullet.tick();
            }

            game.player.tick();

            if (game.player.health <= 0.00) {
                gameOver(game);
                return;
            }
        }
    }
}
pub fn drawFrame(game: *Game) void {
    {
        game.blackHole.blackholeShader.activate();
        defer game.blackHole.blackholeShader.deactivate();
        game.blackHole.blackholeTexture.draw(
            0,
            0,
            .white,
        );
    }
    if (game.isPlaying) {
        game.blackHole.blackholePhaserShader.activate();
        defer game.blackHole.blackholePhaserShader.deactivate();
        game.blackHole.draw();
    }
    rl.drawCircleV(
        configZig.NATIVE_CENTER,
        game.blackHole.finalSize,
        if (game.blackHole.isDisturbed) .red else .black,
    );
    {
        // rl.beginBlendMode(.additive);
        // defer rl.endBlendMode();
        for (game.player.bullets) |projectile| {
            if (projectile.body.enabled) {
                const rotation: f32 = math.radiansToDegrees(projectile.body.orient);
                projectile.texture.drawPro(
                    .{
                        .x = 0,
                        .y = 0,
                        .width = @as(f32, @floatFromInt(projectile.texture.width)),
                        .height = @as(f32, @floatFromInt(projectile.texture.height)),
                    },
                    .{
                        .x = projectile.body.position.x,
                        .y = projectile.body.position.y,
                        .width = @as(f32, @floatFromInt(projectile.texture.width)) / 2,
                        .height = @as(f32, @floatFromInt(projectile.texture.height)) / 4,
                    },
                    .{
                        .x = @as(f32, @floatFromInt(projectile.texture.width)) / 4,
                        .y = @as(f32, @floatFromInt(projectile.texture.height)) / 4,
                    },
                    rotation,
                    .white,
                );
            }
        }
    }

    for (game.asteroids) |asteroid| {
        if (asteroid.isAlive) asteroid.draw();
    }
    PhysicsZig.getPhysicsSystem().debug();
    game.player.draw();

    if (configZig.IS_DEBUG) {
        rl.drawCircleLinesV(game.blackHole.collisionpoints[0], 1, .yellow);
        rl.drawCircleLinesV(game.blackHole.collisionpoints[1], 1, .yellow);
        rl.drawCircleLinesV(game.blackHole.collisionpoints[2], 1, .yellow);
        rl.drawCircleLinesV(game.blackHole.collisionpoints[3], 1, .yellow);
    }
}

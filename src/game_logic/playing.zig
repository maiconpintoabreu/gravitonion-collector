const std = @import("std");
const builtin = @import("builtin");
const math = std.math;
const rl = @import("raylib");

const configZig = @import("../config.zig");
const PhysicsSystem = @import("physics.zig").PhysicsSystem;
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

var gameTime: f64 = 0.1;
// Audios
var music: rl.Music = std.mem.zeroes(rl.Music);
var destruction: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeShader: rl.Shader = std.mem.zeroes(rl.Shader);
var blackholePhaserShader: rl.Shader = std.mem.zeroes(rl.Shader);
var blackholeTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// For shader TODO: move it inside blackhole
var resolutionLoc: i32 = 0;
var timeLoc: i32 = 0;
var radiusLoc: i32 = 0;
var speedLoc: i32 = 0;

// For Phaser Shader
var timePhaserLoc: i32 = 0;

var game: *Game = undefined;
var physiscsSystem: PhysicsSystem = .{};

pub fn startGame(currentGame: *Game) rl.RaylibError!bool {
    game = currentGame;

    try game.init();
    music = try rl.loadMusicStream("resources/ambient.mp3");
    destruction = try rl.loadSound("resources/destruction.wav");
    rl.setSoundVolume(destruction, 0.1);
    blackholeincreasing = try rl.loadSound("resources/blackholeincreasing.mp3");
    blackholeShader = try rl.loadShader(
        rl.textFormat("resources/shaders%s/blackhole.vs", .{shaderVersion}),
        rl.textFormat("resources/shaders%s/blackhole.fs", .{shaderVersion}),
    );
    blackholePhaserShader = try rl.loadShader(
        null,
        rl.textFormat("resources/shaders%s/phaser.fs", .{shaderVersion}),
    );
    resolutionLoc = rl.getShaderLocation(blackholeShader, "resolution");
    timeLoc = rl.getShaderLocation(blackholeShader, "time");
    radiusLoc = rl.getShaderLocation(blackholeShader, "radius");
    speedLoc = rl.getShaderLocation(blackholeShader, "speed");
    timePhaserLoc = rl.getShaderLocation(blackholePhaserShader, "time");
    const blackholeImage = rl.genImageColor(configZig.NATIVE_WIDTH, configZig.NATIVE_HEIGHT, .white);
    blackholeTexture = try blackholeImage.toTexture();
    blackholeImage.unload();
    rl.setShaderValue(blackholeShader, resolutionLoc, &game.screen, .vec2);
    const radius: f32 = 2.0;
    rl.setShaderValue(blackholeShader, radiusLoc, &radius, .float);

    // Start with one asteroid
    game.spawnAsteroidRandom();
    restartGame();
    return true;
}

pub fn restartGame() void {
    game.currentScore = 0;
    gameTime = 0;
    game.asteroidCount = 0;
    physiscsSystem.physicsBodyCount = 10;
    if (rl.isMusicValid(music)) {
        rl.stopMusicStream(music);
        rl.playMusicStream(music);
    }

    game.blackHole.setSize(0.6);
    game.blackHole.isPhasing = false;
    game.blackHole.rotation = 0;
    game.isPlaying = false;

    game.player.bulletsCount = 0;
    game.player.physicsObject = .{
        .rotationSpeed = 200,
        .position = rl.Vector2{
            .x = 50,
            .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the blackhole
        },
        .speed = 0.1,
    };
    game.player.updateSlots();
}
pub fn closeGame() void {
    game.unload();
    if (rl.isMusicValid(music)) music.unload();
    if (rl.isSoundValid(destruction)) destruction.unload();
    if (rl.isSoundValid(blackholeincreasing)) blackholeincreasing.unload();

    if (blackholeTexture.id > 0) {
        blackholeTexture.unload();
    }
    if (blackholeShader.id > 0) {
        blackholeShader.unload();
    }
    if (blackholePhaserShader.id > 0) {
        blackholePhaserShader.unload();
    }
}
fn gameOver() void {
    if (game.highestScore < game.currentScore) {
        game.highestScore = game.currentScore;
    }
    game.gameState = GameState.GameOver;
}
pub fn updateFrame() void {
    if (rl.isKeyReleased(rl.KeyboardKey.escape)) {
        game.gameState = GameState.Pause;
    }
    rl.updateMusicStream(music);
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
        physiscsSystem.tick(delta, configZig.NATIVE_CENTER);
        gameTime += @as(f64, delta);
        game.currentScore += 20 / game.player.physicsObject.position.distance(configZig.NATIVE_CENTER) * game.blackHole.size * delta;
        game.asteroidSpawnCd -= delta;
        game.blackHole.setSize(game.blackHole.size + 0.05 * delta);
        game.player.shootingCd -= delta;
        game.blackHole.tick(delta);
        const reducedTime = @as(f32, @floatCast(gameTime / 2));

        rl.setShaderValue(blackholeShader, timeLoc, &reducedTime, .float);
        rl.setShaderValue(blackholePhaserShader, timePhaserLoc, &reducedTime, .float);

        const rotationSpeed: f32 = game.blackHole.speed;
        rl.setShaderValue(blackholeShader, speedLoc, &rotationSpeed, .float);
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
            game.player.physicsObject.isTurningLeft = true;
            game.player.physicsObject.applyTorque(gamepadSide * delta);
        } else if (gamepadSide > 0.01) {
            rl.traceLog(.info, "right", .{});
            game.player.physicsObject.isTurningRight = true;
            game.player.physicsObject.applyTorque(gamepadSide * delta);
        } else {
            if (rl.isKeyDown(.left) or rl.isGamepadButtonDown(0, .left_face_left) or game.isTouchLeft) {
                game.player.physicsObject.isTurningLeft = true;
                game.player.physicsObject.applyTorque(-1 * delta);
            } else {
                game.player.physicsObject.isTurningLeft = false;
            }
            if (rl.isKeyDown(.right) or rl.isGamepadButtonDown(0, .left_face_right) or game.isTouchRight) {
                game.player.physicsObject.isTurningRight = true;
                game.player.physicsObject.applyTorque(1 * delta);
            } else {
                game.player.physicsObject.isTurningRight = false;
            }
        }

        const gamepadAceleration = rl.getGamepadAxisMovement(0, .right_trigger);
        if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
            game.player.physicsObject.isAccelerating = true;
            if (builtin.cpu.arch.isWasm()) {
                game.player.physicsObject.applyForce(1 * delta);
            } else {
                game.player.physicsObject.applyForce(gamepadAceleration * delta);
            }
        } else if (rl.isKeyDown(.up) or game.isTouchUp) {
            game.player.physicsObject.isAccelerating = true;
            game.player.physicsObject.applyForce(1 * delta);
        } else {
            game.player.physicsObject.isAccelerating = false;
        }

        game.currentTickLength += delta;
        while (game.currentTickLength > configZig.PHYSICS_TICK_SPEED) {
            game.currentTickLength -= configZig.PHYSICS_TICK_SPEED;
            const direction = rl.Vector2.subtract(configZig.NATIVE_CENTER, game.player.physicsObject.position).normalize();
            const gravityScale: f32 = if (game.blackHole.isDisturbed) 5.0 else 1.0;
            game.blackHole.isDisturbed = false;
            const gravity = (game.blackHole.finalSize / 20) * gravityScale * configZig.PHYSICS_TICK_SPEED;
            if (!game.player.physicsObject.isAccelerating) {
                game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, gravity / 4));
            }
            game.player.tick();
            if (rl.checkCollisionCircles(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                configZig.NATIVE_CENTER,
                game.blackHole.finalSize,
            )) {
                gameOver();
                return;
            }

            game.blackHole.collisionpoints[0] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = -5 });
            game.blackHole.collisionpoints[1] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = 5 });
            game.blackHole.collisionpoints[2] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = -5 });
            game.blackHole.collisionpoints[3] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 5 });

            game.blackHole.collisionpoints[0] = configZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[0].subtract(configZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[1] = configZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[1].subtract(configZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[2] = configZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[2].subtract(configZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[3] = configZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[3].subtract(configZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            var centerPoint = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 0 });
            centerPoint = configZig.NATIVE_CENTER.add(centerPoint.subtract(configZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.player.physicsObject.calculateWrap(.{
                .x = 0,
                .y = 0,
                .width = configZig.NATIVE_WIDTH,
                .height = configZig.NATIVE_HEIGHT,
            });

            // phaser against player
            if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                configZig.NATIVE_CENTER,
                centerPoint,
            ) or rl.checkCollisionCircleLine(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                game.blackHole.collisionpoints[0],
                game.blackHole.collisionpoints[2],
            ) or rl.checkCollisionCircleLine(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                game.blackHole.collisionpoints[1],
                game.blackHole.collisionpoints[1],
            ))) {
                gameOver();
                return;
            }

            for (0..game.player.bulletsCount) |projectileIndex| {
                game.player.bullets[projectileIndex].tick(configZig.PHYSICS_TICK_SPEED);
                const projectilePosition = game.player.bullets[projectileIndex].position;
                if (projectilePosition.x < 0 or projectilePosition.x > configZig.NATIVE_WIDTH) {
                    game.player.removeBullet(projectileIndex);
                    continue;
                }
                if (projectilePosition.y < 0 or projectilePosition.y > configZig.NATIVE_HEIGHT) {
                    game.player.removeBullet(projectileIndex);
                    continue;
                }
                if (rl.checkCollisionCircles(
                    configZig.NATIVE_CENTER,
                    game.blackHole.finalSize,
                    projectilePosition,
                    game.player.bullets[projectileIndex].size,
                )) {
                    game.blackHole.setSize(game.blackHole.size + 0.03);
                    game.player.removeBullet(projectileIndex);
                    continue;
                }

                if (game.blackHole.isPhasing and (rl.checkCollisionPointTriangle(
                    projectilePosition,
                    game.blackHole.collisionpoints[0],
                    game.blackHole.collisionpoints[1],
                    game.blackHole.collisionpoints[2],
                ) or rl.checkCollisionPointTriangle(
                    projectilePosition,
                    game.blackHole.collisionpoints[3],
                    game.blackHole.collisionpoints[2],
                    game.blackHole.collisionpoints[1],
                ))) {
                    game.player.removeBullet(projectileIndex);
                    continue;
                }

                for (0..game.asteroidCount) |asteroidIndex| {
                    if (rl.checkCollisionCircles(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize,
                        projectilePosition,
                        game.player.bullets[projectileIndex].size,
                    )) {
                        game.player.removeBullet(projectileIndex);
                        game.removeAsteroid(asteroidIndex);
                        rl.playSound(destruction);
                    }
                }
            }
            for (0..game.asteroidCount) |asteroidIndex| {
                const asteroidDirection = rl.Vector2.subtract(configZig.NATIVE_CENTER, game.asteroids[asteroidIndex].physicsObject.position).normalize();
                game.asteroids[asteroidIndex].physicsObject.applyDirectedForce(rl.Vector2.scale(asteroidDirection, gravity));
                game.asteroids[asteroidIndex].tick();
                if (rl.checkCollisionCircles(
                    configZig.NATIVE_CENTER,
                    game.blackHole.finalSize,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                )) {
                    game.removeAsteroid(asteroidIndex);
                    game.blackHole.setSize(game.blackHole.size + 0.5);
                    game.blackHole.isDisturbed = true;
                    rl.playSound(blackholeincreasing);
                    continue;
                }

                if (rl.checkCollisionCircles(
                    game.player.physicsObject.position,
                    game.player.physicsObject.collisionSize,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                )) {
                    game.removeAsteroid(asteroidIndex);
                    gameOver();
                }

                // phaser against player
                if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                    configZig.NATIVE_CENTER,
                    centerPoint,
                ) or rl.checkCollisionCircleLine(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                    game.blackHole.collisionpoints[0],
                    game.blackHole.collisionpoints[2],
                ) or rl.checkCollisionCircleLine(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                    game.blackHole.collisionpoints[1],
                    game.blackHole.collisionpoints[1],
                ))) {
                    game.removeAsteroid(asteroidIndex);
                    continue;
                }
            }
        }
    }
}
pub fn drawFrame() void {
    // Use the shader to draw a rectangle that covers the whole screen
    {
        blackholeShader.activate();
        defer blackholeShader.deactivate();
        blackholeTexture.draw(
            0,
            0,
            .white,
        );
    }
    if (configZig.IS_DEBUG) {
        rl.drawCircleV(game.blackHole.collisionpoints[0], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[1], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[2], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[3], 5, .yellow);
    }
    if (game.blackHole.isPhasing) {
        {
            blackholePhaserShader.activate();
            defer blackholePhaserShader.deactivate();
            game.blackHole.phaserTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(game.blackHole.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(game.blackHole.phaserTexture.height)),
                },
                .{
                    .x = game.blackHole.collisionpoints[0].x,
                    .y = game.blackHole.collisionpoints[0].y,
                    .width = @as(f32, @floatFromInt(game.blackHole.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(game.blackHole.phaserTexture.height)),
                },
                .{ .x = 0, .y = 0 },
                game.blackHole.rotation,
                .white,
            );
        }
    } else {
        if (game.isPlaying) {
            rl.drawLineEx(
                game.blackHole.collisionpoints[0],
                game.blackHole.collisionpoints[2],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
            rl.drawLineEx(
                game.blackHole.collisionpoints[3],
                game.blackHole.collisionpoints[1],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
        }
    }

    rl.drawCircleV(
        configZig.NATIVE_CENTER,
        game.blackHole.finalSize,
        if (game.blackHole.isDisturbed) .red else .black,
    );
    {
        rl.beginBlendMode(.additive);
        defer rl.endBlendMode();
        for (0..game.player.bulletsCount) |projectileIndex| {
            const projectile: Projectile = game.player.bullets[projectileIndex];
            game.player.bullets[projectileIndex].texture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(projectile.texture.width)),
                    .height = @as(f32, @floatFromInt(projectile.texture.height)),
                },
                .{
                    .x = projectile.position.x,
                    .y = projectile.position.y,
                    .width = @as(f32, @floatFromInt(projectile.texture.width)) / 2,
                    .height = @as(f32, @floatFromInt(projectile.texture.height)) / 2,
                },
                .{
                    .x = @as(f32, @floatFromInt(projectile.texture.width)) / 4,
                    .y = @as(f32, @floatFromInt(projectile.texture.height)) / 4,
                },
                game.player.bullets[projectileIndex].rotation,
                .white,
            );
            if (configZig.IS_DEBUG) {
                rl.drawCircleV(
                    game.player.bullets[projectileIndex].position,
                    game.player.bullets[projectileIndex].size,
                    .yellow,
                );
            }
        }
    }

    for (0..game.asteroidCount) |asteroidIndex| {
        if (configZig.IS_DEBUG) {
            rl.drawCircleV(
                game.asteroids[asteroidIndex].physicsObject.position,
                game.asteroids[asteroidIndex].physicsObject.collisionSize,
                .yellow,
            );
        }
        game.asteroids[asteroidIndex].draw();
    }
    game.player.draw();
}

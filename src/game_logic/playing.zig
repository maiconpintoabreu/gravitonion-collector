const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const playerZig = @import("player.zig");
const Player = playerZig.Player;
const projectileZig = @import("projectile.zig");
const Projectile = projectileZig.Projectile;
const asteroidZig = @import("asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const gameZig = @import("../game.zig");
const Game = gameZig.Game;
const GameState = gameZig.GameState;
const rand = std.crypto.random;
const IS_DEBUG = false;

var gameTime: f64 = 0;
var isWeb: bool = false;
// Audios
var music: rl.Music = std.mem.zeroes(rl.Music);
var shoot: rl.Sound = std.mem.zeroes(rl.Sound);
var destruction: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeShader: rl.Shader = std.mem.zeroes(rl.Shader);
var blackholeTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Textures
var asteroidTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var bulletTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Game Consts
const DEFAULT_ASTEROID_CD = 5;
const DEFAULT_SHOOTING_CD = 0.1;
const PHYSICS_TICK_SPEED = 0.02;
const MAX_PARTICLES = 2048;

const BLACKHOLE_MASS = 1500.0;
const GRAVITATIONAL_CONST = 0.1;

// For shader
var timeLoc: i32 = 0;
var speedLoc: i32 = 0;

var game: *Game = undefined;

pub fn startGame(currentGame: *Game, isEmscripten: bool) bool {
    game = currentGame;
    // TODO: check why the trigger does not work well
    isWeb = isEmscripten;
    music = rl.loadMusicStream("resources/ambient.mp3") catch |err| switch (err) {
        rl.RaylibError.LoadAudioStream => {
            std.debug.print("LoadAudioStream ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    shoot = rl.loadSound("resources/shoot.wav") catch |err| switch (err) {
        rl.RaylibError.LoadSound => {
            std.debug.print("LoadSound Shoot ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    rl.setSoundVolume(shoot, 0.1);
    destruction = rl.loadSound("resources/destruction.wav") catch |err| switch (err) {
        rl.RaylibError.LoadSound => {
            std.debug.print("LoadSound destruction ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    rl.setSoundVolume(destruction, 0.1);
    blackholeincreasing = rl.loadSound("resources/blackholeincreasing.mp3") catch |err| switch (err) {
        rl.RaylibError.LoadSound => {
            std.debug.print("LoadSound blackholeincreasing ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    const playerTexture = rl.loadTexture("resources/ship.png") catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture ship ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    const playerTextureCenter = rl.Vector2{
        .x = @as(f32, @floatFromInt(playerTexture.width)) / 2,
        .y = @as(f32, @floatFromInt(playerTexture.height)) / 2 + 2,
    };
    const playerTextureRec = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(playerTexture.width)),
        .height = @as(f32, @floatFromInt(playerTexture.height)),
    };
    asteroidTexture = rl.loadTexture("resources/rock.png") catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture rock ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    bulletTexture = rl.loadTexture("resources/bullet.png") catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture bullet ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    game.player = Player{
        .textureCenter = playerTextureCenter,
        .texture = playerTexture,
        .textureRec = playerTextureRec,
    };
    const bulletTextureRec = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(bulletTexture.width)),
        .height = @as(f32, @floatFromInt(bulletTexture.height)),
    };

    for (&game.projectiles) |*projectile| {
        projectile.texture = bulletTexture;
        projectile.textureRec = bulletTextureRec;
    }
    const asteroidTextureCenter = rl.Vector2{
        .x = @as(f32, @floatFromInt(playerTexture.width)) / 2,
        .y = @as(f32, @floatFromInt(playerTexture.height)) / 2 + 2,
    };
    const asteroidTextureRec = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(asteroidTexture.width)),
        .height = @as(f32, @floatFromInt(asteroidTexture.height)),
    };
    for (&game.asteroids) |*asteroid| {
        asteroid.texture = asteroidTexture;
        asteroid.textureCenter = asteroidTextureCenter;
        asteroid.textureRec = asteroidTextureRec;
    }
    const shaderVersion = if (isEmscripten) "100" else "330";
    blackholeShader = rl.loadShader(
        rl.textFormat("resources/shaders%s/blackhole.vs", .{shaderVersion}),
        rl.textFormat("resources/shaders%s/blackhole.fs", .{shaderVersion}),
    ) catch |err| switch (err) {
        rl.RaylibError.LoadShader => {
            std.debug.print("LoadShader blackhole.fs ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    timeLoc = rl.getShaderLocation(blackholeShader, "iTime");
    speedLoc = rl.getShaderLocation(blackholeShader, "speed");
    const blackholeImage = rl.genImageColor(800, 460, .white);
    blackholeTexture = rl.loadTextureFromImage(blackholeImage) catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture blackhole ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };

    // Start with one asteroid
    spawnAsteroidRandom();
    if (!game.blackHole.initTexture()) {
        return false;
    }
    restartGame();
    return true;
}

pub fn restartGame() void {
    game.currentScore = 0;
    gameTime = 0;
    // TODO: Align names later
    game.asteroidCount = 0;
    game.projectilesCount = 0;
    if (rl.isMusicValid(music)) {
        rl.stopMusicStream(music);
        rl.playMusicStream(music);
    }

    game.blackHole.setSize(0.6);
    game.blackHole.isPhasing = false;

    game.player.physicsObject = .{
        .rotationSpeed = 200,
        .position = rl.Vector2{ .x = 20, .y = 20 },
        .speed = 0.1,
    };
}
pub fn closeGame() void {
    if (rl.isMusicValid(music)) rl.unloadMusicStream(music);
    if (rl.isSoundValid(shoot)) rl.unloadSound(shoot);
    if (rl.isSoundValid(destruction)) rl.unloadSound(destruction);
    if (rl.isSoundValid(blackholeincreasing)) rl.unloadSound(blackholeincreasing);

    game.player.unload();
    if (bulletTexture.id > 0) {
        rl.unloadTexture(bulletTexture);
    }
    if (blackholeTexture.id > 0) {
        rl.unloadTexture(blackholeTexture);
    }
    if (asteroidTexture.id > 0) {
        rl.unloadTexture(asteroidTexture);
    }
    if (blackholeShader.id > 0) {
        rl.unloadShader(blackholeShader);
    }
}
fn playerShot() void {
    if (game.projectilesCount + 1 == gameZig.MAX_PROJECTILES) {
        return;
    }
    const direction: rl.Vector2 = .{
        .x = math.sin(math.degreesToRadians(game.player.physicsObject.rotation)),
        .y = -math.cos(math.degreesToRadians(game.player.physicsObject.rotation)),
    };
    const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
    game.projectiles[game.projectilesCount].position = game.player.physicsObject.position;
    game.projectiles[game.projectilesCount].rotation = game.player.physicsObject.rotation;
    game.projectiles[game.projectilesCount].direction = norm_vector;
    game.projectiles[game.projectilesCount].speed = 20;
    game.projectiles[game.projectilesCount].size = 1;
    game.projectilesCount += 1;
    rl.playSound(shoot);
}
fn removeProjectile(index: usize) void {
    if (game.projectilesCount == 0) return;
    game.projectiles[index] = game.projectiles[game.projectilesCount - 1];
    game.projectilesCount -= 1;
}
fn removeAsteroid(index: usize) void {
    game.asteroids[index] = game.asteroids[game.asteroidCount - 1];
    game.asteroidCount -= 1;
}
fn spawnAsteroidRandom() void {
    if (game.asteroidCount == gameZig.MAX_ASTEROIDS) {
        return;
    }
    if (rand.boolean()) {
        if (rand.boolean()) {
            game.asteroids[game.asteroidCount].physicsObject.position.x = 0;
        } else {
            game.asteroids[game.asteroidCount].physicsObject.position.x = @as(f32, @floatFromInt(game.width)) / game.camera.zoom;
        }
        game.asteroids[game.asteroidCount].physicsObject.position.y = rand.float(f32) * @as(f32, @floatFromInt(game.height)) / game.camera.zoom;
    } else {
        if (rand.boolean()) {
            game.asteroids[game.asteroidCount].physicsObject.position.y = 0;
        } else {
            game.asteroids[game.asteroidCount].physicsObject.position.y = @as(f32, @floatFromInt(game.height)) / game.camera.zoom;
        }
        game.asteroids[game.asteroidCount].physicsObject.position.x = rand.float(f32) * @as(f32, @floatFromInt(game.width)) / game.camera.zoom;
    }
    game.asteroids[game.asteroidCount].physicsObject.velocity = rl.Vector2.clampValue(
        game.asteroids[game.asteroidCount].physicsObject.velocity,
        0,
        0.2,
    );
    game.asteroids[game.asteroidCount].physicsObject.collisionSize = 5;
    game.asteroidCount += 1;
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

    if (game.gameState == GameState.Playing) {
        // Tick
        const delta = rl.getFrameTime();
        gameTime += @as(f64, delta);
        game.currentScore += 20 / game.player.physicsObject.position.distance(game.nativeSizeScaled) * delta;
        game.asteroidSpawnCd -= delta;
        game.shootingCd -= delta;
        game.blackHole.tick(delta);
        const reducedTime = @as(f32, @floatCast(gameTime / 10));
        const reducedTime2 = @as(f32, @floatCast(gameTime / 2));

        rl.setShaderValue(blackholeShader, timeLoc, &reducedTime2, .float);
        rl.setShaderValue(blackholeShader, speedLoc, &game.blackHole.size, .float);
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = rl.math.clamp(DEFAULT_ASTEROID_CD - reducedTime, 0.2, 100);
            spawnAsteroidRandom();
        }
        // Input
        if (rl.isKeyDown(.space) or rl.isGamepadButtonDown(0, .right_face_down) or game.isShooting) {
            if (game.shootingCd < 0) {
                game.shootingCd = DEFAULT_SHOOTING_CD;
                playerShot();
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
        // TODO: check this if web
        if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
            game.player.physicsObject.isAccelerating = true;
            if (isWeb) {
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
        while (game.currentTickLength > PHYSICS_TICK_SPEED) {
            game.currentTickLength -= PHYSICS_TICK_SPEED;
            const direction = rl.Vector2.subtract(game.nativeSizeScaled, game.player.physicsObject.position).normalize();
            const gravity = (game.blackHole.finalSize / 20) * PHYSICS_TICK_SPEED;
            if (!game.player.physicsObject.isAccelerating) {
                game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, gravity));
            }
            game.player.tick();
            if (rl.checkCollisionCircles(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                game.nativeSizeScaled,
                game.blackHole.finalSize,
            )) {
                gameOver();
                return;
            }

            game.blackHole.collisionpoints[0] = game.nativeSizeScaled.add(.{ .x = 0, .y = -5 * game.virtualRatio.y });
            game.blackHole.collisionpoints[1] = game.nativeSizeScaled.add(.{ .x = 0, .y = 5 * game.virtualRatio.y });
            game.blackHole.collisionpoints[2] = game.nativeSizeScaled.add(.{ .x = 1000 * game.virtualRatio.y, .y = -5 * game.virtualRatio.y });
            game.blackHole.collisionpoints[3] = game.nativeSizeScaled.add(.{ .x = 1000 * game.virtualRatio.y, .y = 5 * game.virtualRatio.y });

            game.blackHole.collisionpoints[0] = game.nativeSizeScaled.add(game.blackHole.collisionpoints[0].subtract(game.nativeSizeScaled).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[1] = game.nativeSizeScaled.add(game.blackHole.collisionpoints[1].subtract(game.nativeSizeScaled).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[2] = game.nativeSizeScaled.add(game.blackHole.collisionpoints[2].subtract(game.nativeSizeScaled).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[3] = game.nativeSizeScaled.add(game.blackHole.collisionpoints[3].subtract(game.nativeSizeScaled).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            var centerPoint = game.nativeSizeScaled.add(.{ .x = 1000 * game.virtualRatio.y, .y = 0 });
            centerPoint = game.nativeSizeScaled.add(centerPoint.subtract(game.nativeSizeScaled).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));

            game.player.physicsObject.calculateWrap(.{
                .x = 0,
                .y = 0,
                .width = @as(f32, @floatFromInt(game.width)) / game.camera.zoom,
                .height = @as(f32, @floatFromInt(game.height)) / game.camera.zoom,
            });

            // phaser against player
            if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                game.nativeSizeScaled,
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

            for (0..game.projectilesCount) |projectileIndex| {
                game.projectiles[projectileIndex].tick(PHYSICS_TICK_SPEED);
                const projectilePosition = game.projectiles[projectileIndex].position;
                if (projectilePosition.x < 0 or projectilePosition.x > @as(f32, @floatFromInt(game.width))) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (projectilePosition.y < 0 or projectilePosition.y > @as(f32, @floatFromInt(game.height))) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (rl.checkCollisionCircles(
                    game.nativeSizeScaled,
                    game.blackHole.finalSize,
                    projectilePosition,
                    game.projectiles[projectileIndex].size * game.virtualRatio.y,
                )) {
                    removeProjectile(projectileIndex);
                    continue;
                }

                if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                    projectilePosition,
                    game.projectiles[projectileIndex].size,
                    game.nativeSizeScaled,
                    centerPoint,
                ) or rl.checkCollisionCircleLine(
                    projectilePosition,
                    game.projectiles[projectileIndex].size,
                    game.blackHole.collisionpoints[0],
                    game.blackHole.collisionpoints[2],
                ) or rl.checkCollisionCircleLine(
                    projectilePosition,
                    game.projectiles[projectileIndex].size,
                    game.blackHole.collisionpoints[1],
                    game.blackHole.collisionpoints[1],
                ))) {
                    removeProjectile(projectileIndex);
                    continue;
                }

                for (0..game.asteroidCount) |asteroidIndex| {
                    if (rl.checkCollisionCircles(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize,
                        projectilePosition,
                        game.projectiles[projectileIndex].size * game.virtualRatio.y,
                    )) {
                        removeProjectile(projectileIndex);
                        removeAsteroid(asteroidIndex);
                        rl.playSound(destruction);
                    }
                }
            }
            for (0..game.asteroidCount) |asteroidIndex| {
                const asteroidDirection = rl.Vector2.subtract(game.nativeSizeScaled, game.asteroids[asteroidIndex].physicsObject.position).normalize();
                game.asteroids[asteroidIndex].physicsObject.applyDirectedForce(rl.Vector2.scale(asteroidDirection, gravity));
                game.asteroids[asteroidIndex].tick();
                if (rl.checkCollisionCircles(
                    game.nativeSizeScaled,
                    game.blackHole.finalSize,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                )) {
                    removeAsteroid(asteroidIndex);
                    game.blackHole.setSize(game.blackHole.size + 0.1);
                    rl.playSound(blackholeincreasing);
                    continue;
                }

                // if (game.blackHole.isPhasing and rl.checkCollisionCircleLine(
                //     game.asteroids[asteroidIndex].physicsObject.position,
                //     game.asteroids[asteroidIndex].physicsObject.collisionSize * 30,
                //     game.nativeSizeScaled,
                //     game.nativeSizeScaled.add(blackholePhaserDirection.scale(100)),
                // )) {
                //     removeProjectile(asteroidIndex);
                //     continue;
                // }

                if (rl.checkCollisionCircles(
                    game.player.physicsObject.position,
                    game.player.physicsObject.collisionSize,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                )) {
                    removeAsteroid(asteroidIndex);
                    gameOver();
                }

                // phaser against player
                if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                    game.nativeSizeScaled,
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
                    removeAsteroid(asteroidIndex);
                    continue;
                }
            }
        }
    }
}
pub fn drawFrame() void {
    rl.beginMode2D(game.camera);
    defer rl.endMode2D();

    // Use the shader to draw a rectangle that covers the whole screen

    rl.beginShaderMode(blackholeShader);
    const textPosition = game.camera.target.subtract(game.camera.offset);
    blackholeTexture.draw(@as(i32, @intFromFloat(textPosition.x)), @as(i32, @intFromFloat(textPosition.y)), .white);
    rl.endShaderMode();

    // const blackHoleTexture = game.blackHole.textures[game.blackHole.currentFrame];
    // blackHoleTexture.drawPro(
    //     rl.Rectangle{
    //         .x = 0,
    //         .y = 0,
    //         .width = @as(f32, @floatFromInt(blackHoleTexture.width)),
    //         .height = @as(f32, @floatFromInt(blackHoleTexture.height)),
    //     },
    //     rl.Rectangle{
    //         .x = game.nativeSizeScaled.x + (2),
    //         .y = game.nativeSizeScaled.y + (-1),
    //         .width = @as(f32, @floatFromInt(blackHoleTexture.width)) * game.blackHole.size,
    //         .height = @as(f32, @floatFromInt(blackHoleTexture.height)) * game.blackHole.size,
    //     },
    //     game.blackHole.origin.scale(game.blackHole.size),
    //     0,
    //     .white,
    // );
    if (IS_DEBUG) {
        rl.drawCircleV(game.blackHole.collisionpoints[0], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[1], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[2], 5, .yellow);
        rl.drawCircleV(game.blackHole.collisionpoints[3], 5, .yellow);
    }
    if (game.blackHole.isPhasing) {
        rl.drawTriangle(
            game.blackHole.collisionpoints[0],
            game.blackHole.collisionpoints[1],
            game.blackHole.collisionpoints[2],
            .white,
        );
        rl.drawTriangle(
            game.blackHole.collisionpoints[3],
            game.blackHole.collisionpoints[2],
            game.blackHole.collisionpoints[1],
            .white,
        );
    } else {
        rl.drawLineEx(
            game.blackHole.collisionpoints[0],
            game.blackHole.collisionpoints[2],
            1,
            .{ .r = 0, .g = 0, .b = 0, .a = 150 },
        );
        rl.drawLineEx(
            game.blackHole.collisionpoints[3],
            game.blackHole.collisionpoints[1],
            1,
            .{ .r = 0, .g = 0, .b = 0, .a = 150 },
        );
    }

    rl.drawCircleV(
        game.nativeSizeScaled,
        game.blackHole.finalSize,
        .black,
    );
    {
        rl.beginBlendMode(.additive);
        defer rl.endBlendMode();
        for (0..game.projectilesCount) |projectileIndex| {
            game.projectiles[projectileIndex].draw();
            // if (IS_DEBUG) {
            rl.drawCircleV(
                game.projectiles[projectileIndex].position,
                game.projectiles[projectileIndex].size,
                .{ .r = 0, .g = 100, .b = 100, .a = 100 },
            );
            // }
        }
    }

    for (0..game.asteroidCount) |asteroidIndex| {
        if (IS_DEBUG) {
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

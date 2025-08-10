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
const GameControllerType = gameZig.GameControllerType;
const rand = std.crypto.random;
const IS_DEBUG = false;

var gameTime: f64 = 0.1;
var isWeb: bool = false;
// Audios
var music: rl.Music = std.mem.zeroes(rl.Music);
var shoot: rl.Sound = std.mem.zeroes(rl.Sound);
var destruction: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeShader: rl.Shader = std.mem.zeroes(rl.Shader);
var blackholePhaserShader: rl.Shader = std.mem.zeroes(rl.Shader);
var blackholeTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Textures
var asteroidTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var bulletTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Game Consts
const DEFAULT_ASTEROID_CD = 5;
const DEFAULT_SHOOTING_CD = 0.1;
const PHYSICS_TICK_SPEED = 0.02;

// For shader
var resolutionLoc: i32 = 0;
var timeLoc: i32 = 0;
var radiusLoc: i32 = 0;
var speedLoc: i32 = 0;

// For Phaser Shader
var timePhaserLoc: i32 = 0;

var game: *Game = undefined;

pub fn startGame(currentGame: *Game, isEmscripten: bool) bool {
    game = currentGame;
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
    blackholePhaserShader = rl.loadShader(
        null,
        rl.textFormat("resources/shaders%s/phaser.fs", .{shaderVersion}),
    ) catch |err| switch (err) {
        rl.RaylibError.LoadShader => {
            std.debug.print("LoadShader phaser.fs ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    resolutionLoc = rl.getShaderLocation(blackholeShader, "resolution");
    timeLoc = rl.getShaderLocation(blackholeShader, "time");
    radiusLoc = rl.getShaderLocation(blackholeShader, "radius");
    speedLoc = rl.getShaderLocation(blackholeShader, "speed");
    timePhaserLoc = rl.getShaderLocation(blackholePhaserShader, "time");
    const blackholeImage = rl.genImageColor(gameZig.NATIVE_WIDTH, gameZig.NATIVE_HEIGHT, .white);
    blackholeTexture = blackholeImage.toTexture() catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture blackhole ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };

    rl.setShaderValue(blackholeShader, resolutionLoc, &game.screen, .vec2);
    const radius: f32 = 2.0;
    rl.setShaderValue(blackholeShader, radiusLoc, &radius, .float);

    // Start with one asteroid
    spawnAsteroidRandom();
    if (!game.blackHole.init()) {
        return false;
    }
    restartGame();
    return true;
}

pub fn restartGame() void {
    game.currentScore = 0;
    gameTime = 0;
    game.asteroidCount = 0;
    game.projectilesCount = 0;
    if (rl.isMusicValid(music)) {
        rl.stopMusicStream(music);
        rl.playMusicStream(music);
    }

    game.blackHole.setSize(0.6);
    game.blackHole.isPhasing = false;
    game.blackHole.rotation = 0;
    game.isPlaying = false;

    game.player.physicsObject = .{
        .rotationSpeed = 200,
        .position = rl.Vector2{
            .x = 50,
            .y = gameZig.NATIVE_HEIGHT / 2, // Put the player beside the blackhole
        },
        .speed = 0.1,
    };
    game.player.tick();
}
pub fn closeGame() void {
    if (rl.isMusicValid(music)) music.unload();
    if (rl.isSoundValid(shoot)) shoot.unload();
    if (rl.isSoundValid(destruction)) destruction.unload();
    if (rl.isSoundValid(blackholeincreasing)) blackholeincreasing.unload();

    game.player.unload();
    if (bulletTexture.id > 0) {
        bulletTexture.unload();
    }
    if (blackholeTexture.id > 0) {
        blackholeTexture.unload();
    }
    if (game.blackHole.phaserTexture.id > 0) {
        game.blackHole.phaserTexture.unload();
    }
    if (asteroidTexture.id > 0) {
        asteroidTexture.unload();
    }
    if (blackholeShader.id > 0) {
        blackholeShader.unload();
    }
    if (blackholePhaserShader.id > 0) {
        blackholePhaserShader.unload();
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
    const norm_vector: rl.Vector2 = direction.normalize();
    game.projectiles[game.projectilesCount].position = game.player.gunSlot;
    game.projectiles[game.projectilesCount].rotation = game.player.physicsObject.rotation;
    game.projectiles[game.projectilesCount].direction = norm_vector;
    game.projectiles[game.projectilesCount].speed = 5;
    game.projectiles[game.projectilesCount].size = 3;
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
            game.asteroids[game.asteroidCount].physicsObject.position.x = gameZig.NATIVE_WIDTH;
        }
        game.asteroids[game.asteroidCount].physicsObject.position.y = rand.float(f32) * gameZig.NATIVE_HEIGHT;
    } else {
        if (rand.boolean()) {
            game.asteroids[game.asteroidCount].physicsObject.position.y = 0;
        } else {
            game.asteroids[game.asteroidCount].physicsObject.position.y = gameZig.NATIVE_HEIGHT;
        }
        game.asteroids[game.asteroidCount].physicsObject.position.x = rand.float(f32) * gameZig.NATIVE_WIDTH;
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
        gameTime += @as(f64, delta);
        game.currentScore += 20 / game.player.physicsObject.position.distance(gameZig.NATIVE_CENTER) * game.blackHole.size * delta;
        game.asteroidSpawnCd -= delta;
        game.blackHole.setSize(game.blackHole.size + 0.05 * delta);
        game.shootingCd -= delta;
        game.blackHole.tick(delta);
        const reducedTime = @as(f32, @floatCast(gameTime / 2));

        rl.setShaderValue(blackholeShader, timeLoc, &reducedTime, .float);
        rl.setShaderValue(blackholePhaserShader, timePhaserLoc, &reducedTime, .float);

        const rotationSpeed: f32 = if (game.blackHole.isRotatingRight) game.blackHole.size * -1 else game.blackHole.size;
        rl.setShaderValue(blackholeShader, speedLoc, &rotationSpeed, .float);
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = rl.math.clamp(DEFAULT_ASTEROID_CD - game.blackHole.size * 1.2, 0.2, 100);
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
            const direction = rl.Vector2.subtract(gameZig.NATIVE_CENTER, game.player.physicsObject.position).normalize();
            const gravityScale: f32 = if (game.blackHole.isDisturbed) 5.0 else 1.0;
            game.blackHole.isDisturbed = false;
            const gravity = (game.blackHole.finalSize / 20) * gravityScale * PHYSICS_TICK_SPEED;
            if (!game.player.physicsObject.isAccelerating) {
                game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, gravity / 4));
            }
            game.player.tick();
            if (rl.checkCollisionCircles(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                gameZig.NATIVE_CENTER,
                game.blackHole.finalSize,
            )) {
                gameOver();
                return;
            }

            game.blackHole.collisionpoints[0] = gameZig.NATIVE_CENTER.add(.{ .x = 0, .y = -5 });
            game.blackHole.collisionpoints[1] = gameZig.NATIVE_CENTER.add(.{ .x = 0, .y = 5 });
            game.blackHole.collisionpoints[2] = gameZig.NATIVE_CENTER.add(.{ .x = 1000, .y = -5 });
            game.blackHole.collisionpoints[3] = gameZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 5 });

            game.blackHole.collisionpoints[0] = gameZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[0].subtract(gameZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[1] = gameZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[1].subtract(gameZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[2] = gameZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[2].subtract(gameZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.blackHole.collisionpoints[3] = gameZig.NATIVE_CENTER.add(game.blackHole.collisionpoints[3].subtract(gameZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            var centerPoint = gameZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 0 });
            centerPoint = gameZig.NATIVE_CENTER.add(centerPoint.subtract(gameZig.NATIVE_CENTER).rotate(
                math.degreesToRadians(game.blackHole.rotation),
            ));
            game.player.physicsObject.calculateWrap(.{
                .x = 0,
                .y = 0,
                .width = gameZig.NATIVE_WIDTH,
                .height = gameZig.NATIVE_HEIGHT,
            });

            // phaser against player
            if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                gameZig.NATIVE_CENTER,
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
                if (projectilePosition.x < 0 or projectilePosition.x > gameZig.NATIVE_WIDTH) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (projectilePosition.y < 0 or projectilePosition.y > gameZig.NATIVE_HEIGHT) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (rl.checkCollisionCircles(
                    gameZig.NATIVE_CENTER,
                    game.blackHole.finalSize,
                    projectilePosition,
                    game.projectiles[projectileIndex].size,
                )) {
                    game.blackHole.setSize(game.blackHole.size + 0.03);
                    removeProjectile(projectileIndex);
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
                    removeProjectile(projectileIndex);
                    continue;
                }

                for (0..game.asteroidCount) |asteroidIndex| {
                    if (rl.checkCollisionCircles(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize,
                        projectilePosition,
                        game.projectiles[projectileIndex].size,
                    )) {
                        removeProjectile(projectileIndex);
                        removeAsteroid(asteroidIndex);
                        rl.playSound(destruction);
                    }
                }
            }
            for (0..game.asteroidCount) |asteroidIndex| {
                const asteroidDirection = rl.Vector2.subtract(gameZig.NATIVE_CENTER, game.asteroids[asteroidIndex].physicsObject.position).normalize();
                game.asteroids[asteroidIndex].physicsObject.applyDirectedForce(rl.Vector2.scale(asteroidDirection, gravity));
                game.asteroids[asteroidIndex].tick();
                if (rl.checkCollisionCircles(
                    gameZig.NATIVE_CENTER,
                    game.blackHole.finalSize,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                )) {
                    removeAsteroid(asteroidIndex);
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
                    removeAsteroid(asteroidIndex);
                    gameOver();
                }

                // phaser against player
                if (game.blackHole.isPhasing and (rl.checkCollisionCircleLine(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize,
                    gameZig.NATIVE_CENTER,
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
    if (IS_DEBUG) {
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
        gameZig.NATIVE_CENTER,
        game.blackHole.finalSize,
        if (game.blackHole.isDisturbed) .red else .black,
    );
    {
        rl.beginBlendMode(.additive);
        defer rl.endBlendMode();
        for (0..game.projectilesCount) |projectileIndex| {
            const projectile: Projectile = game.projectiles[projectileIndex];
            game.projectiles[projectileIndex].texture.drawPro(
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
                game.projectiles[projectileIndex].rotation,
                .white,
            );
            if (IS_DEBUG) {
                rl.drawCircleV(
                    game.projectiles[projectileIndex].position,
                    game.projectiles[projectileIndex].size,
                    .yellow,
                );
            }
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
    if (!game.isPlaying) {
        if (game.gameControllerType == GameControllerType.TouchScreen) {
            rl.drawText(
                "Press any where to start",
                0,
                @as(i32, @intFromFloat(game.player.physicsObject.position.y)) - 30,
                10,
                .white,
            );
        } else {
            rl.drawText(
                "Press any thing to start",
                0,
                @as(i32, @intFromFloat(game.player.physicsObject.position.y)) - 30,
                10,
                .white,
            );
        }
    }
}

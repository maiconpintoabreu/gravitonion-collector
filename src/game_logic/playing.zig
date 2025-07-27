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

var gameTime: f32 = 0;
var isWeb: bool = false;
// Audios
var music: rl.Music = std.mem.zeroes(rl.Music);
var shoot: rl.Sound = std.mem.zeroes(rl.Sound);
var destruction: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound);

// Textures
var asteroidTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var bulletTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Game Consts
const DEFAULT_ASTEROID_CD = 5;
const DEFAULT_SHOOTING_CD = 0.1;
const PHYSICS_TICK_SPEED = 0.02;

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

    // Start with one asteroid
    spawnAsteroidRandom();
    var controlImage: rl.Image = rl.genImageColor(16 * 4, 16, rl.Color.blank);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 9, .y = 2 }, rl.Vector2{ .x = 9, .y = 12 }, rl.Vector2{ .x = 4, .y = 7 }, rl.Color.white);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 16 + 7, .y = 2 }, rl.Vector2{ .x = 16 + 16 - 4, .y = 7 }, rl.Vector2{ .x = 16 + 7, .y = 12 }, rl.Color.white);
    rl.imageDrawTriangle(&controlImage, rl.Vector2{ .x = 32 + 8, .y = 5 }, rl.Vector2{ .x = 32 + 13, .y = 10 }, rl.Vector2{ .x = 32 + 3, .y = 10 }, rl.Color.white);
    rl.imageDrawText(&controlImage, "x", 48 + 3, -3, 20, rl.Color.white);
    controlTexture = rl.loadTextureFromImage(controlImage) catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture controller ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    if (!game.blackHole.initTexture()) {
        return false;
    }
    rl.unloadImage(controlImage);
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

    game.player.physicsObject = .{
        .rotationSpeed = 200,
        .position = rl.Vector2{ .x = 20 * game.virtualRatio, .y = 20 * game.virtualRatio },
        .speed = 0.1,
    };
}
fn uiButtomIcon(buttom: rl.Vector2, buttomSize: f32, icon: f32) bool {
    rl.drawCircleV(buttom, buttomSize, rl.Color.gray);
    const buttomEdge = rl.Vector2{ .x = buttom.x - buttomSize / 2, .y = buttom.y - buttomSize / 2 };
    rl.drawTexturePro(controlTexture, rl.Rectangle{ .x = 16 * icon, .y = 0, .width = 16, .height = 16 }, .{ .x = buttomEdge.x, .y = buttomEdge.y, .width = buttomSize, .height = buttomSize }, rl.Vector2.zero(), 0, rl.Color.white);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointCircle(rl.getMousePosition(), buttom, buttomSize)) {
        return true;
    }
    const touchCount = @as(usize, @intCast(rl.getTouchPointCount()));
    for (0..touchCount) |touchIndex| {
        if (rl.checkCollisionPointCircle(rl.getTouchPosition(@intCast(touchIndex)), buttom, buttomSize)) {
            return true;
        }
    }

    return false;
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
    if (asteroidTexture.id > 0) {
        rl.unloadTexture(asteroidTexture);
    }
    if (controlTexture.id > 0) {
        rl.unloadTexture(controlTexture);
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
    game.projectiles[index] = game.projectiles[game.projectilesCount - 1];
    game.projectilesCount -= 1;
}
fn removeAsteroid(index: usize) void {
    game.asteroids[index] = game.asteroids[game.asteroidCount - 1];
    game.asteroidCount -= 1;
}
fn spawnAsteroidRandom() void {
    if (rand.boolean()) {
        if (rand.boolean()) {
            game.asteroids[game.asteroidCount].physicsObject.position.x = 0;
        } else {
            game.asteroids[game.asteroidCount].physicsObject.position.x = @as(f32, @floatFromInt(game.width));
        }
        game.asteroids[game.asteroidCount].physicsObject.position.y = rand.float(f32) * @as(f32, @floatFromInt(game.height));
    } else {
        if (rand.boolean()) {
            game.asteroids[game.asteroidCount].physicsObject.position.y = 0;
        } else {
            game.asteroids[game.asteroidCount].physicsObject.position.y = @as(f32, @floatFromInt(game.height));
        }
        game.asteroids[game.asteroidCount].physicsObject.position.x = rand.float(f32) * @as(f32, @floatFromInt(game.width));
    }
    game.asteroids[game.asteroidCount].physicsObject.velocity = rl.Vector2.clampValue(
        game.asteroids[game.asteroidCount].physicsObject.velocity,
        0,
        0.2,
    );
    game.asteroids[game.asteroidCount].physicsObject.collisionSize = 5;
    game.asteroidCount += 1;
}
pub fn updateFrame() void {
    // End Debug
    if (rl.isKeyReleased(rl.KeyboardKey.escape)) {
        game.gameState = GameState.Pause;
    }
    if (rl.isMusicValid(music)) {
        rl.updateMusicStream(music);
    }
    if (game.gameState == GameState.Playing) {
        // Tick
        const delta = rl.getFrameTime();
        gameTime += delta;
        game.currentScore += 20 / game.player.physicsObject.position.distance(game.nativeSizeScaled) * delta;
        game.asteroidSpawnCd -= delta;
        game.shootingCd -= delta;
        game.blackHole.tick(delta);
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = rl.math.clamp(DEFAULT_ASTEROID_CD - gameTime / 10, 0.2, 100);
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
            const gravity = (game.blackHole.finalSize * game.virtualRatio / 20) * PHYSICS_TICK_SPEED;
            if (!game.player.physicsObject.isAccelerating) {
                game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, gravity));
            }
            game.player.tick();
            if (rl.checkCollisionCircles(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize * game.virtualRatio,
                game.nativeSizeScaled,
                game.blackHole.finalSize * game.virtualRatio,
            )) {
                if (game.highestScore < game.currentScore) {
                    game.highestScore = game.currentScore;
                }
                game.gameState = GameState.GameOver;
                return;
            }

            game.player.physicsObject.calculateWrap(game.width, game.height);

            for (0..game.projectilesCount) |projectileIndex| {
                game.projectiles[projectileIndex].tick(PHYSICS_TICK_SPEED);
                const particlePosition = game.projectiles[projectileIndex].position;
                if (particlePosition.x < 0 or particlePosition.x > @as(f32, @floatFromInt(game.width))) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (particlePosition.y < 0 or particlePosition.y > @as(f32, @floatFromInt(game.height))) {
                    removeProjectile(projectileIndex);
                    continue;
                }
                if (rl.checkCollisionCircles(
                    game.nativeSizeScaled,
                    game.blackHole.finalSize * game.virtualRatio,
                    particlePosition,
                    game.projectiles[projectileIndex].size * game.virtualRatio,
                )) {
                    removeProjectile(projectileIndex);
                    continue;
                }

                for (0..game.asteroidCount) |asteroidIndex| {
                    if (rl.checkCollisionCircleLine(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                        particlePosition,
                        game.projectiles[projectileIndex].previousPosition,
                    )) {}
                    if (rl.checkCollisionCircles(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                        particlePosition,
                        game.projectiles[projectileIndex].size * game.virtualRatio,
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
                    game.blackHole.finalSize * game.virtualRatio,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                )) {
                    removeAsteroid(asteroidIndex);
                    game.blackHole.setSize(game.blackHole.size + 0.5);
                    rl.playSound(blackholeincreasing);
                } else if (rl.checkCollisionCircles(
                    game.player.physicsObject.position,
                    game.player.physicsObject.collisionSize * game.virtualRatio,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                )) {
                    removeAsteroid(asteroidIndex);
                }
            }
        }
    }
}
pub fn drawFrame() void {
    const blackHoleTexture = game.blackHole.textures[game.blackHole.currentFrame];
    blackHoleTexture.drawPro(
        rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(blackHoleTexture.width)),
            .height = @as(f32, @floatFromInt(blackHoleTexture.height)),
        },
        rl.Rectangle{
            .x = game.nativeSizeScaled.x + (2 * game.virtualRatio),
            .y = game.nativeSizeScaled.y + (-1 * game.virtualRatio),
            .width = @as(f32, @floatFromInt(blackHoleTexture.width)) * game.blackHole.size * game.virtualRatio,
            .height = @as(f32, @floatFromInt(blackHoleTexture.height)) * game.blackHole.size * game.virtualRatio,
        },
        game.blackHole.origin.scale(game.blackHole.size).scale(game.virtualRatio),
        0,
        .white,
    );
    if (IS_DEBUG) {
        rl.drawCircleV(
            game.nativeSizeScaled,
            game.blackHole.finalSize * game.virtualRatio,
            .{ .r = 0, .g = 100, .b = 100, .a = 100 },
        );
    }
    {
        rl.beginBlendMode(.additive);
        defer rl.endBlendMode();
        for (0..game.projectilesCount) |projectileIndex| {
            game.projectiles[projectileIndex].draw(game.virtualRatio);
            // if (IS_DEBUG) {
            rl.drawCircleV(
                game.projectiles[projectileIndex].position,
                game.projectiles[projectileIndex].size * game.virtualRatio,
                .{ .r = 0, .g = 100, .b = 100, .a = 100 },
            );
            // }
        }
    }

    for (0..game.asteroidCount) |asteroidIndex| {
        if (IS_DEBUG) {
            rl.drawCircleV(
                game.asteroids[asteroidIndex].physicsObject.position,
                game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                .yellow,
            );
        }
        game.asteroids[asteroidIndex].draw(game.virtualRatio);
    }
    // rl.drawCircleV(
    //     game.player.physicsObject.position.add(game.player.physicsObject.direction.normalize().scale(-10 * game.virtualRatio)),
    //     2 * game.virtualRatio,
    //     .yellow,
    // );
    game.player.draw(game.virtualRatio);
    // UI
    if (!rl.isGamepadAvailable(0)) {
        if (uiButtomIcon(
            .{
                .x = 40 * game.virtualRatio,
                .y = (@as(f32, @floatFromInt(game.height)) - 50 * game.virtualRatio),
            },
            30 * game.virtualRatio,
            0,
        )) {
            game.isTouchLeft = true;
        } else {
            game.isTouchLeft = false;
        }
        if (uiButtomIcon(
            .{
                .x = (100 + 30) * game.virtualRatio,
                .y = (@as(f32, @floatFromInt(game.height)) - 50 * game.virtualRatio),
            },
            30 * game.virtualRatio,
            1,
        )) {
            game.isTouchRight = true;
        } else {
            game.isTouchRight = false;
        }
        if (uiButtomIcon(
            .{
                .x = (@as(f32, @floatFromInt(game.width)) - 30) - 30 * game.virtualRatio,
                .y = (@as(f32, @floatFromInt(game.height)) - 50 * game.virtualRatio),
            },
            30 * game.virtualRatio,
            2,
        )) {
            game.isTouchUp = true;
        } else {
            game.isTouchUp = false;
        }
        if (uiButtomIcon(
            .{
                .x = (@as(f32, @floatFromInt(game.width)) - 30) - 30 * game.virtualRatio,
                .y = (@as(f32, @floatFromInt(game.height)) - 120 * game.virtualRatio),
            },
            30 * game.virtualRatio,
            3,
        )) {
            game.isShooting = true;
        } else {
            game.isShooting = false;
        }
    }
    const fontSize = 15 * @as(i32, @intFromFloat(game.virtualRatio));
    rl.drawText(
        rl.textFormat("Score: %3.2f", .{game.currentScore}),
        @as(i32, @intFromFloat(game.nativeSizeScaled.x)) - fontSize,
        fontSize,
        fontSize,
        .white,
    );
    rl.drawFPS(10, 10);
    // Start Debug
    if (IS_DEBUG) {
        rl.drawText(rl.textFormat("--------------DEBUG--------------", .{}), 10, 20 + fontSize, fontSize, .white);
        rl.drawText(rl.textFormat("game.Projectiles: %i", .{game.projectilesCount}), 10, 20 + fontSize * 2, fontSize, .white);
        rl.drawText(rl.textFormat("game.ASteroids: %i", .{game.asteroidCount}), 10, 20 + fontSize * 3, fontSize, .white);
    }
}

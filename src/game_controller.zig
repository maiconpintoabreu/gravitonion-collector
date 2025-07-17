const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const playerZig = @import("player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const rand = std.crypto.random;
const IS_DEBUG = false;

// Global Variables
var game: Game = .{};
var music: rl.Music = std.mem.zeroes(rl.Music);
var shoot: rl.Sound = std.mem.zeroes(rl.Sound);
var destruction: rl.Sound = std.mem.zeroes(rl.Sound);
var blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound);
var projectiles: [MAX_PROJECTILES]Projectile = std.mem.zeroes([MAX_PROJECTILES]Projectile);
var asteroidTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);
var projectilesCount: usize = 0;

// Screen consts
const NATIVE_WIDTH = 160 * 3;
const NATIVE_HEIGHT = 90 * 3;
const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };

// Game Costs
const BLACK_HOLE_SPRINTE_COUNT = 11;
const BLACK_HOLE_FRAME_SPEED: f32 = 0.3;
const MAX_ASTEROIDS = 100;
const DEFAULT_ASTEROID_CD = 5;
const DEFAULT_SHOOTING_CD = 0.1;
const PHYSICS_TICK_SPEED = 0.02;
const BLACK_HOLE_SCALE = 20;

const MAX_PROJECTILES = 1000;
const MAX_PROJECTILE_TAIL_SIZE = 3;

// Game Structs
const Projectile = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    oldPositions: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    size: f32 = 10,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    speed: f32 = 20,

    fn tick(self: *Projectile, delta: f32) void {
        self.oldPositions = self.position;
        self.position = self.position.add(self.direction.scale(self.speed * delta));
    }
};
const BlackHole = struct {
    size: f32 = 0.6,
    finalSize: f32 = 0.6 * BLACK_HOLE_SCALE,
    resizeCD: f32 = 2,
    frameTimer: f32 = BLACK_HOLE_FRAME_SPEED,
    currentFrame: usize = 0,
    textures: [BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D = std.mem.zeroes([BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D),
    origin: rl.Vector2 = std.mem.zeroes(rl.Vector2),
};

const Game = struct {
    player: Player = .{},
    blackHole: BlackHole = .{},
    asteroids: [MAX_ASTEROIDS]Asteroid = std.mem.zeroes([MAX_ASTEROIDS]Asteroid),
    virtualRatio: f32 = 1,
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    width: i32 = 800,
    height: i32 = 460,
    asteroidAmount: usize = 0,
    asteroidSpawnCd: f32 = DEFAULT_ASTEROID_CD,
    shootingCd: f32 = DEFAULT_SHOOTING_CD,
    currentTickLength: f32 = 0.0,
    isPlaying: bool = false,
    isPaused: bool = false,
    isTouchLeft: bool = false,
    isTouchRight: bool = false,
    isTouchUp: bool = false,
    isShooting: bool = false,
    currentScore: f32 = 0,
    highestScore: f32 = 0,
};

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

pub fn startGame() bool {
    rl.initWindow(game.width, game.height, "Space Researcher");
    rl.initAudioDevice();
    game.isPlaying = true;
    updateRatio();
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
    game.player = Player{
        .textureCenter = playerTextureCenter,
        .texture = playerTexture,
        .textureRec = playerTextureRec,
    };
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
    for (0..BLACK_HOLE_SPRINTE_COUNT) |blackholeIndex| {
        const indexPlus: usize = blackholeIndex + 1;
        game.blackHole.textures[blackholeIndex] = rl.loadTexture(rl.textFormat(
            "resources/blackhole/black_hole%i.png",
            .{indexPlus},
        )) catch |err| switch (err) {
            rl.RaylibError.LoadTexture => {
                std.debug.print(
                    "LoadTexture blackhole ERROR",
                    .{},
                );
                return false;
            },
            else => {
                std.debug.print("ERROR", .{});
                return false;
            },
        };
    }
    // Set orgin of blackhole
    game.blackHole.origin = rl.Vector2{
        .x = @as(f32, @floatFromInt(game.blackHole.textures[0].width)) / 2,
        .y = @as(f32, @floatFromInt(game.blackHole.textures[0].height)) / 2,
    };

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
    rl.unloadImage(controlImage);
    restartGame();
    return true;
}

fn restartGame() void {
    game.currentScore = 0;
    // TODO: Align names later
    game.asteroidAmount = 0;
    projectilesCount = 0;
    if (rl.isMusicValid(music)) {
        rl.stopMusicStream(music);
        rl.playMusicStream(music);
    }

    game.player.physicsObject = .{
        .rotationSpeed = 200,
        .position = rl.Vector2{ .x = 20 * game.virtualRatio, .y = 20 * game.virtualRatio },
        .speed = 0.1,
        .isFacingMovement = false,
    };
}
fn uiButtomIcon(buttom: rl.Vector2, buttomSize: f32, icon: f32) bool {
    rl.drawCircleV(buttom, buttomSize, rl.Color.gray);
    const buttomEdge = rl.Vector2{ .x = buttom.x - buttomSize / 2, .y = buttom.y - buttomSize / 2 };
    rl.drawTexturePro(controlTexture, rl.Rectangle{ .x = 16 * icon, .y = 0, .width = 16, .height = 16 }, .{ .x = buttomEdge.x, .y = buttomEdge.y, .width = buttomSize, .height = buttomSize }, rl.Vector2.zero(), 0, rl.Color.white);
    if (rl.isMouseButtonDown(.left) and rl.checkCollisionPointCircle(rl.getMousePosition(), buttom, buttomSize)) {
        return true;
    }

    for (0..@as(usize, @intCast(rl.getTouchPointCount()))) |touchIndex| {
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

    rl.closeAudioDevice();
    game.player.unload();
    if (asteroidTexture.id > 0) {
        rl.unloadTexture(asteroidTexture);
    }
    if (controlTexture.id > 0) {
        rl.unloadTexture(controlTexture);
    }

    for (0..BLACK_HOLE_SPRINTE_COUNT) |blackholeIndex| {
        if (game.blackHole.textures[blackholeIndex].id > 0) {
            rl.unloadTexture(game.blackHole.textures[blackholeIndex]);
        }
    }
}
fn playerShot() void {
    if (projectilesCount + 1 == MAX_PROJECTILES) {
        return;
    }
    const direction: rl.Vector2 = .{
        .x = math.sin(math.degreesToRadians(game.player.physicsObject.rotation)),
        .y = -math.cos(math.degreesToRadians(game.player.physicsObject.rotation)),
    };
    const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
    projectiles[projectilesCount].position = game.player.physicsObject.position;
    projectiles[projectilesCount].oldPositions = game.player.physicsObject.position;
    projectiles[projectilesCount].direction = norm_vector;
    projectiles[projectilesCount].speed = 1000;
    projectiles[projectilesCount].size = 1;
    projectilesCount += 1;
    rl.playSound(shoot);
}
fn removeProjectile(index: usize) void {
    projectiles[index] = projectiles[projectilesCount - 1];
    projectilesCount -= 1;
}
fn removeAsteroid(index: usize) void {
    game.asteroids[index] = game.asteroids[game.asteroidAmount - 1];
    game.asteroidAmount -= 1;
}
fn spawnAsteroidRandom() void {
    if (rand.boolean()) {
        if (rand.boolean()) {
            game.asteroids[game.asteroidAmount].physicsObject.position.x = 0;
        } else {
            game.asteroids[game.asteroidAmount].physicsObject.position.x = @as(f32, @floatFromInt(game.width));
        }
        game.asteroids[game.asteroidAmount].physicsObject.position.y = rand.float(f32) * @as(f32, @floatFromInt(game.height));
    } else {
        if (rand.boolean()) {
            game.asteroids[game.asteroidAmount].physicsObject.position.y = 0;
        } else {
            game.asteroids[game.asteroidAmount].physicsObject.position.y = @as(f32, @floatFromInt(game.height));
        }
        game.asteroids[game.asteroidAmount].physicsObject.position.x = rand.float(f32) * @as(f32, @floatFromInt(game.width));
    }
    game.asteroids[game.asteroidAmount].physicsObject.velocity = rl.Vector2.clampValue(
        game.asteroids[game.asteroidAmount].physicsObject.velocity,
        0,
        0.2,
    );
    game.asteroids[game.asteroidAmount].physicsObject.collisionSize = 5;
    game.asteroidAmount += 1;
}
pub fn updateFrame() bool {
    if (rl.isWindowResized()) {
        const previousScale = game.virtualRatio;
        updateRatio();
        var scaleDiff = game.virtualRatio - previousScale;
        if (scaleDiff != 0) {
            if (scaleDiff < 0) {
                scaleDiff = scaleDiff * -1;
                scaleDiff = 1 / scaleDiff;
            }
            for (0..projectilesCount) |projectileIndex| {
                projectiles[projectileIndex].position = projectiles[projectileIndex].position.scale(scaleDiff);
                projectiles[projectileIndex].oldPositions = projectiles[projectileIndex].oldPositions.scale(scaleDiff);
            }
            for (0..game.asteroidAmount) |asteroidIndex| {
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

    if (rl.isMusicValid(music)) {
        rl.updateMusicStream(music);
    }
    if (!game.isPaused) {
        // Tick
        const delta = rl.getFrameTime();
        game.asteroidSpawnCd -= delta;
        game.shootingCd -= delta;
        game.blackHole.frameTimer -= delta;
        if (game.blackHole.frameTimer <= 0) {
            game.blackHole.currentFrame += 1;
            game.blackHole.frameTimer = BLACK_HOLE_FRAME_SPEED;
            if (game.blackHole.currentFrame == BLACK_HOLE_SPRINTE_COUNT) {
                game.blackHole.currentFrame = 0;
            }
        }
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = DEFAULT_ASTEROID_CD;
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
        rl.traceLog(.info, "%f", .{gamepadSide});
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
            game.player.physicsObject.applyForce(gamepadAceleration * delta);
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
            game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, 0.1 * game.blackHole.finalSize * game.virtualRatio / 10 * delta));
            game.player.tick();

            game.player.physicsObject.calculateWrap(game.width, game.height);

            for (0..projectilesCount) |projectileIndex| {
                projectiles[projectileIndex].tick(delta);
                const particlePosition = projectiles[projectileIndex].position;
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
                    projectiles[projectileIndex].size * game.virtualRatio,
                )) {
                    removeProjectile(projectileIndex);
                    continue;
                }

                for (0..game.asteroidAmount) |asteroidIndex| {
                    if (rl.checkCollisionCircles(
                        game.asteroids[asteroidIndex].physicsObject.position,
                        game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                        particlePosition,
                        projectiles[projectileIndex].size * game.virtualRatio,
                    )) {
                        removeProjectile(projectileIndex);
                        removeAsteroid(asteroidIndex);
                        rl.playSound(destruction);
                    }
                }
            }
            for (0..game.asteroidAmount) |asteroidIndex| {
                const asteroidDirection = rl.Vector2.subtract(game.nativeSizeScaled, game.asteroids[asteroidIndex].physicsObject.position).normalize();
                game.asteroids[asteroidIndex].physicsObject.applyDirectedForce(rl.Vector2.scale(asteroidDirection, 0.5 * game.blackHole.finalSize * game.virtualRatio / 10 * delta));
                game.asteroids[asteroidIndex].tick();
                if (rl.checkCollisionCircles(
                    game.nativeSizeScaled,
                    game.blackHole.finalSize * game.virtualRatio,
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                )) {
                    removeAsteroid(asteroidIndex);
                    game.blackHole.size += 0.05;
                    game.blackHole.finalSize = game.blackHole.size * BLACK_HOLE_SCALE;
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
    {
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(rl.Color.init(20, 20, 20, 255));

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
            for (0..projectilesCount) |projectileIndex| {
                rl.drawCircleV(projectiles[projectileIndex].position, projectiles[projectileIndex].size * game.virtualRatio, .white);
                rl.drawLineV(
                    projectiles[projectileIndex].position,
                    projectiles[projectileIndex].oldPositions,
                    .white,
                );
            }
        }
        for (0..game.asteroidAmount) |asteroidIndex| {
            if (IS_DEBUG) {
                rl.drawCircleV(
                    game.asteroids[asteroidIndex].physicsObject.position,
                    game.asteroids[asteroidIndex].physicsObject.collisionSize * game.virtualRatio,
                    .yellow,
                );
            }
            game.asteroids[asteroidIndex].draw(game.virtualRatio);
        }
        rl.drawCircleV(
            game.player.physicsObject.position.add(game.player.physicsObject.direction.normalize().scale(-10 * game.virtualRatio)),
            2 * game.virtualRatio,
            .yellow,
        );
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
        // Start Debug
        rl.drawFPS(10, 10);
        rl.drawText(rl.textFormat("------------------------------", .{}), 10, 30, 10, .white);
        rl.drawText(rl.textFormat("Projectiles: %i", .{projectilesCount}), 10, 40, 10, .white);
        rl.drawText(rl.textFormat("ASteroids: %i", .{game.asteroidAmount}), 10, 50, 10, .white);
    }
    // End Debug
    if (rl.isKeyDown(rl.KeyboardKey.escape) or rl.windowShouldClose()) {
        game.isPlaying = false;
    }
    return game.isPlaying;
}

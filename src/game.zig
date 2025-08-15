const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;

const configZig = @import("config.zig");
const playerZig = @import("game_logic/player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("game_logic/asteroid.zig");
const Asteroid = asteroidZig.Asteroid;

pub const GameState = enum {
    MainMenu,
    Playing,
    GameOver,
    Pause,
    Quit,
};

pub const GameControllerType = enum {
    Keyboard,
    Joystick,
    TouchScreen,
};

const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;
const BLACK_HOLE_SIZE_PHASER_ACTIVE = 1.5;

const BLACK_DEFAULT_SIZE = 0.6;
const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_PHASER_ROTATION_SPEED: f32 = 20;
const BLACK_HOLE_PHASER_MAX_ROTATION: f32 = 360.0;

const BlackHole = struct {
    size: f32 = BLACK_DEFAULT_SIZE,
    finalSize: f32 = BLACK_DEFAULT_SIZE * BLACK_HOLE_SCALE,
    speed: f32 = BLACK_DEFAULT_SIZE,
    phasersCD: f32 = BLACK_HOLE_PHASER_CD,
    phasersMinDuration: f32 = BLACK_HOLE_PHASER_MIN_DURATION,
    isPhasing: bool = false,
    isDisturbed: bool = false,
    rotation: f32 = 0,
    isRotatingRight: bool = false,
    phaserTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    collisionpoints: [BLACK_HOLE_COLLISION_POINTS]rl.Vector2 = std.mem.zeroes([BLACK_HOLE_COLLISION_POINTS]rl.Vector2),
    pub fn tick(self: *BlackHole, delta: f32) void {
        self.phasersCD -= delta;
        if (self.isRotatingRight) {
            self.rotation -= BLACK_HOLE_PHASER_ROTATION_SPEED * delta;
        } else {
            self.rotation += BLACK_HOLE_PHASER_ROTATION_SPEED * delta;
        }
        if (self.rotation < 0) {
            self.rotation += BLACK_HOLE_PHASER_MAX_ROTATION;
        } else if (self.rotation > BLACK_HOLE_PHASER_MAX_ROTATION) {
            self.rotation -= BLACK_HOLE_PHASER_MAX_ROTATION;
        }
        if (self.isPhasing) {
            const tempSize = self.size - delta;
            if (tempSize < BLACK_DEFAULT_SIZE) {
                self.setSize(BLACK_DEFAULT_SIZE);
                self.isPhasing = false;
            } else {
                self.setSize(self.size - (0.1 / (BLACK_DEFAULT_SIZE / self.size) * delta));
            }
        }
        if ((self.size > BLACK_HOLE_SIZE_PHASER_ACTIVE) and !self.isPhasing) {
            self.phasersCD = BLACK_HOLE_PHASER_CD;
            self.phasersMinDuration = BLACK_HOLE_PHASER_MIN_DURATION;
            self.isPhasing = true;
            self.isRotatingRight = rand.boolean();
        }
        self.speed = rl.math.lerp(
            self.speed,
            if (self.isRotatingRight) self.size * -1 else self.size,
            0.5,
        );
    }
    pub fn init(self: *BlackHole) rl.RaylibError!void {
        if (self.phaserTexture.id > 0) {
            return;
        }
        // Init Phaser
        const phaserImage = rl.Image.genColor(256 * 2, 10, .blank);
        self.phaserTexture = try phaserImage.toTexture();
        phaserImage.unload();
        rl.traceLog(.info, "Blackhole init Completed", .{});
    }
    pub fn setSize(self: *BlackHole, size: f32) void {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
    }
    pub fn unload(self: *BlackHole) void {
        if (self.phaserTexture.id > 0) {
            self.phaserTexture.unload();
        }
    }
};

pub const Game = struct {
    asteroids: [configZig.MAX_ASTEROIDS]Asteroid = std.mem.zeroes([configZig.MAX_ASTEROIDS]Asteroid),
    camera: rl.Camera2D = .{
        .offset = std.mem.zeroes(rl.Vector2),
        .rotation = 0,
        .target = std.mem.zeroes(rl.Vector2),
        .zoom = 1,
    },
    player: Player = .{},
    blackHole: BlackHole = .{},
    gameState: GameState = GameState.MainMenu,
    gameControllerType: GameControllerType = GameControllerType.Keyboard,
    virtualRatio: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    screen: rl.Vector2 = .{
        .x = configZig.NATIVE_WIDTH,
        .y = configZig.NATIVE_HEIGHT,
    },
    asteroidSpawnCd: f32 = 0,
    currentTickLength: f32 = 0.0,
    isTouchLeft: bool = false,
    isTouchRight: bool = false,
    isTouchUp: bool = false,
    isShooting: bool = false,
    currentScore: f32 = 0,
    highestScore: f32 = 0,
    asteroidCount: usize = 0,
    isPlaying: bool = false,
    pub fn init(self: *Game) rl.RaylibError!void {
        // Init asteroid to reuse texture
        const asteroidTexture: rl.Texture2D = try rl.loadTexture("resources/rock.png");
        const asteroidTextureCenter = rl.Vector2{
            .x = @as(f32, @floatFromInt(asteroidTexture.width)) / 2,
            .y = @as(f32, @floatFromInt(asteroidTexture.height)) / 2 + 2,
        };
        const asteroidTextureRec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(asteroidTexture.width)),
            .height = @as(f32, @floatFromInt(asteroidTexture.height)),
        };
        for (&self.asteroids) |*asteroid| {
            asteroid.texture = asteroidTexture;
            asteroid.textureCenter = asteroidTextureCenter;
            asteroid.textureRec = asteroidTextureRec;
        }
        try self.blackHole.init();
        try self.player.init(std.mem.zeroes(rl.Vector2));
        rl.traceLog(.info, "Game init Completed", .{});
    }

    pub fn spawnAsteroidRandom(self: *Game) void {
        if (self.asteroidCount == configZig.MAX_ASTEROIDS) {
            return;
        }
        if (rand.boolean()) {
            if (rand.boolean()) {
                self.asteroids[self.asteroidCount].physicsObject.position.x = 0;
            } else {
                self.asteroids[self.asteroidCount].physicsObject.position.x = configZig.NATIVE_WIDTH;
            }
            self.asteroids[self.asteroidCount].physicsObject.position.y = rand.float(f32) * configZig.NATIVE_HEIGHT;
        } else {
            if (rand.boolean()) {
                self.asteroids[self.asteroidCount].physicsObject.position.y = 0;
            } else {
                self.asteroids[self.asteroidCount].physicsObject.position.y = configZig.NATIVE_HEIGHT;
            }
            self.asteroids[self.asteroidCount].physicsObject.position.x = rand.float(f32) * configZig.NATIVE_WIDTH;
        }
        self.asteroids[self.asteroidCount].physicsObject.velocity = rl.Vector2.clampValue(
            self.asteroids[self.asteroidCount].physicsObject.velocity,
            0,
            0.2,
        );
        self.asteroids[self.asteroidCount].physicsObject.collisionSize = 5;
        self.asteroidCount += 1;
    }

    pub fn removeAsteroid(self: *Game, index: usize) void {
        self.asteroids[index] = self.asteroids[self.asteroidCount - 1];
        self.asteroidCount -= 1;
    }

    pub fn unload(self: *Game) void {
        // remove only first as they are all the same
        if (self.asteroids[0].texture.id > 0) {
            self.asteroids[0].texture.unload();
        }
        self.blackHole.unload();
        self.player.unload();
    }
};

const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;

const playerZig = @import("game_logic/player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("game_logic/asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const projectileZig = @import("game_logic/projectile.zig");
const Projectile = projectileZig.Projectile;

// Screen consts
pub const NATIVE_WIDTH = 640;
pub const NATIVE_HEIGHT = 360;
pub const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };

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

// Game consts
pub const MAX_PROJECTILES = 200;
pub const MAX_ASTEROIDS = 50;
const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;

const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_PHASER_ROTATION_SPEED: f32 = 20;

const BlackHole = struct {
    size: f32 = 0.6,
    finalSize: f32 = 0.6 * BLACK_HOLE_SCALE,
    phasersCD: f32 = BLACK_HOLE_PHASER_CD,
    phasersMinDuration: f32 = BLACK_HOLE_PHASER_MIN_DURATION,
    isPhasing: bool = false,
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
            self.rotation += 360;
        } else if (self.rotation > 360) {
            self.rotation -= 360;
        }
        if (self.isPhasing) {
            if (self.phasersMinDuration < 0) {
                const tempSize = self.size - delta;
                if (tempSize < 0.6) {
                    self.setSize(0.6);
                    self.isPhasing = false;
                } else {
                    self.setSize(self.size - (0.1 * delta));
                }
            } else {
                self.phasersMinDuration -= delta;
            }
        }
        if ((self.size > 1 or self.phasersCD < 0) and !self.isPhasing) {
            self.phasersCD = BLACK_HOLE_PHASER_CD;
            self.phasersMinDuration = BLACK_HOLE_PHASER_MIN_DURATION;
            self.isPhasing = true;
            self.isRotatingRight = rand.boolean();
        }
    }
    pub fn init(self: *BlackHole) bool {
        if (self.phaserTexture.id > 0) {
            return true;
        }
        // Init Phaser
        const phaserImage = rl.Image.genColor(256 * 2, 10, .blank);
        self.phaserTexture = phaserImage.toTexture() catch |err| switch (err) {
            else => {
                std.debug.print("ERROR", .{});
                return false;
            },
        };
        phaserImage.unload();

        return true;
    }
    pub fn setSize(self: *BlackHole, size: f32) void {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
    }
};

pub const Game = struct {
    asteroids: [MAX_ASTEROIDS]Asteroid = std.mem.zeroes([MAX_ASTEROIDS]Asteroid),
    projectiles: [MAX_PROJECTILES]Projectile = std.mem.zeroes([MAX_PROJECTILES]Projectile),
    camera: rl.Camera2D = .{
        .offset = .{ .x = 0, .y = 0 },
        .rotation = 0,
        .target = .{ .x = 0, .y = 0 },
        .zoom = 1,
    },
    player: Player = .{},
    blackHole: BlackHole = .{},
    gameState: GameState = GameState.MainMenu,
    gameControllerType: GameControllerType = GameControllerType.Keyboard,
    virtualRatio: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    screen: rl.Vector2 = .{
        .x = 800,
        .y = 450,
    },
    asteroidSpawnCd: f32 = 0,
    shootingCd: f32 = 0,
    currentTickLength: f32 = 0.0,
    isTouchLeft: bool = false,
    isTouchRight: bool = false,
    isTouchUp: bool = false,
    isShooting: bool = false,
    currentScore: f32 = 0,
    highestScore: f32 = 0,
    asteroidCount: usize = 0,
    projectilesCount: usize = 0,
    isPlaying: bool = false,
};

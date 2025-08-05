const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;

const playerZig = @import("game_logic/player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("game_logic/asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const projectileZig = @import("game_logic/projectile.zig");
const Projectile = projectileZig.Projectile;

pub const GameState = enum {
    MainMenu,
    Playing,
    GameOver,
    Pause,
    Quit,
};

// Game consts
pub const MAX_PROJECTILES = 200;
pub const MAX_ASTEROIDS = 50;
const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;

const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_SPRINTE_COUNT = 11;
const BLACK_HOLE_FRAME_SPEED: f32 = 0.3;
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
    frameTimer: f32 = BLACK_HOLE_FRAME_SPEED,
    currentFrame: usize = 0,
    textures: [BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D = std.mem.zeroes([BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D),
    collisionpoints: [BLACK_HOLE_COLLISION_POINTS]rl.Vector2 = std.mem.zeroes([BLACK_HOLE_COLLISION_POINTS]rl.Vector2),
    origin: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    pub fn tick(self: *BlackHole, delta: f32) void {
        self.frameTimer -= delta;
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

        if (self.frameTimer <= 0) {
            self.currentFrame += 1;
            self.frameTimer = BLACK_HOLE_FRAME_SPEED;
            if (self.currentFrame == BLACK_HOLE_SPRINTE_COUNT) {
                self.currentFrame = 0;
            }
        }
    }
    pub fn initTexture(self: *BlackHole) bool {
        if (self.textures[0].id > 0) {
            return true;
        }
        for (0..BLACK_HOLE_SPRINTE_COUNT) |blackholeIndex| {
            const indexPlus: usize = blackholeIndex + 1;
            self.textures[blackholeIndex] = rl.loadTexture(rl.textFormat(
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
        self.origin = rl.Vector2{
            .x = @as(f32, @floatFromInt(self.textures[0].width)) / 2,
            .y = @as(f32, @floatFromInt(self.textures[0].height)) / 2,
        };
        // Init Phaser
        const phaserImage = rl.genImageColor(256, 20, .white);
        self.phaserTexture = phaserImage.toTexture() catch |err| switch (err) {
            else => {
                std.debug.print("ERROR", .{});
                return false;
            },
        };
        rl.unloadImage(phaserImage);

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
    virtualRatio: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    width: i32 = 800,
    height: i32 = 460,
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
};

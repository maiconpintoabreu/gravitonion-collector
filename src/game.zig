const std = @import("std");
const rl = @import("raylib");

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
const MAX_ASTEROIDS = 50;
pub const MAX_PROJECTILES = 200;
const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_SPRINTE_COUNT = 11;
const BLACK_HOLE_FRAME_SPEED: f32 = 0.3;

const BlackHole = struct {
    size: f32 = 0.6,
    finalSize: f32 = 0.6 * BLACK_HOLE_SCALE,
    resizeCD: f32 = 2,
    frameTimer: f32 = BLACK_HOLE_FRAME_SPEED,
    currentFrame: usize = 0,
    textures: [BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D = std.mem.zeroes([BLACK_HOLE_SPRINTE_COUNT]rl.Texture2D),
    origin: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    pub fn tick(self: *BlackHole, delta: f32) void {
        self.frameTimer -= delta;
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
    player: Player = .{},
    blackHole: BlackHole = .{},
    gameState: GameState = GameState.MainMenu,
    virtualRatio: f32 = 1,
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

const std = @import("std");
const rl = @import("raylib");
const playerZig = @import("game_logic/player.zig");
const Player = playerZig.Player;

const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_SPRINTE_COUNT = 11;
const BLACK_HOLE_FRAME_SPEED: f32 = 0.3;

const DEFAULT_ASTEROID_CD = 5;
const DEFAULT_SHOOTING_CD = 0.1;

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
        if (self.blackHole.frameTimer <= 0) {
            self.blackHole.currentFrame += 1;
            self.blackHole.frameTimer = BLACK_HOLE_FRAME_SPEED;
            if (self.blackHole.currentFrame == BLACK_HOLE_SPRINTE_COUNT) {
                self.blackHole.currentFrame = 0;
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
        return true;
    }
    pub fn setSize(self: *BlackHole, size: f32) bool {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
    }
};

const Game = struct {
    player: Player = .{},
    blackHole: BlackHole = .{},
    virtualRatio: f32 = 1,
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    width: i32 = 800,
    height: i32 = 460,
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

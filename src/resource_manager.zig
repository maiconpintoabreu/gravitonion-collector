const std = @import("std");
const rl = @import("raylib");

pub var resourceManager: ResourceManager = .{};

pub const TextureData = struct {
    rec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    center: rl.Vector2 = std.mem.zeroes(rl.Vector2),
};

const ResourceManager = struct {
    isInitialized: bool = false,
    textureSheet: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    bulletTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    shipData: TextureData = .{
        .rec = .{
            .x = 198.0,
            .y = 0.0,
            .width = 15.0,
            .height = 15.0,
        },
        .center = .{
            .x = 15.0 / 2.0,
            .y = 15.0 / 2.0,
        },
    },
    asteroidData: TextureData = .{
        .rec = .{
            .x = 150.0,
            .y = 0.0,
            .width = 15.0,
            .height = 12.0,
        },
        .center = .{
            .x = 15.0 / 2.0,
            .y = 12.0 / 2.0,
        },
    },
    shieldData: TextureData = .{
        .rec = .{
            .x = 0.0,
            .y = 0.0,
            .width = 21.0,
            .height = 21.0,
        },
        .center = .{
            .x = 21.0 / 2.0,
            .y = 21.0 / 2.0,
        },
    },
    powerupGunData: TextureData = .{
        .rec = .{
            .x = 67.0,
            .y = 0.0,
            .width = 16.0,
            .height = 16.0,
        },
        .center = .{
            .x = 16.0 / 2.0,
            .y = 16.0 / 2.0,
        },
    },
    powerupShieldData: TextureData = .{
        .rec = .{
            .x = 84.0,
            .y = 0.0,
            .width = 16.0,
            .height = 16.0,
        },
        .center = .{
            .x = 16.0 / 2.0,
            .y = 16.0 / 2.0,
        },
    },
    powerupGravityData: TextureData = .{
        .rec = .{
            .x = 111.0,
            .y = 0.0,
            .width = 16.0,
            .height = 16.0,
        },
        .center = .{
            .x = 16.0 / 2.0,
            .y = 16.0 / 2.0,
        },
    },
    bulletData: TextureData = .{
        .rec = std.mem.zeroes(rl.Rectangle),
        .center = std.mem.zeroes(rl.Vector2),
    },

    pub fn init(self: *ResourceManager) rl.RaylibError!void {
        if (self.isInitialized) return;

        // Loads Atlas
        self.textureSheet = try rl.loadTexture("resources/sheet.png");

        // Loads anything else
        self.bulletTexture = try rl.loadTexture("resources/bullet.png");
        self.bulletData.rec = .{
            .x = 0.0,
            .y = 0.0,
            .width = @as(f32, @floatFromInt(self.bulletTexture.width)),
            .height = @as(f32, @floatFromInt(self.bulletTexture.height)),
        };
        self.bulletData.center = .{
            .x = @as(f32, @floatFromInt(self.bulletTexture.width)) / 4,
            .y = @as(f32, @floatFromInt(self.bulletTexture.height)) / 4,
        };

        self.isInitialized = true;
    }

    pub fn unload(self: *ResourceManager) void {
        self.textureSheet.unload();
        self.bulletTexture.unload();
    }
};

const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const configZig = @import("config.zig");

const shaderVersion = if (builtin.cpu.arch.isWasm()) "100" else "330";

pub var resourceManager: ResourceManager = .{};

pub const TextureData = struct {
    rec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    center: rl.Vector2 = std.mem.zeroes(rl.Vector2),
};
const BlackholeData = struct {
    resolutionLoc: i32 = 0,
    timeLoc: i32 = 0,
    radiusLoc: i32 = 0,
    speedLoc: i32 = 0,
};

const BlackholePhaserData = struct {
    timePhaserLoc: i32 = 0,
};

const ResourceManager = struct {
    isInitialized: bool = false,

    // TextureAtlas
    textureSheet: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    // Shaders
    blackholeShader: rl.Shader = std.mem.zeroes(rl.Shader),
    blackholePhaserShader: rl.Shader = std.mem.zeroes(rl.Shader),

    // Sounds
    shoot: rl.Sound = std.mem.zeroes(rl.Sound),
    blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound),
    music: rl.Music = std.mem.zeroes(rl.Music),
    destruction: rl.Sound = std.mem.zeroes(rl.Sound),

    // Other Textures
    phaserTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    blackholeTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    shipData: TextureData = .{
        .rec = .{ .x = 198.0, .y = 0.0, .width = 15.0, .height = 15.0 },
        .center = .{ .x = 15.0 / 2.0, .y = 15.0 / 2.0 },
    },
    asteroidData: TextureData = .{
        .rec = .{ .x = 150.0, .y = 0.0, .width = 15.0, .height = 12.0 },
        .center = .{ .x = 15.0 / 2.0, .y = 12.0 / 2.0 },
    },
    shieldData: TextureData = .{
        .rec = .{ .x = 0.0, .y = 0.0, .width = 21.0, .height = 21.0 },
        .center = .{ .x = 21.0 / 2.0, .y = 21.0 / 2.0 },
    },
    powerupGunData: TextureData = .{
        .rec = .{ .x = 67.0, .y = 0.0, .width = 16.0, .height = 16.0 },
        .center = .{ .x = 16.0 / 2.0, .y = 16.0 / 2.0 },
    },
    powerupShieldData: TextureData = .{
        .rec = .{ .x = 84.0, .y = 0.0, .width = 16.0, .height = 16.0 },
        .center = .{ .x = 16.0 / 2.0, .y = 16.0 / 2.0 },
    },
    powerupGravityData: TextureData = .{
        .rec = .{ .x = 101.0, .y = 0.0, .width = 16.0, .height = 16.0 },
        .center = .{ .x = 16.0 / 2.0, .y = 16.0 / 2.0 },
    },
    bulletData: TextureData = .{
        .rec = .{ .x = 213.0, .y = 0.0, .width = 16.0, .height = 16.0 },
        .center = .{ .x = 16.0 / 2.0, .y = 16.0 / 2.0 },
    },
    blackholeData: BlackholeData = .{},
    blackholePhaserData: BlackholePhaserData = .{},

    pub fn init(self: *ResourceManager) rl.RaylibError!void {
        if (self.isInitialized) return;

        // Loads Atlas
        self.textureSheet = try rl.loadTexture("resources/sheet.png");

        self.shoot = try rl.loadSound("resources/shoot.wav");
        rl.setSoundVolume(self.shoot, 0.1);

        self.blackholeincreasing = try rl.loadSound("resources/blackholeincreasing.mp3");

        self.music = try rl.loadMusicStream("resources/ambient.mp3");
        self.destruction = try rl.loadSound("resources/destruction.wav");
        rl.setSoundVolume(self.destruction, 0.1);

        self.blackholeShader = try rl.loadShader(
            rl.textFormat("resources/shaders%s/blackhole.vs", .{shaderVersion}),
            rl.textFormat("resources/shaders%s/blackhole.fs", .{shaderVersion}),
        );

        self.blackholeData.resolutionLoc = rl.getShaderLocation(self.blackholeShader, "resolution");
        self.blackholeData.timeLoc = rl.getShaderLocation(self.blackholeShader, "time");
        self.blackholeData.radiusLoc = rl.getShaderLocation(self.blackholeShader, "radius");
        self.blackholeData.speedLoc = rl.getShaderLocation(self.blackholeShader, "speed");

        self.blackholePhaserShader = try rl.loadShader(
            null,
            rl.textFormat("resources/shaders%s/phaser.fs", .{shaderVersion}),
        );
        self.blackholePhaserData.timePhaserLoc = rl.getShaderLocation(self.blackholePhaserShader, "time");

        const BlackholeImage = rl.genImageColor(configZig.NATIVE_WIDTH, configZig.NATIVE_HEIGHT, .white);
        self.blackholeTexture = try BlackholeImage.toTexture();
        BlackholeImage.unload();

        const phaserImage = rl.Image.genColor(256 * 2, 10, .white);
        self.phaserTexture = try phaserImage.toTexture();
        phaserImage.unload();

        const radius: f32 = 2.0;
        rl.setShaderValue(self.blackholeShader, self.blackholeData.radiusLoc, &radius, .float);

        self.isInitialized = true;
    }

    pub fn unload(self: *ResourceManager) void {
        self.textureSheet.unload();
        self.blackholePhaserShader.unload();
        self.blackholeShader.unload();
        self.shoot.unload();
        self.blackholeincreasing.unload();
        self.blackholeTexture.unload();
        self.phaserTexture.unload();
        self.music.unload();
        self.destruction.unload();
    }
};

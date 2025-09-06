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
        .rec = .{ .x = 184.000, .y = 0.000, .width = 32.0, .height = 32.0 },
        .center = .{ .x = 32.0 / 2.0, .y = 32.0 / 2.0 },
    },
    asteroidData: TextureData = .{
        .rec = .{ .x = 0.000, .y = 0.000, .width = 43.0, .height = 43.0 },
        .center = .{ .x = 43.0 / 2.0, .y = 43.0 / 2.0 },
    },
    shieldData: TextureData = .{
        .rec = .{ .x = 145.000, .y = 0.000, .width = 39.0, .height = 32.0 },
        .center = .{ .x = 39.0 / 2.0, .y = 32.0 / 2.0 },
    },
    powerupGunData: TextureData = .{
        .rec = .{ .x = 77.000, .y = 0.000, .width = 34.0, .height = 33.0 },
        .center = .{ .x = 34.0 / 2.0, .y = 33.0 / 2.0 },
    },
    powerupShieldData: TextureData = .{
        .rec = .{ .x = 111.000, .y = 0.000, .width = 34.0, .height = 33.0 },
        .center = .{ .x = 34.0 / 2.0, .y = 33.0 / 2.0 },
    },
    powerupGravityData: TextureData = .{
        .rec = .{ .x = 43.000, .y = 0.000, .width = 34.0, .height = 33.0 },
        .center = .{ .x = 34.0 / 2.0, .y = 33.0 / 2.0 },
    },
    bulletData: TextureData = .{
        .rec = .{ .x = 216.000, .y = 0.000, .width = 16.0, .height = 16.0 },
        .center = .{ .x = 16.0 / 2.0, .y = 16.0 / 2.0 },
    },
    blackholeData: BlackholeData = .{},
    blackholePhaserData: BlackholePhaserData = .{},

    pub fn init(self: *ResourceManager) rl.RaylibError!void {
        if (self.isInitialized) return;
        if (!rl.fileExists("resources/sheet.png")) {
            const asteroidImage = try rl.loadImage("default_resources/asteroid1.png");
            const powerupGravityImage = try rl.loadImage("default_resources/powerupGravity.png");
            const powerupGunImage = try rl.loadImage("default_resources/powerupGun.png");
            const powerupShieldImage = try rl.loadImage("default_resources/powerupShield.png");
            const shieldImage = try rl.loadImage("default_resources/shield1.png");
            const shipImage = try rl.loadImage("default_resources/ship.png");
            const bulletImage = try rl.loadImage("default_resources/bullet.png");
            defer asteroidImage.unload();
            defer powerupGravityImage.unload();
            defer powerupGunImage.unload();
            defer powerupShieldImage.unload();
            defer shieldImage.unload();
            defer shipImage.unload();
            defer bulletImage.unload();
            const sunWidth = asteroidImage.width + powerupGravityImage.width + powerupGunImage.width + powerupShieldImage.width + shieldImage.width + shipImage.width + bulletImage.width;
            var maxHeight = asteroidImage.height;
            maxHeight = if (maxHeight < powerupGravityImage.height) powerupGravityImage.height else maxHeight;
            maxHeight = if (maxHeight < powerupGunImage.height) powerupGunImage.height else maxHeight;
            maxHeight = if (maxHeight < powerupShieldImage.height) powerupShieldImage.height else maxHeight;
            maxHeight = if (maxHeight < shieldImage.height) shieldImage.height else maxHeight;
            maxHeight = if (maxHeight < shipImage.height) shipImage.height else maxHeight;
            maxHeight = if (maxHeight < bulletImage.height) bulletImage.height else maxHeight;
            var sheetImage = rl.Image.genColor(sunWidth, maxHeight, .blank);
            var currentX: f32 = 0.0;
            sheetImage.drawImage(
                asteroidImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(asteroidImage.width)), .height = @as(f32, @floatFromInt(asteroidImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(asteroidImage.width)), .height = @as(f32, @floatFromInt(asteroidImage.height)) },
                .white,
            );
            rl.traceLog(.info, "asteroid .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height = %i, }", .{ currentX, @as(f32, @floatCast(0.0)), asteroidImage.width, asteroidImage.height });
            currentX += @as(f32, @floatFromInt(asteroidImage.width));
            sheetImage.drawImage(
                powerupGravityImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(powerupGravityImage.width)), .height = @as(f32, @floatFromInt(powerupGravityImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(powerupGravityImage.width)), .height = @as(f32, @floatFromInt(powerupGravityImage.height)) },
                .white,
            );
            rl.traceLog(.info, "powerupGravity .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), powerupGravityImage.width, powerupGravityImage.height });
            currentX += @as(f32, @floatFromInt(powerupGravityImage.width));
            sheetImage.drawImage(
                powerupGunImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(powerupGunImage.width)), .height = @as(f32, @floatFromInt(powerupGunImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(powerupGunImage.width)), .height = @as(f32, @floatFromInt(powerupGunImage.height)) },
                .white,
            );
            rl.traceLog(.info, "powerupGun .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), powerupGunImage.width, powerupGunImage.height });
            currentX += @as(f32, @floatFromInt(powerupGunImage.width));
            sheetImage.drawImage(
                powerupShieldImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(powerupShieldImage.width)), .height = @as(f32, @floatFromInt(powerupShieldImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(powerupShieldImage.width)), .height = @as(f32, @floatFromInt(powerupShieldImage.height)) },
                .white,
            );
            rl.traceLog(.info, "powerupShield .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), powerupShieldImage.width, powerupShieldImage.height });
            currentX += @as(f32, @floatFromInt(powerupShieldImage.width));
            sheetImage.drawImage(
                shieldImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(shieldImage.width)), .height = @as(f32, @floatFromInt(shieldImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(shieldImage.width)), .height = @as(f32, @floatFromInt(shieldImage.height)) },
                .white,
            );
            rl.traceLog(.info, "shield .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), shieldImage.width, shieldImage.height });
            currentX += @as(f32, @floatFromInt(shieldImage.width));
            sheetImage.drawImage(
                shipImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(shipImage.width)), .height = @as(f32, @floatFromInt(shipImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(shipImage.width)), .height = @as(f32, @floatFromInt(shipImage.height)) },
                .white,
            );
            rl.traceLog(.info, "ship .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), shipImage.width, shipImage.height });
            currentX += @as(f32, @floatFromInt(shipImage.width));
            sheetImage.drawImage(
                bulletImage,
                .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(bulletImage.width)), .height = @as(f32, @floatFromInt(bulletImage.height)) },
                .{ .x = currentX, .y = 0.0, .width = @as(f32, @floatFromInt(bulletImage.width)), .height = @as(f32, @floatFromInt(bulletImage.height)) },
                .white,
            );
            rl.traceLog(.info, "bullet .{ .x = %3.3f, .y =  %3.3f, .width =  %i, .height =  %i, }", .{ currentX, @as(f32, @floatCast(0.0)), bulletImage.width, bulletImage.height });
            _ = sheetImage.exportToFile("resources/sheet.png");
        }
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

        const screen = rl.Vector2{
            .x = @as(f32, @floatFromInt(configZig.NATIVE_WIDTH)),
            .y = @as(f32, @floatFromInt(configZig.NATIVE_HEIGHT)),
        };
        rl.setShaderValue(self.blackholeShader, self.blackholeData.resolutionLoc, &screen, .vec2);

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

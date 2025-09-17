const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const configZig = @import("config.zig");
const Allocator = std.mem.Allocator;

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

fn concat(allocator: Allocator, a: []const u8, b: []const u8, l: []const u8) []u8 {
    const result = allocator.alloc(u8, a.len + b.len + l.len) catch |err| switch (err) {
        else => {
            rl.traceLog(.err, "Concat ERROR", .{});
            unreachable;
        },
    };
    @memcpy(result[0..a.len], a);
    const combLen = a.len + l.len;
    @memcpy(result[a.len..combLen], l);
    @memcpy(result[combLen..], b);
    return result;
}
fn createSheetItem(sheetImage: *rl.Image, source: rl.Image, offSet: rl.Vector2, itemName: []const u8) void {
    sheetImage.drawImage(
        source,
        .{ .x = 0.0, .y = 0.0, .width = @as(f32, @floatFromInt(source.width)), .height = @as(f32, @floatFromInt(source.height)) },
        .{ .x = offSet.x, .y = offSet.y, .width = @as(f32, @floatFromInt(source.width)), .height = @as(f32, @floatFromInt(source.height)) },
        .white,
    );

    rl.traceLog(.info, "%s, .{ .rec = .{ .x = %3.3f, .y = %3.3f, .width = %i, .height = %i  }, .center = .{ .x = %3.3f, .y = %3.3f } },", .{
        itemName.ptr,
        offSet.x,
        offSet.y,
        source.width,
        source.height,
        @as(f32, @floatFromInt(source.width)) * 0.5,
        @as(f32, @floatFromInt(source.height)) * 0.5,
    });
    // return rl.textFormat("%s, %3.3f, %3.3f, %i, %i", .{ itemName.ptr, xOffSet, @as(f32, @floatCast(0.0)), source.width, source.height });
}

pub const ResourceManager = struct {
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
    backgroundTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    asteroid1Data: TextureData = .{ .rec = .{ .x = 0.000, .y = 0.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 - 5.0 } },
    asteroid2Data: TextureData = .{ .rec = .{ .x = 64.000, .y = 0.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 + 4.0 } },
    powerupGravityData: TextureData = .{ .rec = .{ .x = 0.000, .y = 64.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    powerupGunData: TextureData = .{ .rec = .{ .x = 64.000, .y = 64.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    powerupShieldData: TextureData = .{ .rec = .{ .x = 128.000, .y = 64.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    shieldData: TextureData = .{ .rec = .{ .x = 0.000, .y = 128.000, .width = 39, .height = 32 }, .center = .{ .x = 19.500, .y = 16.000 } },
    shipData: TextureData = .{ .rec = .{ .x = 0.000, .y = 160.000, .width = 32, .height = 32 }, .center = .{ .x = 16.000, .y = 16.000 } },
    bulletData: TextureData = .{ .rec = .{ .x = 0.000, .y = 192.000, .width = 16, .height = 16 }, .center = .{ .x = 8.000, .y = 8.000 } },
    uiButtomLeftData: TextureData = .{ .rec = .{ .x = 0.000, .y = 208.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    uiButtomRightData: TextureData = .{ .rec = .{ .x = 64.000, .y = 208.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    uiButtomAccelerateData: TextureData = .{ .rec = .{ .x = 128.000, .y = 208.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    uiButtomShootData: TextureData = .{ .rec = .{ .x = 192.000, .y = 208.000, .width = 64, .height = 64 }, .center = .{ .x = 32.000, .y = 32.000 } },
    uiButtomPauseData: TextureData = .{ .rec = .{ .x = 0.000, .y = 272.000, .width = 32, .height = 16 }, .center = .{ .x = 16.000, .y = 8.000 } },
    blackholeData: BlackholeData = .{},
    blackholePhaserData: BlackholePhaserData = .{},

    pub fn init(self: *ResourceManager) rl.RaylibError!void {
        if (self.isInitialized) return;
        if (!rl.fileExists("resources/sheet.png")) {
            const asteroid1Image = try rl.loadImage("default_resources/asteroid1.png");
            defer asteroid1Image.unload();
            const asteroid2Image = try rl.loadImage("default_resources/asteroid2.png");
            defer asteroid2Image.unload();
            const powerupGravityImage = try rl.loadImage("default_resources/powerupGravity.png");
            defer powerupGravityImage.unload();
            const powerupGunImage = try rl.loadImage("default_resources/powerupGun.png");
            defer powerupGunImage.unload();
            const powerupShieldImage = try rl.loadImage("default_resources/powerupShield.png");
            defer powerupShieldImage.unload();
            const shieldImage = try rl.loadImage("default_resources/shield1.png");
            defer shieldImage.unload();
            const shipImage = try rl.loadImage("default_resources/ship.png");
            defer shipImage.unload();
            const bulletImage = try rl.loadImage("default_resources/bullet.png");
            defer bulletImage.unload();
            const leftImage = try rl.loadImage("default_resources/ui_left.png");
            defer leftImage.unload();
            const rightImage = try rl.loadImage("default_resources/ui_right.png");
            defer rightImage.unload();
            const upImage = try rl.loadImage("default_resources/ui_up.png");
            defer upImage.unload();
            const shootImage = try rl.loadImage("default_resources/ui_shoot.png");
            defer shootImage.unload();
            const pauseImage = try rl.loadImage("default_resources/ui_pause.png");
            defer pauseImage.unload();
            const sunHeight = asteroid1Image.height + powerupGravityImage.height + shieldImage.height + shipImage.height + bulletImage.height + leftImage.height + pauseImage.height;
            const maxWidth = leftImage.width * 4;

            var sheetImage = rl.Image.genColor(maxWidth, sunHeight, .blank);
            defer sheetImage.unload();

            var currentPosition: rl.Vector2 = .zero();

            createSheetItem(
                &sheetImage,
                asteroid1Image,
                currentPosition,
                "asteroid1",
            );
            currentPosition.x += @as(f32, @floatFromInt(asteroid1Image.width));

            createSheetItem(
                &sheetImage,
                asteroid2Image,
                currentPosition,
                "asteroid2",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(asteroid1Image.height));

            createSheetItem(
                &sheetImage,
                powerupGravityImage,
                currentPosition,
                "powerupGravity",
            );
            currentPosition.x += @as(f32, @floatFromInt(asteroid1Image.width));

            createSheetItem(
                &sheetImage,
                powerupGunImage,
                currentPosition,
                "powerupGun",
            );
            currentPosition.x += @as(f32, @floatFromInt(asteroid1Image.width));

            createSheetItem(
                &sheetImage,
                powerupShieldImage,
                currentPosition,
                "powerupShield",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(powerupGravityImage.height));

            createSheetItem(
                &sheetImage,
                shieldImage,
                currentPosition,
                "shield",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(shieldImage.height));

            createSheetItem(
                &sheetImage,
                shipImage,
                currentPosition,
                "ship",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(shipImage.height));

            createSheetItem(
                &sheetImage,
                bulletImage,
                currentPosition,
                "bullet",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(bulletImage.height));

            createSheetItem(
                &sheetImage,
                leftImage,
                currentPosition,
                "ui_left",
            );
            currentPosition.x += @as(f32, @floatFromInt(leftImage.width));

            createSheetItem(
                &sheetImage,
                rightImage,
                currentPosition,
                "ui_right",
            );
            currentPosition.x += @as(f32, @floatFromInt(rightImage.width));

            createSheetItem(
                &sheetImage,
                upImage,
                currentPosition,
                "ui_up",
            );
            currentPosition.x += @as(f32, @floatFromInt(upImage.width));

            createSheetItem(
                &sheetImage,
                shootImage,
                currentPosition,
                "ui_shoot",
            );
            currentPosition.x = 0.0;
            currentPosition.y += @as(f32, @floatFromInt(leftImage.height));

            createSheetItem(
                &sheetImage,
                pauseImage,
                currentPosition,
                "ui_pause",
            );
            // const breakLine = "\n";
            // var buffer: [2000]u8 = undefined;
            // var fba = std.heap.FixedBufferAllocator.init(&buffer);
            // const allocator = fba.allocator();
            // const result = std.fmt.allocPrint(allocator, "{s}\n{s}", .{ asteroid1Text, asteroid2Text }) catch |err| switch (err) {
            //     else => {
            //         return;
            //     },
            // };
            // defer allocator.free(result);
            // _ = breakLine;
            // _ = powerupGravityText;
            // _ = powerupGunText;
            // _ = powerupShieldText;
            // _ = shieldText;
            // _ = shipText;
            // _ = bulletText;

            // _ = rl.saveFileText("resources/sheet.csv", rl.textFormat("%s", .{result.ptr}));

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
        defer BlackholeImage.unload();
        self.blackholeTexture = try BlackholeImage.toTexture();

        const phaserImage = rl.Image.genColor(256 * 2, 10, .white);
        defer phaserImage.unload();
        self.phaserTexture = try phaserImage.toTexture();

        const radius: f32 = 2.0;
        rl.setShaderValue(self.blackholeShader, self.blackholeData.radiusLoc, &radius, .float);

        const screen = rl.Vector2{
            .x = @as(f32, @floatFromInt(configZig.NATIVE_WIDTH)),
            .y = @as(f32, @floatFromInt(configZig.NATIVE_HEIGHT)),
        };
        rl.setShaderValue(self.blackholeShader, self.blackholeData.resolutionLoc, &screen, .vec2);

        self.backgroundTexture = try rl.loadTexture("resources/neb.png");
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
        self.backgroundTexture.unload();
    }
};

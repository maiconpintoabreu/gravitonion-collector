const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const configZig = @import("../config.zig");

const Player = @import("player.zig").Player;
const Asteroid = @import("asteroid.zig").Asteroid;
const PickupItem = @import("pickup_item.zig").PickupItem;
const Blackhole = @import("blackhole.zig").Blackhole;

const PhysicsZig = @import("physics.zig");
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ResourceManagerZig = @import("../resource_manager.zig");

const math = std.math;

pub const Vector2i = struct {
    x: i32,
    y: i32,

    pub fn zero() Vector2i {
        return .{ .x = 0, .y = 0 };
    }
    pub fn toVector2(self: Vector2i) rl.Vector2 {
        return .{
            .x = @as(f32, @floatFromInt(self.x)),
            .y = @as(f32, @floatFromInt(self.y)),
        };
    }
};

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

pub const Game = struct {
    asteroids: [configZig.MAX_ASTEROIDS]Asteroid = @splat(.{}),
    pickups: [configZig.MAX_PICKUPS]PickupItem = @splat(.{}),
    camera: rl.Camera2D = std.mem.zeroes(rl.Camera2D),
    player: Player = .{},
    blackhole: Blackhole = .{},
    gameTime: f64 = 0.1,
    font: rl.Font = std.mem.zeroes(rl.Font),
    controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    gameState: GameState = GameState.MainMenu,
    gameControllerType: GameControllerType = GameControllerType.Keyboard,
    virtualRatio: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    screen: Vector2i = .{
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
    isPlaying: bool = false,

    pub fn init(self: *Game, physics: *PhysicSystem) rl.RaylibError!void {
        // TODO: Move parent set to init when I have time
        self.blackhole.parent = self;
        self.player.parent = self;

        try self.blackhole.init(physics);
        try self.player.init(physics, std.mem.zeroes(rl.Vector2));
        if (builtin.is_test) return;

        // Init asteroid to reuse texture
        for (&self.asteroids) |*asteroid| {
            asteroid.parent = self;
            asteroid.init(physics);
        }
        for (&self.pickups) |*pickup| {
            pickup.parent = self;
            pickup.init(physics);
        }
        const resourceManager = ResourceManagerZig.resourceManager;

        const screen = self.screen.toVector2();
        rl.setShaderValue(resourceManager.blackholeShader, resourceManager.blackholeData.resolutionLoc, &screen, .vec2);

        self.restart(physics);
        // Start with one asteroid
        self.spawnAsteroidRandom(physics);
        rl.traceLog(.info, "Game init Completed", .{});
    }

    pub fn restart(self: *Game, physics: *PhysicSystem) void {
        const resourceManager = ResourceManagerZig.resourceManager;
        self.currentScore = 0;
        self.gameTime = 0;
        if (rl.isMusicValid(resourceManager.music)) {
            rl.stopMusicStream(resourceManager.music);
            rl.playMusicStream(resourceManager.music);
        }

        self.blackhole.setSize(physics, 0.6);
        self.blackhole.isPhasing = false;
        self.isPlaying = false;

        self.player.isAlive = true;
        self.player.health = 100.0;
        self.player.teleport(
            physics,
            rl.Vector2{
                .x = 50,
                .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the Blackhole
            },
            0.0,
        );

        physics.reset(.PlayerBullet);
        physics.reset(.Asteroid);
        for (&self.asteroids) |*asteroid| {
            asteroid.isAlive = false;
        }
        for (&self.player.bullets) |*bullets| {
            bullets.isAlive = false;
        }
        physics.disableBody(self.blackhole.phaserBody.id);
        self.player.updateSlots(self.player.body);
    }

    pub fn gameOver(self: *Game) void {
        if (self.highestScore < self.currentScore) {
            self.highestScore = self.currentScore;
        }
        self.gameState = GameState.GameOver;
    }

    pub fn tick(self: *Game, physics: *PhysicSystem, delta: f32) void {
        if (rl.isKeyReleased(rl.KeyboardKey.escape)) {
            self.gameState = GameState.Pause;
        }
        if (!self.isPlaying and rl.getKeyPressed() != .null) {
            self.isPlaying = true;
            return;
        }
        const resourceManager = ResourceManagerZig.resourceManager;
        rl.updateMusicStream(resourceManager.music);
        // Only change to keyboard if Touchscreen
        if (self.gameControllerType == GameControllerType.TouchScreen and rl.getKeyPressed() != .null) {
            self.gameControllerType = GameControllerType.Keyboard;
            if (!self.isPlaying) {
                self.isPlaying = true;
            }
        }
        if (self.gameState == GameState.Playing and self.isPlaying) {
            // Tick
            self.gameTime += @as(f64, delta);
            self.currentScore += 20 / self.blackhole.size * delta; // TODO: add distance on calculation
            self.asteroidSpawnCd -= delta;
            self.blackhole.setSize(physics, self.blackhole.size + 0.05 * delta);
            self.player.shootingCd -= delta;
            const reducedTime = @as(f32, @floatCast(self.gameTime / 2));

            rl.setShaderValue(resourceManager.blackholeShader, resourceManager.blackholeData.timeLoc, &reducedTime, .float);
            rl.setShaderValue(resourceManager.blackholePhaserShader, resourceManager.blackholePhaserData.timePhaserLoc, &reducedTime, .float);

            const rotationSpeed: f32 = self.blackhole.speed;
            rl.setShaderValue(resourceManager.blackholeShader, resourceManager.blackholeData.speedLoc, &rotationSpeed, .float);
            if (self.asteroidSpawnCd < 0) {
                self.asteroidSpawnCd = math.clamp(
                    configZig.DEFAULT_ASTEROID_CD - self.blackhole.size * 2.0,
                    0.2,
                    50,
                );
                self.spawnAsteroidRandom(physics);
            }
            // Input
            if (rl.isKeyDown(.space) or rl.isGamepadButtonDown(0, .right_face_down) or self.isShooting) {
                if (self.player.shootingCd < 0) {
                    self.player.shootingCd = configZig.DEFAULT_SHOOTING_CD;
                    self.player.shotBullet(physics);
                }
            }
            const gamepadSide = rl.getGamepadAxisMovement(0, .left_x);
            if (gamepadSide < -0.01) {
                rl.traceLog(.info, "left", .{});
                self.player.isTurningLeft = true;
                self.player.turnLeft(physics, gamepadSide * delta);
            } else if (gamepadSide > 0.01) {
                rl.traceLog(.info, "right", .{});
                self.player.isTurningRight = true;
                self.player.turnRight(physics, gamepadSide * delta);
            } else {
                if (rl.isKeyDown(.left) or rl.isGamepadButtonDown(0, .left_face_left) or self.isTouchLeft) {
                    self.player.isTurningLeft = true;
                    self.player.turnLeft(physics, delta);
                } else {
                    self.player.isTurningLeft = false;
                }
                if (rl.isKeyDown(.right) or rl.isGamepadButtonDown(0, .left_face_right) or self.isTouchRight) {
                    self.player.isTurningRight = true;
                    self.player.turnRight(physics, delta);
                } else {
                    self.player.isTurningRight = false;
                }
            }
            const gamepadAceleration = rl.getGamepadAxisMovement(0, .right_trigger);
            if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
                self.player.isAccelerating = true;
                if (builtin.cpu.arch.isWasm()) {
                    self.player.accelerate(physics, delta);
                } else {
                    self.player.accelerate(physics, gamepadAceleration * delta);
                }
            } else if (rl.isKeyDown(.up) or self.isTouchUp) {
                self.player.isAccelerating = true;
                self.player.accelerate(physics, delta);
            } else {
                self.player.isAccelerating = false;
            }
            self.currentTickLength += delta;
            while (self.currentTickLength > configZig.PHYSICS_TICK_SPEED) {
                self.currentTickLength -= configZig.PHYSICS_TICK_SPEED;
                const gravityScale: f32 = if (self.blackhole.isDisturbed) 100.0 else 0.4;
                physics.tick(configZig.PHYSICS_TICK_SPEED, gravityScale);
                if (self.player.health <= 0.00) {
                    self.gameOver();
                    return;
                }
                self.blackhole.tick(physics, configZig.PHYSICS_TICK_SPEED);
                for (&self.player.bullets) |*bullet| {
                    bullet.tick(physics);
                }
                self.player.tick(configZig.PHYSICS_TICK_SPEED);
                for (&self.asteroids) |*asteroid| {
                    asteroid.tick(physics);
                }
                for (&self.pickups) |*pickup| {
                    pickup.tick(physics);
                }
            }
        }
    }

    pub fn draw(self: Game, physics: *PhysicSystem) void {
        const resourceManager = ResourceManagerZig.resourceManager;
        {
            resourceManager.blackholeShader.activate();
            defer resourceManager.blackholeShader.deactivate();
            resourceManager.blackholeTexture.draw(
                0,
                0,
                .white,
            );
        }
        if (self.isPlaying) {
            self.blackhole.draw();
        }
        rl.drawCircleV(
            configZig.NATIVE_CENTER,
            self.blackhole.finalSize,
            if (self.blackhole.isDisturbed) .red else .black,
        );

        for (self.pickups) |pickupItem| {
            if (!pickupItem.isAlive) continue;
            const data: ResourceManagerZig.TextureData = switch (pickupItem.item.type) {
                .AntiGravity => resourceManager.powerupGravityData,
                .GunImprovement => resourceManager.powerupGunData,
                .Shield => resourceManager.powerupShieldData,
            };
            resourceManager.textureSheet.drawPro(
                data.rec,
                .{
                    .x = pickupItem.body.position.x,
                    .y = pickupItem.body.position.y,
                    .width = data.rec.width,
                    .height = data.rec.height,
                },
                data.center,
                0.0,
                .white,
            );
        }
        for (self.asteroids) |asteroid| {
            if (asteroid.isAlive) asteroid.draw();
        }
        self.player.draw();
        physics.debug();
    }

    fn spawnAsteroidRandom(self: *Game, physics: *PhysicSystem) void {
        for (&self.asteroids) |*asteroid| {
            if (!asteroid.isAlive) {
                asteroid.isAlive = true;
                asteroid.spawn(physics);
                return;
            }
        }
    }

    pub fn spawnPickupFromAsteroid(self: *Game, physics: *PhysicSystem, asteroid: Asteroid) void {
        for (&self.pickups) |*pickup| {
            if (!pickup.isAlive) {
                pickup.isAlive = true;
                pickup.generateRandomItem();
                pickup.spawn(physics, asteroid.body);
                return;
            }
        }
    }

    pub fn unload(self: *Game) void {

        // remove only first as they are all the same
        self.blackhole.unload();
        self.player.unload();
    }
};

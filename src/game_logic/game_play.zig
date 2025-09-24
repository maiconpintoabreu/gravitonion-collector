const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const configZig = @import("../config.zig");

const Player = @import("player.zig").Player;
const Asteroid = @import("asteroid.zig").Asteroid;
const PickupItem = @import("pickup_item.zig").PickupItem;
const Blackhole = @import("blackhole.zig").Blackhole;
const Particle = @import("particle.zig").Particle;
const Projectile = @import("projectile.zig").Projectile;

const PhysicsZig = @import("physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const PhysicsBody = PhysicsZig.PhysicsBody;
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

pub const GameObject = union(enum) {
    Player: Player,
    Asteroid: Asteroid,
    PickupItem: PickupItem,
    Blackhole: Blackhole,
    Projectile: Projectile,
};

pub const Game = struct {
    physics: PhysicsSystem = .{},
    gameObjectsAmount: usize = undefined,
    gameObjects: [configZig.MAX_GAME_OBJECTS]GameObject = undefined,
    camera: rl.Camera2D = std.mem.zeroes(rl.Camera2D),
    player: *Player = undefined,
    blackhole: *Blackhole = undefined,
    gameTime: f64 = 0.1,
    font: rl.Font = std.mem.zeroes(rl.Font),
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

    pub fn init(self: *Game) rl.RaylibError!void {

        // Adding default gameobjects
        self.gameObjectsAmount = 0;
        self.gameObjects[self.gameObjectsAmount] = .{ .Player = .{ .parent = self } };
        self.player = &self.gameObjects[self.gameObjectsAmount].Player;
        try self.gameObjects[self.gameObjectsAmount].Player.init(&self.physics, std.mem.zeroes(rl.Vector2));
        self.gameObjectsAmount += 1;

        self.gameObjects[self.gameObjectsAmount] = .{ .Blackhole = .{ .parent = self } };
        self.blackhole = &self.gameObjects[self.gameObjectsAmount].Blackhole;
        try self.gameObjects[self.gameObjectsAmount].Blackhole.init(&self.physics);
        self.gameObjectsAmount += 1;

        // Avoid opengl calls while testing
        if (builtin.is_test) return;

        rl.traceLog(.info, "Game init Completed", .{});
    }

    pub fn restart(self: *Game) void {
        const resourceManager = ResourceManagerZig.resourceManager;
        self.currentScore = 0;
        self.gameObjectsAmount = 2;
        self.gameTime = 0;
        if (rl.isMusicValid(resourceManager.music)) {
            rl.stopMusicStream(resourceManager.music);
            rl.playMusicStream(resourceManager.music);
        }

        self.blackhole.setSize(&self.physics, configZig.BLACK_HOLE_SIZE_DEFAULT);
        self.blackhole.isPhasing = false;
        self.isPlaying = false;

        self.player.isAlive = true;
        self.player.health = 100.0;
        self.player.isInvunerable = true;

        self.player.teleport(
            &self.physics,
            rl.Vector2{
                .x = 50,
                .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the Blackhole
            },
            0.0,
        );

        self.physics.reset();

        // self.player.updateSlots(self.player.body);
    }

    pub fn gameOver(self: *Game) void {
        if (self.highestScore < self.currentScore) {
            self.highestScore = self.currentScore;
        }
        self.gameState = GameState.GameOver;
    }

    pub fn tick(self: *Game, delta: f32) void {
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
            self.currentTickLength += delta;
            self.gameTime += @as(f64, delta);
            self.currentScore += 20 / self.blackhole.size * delta; // TODO: add distance on calculation
            self.asteroidSpawnCd -= delta;
            self.blackhole.setSize(&self.physics, self.blackhole.size + 0.05 * delta);
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
                self.spawnAsteroidRandom();
            }
            // Input
            if (rl.isKeyDown(.space) or rl.isGamepadButtonDown(0, .right_face_down) or self.isShooting) {
                if (self.player.shootingCd < 0) {
                    self.player.shootingCd = configZig.DEFAULT_SHOOTING_CD;
                    self.player.shotBullet(&self.physics);
                }
            }
            const gamepadSide = rl.getGamepadAxisMovement(0, .left_x);
            if (gamepadSide < -0.01) {
                rl.traceLog(.info, "left", .{});
                self.player.isTurningLeft = true;
                self.player.turnLeft(&self.physics, gamepadSide * delta);
            } else if (gamepadSide > 0.01) {
                rl.traceLog(.info, "right", .{});
                self.player.isTurningRight = true;
                self.player.turnRight(&self.physics, gamepadSide * delta);
            } else {
                if (rl.isKeyDown(.left) or rl.isGamepadButtonDown(0, .left_face_left) or self.isTouchLeft) {
                    self.player.isTurningLeft = true;
                    self.player.turnLeft(&self.physics, delta);
                } else {
                    self.player.isTurningLeft = false;
                }
                if (rl.isKeyDown(.right) or rl.isGamepadButtonDown(0, .left_face_right) or self.isTouchRight) {
                    self.player.isTurningRight = true;
                    self.player.turnRight(&self.physics, delta);
                } else {
                    self.player.isTurningRight = false;
                }
            }
            const gamepadAceleration = rl.getGamepadAxisMovement(0, .right_trigger);
            if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
                self.player.isAccelerating = true;
                if (builtin.cpu.arch.isWasm()) {
                    self.player.accelerate(&self.physics, delta);
                } else {
                    self.player.accelerate(&self.physics, gamepadAceleration * delta);
                }
            } else if (rl.isKeyDown(.up) or self.isTouchUp) {
                self.player.isAccelerating = true;
                self.player.accelerate(&self.physics, delta);
            } else {
                self.player.isAccelerating = false;
            }
            if (self.player.health <= 0.00) {
                self.gameOver();
                return;
            }
        }
    }

    pub fn physicsTick(self: *Game, delta: f32) void {
        const gravityScale: f32 = if (self.blackhole.isDisturbed) 100.0 else 0.4;
        self.physics.tick(delta, gravityScale);
        var gameObjectIndex: usize = self.gameObjectsAmount - 1;
        while (true) {
            switch (self.gameObjects[gameObjectIndex]) {
                .Player => {
                    self.gameObjects[gameObjectIndex].Player.tick(&self.physics, configZig.PHYSICS_TICK_SPEED);
                },
                .Blackhole => {
                    self.gameObjects[gameObjectIndex].Blackhole.tick(&self.physics, configZig.PHYSICS_TICK_SPEED);
                },
                .Asteroid => {
                    self.gameObjects[gameObjectIndex].Asteroid.tick(&self.physics);
                    if (self.gameObjects[gameObjectIndex].Asteroid.shouldDie) {
                        self.gameObjects[gameObjectIndex].Asteroid.isAlive = false;
                        self.unSpawn(self.gameObjects[gameObjectIndex].Asteroid.id, self.gameObjects[gameObjectIndex].Asteroid.bodyId);
                    }
                },
                .Projectile => {
                    self.gameObjects[gameObjectIndex].Projectile.tick(&self.physics);
                    if (self.gameObjects[gameObjectIndex].Projectile.shouldDie) {
                        self.gameObjects[gameObjectIndex].Projectile.isAlive = false;
                        self.unSpawn(self.gameObjects[gameObjectIndex].Projectile.id, self.gameObjects[gameObjectIndex].Projectile.bodyId);
                    }
                },
                .PickupItem => {
                    self.gameObjects[gameObjectIndex].PickupItem.tick(&self.physics, configZig.PHYSICS_TICK_SPEED);
                    if (self.gameObjects[gameObjectIndex].PickupItem.shouldDie) {
                        self.gameObjects[gameObjectIndex].PickupItem.isAlive = false;
                        self.unSpawn(self.gameObjects[gameObjectIndex].PickupItem.id, self.gameObjects[gameObjectIndex].PickupItem.bodyId);
                    }
                },
            }
            if (gameObjectIndex == 0) break;
            gameObjectIndex -= 1;
        }
    }

    pub fn draw(self: Game) void {
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
            self.blackhole.draw(self.physics);
        }
        rl.drawCircleV(
            configZig.NATIVE_CENTER,
            self.blackhole.finalSize,
            if (self.blackhole.isDisturbed) .red else .black,
        );

        for (0..self.gameObjectsAmount) |i| {
            switch (self.gameObjects[i]) {
                .Player => {},
                .Blackhole => {},
                inline else => |object| object.draw(self.physics),
            }
        }

        self.player.draw(self.physics);
        self.physics.debug();
    }

    // TODO: handle error
    fn spawnAsteroidRandom(self: *Game) void {
        if (self.gameObjectsAmount == configZig.MAX_GAME_OBJECTS) unreachable;
        self.gameObjects[self.gameObjectsAmount] = .{ .Asteroid = .{
            .id = self.gameObjectsAmount,
            .parent = self,
        } };
        self.gameObjects[self.gameObjectsAmount].Asteroid.init(&self.physics);
        self.gameObjectsAmount += 1;
    }

    // TODO: handle error
    pub fn spawnPickupFromAsteroid(self: *Game, asteroid: Asteroid) void {
        if (self.gameObjectsAmount == configZig.MAX_GAME_OBJECTS) unreachable;
        self.gameObjects[self.gameObjectsAmount] = .{ .PickupItem = .{
            .id = self.gameObjectsAmount,
            .parent = self,
            .lifeTime = configZig.PICKUP_LIFETIME_DURATION,
        } };
        self.gameObjects[self.gameObjectsAmount].PickupItem.init(&self.physics, self.physics.getBody(asteroid.bodyId).position);
        self.gameObjectsAmount += 1;
    }

    pub fn spawnProjectile(self: *Game, position: rl.Vector2, orient: f32, speed: f32) void {
        if (self.gameObjectsAmount == configZig.MAX_GAME_OBJECTS) unreachable;
        self.gameObjects[self.gameObjectsAmount] = .{ .Projectile = .{
            .id = self.gameObjectsAmount,
            .parent = self,
        } };
        self.gameObjects[self.gameObjectsAmount].Projectile.init(&self.physics);
        self.gameObjects[self.gameObjectsAmount].Projectile.teleport(&self.physics, position, orient);

        self.physics.applyForceToBody(self.gameObjects[self.gameObjectsAmount].Projectile.bodyId, speed);

        const resourceManager = ResourceManagerZig.resourceManager;
        self.gameObjectsAmount += 1;
        rl.playSound(resourceManager.shoot);
    }

    // TODO: handle error
    pub fn unSpawn(self: *Game, id: usize, bodyId: usize) void {
        if (id >= configZig.MAX_GAME_OBJECTS) unreachable;
        if (id < 2) unreachable; // Cannot remove Player, Blackhole
        if (bodyId < 3) unreachable; // Cannot remove Player, Blackhole or Phaser
        self.gameObjectsAmount -= 1;
        if (self.gameObjectsAmount < 3) return;
        self.physics.removeBody(bodyId);

        self.gameObjects[id] = self.gameObjects[self.gameObjectsAmount];
        switch (self.gameObjects[id]) {
            .Asteroid => {
                self.gameObjects[id].Asteroid.id = id;
            },
            .Projectile => {
                self.gameObjects[id].Projectile.id = id;
            },
            .PickupItem => {
                self.gameObjects[id].PickupItem.id = id;
            },
            else => unreachable,
        }
    }

    pub fn unload(self: *Game) void {

        // remove only first as they are all the same
        self.blackhole.unload();
        self.player.unload();
    }
};

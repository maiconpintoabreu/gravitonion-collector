const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const configZig = @import("../config.zig");

const Player = @import("player.zig").Player;
const Asteroid = @import("asteroid.zig").Asteroid;
const Blackhole = @import("blackhole.zig").Blackhole;

const PhysicsZig = @import("physics.zig");

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
    camera: rl.Camera2D = .{
        .offset = std.mem.zeroes(rl.Vector2),
        .rotation = 0,
        .target = std.mem.zeroes(rl.Vector2),
        .zoom = 1,
    },
    player: Player = .{},
    blackhole: Blackhole = .{},
    gameTime: f64 = 0.1,
    font: rl.Font = std.mem.zeroes(rl.Font),
    controlTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    music: rl.Music = std.mem.zeroes(rl.Music),
    destruction: rl.Sound = std.mem.zeroes(rl.Sound),
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
        try self.blackhole.init();
        // self.restart();
        // Init asteroid to reuse texture
        const asteroidTexture: rl.Texture2D = try rl.loadTexture("resources/rock.png");
        const asteroidTextureCenter = rl.Vector2{
            .x = @as(f32, @floatFromInt(asteroidTexture.width)) / 2,
            .y = @as(f32, @floatFromInt(asteroidTexture.height)) / 2 + 2,
        };
        const asteroidTextureRec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(asteroidTexture.width)),
            .height = @as(f32, @floatFromInt(asteroidTexture.height)),
        };
        for (&self.asteroids) |*asteroid| {
            asteroid.texture = asteroidTexture;
            asteroid.textureCenter = asteroidTextureCenter;
            asteroid.textureRec = asteroidTextureRec;
            try asteroid.init();
        }

        self.music = try rl.loadMusicStream("resources/ambient.mp3");
        self.destruction = try rl.loadSound("resources/destruction.wav");
        rl.setSoundVolume(self.destruction, 0.1);

        const screen = self.screen.toVector2();
        rl.setShaderValue(self.blackhole.blackholeShader, self.blackhole.resolutionLoc, &screen, .vec2);

        try self.player.init(std.mem.zeroes(rl.Vector2));
        self.restart();
        // Start with one asteroid
        self.spawnAsteroidRandom();
        rl.traceLog(.info, "Game init Completed", .{});
    }

    pub fn restart(self: *Game) void {
        self.currentScore = 0;
        self.gameTime = 0;
        if (rl.isMusicValid(self.music)) {
            rl.stopMusicStream(self.music);
            rl.playMusicStream(self.music);
        }

        self.blackhole.setSize(0.6);
        self.blackhole.isPhasing = false;
        self.isPlaying = false;

        self.player.isAlive = true;
        self.player.health = 100.0;
        self.player.teleport(
            rl.Vector2{
                .x = 50,
                .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the Blackhole
            },
            0.0,
        );

        PhysicsZig.getPhysicsSystem().reset(.PlayerBullet);
        PhysicsZig.getPhysicsSystem().reset(.Asteroid);
        for (&self.asteroids) |*asteroid| {
            asteroid.isAlive = false;
        }
        for (&self.player.bullets) |*bullets| {
            bullets.isAlive = false;
        }
        PhysicsZig.getPhysicsSystem().disableBody(self.blackhole.phaserBody.id);
        self.player.updateSlots(self.player.body);
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
        rl.updateMusicStream(self.music);
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
            self.blackhole.setSize(self.blackhole.size + 0.05 * delta);
            self.player.shootingCd -= delta;
            const reducedTime = @as(f32, @floatCast(self.gameTime / 2));

            rl.setShaderValue(self.blackhole.blackholeShader, self.blackhole.timeLoc, &reducedTime, .float);
            rl.setShaderValue(self.blackhole.blackholePhaserShader, self.blackhole.timePhaserLoc, &reducedTime, .float);

            const rotationSpeed: f32 = self.blackhole.speed;
            rl.setShaderValue(self.blackhole.blackholeShader, self.blackhole.speedLoc, &rotationSpeed, .float);
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
                    self.player.shotBullet();
                }
            }
            const gamepadSide = rl.getGamepadAxisMovement(0, .left_x);
            if (gamepadSide < -0.01) {
                rl.traceLog(.info, "left", .{});
                self.player.isTurningLeft = true;
                self.player.turnLeft(gamepadSide * delta);
            } else if (gamepadSide > 0.01) {
                rl.traceLog(.info, "right", .{});
                self.player.isTurningRight = true;
                self.player.turnRight(gamepadSide * delta);
            } else {
                if (rl.isKeyDown(.left) or rl.isGamepadButtonDown(0, .left_face_left) or self.isTouchLeft) {
                    self.player.isTurningLeft = true;
                    self.player.turnLeft(delta);
                } else {
                    self.player.isTurningLeft = false;
                }
                if (rl.isKeyDown(.right) or rl.isGamepadButtonDown(0, .left_face_right) or self.isTouchRight) {
                    self.player.isTurningRight = true;
                    self.player.turnRight(delta);
                } else {
                    self.player.isTurningRight = false;
                }
            }

            const gamepadAceleration = rl.getGamepadAxisMovement(0, .right_trigger);
            if (rl.isGamepadButtonDown(0, .right_trigger_2)) {
                self.player.isAccelerating = true;
                if (builtin.cpu.arch.isWasm()) {
                    self.player.accelerate(delta);
                } else {
                    self.player.accelerate(gamepadAceleration * delta);
                }
            } else if (rl.isKeyDown(.up) or self.isTouchUp) {
                self.player.isAccelerating = true;
                self.player.accelerate(delta);
            } else {
                self.player.isAccelerating = false;
            }

            self.currentTickLength += delta;
            while (self.currentTickLength > configZig.PHYSICS_TICK_SPEED) {
                self.currentTickLength -= configZig.PHYSICS_TICK_SPEED;
                const gravityScale: f32 = if (self.blackhole.isDisturbed) 100.0 else 0.4;
                PhysicsZig.getPhysicsSystem().tick(configZig.PHYSICS_TICK_SPEED, gravityScale);

                if (self.player.health <= 0.00) {
                    self.gameOver();
                    return;
                }

                self.blackhole.tick(delta);

                for (&self.player.bullets) |*bullet| {
                    bullet.tick();
                }

                self.player.tick(configZig.PHYSICS_TICK_SPEED);

                for (&self.asteroids) |*asteroid| {
                    asteroid.tick();
                }
            }
        }
    }
    pub fn draw(self: Game) void {
        {
            self.blackhole.blackholeShader.activate();
            defer self.blackhole.blackholeShader.deactivate();
            self.blackhole.blackholeTexture.draw(
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

        for (self.asteroids) |asteroid| {
            if (asteroid.isAlive) asteroid.draw();
        }

        PhysicsZig.getPhysicsSystem().debug();
        self.player.draw();
    }

    fn spawnAsteroidRandom(self: *Game) void {
        for (&self.asteroids) |*asteroid| {
            if (!asteroid.isAlive) {
                asteroid.isAlive = true;
                asteroid.spawn();
                return;
            }
        }
    }

    pub fn unload(self: *Game) void {
        if (rl.isMusicValid(self.music)) self.music.unload();
        if (rl.isSoundValid(self.destruction)) self.destruction.unload();
        if (rl.isSoundValid(self.blackhole.blackholeincreasing)) self.blackhole.blackholeincreasing.unload();

        // remove only first as they are all the same
        if (self.asteroids[0].texture.id > 0) {
            self.asteroids[0].texture.unload();
        }
        self.blackhole.unload();
        self.player.unload();
    }
};

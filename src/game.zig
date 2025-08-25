const std = @import("std");
const rl = @import("raylib");
const rand = std.crypto.random;
const math = std.math;

const configZig = @import("config.zig");
const playerZig = @import("game_logic/player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("game_logic/asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const PhysicsZig = @import("game_logic/physics.zig");
const PhysicsShapeUnion = PhysicsZig.PhysicsShapeUnion;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;
const PhysicsBody = PhysicsZig.PhysicsBody;
const Collidable = PhysicsZig.Collidable;

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

const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;
const BLACK_HOLE_SIZE_PHASER_ACTIVE = 1.5;

const BLACK_DEFAULT_SIZE = 0.6;
const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_PHASER_ROTATION_SPEED: f32 = 0.1;
const BLACK_HOLE_PHASER_MAX_ROTATION: f32 = 360.0;

const BlackHole = struct {
    physicsId: i32 = -1,
    size: f32 = BLACK_DEFAULT_SIZE,
    finalSize: f32 = BLACK_DEFAULT_SIZE * BLACK_HOLE_SCALE,
    speed: f32 = BLACK_DEFAULT_SIZE,
    phaserPhysicsId: i32 = -1,
    phasersCD: f32 = BLACK_HOLE_PHASER_CD,
    phasersMinDuration: f32 = BLACK_HOLE_PHASER_MIN_DURATION,
    isPhasing: bool = false,
    isDisturbed: bool = false,
    isRotatingRight: bool = false,
    phaserTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    collisionpoints: [BLACK_HOLE_COLLISION_POINTS]rl.Vector2 = std.mem.zeroes([BLACK_HOLE_COLLISION_POINTS]rl.Vector2),
    collider: ?Collidable = null,

    fn colliding(ptr: *anyopaque, data: *PhysicsBody) void {
        const self: *BlackHole = @ptrCast(@alignCast(ptr));
        if (data.tag == .Asteroid) {
            self.setSize(self.size + 0.1);
        } else if (data.tag == .PlayerBullet) {
            self.setSize(self.size + 0.02);
        }
        rl.traceLog(.info, "BlackHole Colliding", .{});
    }

    pub fn create(self: *BlackHole) Collidable {
        return Collidable{
            .ptr = self,
            .impl = &.{ .collidingWith = colliding },
        };
    }
    pub fn init(self: *BlackHole) rl.RaylibError!void {
        if (self.phaserTexture.id > 0) {
            return;
        }
        self.collider = self.create();
        const physicsBodyInit: PhysicsBodyInitiator = .{
            .owner = &self.collider,
            .position = configZig.NATIVE_CENTER,
            .mass = 0,
            .useGravity = false,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Circular = .{
                    .radius = self.finalSize,
                },
            },
            .enabled = true,
            .isWrapable = true,
            .tag = PhysicsZig.PhysicsBodyTagEnum.Blackhole,
        };
        self.physicsId = PhysicsZig.getPhysicsSystem().createBody(physicsBodyInit);
        // Init Phaser
        const phaserImage = rl.Image.genColor(256 * 2, 10, .white);
        self.phaserTexture = try phaserImage.toTexture();
        phaserImage.unload();

        const phaserPhysicsBodyInit: PhysicsBodyInitiator = .{
            .owner = &self.collider,
            .position = configZig.NATIVE_CENTER,
            .mass = 0,
            .useGravity = false,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Polygon = .{
                    .pointCount = 4,
                    .points = self.collisionpoints,
                },
            },
            .enabled = false,
            .isWrapable = true,
            .tag = PhysicsZig.PhysicsBodyTagEnum.Phaser,
        };
        self.phaserPhysicsId = PhysicsZig.getPhysicsSystem().createBody(phaserPhysicsBodyInit);
        rl.traceLog(.info, "Blackhole init Completed", .{});
    }
    pub fn tick(self: *BlackHole, delta: f32) void {
        self.phasersCD -= delta;
        if (self.isRotatingRight) {
            PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.physicsId, 1);
        } else {
            PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.physicsId, -1);
        }
        if (self.isPhasing) {
            const tempSize = self.size - delta;
            if (tempSize < BLACK_DEFAULT_SIZE) {
                self.setSize(BLACK_DEFAULT_SIZE);
                PhysicsZig.getPhysicsSystem().disableBody(self.phaserPhysicsId);
                self.isPhasing = false;
            } else {
                self.setSize(self.size - (0.1 / (BLACK_DEFAULT_SIZE / self.size) * delta));
            }
        }
        if ((self.size > BLACK_HOLE_SIZE_PHASER_ACTIVE) and !self.isPhasing) {
            self.phasersCD = BLACK_HOLE_PHASER_CD;
            self.phasersMinDuration = BLACK_HOLE_PHASER_MIN_DURATION;
            PhysicsZig.getPhysicsSystem().enableBody(self.phaserPhysicsId);
            self.isPhasing = true;
            self.isRotatingRight = rand.boolean();
        }
        self.speed = rl.math.lerp(
            self.speed,
            if (self.isRotatingRight) self.size * -1 else self.size,
            0.5,
        );
        const body = PhysicsZig.getPhysicsSystem().getBody(self.physicsId);
        self.collisionpoints[0] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = -5 });
        self.collisionpoints[1] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = 5 });
        self.collisionpoints[2] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = -5 });
        self.collisionpoints[3] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 5 });

        self.collisionpoints[0] = body.position.add(self.collisionpoints[0].subtract(body.position).rotate(
            body.orient,
        ));
        self.collisionpoints[1] = body.position.add(self.collisionpoints[1].subtract(body.position).rotate(
            body.orient,
        ));
        self.collisionpoints[2] = body.position.add(self.collisionpoints[2].subtract(body.position).rotate(
            body.orient,
        ));
        self.collisionpoints[3] = body.position.add(self.collisionpoints[3].subtract(body.position).rotate(
            body.orient,
        ));

        PhysicsZig.getPhysicsSystem().changeBodyShape(self.phaserPhysicsId, PhysicsShapeUnion{
            .Polygon = .{
                .pointCount = 4,
                .points = self.collisionpoints,
            },
        });
    }
    pub fn setSize(self: *BlackHole, size: f32) void {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
        PhysicsZig.getPhysicsSystem().changeBodyShape(self.physicsId, PhysicsShapeUnion{
            .Circular = .{ .radius = self.finalSize },
        });
    }
    pub fn draw(self: BlackHole) void {
        const blackholeBody = PhysicsZig.getPhysicsSystem().getBody(self.physicsId);
        if (self.isPhasing) {
            self.phaserTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(self.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(self.phaserTexture.height)),
                },
                .{
                    .x = self.collisionpoints[0].x,
                    .y = self.collisionpoints[0].y,
                    .width = @as(f32, @floatFromInt(self.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(self.phaserTexture.height)),
                },
                rl.Vector2.zero(),
                math.radiansToDegrees(blackholeBody.orient),
                .white,
            );
        } else {
            rl.drawLineEx(
                self.collisionpoints[0],
                self.collisionpoints[2],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
            rl.drawLineEx(
                self.collisionpoints[1],
                self.collisionpoints[3],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
        }
    }
    pub fn unload(self: *BlackHole) void {
        if (self.phaserTexture.id > 0) {
            self.phaserTexture.unload();
        }
    }
};

pub const Game = struct {
    asteroids: [configZig.MAX_ASTEROIDS]Asteroid = std.mem.zeroes([configZig.MAX_ASTEROIDS]Asteroid),
    camera: rl.Camera2D = .{
        .offset = std.mem.zeroes(rl.Vector2),
        .rotation = 0,
        .target = std.mem.zeroes(rl.Vector2),
        .zoom = 1,
    },
    player: Player = .{},
    blackHole: BlackHole = .{},
    gameState: GameState = GameState.MainMenu,
    gameControllerType: GameControllerType = GameControllerType.Keyboard,
    virtualRatio: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    nativeSizeScaled: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    screen: rl.Vector2 = .{
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
        try self.blackHole.init();
        try self.player.init(std.mem.zeroes(rl.Vector2));
        rl.traceLog(.info, "Game init Completed", .{});
    }
    pub fn tick(self: *Game, delta: f32) void {
        _ = self;
        _ = delta;
    }

    pub fn spawnAsteroidRandom(self: *Game) void {
        for (&self.asteroids) |*asteroid| {
            if (!asteroid.isAlive) {
                asteroid.isAlive = true;
                asteroid.spawn();
                return;
            }
        }
    }

    pub fn unload(self: *Game) void {
        // remove only first as they are all the same
        if (self.asteroids[0].texture.id > 0) {
            self.asteroids[0].texture.unload();
        }
        self.blackHole.unload();
        self.player.unload();
    }
};

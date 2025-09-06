const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const configZig = @import("../config.zig");

const Game = @import("game_play.zig").Game;
const PhysicsZig = @import("physics.zig");
const ResourceManagerZig = @import("../resource_manager.zig");
const PhysicsShapeUnion = PhysicsZig.PhysicsShapeUnion;
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;

const math = std.math;
const rand = std.crypto.random;

const shaderVersion = if (builtin.cpu.arch.isWasm()) "100" else "330";

const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;
const BLACK_HOLE_SIZE_PHASER_ACTIVE = 1.5;

const BLACK_DEFAULT_SIZE = 0.6;
const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_PHASER_ROTATION_SPEED: f32 = 0.1;
const BLACK_HOLE_PHASER_MAX_ROTATION: f32 = 360.0;

pub const Blackhole = struct {
    parent: *Game = undefined,
    body: PhysicsBody = .{},
    phaserBody: PhysicsBody = .{},
    size: f32 = BLACK_DEFAULT_SIZE,
    finalSize: f32 = BLACK_DEFAULT_SIZE * BLACK_HOLE_SCALE,
    speed: f32 = BLACK_DEFAULT_SIZE,
    phasersCD: f32 = BLACK_HOLE_PHASER_CD,
    phasersMinDuration: f32 = BLACK_HOLE_PHASER_MIN_DURATION,
    isPhasing: bool = false,
    isDisturbed: bool = false,
    isRotatingRight: bool = false,
    collisionpoints: [BLACK_HOLE_COLLISION_POINTS]rl.Vector2 = std.mem.zeroes([BLACK_HOLE_COLLISION_POINTS]rl.Vector2),

    fn colliding(self: *Blackhole, physics: *PhysicSystem, data: *PhysicsBody) void {
        if (data.tag == .Asteroid) {
            self.setSize(physics, self.size + 0.1);
        } else if (data.tag == .PlayerBullet) {
            self.setSize(physics, self.size + 0.02);
        }
        rl.traceLog(.info, "Blackhole Colliding", .{});
    }

    pub fn init(self: *Blackhole, physics: *PhysicSystem) rl.RaylibError!void {
        self.body = .{
            .position = configZig.NATIVE_CENTER,
            .shape = .{
                .Circular = .{
                    .radius = self.finalSize,
                },
            },
            .enabled = true,
            .isWrapable = true,
            .tag = .Blackhole,
        };
        physics.addBody(&self.body);
        if (builtin.is_test) return;

        self.phaserBody = .{
            .position = configZig.NATIVE_CENTER,
            .shape = .{
                .Polygon = .{
                    .pointCount = 4,
                    .points = self.collisionpoints,
                },
            },
            .tag = .Phaser,
        };
        physics.addBody(&self.phaserBody);

        rl.traceLog(.info, "Blackhole init Completed", .{});
    }
    pub fn tick(self: *Blackhole, physics: *PhysicSystem, delta: f32) void {
        self.isDisturbed = false;
        if (self.body.collidingWith) |otherBody| {
            self.colliding(physics, otherBody);
        }
        self.phasersCD -= delta;
        if (self.isRotatingRight) {
            physics.applyTorqueToBody(self.body.id, 1);
        } else {
            physics.applyTorqueToBody(self.body.id, -1);
        }
        if (self.isPhasing) {
            if (self.size < BLACK_DEFAULT_SIZE) {
                self.setSize(physics, BLACK_DEFAULT_SIZE);
                physics.disableBody(self.phaserBody.id);
                self.isPhasing = false;
            } else {
                self.setSize(physics, self.size - (0.6 * self.size) * delta);
            }
        }
        if ((self.size > BLACK_HOLE_SIZE_PHASER_ACTIVE) and !self.isPhasing) {
            self.phasersCD = BLACK_HOLE_PHASER_CD;
            self.phasersMinDuration = BLACK_HOLE_PHASER_MIN_DURATION;
            physics.enableBody(self.phaserBody.id);
            self.isPhasing = true;
            self.isRotatingRight = rand.boolean();
        }
        self.speed = rl.math.lerp(
            self.speed,
            if (self.isRotatingRight) self.size * -1 else self.size,
            0.5,
        );
        self.collisionpoints[0] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = -5 });
        self.collisionpoints[1] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = 5 });
        self.collisionpoints[2] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = -5 });
        self.collisionpoints[3] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 5 });

        self.collisionpoints[0] = self.body.position.add(self.collisionpoints[0].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[1] = self.body.position.add(self.collisionpoints[1].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[2] = self.body.position.add(self.collisionpoints[2].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[3] = self.body.position.add(self.collisionpoints[3].subtract(self.body.position).rotate(
            self.body.orient,
        ));

        physics.changeBodyShape(self.phaserBody.id, PhysicsShapeUnion{
            .Polygon = .{
                .pointCount = 4,
                .points = self.collisionpoints,
            },
        });
    }
    pub fn setSize(self: *Blackhole, physics: *PhysicSystem, size: f32) void {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
        physics.changeBodyShape(self.body.id, PhysicsShapeUnion{
            .Circular = .{ .radius = self.finalSize },
        });
    }
    pub fn draw(self: Blackhole) void {
        const BlackholeBody = self.body;
        const resourceManager = ResourceManagerZig.resourceManager;
        if (self.isPhasing) {
            resourceManager.blackholePhaserShader.activate();
            defer resourceManager.blackholePhaserShader.deactivate();
            resourceManager.phaserTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(resourceManager.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(resourceManager.phaserTexture.height)),
                },
                .{
                    .x = self.collisionpoints[0].x,
                    .y = self.collisionpoints[0].y,
                    .width = @as(f32, @floatFromInt(resourceManager.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(resourceManager.phaserTexture.height)),
                },
                rl.Vector2.zero(),
                math.radiansToDegrees(BlackholeBody.orient),
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
    pub fn unload(self: *Blackhole) void {
        _ = self;
    }
};

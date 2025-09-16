const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const Game = @import("game_play.zig").Game;
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const CollisionData = PhysicsZig.CollisionData;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ResourceManagerZig = @import("../resource_manager.zig");

pub const Asteroid = struct {
    id: usize = undefined,
    parent: *Game = undefined,
    bodyId: usize = undefined,
    shouldDie: bool = false,
    isAlive: bool = true,
    type: i8 = 0,
    constantRotationSpeed: f32 = 10,

    fn colliding(self: *Asteroid, data: CollisionData) void {
        if (self.shouldDie) return;
        if (data.tag != .Asteroid) {
            if (data.tag == .PlayerBullet) {
                self.parent.spawnPickupFromAsteroid(self.*);
            }
            self.shouldDie = true;
        }
    }

    pub fn init(self: *Asteroid, physics: *PhysicSystem) void {
        self.type = rand.intRangeLessThan(i8, 0, 2);
        var body: PhysicsBody = .{
            .enabled = true,
            .mass = 2,
            .useGravity = true,
            .shape = .{
                .Circular = .{
                    .radius = if (self.type == 0) 24 else 20,
                },
            },
            .tag = .Asteroid,
        };
        self.bodyId = physics.addBody(&body);
        if (rand.boolean()) {
            self.constantRotationSpeed = rand.float(f32) * 100;
        } else {
            self.constantRotationSpeed = rand.float(f32) * -100;
        }
        self.spawn(physics);
    }
    pub fn tick(self: *Asteroid, physics: *PhysicSystem) void {
        if (self.shouldDie) return;
        const body = physics.getBody(self.bodyId);
        if (body.collidingData) |otherBody| {
            self.colliding(otherBody);
            physics.resetBody(body.id);
        }
        if (self.isAlive) {
            physics.applyTorqueToBody(self.bodyId, self.constantRotationSpeed);
        }
    }

    pub fn spawn(self: Asteroid, physics: *PhysicSystem) void {
        var moveTo: rl.Vector2 = std.mem.zeroes(rl.Vector2);
        if (rand.boolean()) {
            if (rand.boolean()) {
                moveTo.x = 0;
            } else {
                moveTo.x = configZig.NATIVE_WIDTH;
            }
            moveTo.y = rand.float(f32) * configZig.NATIVE_HEIGHT;
        } else {
            if (rand.boolean()) {
                moveTo.y = 0;
            } else {
                moveTo.y = configZig.NATIVE_HEIGHT;
            }
            moveTo.x = rand.float(f32) * configZig.NATIVE_WIDTH;
        }
        physics.moveBody(self.bodyId, moveTo, 0.0);
    }

    pub fn draw(self: Asteroid, physics: PhysicSystem) void {
        if (self.shouldDie) return;
        if (!self.isAlive) return;
        if (self.bodyId < 0) return;

        const body = physics.getBody(self.bodyId);

        const resourceManager = ResourceManagerZig.resourceManager;
        const data = switch (self.type) {
            0 => resourceManager.asteroid1Data,
            else => resourceManager.asteroid2Data,
        };
        resourceManager.textureSheet.drawPro(
            data.rec,
            .{
                .x = body.position.x,
                .y = body.position.y,
                .width = data.rec.width,
                .height = data.rec.height,
            },
            data.center,
            body.orient,
            .white,
        );
    }
};

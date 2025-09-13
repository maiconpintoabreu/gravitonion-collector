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
    isAlive: bool = true,

    fn colliding(self: *Asteroid, data: CollisionData) void {
        if (data.tag != .Asteroid) {
            if (data.tag == .PlayerBullet) {
                self.parent.spawnPickupFromAsteroid(self.*);
            }
            self.isAlive = false;
        }
    }

    pub fn init(self: *Asteroid, physics: *PhysicSystem) void {
        var body: PhysicsBody = .{
            .enabled = true,
            .mass = 2,
            .useGravity = true,
            .shape = .{
                .Circular = .{
                    .radius = 24,
                },
            },
            .tag = .Asteroid,
        };
        self.bodyId = physics.addBody(&body);
        self.spawn(physics);
    }
    pub fn tick(self: *Asteroid, physics: *PhysicSystem) void {
        const body = physics.getBody(self.bodyId);
        if (body.collidingData) |otherBody| {
            self.colliding(otherBody);
            physics.resetBody(body.id);
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
        if (self.bodyId < 0) return;
        if (!self.isAlive) return;

        const body = physics.getBody(self.bodyId);

        const resourceManager = ResourceManagerZig.resourceManager;
        resourceManager.textureSheet.drawPro(
            resourceManager.asteroidData.rec,
            .{
                .x = body.position.x,
                .y = body.position.y,
                .width = resourceManager.asteroidData.rec.width,
                .height = resourceManager.asteroidData.rec.height,
            },
            resourceManager.asteroidData.center,
            body.orient,
            .white,
        );
    }
};

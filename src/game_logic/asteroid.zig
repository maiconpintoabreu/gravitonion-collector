const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const Game = @import("game_play.zig").Game;
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ResourceManagerZig = @import("../resource_manager.zig");

pub const Asteroid = struct {
    parent: *Game = undefined,
    body: PhysicsBody = .{
        .mass = 2,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 24,
            },
        },
        .tag = .Asteroid,
    },
    isAlive: bool = false,

    fn colliding(self: *Asteroid, physics: *PhysicSystem, data: *PhysicsBody) void {
        if (data.tag != .Asteroid) {
            if (data.tag == .PlayerBullet) {
                self.parent.spawnPickupFromAsteroid(physics, self.*);
            }
            physics.disableBody(self.body.id);
            self.isAlive = false;
        }
    }

    pub fn init(self: *Asteroid, physics: *PhysicSystem) void {
        physics.addBody(&self.body);
    }
    pub fn tick(self: *Asteroid, physics: *PhysicSystem) void {
        if (self.body.collidingWith) |otherBody| {
            self.colliding(physics, otherBody);
        }
    }
    pub fn unSpawn(self: Asteroid, physics: *PhysicSystem) void {
        physics.disableBody(self.body.id);
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
        physics.moveBody(self.body.id, moveTo, 0.0);
        physics.enableBody(self.body.id);
    }

    pub fn draw(self: Asteroid) void {
        if (self.body.id < 0) return;
        if (!self.body.enabled) return;
        const resourceManager = ResourceManagerZig.resourceManager;
        resourceManager.textureSheet.drawPro(
            resourceManager.asteroidData.rec,
            .{
                .x = self.body.position.x,
                .y = self.body.position.y,
                .width = resourceManager.asteroidData.rec.width,
                .height = resourceManager.asteroidData.rec.height,
            },
            resourceManager.asteroidData.center,
            self.body.orient,
            .white,
        );
    }
};

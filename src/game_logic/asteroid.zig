const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const Game = @import("game_play.zig").Game;
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;

pub const Asteroid = struct {
    parent: *Game = undefined,
    body: PhysicsBody = .{
        .mass = 2,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 6,
            },
        },
        .tag = .Asteroid,
    },
    isAlive: bool = false,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

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
        if (self.texture.id == 0) return;
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        if (!self.body.enabled) return;
        self.texture.drawPro(
            self.textureRec,
            .{
                .x = self.body.position.x,
                .y = self.body.position.y,
                .width = currentWidth,
                .height = currentHeight,
            },
            .{ .x = currentWidth / 2, .y = currentHeight / 2 },
            self.body.orient,
            .white,
        );
    }
};

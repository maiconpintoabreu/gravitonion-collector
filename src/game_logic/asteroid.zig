const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const PhysicsObject = PhysicsZig.PhysicsBody;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;
const PhysicsBody = PhysicsZig.PhysicsBody;
const Collidable = PhysicsZig.Collidable;

pub const Asteroid = struct {
    // physicsObject: PhysicsObject = .{},
    physicsId: i32 = -1,
    body: PhysicsBody = .{},
    size: f32 = 6,
    isAlive: bool = false,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    fn colliding(self: *Asteroid, data: *PhysicsBody) void {
        if (data.tag != .Asteroid) {
            PhysicsZig.getPhysicsSystem().disableBody(self.physicsId);
            self.isAlive = false;
        }
    }

    pub fn init(self: *Asteroid) rl.RaylibError!void {
        self.body = .{
            .position = .{ .x = 0, .y = 0 },
            .mass = 2,
            .useGravity = true,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Circular = .{
                    .radius = self.size,
                },
            },
            .enabled = false,
            .isWrapable = false,
            .tag = PhysicsZig.PhysicsBodyTagEnum.Asteroid,
        };
        self.physicsId = PhysicsZig.getPhysicsSystem().addBody(&self.body);
    }
    pub fn tick(self: *Asteroid) void {
        if (self.body.collidingWith) |otherBody| {
            self.colliding(otherBody);
        }
    }
    pub fn unSpawn(self: Asteroid) void {
        PhysicsZig.getPhysicsSystem().disableBody(self.physicsId);
    }

    pub fn spawn(self: Asteroid) void {
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
        // self.asteroids[self.asteroidCount].physicsObject.velocity = rl.Vector2.clampValue(
        //     self.asteroids[self.asteroidCount].physicsObject.velocity,
        //     0,
        //     0.2,
        // );
        PhysicsZig.getPhysicsSystem().moveBody(self.physicsId, moveTo, 0.0);
        PhysicsZig.getPhysicsSystem().enableBody(self.physicsId);
    }

    pub fn draw(self: Asteroid) void {
        if (self.physicsId < 0) return;
        if (self.texture.id == 0) return;
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        if (!self.body.enabled) return;
        self.texture.drawPro(self.textureRec, .{
            .x = self.body.position.x,
            .y = self.body.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, .{ .x = currentWidth / 2, .y = currentHeight / 2 }, self.body.orient, .white);
    }
};

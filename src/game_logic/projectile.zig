const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;

pub const Projectile = struct {
    body: PhysicsBody = .{
        .shape = .{
            .Circular = .{
                .radius = 3,
            },
        },
        .tag = .PlayerBullet,
    },
    speed: f32 = 20,
    rotation: f32 = 0,
    isAlive: bool = false,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    fn colliding(self: *Projectile, physics: *PhysicSystem, data: *PhysicsBody) void {
        _ = data;
        physics.disableBody(self.body.id);
        self.isAlive = false;
        rl.traceLog(.info, "Projectile Colliding", .{});
    }

    // Init physics
    pub fn init(self: *Projectile, physics: *PhysicSystem) void {
        physics.addBody(&self.body);
    }

    pub fn teleport(self: *Projectile, physics: *PhysicSystem, position: rl.Vector2, orient: f32) void {
        physics.moveBody(self.body.id, position, orient);
    }

    pub fn tick(self: *Projectile, physics: *PhysicSystem) void {
        if (self.body.collidingWith) |otherBody| {
            self.colliding(physics, otherBody);
        }
    }

    pub fn unload(self: *Projectile) void {
        if (self.texture.id > 0) {
            self.texture.unload();
        }
    }
};

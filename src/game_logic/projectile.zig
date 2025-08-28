const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;

pub const Projectile = struct {
    physicsId: i32 = -1,
    body: PhysicsBody = .{},
    size: f32 = 3,
    speed: f32 = 20,
    rotation: f32 = 0,
    isAlive: bool = false,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    fn colliding(self: *Projectile, data: *PhysicsBody) void {
        _ = data;
        PhysicsZig.getPhysicsSystem().disableBody(self.physicsId);
        self.isAlive = false;
        rl.traceLog(.info, "Projectile Colliding", .{});
    }

    // Init physics
    pub fn init(self: *Projectile) rl.RaylibError!void {
        self.body = .{
            .position = .{ .x = 0, .y = 0 },
            .mass = 0,
            .useGravity = false,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Circular = .{
                    .radius = self.size,
                },
            },
            .enabled = false,
            .isWrapable = false,
            .tag = PhysicsZig.PhysicsBodyTagEnum.PlayerBullet,
        };
        self.physicsId = PhysicsZig.getPhysicsSystem().addBody(&self.body);
    }

    pub fn teleport(self: *Projectile, position: rl.Vector2, orient: f32) void {
        PhysicsZig.getPhysicsSystem().moveBody(self.physicsId, position, orient);
    }

    pub fn tick(self: *Projectile) void {
        if (self.body.collidingWith) |otherBody| {
            self.colliding(otherBody);
        }
    }

    pub fn unload(self: *Projectile) void {
        if (self.texture.id > 0) {
            self.texture.unload();
        }
    }
};

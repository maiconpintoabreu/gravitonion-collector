const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const physicsObjectZig = @import("physics_object.zig");
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicsObject = physicsObjectZig.PhysicsObject;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;

pub const Projectile = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    physicsBody: ?*PhysicsBody = null,
    previousPosition: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    size: f32 = 3,
    speed: f32 = 20,
    rotation: f32 = 0,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    // Init physics
    pub fn init(self: *Projectile) rl.RaylibError!void {
        const physicsBodyInit: PhysicsBodyInitiator = .{
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
        };
        const id = PhysicsZig.physicsSystem.createBody(physicsBodyInit);
        self.physicsBody = PhysicsZig.physicsSystem.getBody(id);
    }
    pub fn tick(self: *Projectile, delta: f32) void {
        self.speed += self.speed * delta;
        self.previousPosition = self.position;
        self.position = self.position.add(self.direction.scale(self.speed));
    }

    pub fn unload(self: *Projectile) void {
        if (self.texture.id > 0) {
            self.texture.unload();
        }
    }
};

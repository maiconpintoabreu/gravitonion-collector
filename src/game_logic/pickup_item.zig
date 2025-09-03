const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;

pub const PickupItem = struct {
    body: PhysicsBody = .{
        .mass = 2,
        .useGravity = false,
        .shape = .{
            .Circular = .{
                .radius = 6,
            },
        },
        .tag = .PickupItem,
    },
    isAlive: bool = false,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),

    fn colliding(self: *PickupItem, physics: *PhysicSystem, data: *PhysicsBody) void {
        if (data.tag != .PickupItem) {
            physics.disableBody(self.body.id);
            self.isAlive = false;
        }
    }

    pub fn init(self: *PickupItem, physics: *PhysicSystem) void {
        physics.addBody(&self.body);
    }
    pub fn tick(self: *PickupItem, physics: *PhysicSystem) void {
        if (self.body.collidingWith) |otherBody| {
            self.colliding(physics, otherBody);
        }
    }
    pub fn unSpawn(self: PickupItem, physics: *PhysicSystem) void {
        physics.disableBody(self.body.id);
    }

    pub fn spawn(self: PickupItem, physics: *PhysicSystem, body: PhysicsBody) void {
        physics.moveBody(self.body.id, body.position, body.orient);
        physics.enableBody(self.body.id);
    }

    pub fn draw(self: PickupItem) void {
        if (self.body.id < 0) return;
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

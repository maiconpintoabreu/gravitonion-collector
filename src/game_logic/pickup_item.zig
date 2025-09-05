const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const Game = @import("game_play.zig").Game;
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ItemZig = @import("inventory/item.zig");
const Item = ItemZig.Item;

pub const PickupItem = struct {
    parent: *Game = undefined,
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
    item: Item = .{},
    isAlive: bool = false,

    fn colliding(self: *PickupItem, physics: *PhysicSystem, data: *PhysicsBody) void {
        if (data.tag == .Player) {
            physics.disableBody(self.body.id);
            self.isAlive = false;
            self.parent.player.pickupItem(self.item);
        }
    }

    pub fn init(self: *PickupItem, physics: *PhysicSystem) void {
        physics.addBody(&self.body);
    }

    pub fn generateRandomItem(self: *PickupItem) void {
        self.item = .{};
        if (rand.boolean()) {
            self.item.type = .{ .Shield = .{ .shieldDuration = 5 } };
        } else {
            self.item.type = .{ .GunImprovement = .{ .gunSpeedIncrease = 2.0 } };
        }
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

    pub fn draw(self: PickupItem, texture: rl.Texture2D) void {
        if (self.body.id < 0) return;
        if (texture.id == 0) return;
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        if (!self.body.enabled) return;
        texture.drawPro(self.textureRec, .{
            .x = self.body.position.x,
            .y = self.body.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, .{ .x = currentWidth / 2, .y = currentHeight / 2 }, self.body.orient, .white);
    }
};

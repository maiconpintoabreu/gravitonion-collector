const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const Game = @import("game_play.zig").Game;
const PhysicsBody = PhysicsZig.PhysicsBody;
const CollisionData = PhysicsZig.CollisionData;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ItemZig = @import("inventory/item.zig");
const Item = ItemZig.Item;
const ResourceManagerZig = @import("../resource_manager.zig");

pub const PickupItem = struct {
    id: usize = undefined,
    parent: *Game = undefined,
    bodyId: usize = undefined,
    item: Item = .{},
    isAlive: bool = true,
    lifeTime: f32 = configZig.PICKUP_LIFETIME_DURATION,

    fn colliding(self: *PickupItem, data: CollisionData) void {
        if (data.tag == .Player) {
            self.isAlive = false;
            self.parent.player.pickupItem(self.item);
        } else if (data.tag == .Phaser) {
            self.isAlive = false;
        }
    }

    pub fn init(self: *PickupItem, physics: *PhysicSystem, initialPosition: rl.Vector2) void {
        var body: PhysicsBody = .{
            .position = initialPosition,
            .mass = 2,
            .useGravity = false,
            .shape = .{
                .Circular = .{
                    .radius = 16,
                },
            },
            .tag = .PickupItem,
        };
        self.bodyId = physics.addBody(&body);
        self.generateRandomItem();
    }

    pub fn generateRandomItem(self: *PickupItem) void {
        self.item = .{};
        const itemTypes: [3]ItemZig.ItemTypeUnion = .{
            .{ .Shield = .{ .shieldDuration = 5 } },
            .{ .GunImprovement = .{ .gunSpeedIncrease = 2.0 } },
            .{ .AntiGravity = .{ .antiGravityDuration = 5.0 } },
        };
        const index = @as(usize, @intFromFloat(rand.float(f32) * 3.0));
        self.item.type = itemTypes[index];
    }

    pub fn tick(self: *PickupItem, physics: *PhysicSystem, delta: f32) void {
        self.lifeTime -= delta;
        if (self.lifeTime <= 0.0) {
            self.isAlive = false;
            return;
        }
        const body = physics.getBody(self.bodyId);
        if (body.collidingData) |otherBody| {
            self.colliding(otherBody);
            physics.resetBody(body.id);
        }
    }

    pub fn spawn(self: PickupItem, physics: *PhysicSystem, body: PhysicsBody) void {
        physics.moveBody(self.bodyId, body.position, body.orient);
        physics.enableBody(self.bodyId);
    }

    pub fn draw(self: PickupItem, physics: PhysicSystem) void {
        if (!self.isAlive) return;
        const textureData = self.item.getTextureData();
        const currentWidth = textureData.rec.width;
        const currentHeight = textureData.rec.height;
        const body = physics.getBody(self.bodyId);

        const resourceManager = ResourceManagerZig.resourceManager;
        resourceManager.textureSheet.drawPro(textureData.rec, .{
            .x = body.position.x,
            .y = body.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, textureData.center, 0.0, .white);
    }
};

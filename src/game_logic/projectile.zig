const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const PhysicsZig = @import("physics.zig");
const Game = @import("game_play.zig").Game;
const PhysicsBody = PhysicsZig.PhysicsBody;
const CollisionData = PhysicsZig.CollisionData;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const ResourceManagerZig = @import("../resource_manager.zig");

pub const Projectile = struct {
    id: usize = undefined,
    parent: *Game = undefined,
    bodyId: usize = undefined,
    speed: f32 = 20,
    rotation: f32 = 0,
    shouldDie: bool = false,
    isAlive: bool = true,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),

    fn colliding(self: *Projectile, data: CollisionData) void {
        if (self.shouldDie) return;
        _ = data;
        self.shouldDie = true;
    }

    // Init physics
    pub fn init(self: *Projectile, physics: *PhysicSystem) void {
        var body: PhysicsBody = .{
            .shape = .{
                .Circular = .{
                    .radius = 5,
                },
            },
            .tag = .PlayerBullet,
            .speedLimit = 10,
        };
        self.bodyId = physics.addBody(&body);
    }

    pub fn teleport(self: *Projectile, physics: *PhysicSystem, position: rl.Vector2, orient: f32) void {
        physics.moveBody(self.bodyId, position, orient);
    }

    pub fn tick(self: *Projectile, physics: *PhysicSystem) void {
        if (self.shouldDie) return;
        const body: PhysicsBody = physics.getBody(self.bodyId);
        self.isAlive = body.isVisible;
        if (body.collidingData) |otherBody| {
            self.colliding(otherBody);
            physics.resetBody(body.id);
        }
    }

    pub fn draw(self: Projectile, physics: PhysicSystem) void {
        if (self.shouldDie) return;
        if (!self.isAlive) return;

        const body: PhysicsBody = physics.getBody(self.bodyId);
        const rotation: f32 = math.radiansToDegrees(body.orient);
        const resourceManager = ResourceManagerZig.resourceManager;
        resourceManager.textureSheet.drawPro(
            resourceManager.bulletData.rec,
            .{
                .x = body.position.x,
                .y = body.position.y,
                .width = resourceManager.bulletData.rec.width,
                .height = resourceManager.bulletData.rec.height,
            },
            resourceManager.bulletData.center,
            rotation,
            .white,
        );
    }

    pub fn unload(self: *Projectile) void {
        if (self.texture.id > 0) {
            self.texture.unload();
        }
    }
};

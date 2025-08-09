const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const physicsZig = @import("physics_object.zig");
const PhysicsObject = physicsZig.PhysicsObject;
const MAX_HEALTH = 100;
const MAX_POWER = 100;

pub const Player = struct {
    physicsObject: PhysicsObject = .{
        .rotationSpeed = 200,
    },
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    health: f32 = MAX_HEALTH,
    power: f32 = MAX_POWER,
    gunSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    pub fn tick(self: *Player) void {
        self.physicsObject.velocity = rl.Vector2.clampValue(
            self.physicsObject.velocity,
            0,
            1.8,
        );
        self.physicsObject.tick();
        self.gunSlot = self.physicsObject.position.add(self.physicsObject.direction.scale(10));
    }
    pub fn draw(self: *Player) void {
        if (self.texture.id == 0) {
            return;
        }
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        rl.drawTexturePro(
            self.texture,
            self.textureRec,
            .{
                .x = self.physicsObject.position.x,
                .y = self.physicsObject.position.y,
                .width = currentWidth,
                .height = currentHeight,
            },
            .{ .x = currentWidth / 2, .y = currentHeight / 2 },
            self.physicsObject.rotation,
            .white,
        );
    }
    pub fn unload(self: *Player) void {
        if (self.texture.id > 0) {
            rl.unloadTexture(self.texture);
        }
    }
};

const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const physicsZig = @import("physics_object.zig");
const PhysicsObject = physicsZig.PhysicsObject;

pub const Projectile = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    size: f32 = 10,
    speed: f32 = 20,
    rotation: f32 = 0,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    pub fn tick(self: *Projectile, delta: f32) void {
        self.speed += self.speed * delta;
        self.position = self.position.add(self.direction.scale(self.speed));
    }
    pub fn draw(self: *Projectile, scale: f32) void {
        if (self.texture.id == 0) {
            return;
        }
        const currentWidth = self.textureRec.width * scale * 0.4;
        const currentHeight = self.textureRec.height * scale * 0.4;
        rl.drawTexturePro(self.texture, self.textureRec, .{
            .x = self.position.x,
            .y = self.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, .{ .x = currentWidth / 2, .y = currentHeight / 2 }, self.rotation, .white);
    }
    pub fn unload(self: *Projectile) void {
        if (self.texture.id > 0) {
            rl.unloadTexture(self.texture);
        }
    }
};

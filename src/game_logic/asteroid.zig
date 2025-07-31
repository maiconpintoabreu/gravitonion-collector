const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const physicsZig = @import("physics_object.zig");
const PhysicsObject = physicsZig.PhysicsObject;

pub const Asteroid = struct {
    physicsObject: PhysicsObject = .{},
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    pub fn tick(self: *Asteroid) void {
        self.physicsObject.velocity = rl.Vector2.clampValue(self.physicsObject.velocity, 0, 0.8);
        self.physicsObject.tick();
    }
    pub fn draw(self: *Asteroid) void {
        if (self.texture.id == 0) {
            return;
        }
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        rl.drawTexturePro(self.texture, self.textureRec, .{
            .x = self.physicsObject.position.x,
            .y = self.physicsObject.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, .{ .x = currentWidth / 2, .y = currentHeight / 2 }, self.physicsObject.rotation, .white);
    }
    pub fn unload(self: *Asteroid) void {
        if (self.texture.id > 0) {
            rl.unloadTexture(self.texture);
        }
    }
};

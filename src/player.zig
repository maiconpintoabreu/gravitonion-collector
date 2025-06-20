const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const physicsZig = @import("physics_object.zig");
const PhysicsObject = physicsZig.PhysicsObject;

pub const Player = struct {
    physicsObject: PhysicsObject = .{
        .rotationSpeed = 200,
        .isFacingMovement = true,
    },
    currentTickLength: f32 = 0.01,
    defaultTickLength: f32 = 0.01,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    pub fn tick(self: *Player, delta: f32) void {
        self.currentTickLength -= delta;
        if (self.currentTickLength < 0) {
            self.currentTickLength = self.defaultTickLength;
            self.physicsObject.tick();
        }
    }
    pub fn draw(self: *Player) void {
        if (self.texture.id == 0) {
            return;
        }
        rl.drawTexturePro(self.texture, self.textureRec, .{
            .x = self.physicsObject.position.x,
            .y = self.physicsObject.position.y,
            .width = self.textureRec.width,
            .height = self.textureRec.height,
        }, self.textureCenter, self.physicsObject.rotation, .white);
    }
    pub fn unload(self: *Player) void {
        if (self.texture.id > 0) {
            rl.unloadTexture(self.texture);
        }
    }
};

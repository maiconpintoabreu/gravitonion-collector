const std = @import("std");
const rl = @import("raylib");

pub const Particle = struct {
    isAlive: bool = false,
    timeToDie: f32 = 0.0,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),

    pub fn tick(self: *Particle, delta: f32) void {
        if (self.isAlive) {
            self.timeToDie -= delta;
            if (self.timeToDie < 0.0) {
                self.isAlive = false;
            }
        }
    }

    pub fn spawn(self: *Particle, position: rl.Vector2, duration: f32) void {
        self.isAlive = true;
        self.timeToDie = std.math.clamp(duration, 0.01, 1.0);
        self.position = position;
    }

    pub fn draw(self: Particle) void {
        if (self.timeToDie < 0.01) return;

        rl.drawCircleV(self.position, 2, .{
            .r = 255,
            .g = 255,
            .b = 0,
            .a = @as(u8, @intFromFloat(255.0 * self.timeToDie)),
        });
    }
};

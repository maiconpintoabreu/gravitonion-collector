const std = @import("std");
const math = std.math;
const rl = @import("raylib");

const constantsZig = @import("constants.zig");
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
    rightTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    leftTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    pub fn tick(self: *Player) void {
        self.physicsObject.velocity = rl.Vector2.clampValue(
            self.physicsObject.velocity,
            0,
            1.8,
        );
        self.physicsObject.tick();
        self.updateSlots();
    }
    pub fn updateSlots(self: *Player) void {
        self.gunSlot = self.physicsObject.position.add(self.physicsObject.direction.scale(10));
        const back = self.physicsObject.position.add(.{ .x = 0, .y = 8 });

        self.rightTurbineSlot = self.physicsObject.position.add(back.subtract(self.physicsObject.position).rotate(
            math.degreesToRadians(self.physicsObject.rotation - 25),
        ));

        self.leftTurbineSlot = self.physicsObject.position.add(back.subtract(self.physicsObject.position).rotate(
            math.degreesToRadians(self.physicsObject.rotation + 25),
        ));
    }
    pub fn draw(self: *Player) void {
        if (self.texture.id == 0) {
            return;
        }
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;

        // inverted
        if (self.physicsObject.isTurningRight or self.physicsObject.isAccelerating) {
            rl.drawCircleV(self.leftTurbineSlot, 1, .yellow);
        }
        if (self.physicsObject.isTurningLeft or self.physicsObject.isAccelerating) {
            rl.drawCircleV(self.rightTurbineSlot, 1, .yellow);
        }
        self.texture.drawPro(
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
            self.texture.unload();
        }
    }
};

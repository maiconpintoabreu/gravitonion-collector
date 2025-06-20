const std = @import("std");
const math = std.math;
const rl = @import("raylib");
pub const PhysicsObject = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    speed: f32 = 0.2,
    rotation: f32 = 90,
    torque: f32 = 0,
    rotationSpeed: f32 = 20,
    collisionSize: f32 = 7,
    isFacingMovement: bool = true,
    isTurningLeft: bool = false,
    isTurningRight: bool = false,
    isAccelerating: bool = false,
    pub fn tick(self: *PhysicsObject) void {
        self.position = rl.Vector2.add(self.position, self.velocity);
        if (self.isFacingMovement and !self.isAccelerating and !self.isTurningLeft and !self.isTurningRight) {
            var angle = math.radiansToDegrees(math.atan2(self.velocity.y, self.velocity.x)) + 90;
            if (angle > 180) {
                angle -= 360;
            }
            if (angle < -180) {
                angle += 360;
            }
            if (self.rotation > angle) {
                const rotDiff = self.rotation - angle;
                if (rotDiff > 180) {
                    self.rotation += 1;
                } else {
                    self.rotation -= 1;
                }
            } else {
                const rotDiff = angle - self.rotation;
                if (rotDiff > 180) {
                    self.rotation -= 1;
                } else {
                    self.rotation += 1;
                }
            }
        }
        if (self.rotation > 180.0) {
            self.rotation -= 360.0;
        } else if (self.rotation < -180.0) {
            self.rotation += 360.0;
        }
    }
    pub fn applyForce(self: *PhysicsObject, force: f32) void {
        const direction: rl.Vector2 = .{
            .x = math.sin(math.degreesToRadians(self.rotation)),
            .y = -math.cos(math.degreesToRadians(self.rotation)),
        };
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
        self.velocity = rl.Vector2.add(self.velocity, rl.Vector2.scale(norm_vector, force * self.speed));
    }
    pub fn applyDirectedForce(self: *PhysicsObject, force: rl.Vector2) void {
        self.velocity = rl.Vector2.add(self.velocity, force);
    }
    pub fn applyTorque(self: *PhysicsObject, torque: f32) void {
        self.rotation += torque * self.rotationSpeed;
    }
};

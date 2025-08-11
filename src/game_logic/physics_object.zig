const std = @import("std");
const math = std.math;
const rl = @import("raylib");
pub const PhysicsObject = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    speed: f32 = 2,
    rotation: f32 = 90,
    direction: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    torque: f32 = 0,
    rotationSpeed: f32 = 20,
    collisionSize: f32 = 10,
    currentTickLength: f32 = 0.01,
    defaultTickLength: f32 = 0.01,
    isTurningLeft: bool = false,
    isTurningRight: bool = false,
    isAccelerating: bool = false,
    pub fn tick(self: *PhysicsObject) void {
        if (!self.isAccelerating) {
            self.velocity = self.velocity.subtract(self.velocity.normalize().scale(0.002));
        }
        if (self.rotation > 180.0) {
            self.rotation -= 360.0;
        } else if (self.rotation < -180.0) {
            self.rotation += 360.0;
        }
        self.position = rl.Vector2.add(self.position, self.velocity);
        self.direction = rl.Vector2{
            .x = math.sin(math.degreesToRadians(self.rotation)),
            .y = -math.cos(math.degreesToRadians(self.rotation)),
        };
    }
    pub fn applyForce(self: *PhysicsObject, force: f32) void {
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(self.direction);
        self.velocity = self.velocity.add(rl.Vector2.scale(
            norm_vector,
            force * self.speed * 20,
        ));
    }
    pub fn applyDirectedForce(self: *PhysicsObject, force: rl.Vector2) void {
        self.velocity = self.velocity.add(force);
    }
    pub fn calculateWrap(self: *PhysicsObject, window: rl.Rectangle) void {
        if (self.position.x < window.x) {
            self.position.x = window.width;
        } else if (self.position.x > window.width) {
            self.position.x = window.x;
        }
        if (self.position.y < window.y) {
            self.position.y = window.height;
        } else if (self.position.y > window.height) {
            self.position.y = window.y;
        }
    }
    pub fn applyTorque(self: *PhysicsObject, torque: f32) void {
        self.rotation += torque * self.rotationSpeed;
    }
};

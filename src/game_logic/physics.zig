const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");

pub var physicsSystem: PhysicsSystem = .{};
pub const PhysicsShapeCircular = struct {
    radius: f32 = 0.0,
};

// Set only 4 points for now add more if needed
pub const PhysicsShapePolygon = struct {
    pointCount: usize = 0,
    points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2),
};
pub const PhysicsShapeUnion = union(enum) {
    Circular: PhysicsShapeCircular,
    Polygon: PhysicsShapePolygon,
};
pub const PhysicsBodyInitiator = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    shape: ?PhysicsShapeUnion = null, // optional for now. TODO: make it not optional if possible
    useGravity: bool = false, // Apply gravity force to dynamics
    mass: f32 = 0.0, // Physics body mass
    enabled: bool = false,
};
pub const PhysicsBody = struct {
    id: i32 = -1,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    force: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear force (reset to 0 every step)
    angularVelocity: f32 = 0.0, // Current angular velocity applied to orient
    torque: f32 = 0.0, // Current angular force (reset to 0 every step)
    orient: f32 = 0.0, // Rotation in radians
    inertia: f32 = 0.0, // Moment of inertia
    inverseInertia: f32 = 0.0, // Inverse value of inertia
    mass: f32 = 0.0, // Physics body mass
    inverseMass: f32 = 0.0, // Inverse value of mass
    staticFriction: f32 = 0.0, // Friction when the body has not movement (0 to 1)
    dynamicFriction: f32 = 0.0, // Friction when the body has movement (0 to 1)
    restitution: f32 = 0.0, // Restitution coefficient of the body (0 to 1)
    useGravity: bool = false, // Apply gravity force to dynamics
    freezeOrient: bool = false, // Physics rotation constraint
    collidesWIthPlayer: bool = false,
    isColliding: bool = false,
    collidingWith: ?*PhysicsBody = null,
    shape: ?PhysicsShapeUnion = null,
    enabled: bool = false,
};
pub const PhysicsSystem = struct {
    physicsBodyCount: usize = 0,
    currentId: i32 = 0,
    physicsBodies: [configZig.MAX_PHYSICS_OBJECTS]PhysicsBody = std.mem.zeroes([configZig.MAX_PHYSICS_OBJECTS]PhysicsBody),

    pub fn getBody(self: *PhysicsSystem, id: i32) ?*PhysicsBody {
        for (&self.physicsBodies) |*body| {
            if (body.id == id) {
                return body;
            }
        }
        return null;
    }

    pub fn createBody(self: *PhysicsSystem, physicsBodyInit: PhysicsBodyInitiator) i32 {
        if (physicsBodyInit.enabled) {
            self.physicsBodies[self.physicsBodyCount] = PhysicsBody{
                .id = self.currentId,
                .position = physicsBodyInit.position,
                .mass = physicsBodyInit.mass,
                .shape = physicsBodyInit.shape,
                .enabled = physicsBodyInit.enabled,
            };
            self.physicsBodyCount += 1;
        }
        self.currentId += 1;
        return self.currentId - 1;
    }

    pub fn tick(self: *PhysicsSystem, delta: f32, gravity: rl.Vector2) void {
        //TODO: calculate gravity
        rl.traceLog(.info, "Tick: %i", .{self.physicsBodyCount});
        for (&self.physicsBodies) |*body| {
            if (body.enabled) continue;
            rl.traceLog(.info, "PhysicsBody Enable id: %i", .{body.id});
        }

        //TODO: check collision
        for (0..self.physicsBodyCount) |i| {
            for (0..self.physicsBodyCount) |j| {
                if (i == j) continue;
            }
        }
        _ = delta;
        _ = gravity;
    }
};

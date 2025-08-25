const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
var physicsSystem: PhysicsSystem = .{};

pub fn getPhysicsSystem() *PhysicsSystem {
    return &physicsSystem;
}

pub const PhysicsShapeCircular = struct {
    radius: f32 = 0.0,
};

pub const PhysicsBodyTagEnum = enum {
    Player,
    Asteroid,
    PlayerBullet,
    Blackhole,
    Phaser,
};
pub const Collidable = struct {
    ptr: *anyopaque,
    impl: *const Interface,

    pub const Interface = struct {
        collidingWith: *const fn (ctx: *anyopaque, data: *PhysicsBody) void,
    };

    pub fn collidingWith(self: Collidable, data: *PhysicsBody) void {
        return self.impl.collidingWith(self.ptr, data);
    }
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
    tag: PhysicsBodyTagEnum = PhysicsBodyTagEnum.Asteroid,
    owner: *anyopaque = undefined,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    shape: ?PhysicsShapeUnion = null, // optional for now. TODO: make it not optional if possible
    useGravity: bool = false, // Apply gravity force to dynamics
    mass: f32 = 0.0, // Physics body mass
    enabled: bool = false,
    isWrapable: bool = false,
};
pub const PhysicsBody = struct {
    id: i32 = -1,
    tag: PhysicsBodyTagEnum = PhysicsBodyTagEnum.Asteroid,
    owner: ?*anyopaque = null,
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
    collidingWith: ?*anyopaque = null,
    collidingWithTag: ?PhysicsBodyTagEnum = null,
    shape: ?PhysicsShapeUnion = null,
    enabled: bool = false,
    isWrapable: bool = false,
    isVisible: bool = true,
};
pub const PhysicsSystem = struct {
    physicsBodyCount: usize = 0,
    currentId: i32 = 0,
    physicsBodies: [configZig.MAX_PHYSICS_OBJECTS]PhysicsBody = std.mem.zeroes([configZig.MAX_PHYSICS_OBJECTS]PhysicsBody),
    pub fn resetById(self: *PhysicsSystem, id: i32) void {
        const idUsized = @as(usize, @intCast(id));
        self.physicsBodies[idUsized].isColliding = false;
    }
    pub fn reset(self: *PhysicsSystem, tag: PhysicsBodyTagEnum) void {
        for (&self.physicsBodies) |*body| {
            if (body.tag == tag) {
                body.enabled = false;
                body.isColliding = false;
                body.collidingWith = null;
                body.collidingWithTag = null;
            }
        }
    }
    pub fn getBody(self: *PhysicsSystem, id: i32) PhysicsBody {
        return self.physicsBodies[@as(usize, @intCast(id))];
    }
    pub fn changeBodyShape(self: *PhysicsSystem, id: i32, shape: PhysicsShapeUnion) void {
        const idUsized = @as(usize, @intCast(id));
        self.physicsBodies[idUsized].shape = shape;
    }

    // TODO: change EnableDesable system to resort the array to keep only enabled bodies on the beginning
    // may need to change id system
    pub fn enableBody(self: *PhysicsSystem, id: i32) void {
        const idUsized = @as(usize, @intCast(id));
        if (self.physicsBodies[idUsized].tag == PhysicsBodyTagEnum.PlayerBullet) {
            self.physicsBodies[idUsized].enabled = true;
        } else if (self.physicsBodies[idUsized].tag == PhysicsBodyTagEnum.Asteroid) {
            self.physicsBodies[idUsized].enabled = true;
        } else {
            self.physicsBodies[idUsized].enabled = true;
        }
    }

    pub fn disableBody(self: *PhysicsSystem, id: i32) void {
        const idUsized = @as(usize, @intCast(id));
        self.physicsBodies[idUsized].enabled = false;
    }

    pub fn moveBody(self: *PhysicsSystem, id: i32, position: rl.Vector2, orient: f32) void {
        const idUsized = @as(usize, @intCast(id));
        self.physicsBodies[idUsized].position = position;
        self.physicsBodies[idUsized].orient = orient;
        self.physicsBodies[idUsized].velocity = std.mem.zeroes(rl.Vector2);
        self.physicsBodies[idUsized].isVisible = true;
    }

    pub fn applyForceToBody(self: *PhysicsSystem, id: i32, force: f32) void {
        var body = &self.physicsBodies[@as(usize, @intCast(id))];
        const direction = rl.Vector2{
            .x = math.sin(body.orient),
            .y = -math.cos(body.orient),
        };
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
        body.force = body.force.add(norm_vector.scale(force));
    }

    pub fn applyTorqueToBody(self: *PhysicsSystem, id: i32, torque: f32) void {
        var body = &self.physicsBodies[@as(usize, @intCast(id))];
        body.torque += torque;
    }

    pub fn createBody(self: *PhysicsSystem, physicsBodyInit: PhysicsBodyInitiator) i32 {
        const id = @as(i32, @intCast(self.physicsBodyCount));
        self.physicsBodies[self.physicsBodyCount] = PhysicsBody{
            .id = id,
            .owner = physicsBodyInit.owner,
            .position = physicsBodyInit.position,
            .mass = physicsBodyInit.mass,
            .shape = physicsBodyInit.shape,
            .useGravity = physicsBodyInit.useGravity,
            .enabled = physicsBodyInit.enabled,
            .isWrapable = physicsBodyInit.isWrapable,
            .tag = physicsBodyInit.tag,
        };
        self.physicsBodyCount += 1;
        return id;
    }

    pub fn tick(self: *PhysicsSystem, delta: f32, gravityScale: f32) void {
        for (&self.physicsBodies) |*body| {
            if (!body.enabled) continue;

            // reset body
            body.isColliding = false;
            body.collidingWith = null;
            body.collidingWithTag = null;

            const gravityDirection = configZig.NATIVE_CENTER.subtract(body.position).normalize();
            body.orient += body.angularVelocity;

            // Calculate force or Calculate gravity
            if (body.force.length() > 0) {
                body.velocity = body.velocity.add(body.force);
            } else {
                if (body.useGravity) {
                    body.velocity = body.velocity.add(gravityDirection.scale(body.mass * gravityScale * delta / 2));
                }
            }

            body.angularVelocity = body.torque * 1 * (delta / 2.0);

            body.position = body.position.add(body.velocity);

            if (body.isWrapable) {
                if (body.position.x < 0.0) {
                    body.position.x = configZig.NATIVE_WIDTH;
                } else if (body.position.x > configZig.NATIVE_WIDTH) {
                    body.position.x = 0.0;
                }
                if (body.position.y < 0.0) {
                    body.position.y = configZig.NATIVE_HEIGHT;
                } else if (body.position.y > configZig.NATIVE_HEIGHT) {
                    body.position.y = 0.0;
                }
            } else {
                if (body.position.x < 0.0) {
                    body.isVisible = false;
                    body.enabled = false;
                } else if (body.position.x > configZig.NATIVE_WIDTH) {
                    body.isVisible = false;
                    body.enabled = false;
                } else if (body.position.y < 0.0) {
                    body.isVisible = false;
                    body.enabled = false;
                } else if (body.position.y > configZig.NATIVE_HEIGHT) {
                    body.isVisible = false;
                    body.enabled = false;
                } else {
                    body.isVisible = true;
                }
            }

            // clear torque and force
            body.force.x = 0;
            body.force.y = 0;
            body.torque = 0;
        }
        checkCollisions(self.*);
    }
    pub fn debug(self: PhysicsSystem) void {
        if (configZig.IS_DEBUG) {
            for (self.physicsBodies) |body| {
                if (!body.enabled) continue;

                switch (body.shape.?) {
                    .Circular => |shape| {
                        rl.drawCircleLinesV(
                            body.position,
                            shape.radius,
                            .yellow,
                        );
                    },
                    else => {},
                }
            }
        }
    }
    fn checkCollisions(self: *PhysicsSystem) void {
        for (0..self.physicsBodyCount) |i| {
            if (!self.physicsBodies[i].enabled) continue;
            for (0..self.physicsBodyCount) |j| {
                if (i == j) continue;
                if (!self.physicsBodies[j].enabled) continue;
                // check tag combination to see if can collide
                var shouldCollide = false;
                switch (self.physicsBodies[i].tag) {
                    .PlayerBullet => {
                        switch (self.physicsBodies[j].tag) {
                            .Blackhole => {
                                shouldCollide = true;
                            },
                            .Asteroid => {
                                shouldCollide = true;
                            },
                            .Phaser => {
                                shouldCollide = true;
                            },
                            else => {},
                        }
                    },
                    .Player => {
                        switch (self.physicsBodies[j].tag) {
                            .Blackhole => {
                                shouldCollide = true;
                            },
                            .Asteroid => {
                                shouldCollide = true;
                            },
                            .Phaser => {
                                shouldCollide = true;
                            },
                            else => {},
                        }
                    },
                    .Asteroid => {
                        switch (self.physicsBodies[j].tag) {
                            .Blackhole => {
                                shouldCollide = true;
                            },
                            .Phaser => {
                                shouldCollide = true;
                            },
                            else => {},
                        }
                    },
                    else => {},
                }
                if (!shouldCollide) {
                    continue;
                }
                switch (self.physicsBodies[i].shape.?) {
                    .Circular => |leftShape| {
                        switch (self.physicsBodies[j].shape.?) {
                            .Circular => |rightShape| {
                                if (rl.checkCollisionCircles(
                                    self.physicsBodies[i].position,
                                    leftShape.radius,
                                    self.physicsBodies[j].position,
                                    rightShape.radius,
                                )) {
                                    setCollision(&self.physicsBodies[i], &self.physicsBodies[j]);
                                }
                            },
                            .Polygon => |rightShape| {
                                const points = rightShape.points[0..rightShape.pointCount];
                                if (rl.checkCollisionPointPoly(
                                    self.physicsBodies[i].position,
                                    points,
                                )) {
                                    setCollision(&self.physicsBodies[i], &self.physicsBodies[j]);
                                }
                            },
                        }
                    },
                    // TODO: implement polygon collisions
                    .Polygon => {
                        switch (self.physicsBodies[i].shape.?) {
                            .Circular => {},
                            .Polygon => {},
                        }
                    },
                }
            }
        }
    }
    fn setCollision(bodyFrom: PhysicsBody, bodyTo: *PhysicsBody) void {
        const owner: *Collidable = @as(*Collidable, @ptrCast(@alignCast(bodyFrom.owner)));
        owner.collidingWith(bodyTo);
        const otherOwner: *Collidable = @as(*Collidable, @ptrCast(@alignCast(bodyTo.owner)));
        otherOwner.collidingWith(bodyFrom);
    }
};

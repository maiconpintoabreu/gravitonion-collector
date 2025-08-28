const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");

// TODO: Find a way to remove this global variable
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

// Set only 4 points for now add more if needed
pub const PhysicsShapePolygon = struct {
    pointCount: usize = 0,
    points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2),
};

pub const PhysicsShapeUnion = union(enum) {
    Circular: PhysicsShapeCircular,
    Polygon: PhysicsShapePolygon,
};

pub const PhysicsBody = struct {
    id: i32 = -1,
    tag: PhysicsBodyTagEnum = PhysicsBodyTagEnum.Asteroid,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    force: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear force (reset to 0 every step)
    angularVelocity: f32 = 0.0, // Current angular velocity applied to orient
    torque: f32 = 0.0, // Current angular force (reset to 0 every step)
    orient: f32 = 0.0, // Rotation in radians
    mass: f32 = 0.0, // Physics body mass
    useGravity: bool = false, // Apply gravity force to dynamics
    isColliding: bool = false,
    collidingWith: ?*PhysicsBody = null,
    shape: PhysicsShapeUnion = undefined,
    enabled: bool = false,
    isWrapable: bool = false,
    isVisible: bool = true,
};
pub const PhysicsSystem = struct {
    physicsBodyCount: usize = 0,
    currentId: i32 = 0,
    physicsBodyList: [configZig.MAX_PHYSICS_OBJECTS]*PhysicsBody = undefined,

    pub fn resetById(self: *PhysicsSystem, id: i32) void {
        self.physicsBodyList[@as(usize, @intCast(id))].isColliding = false;
    }

    pub fn reset(self: *PhysicsSystem, tag: PhysicsBodyTagEnum) void {
        for (0..self.physicsBodyCount) |i| {
            var body = self.physicsBodyList[i];
            if (body.tag == tag) {
                body.enabled = false;
                body.isColliding = false;
                body.collidingWith = null;
            }
        }
    }

    // no needed anymore as body lives inside the gameobject
    // pub fn getBody(self: *PhysicsSystem, id: i32) PhysicsBody {
    //     return self.physicsBodies[@as(usize, @intCast(id))];
    // }

    pub fn changeBodyShape(self: *PhysicsSystem, id: i32, shape: PhysicsShapeUnion) void {
        self.physicsBodyList[@as(usize, @intCast(id))].shape = shape;
    }

    // TODO: change EnableDesable system to resort the array to keep only enabled bodies on the beginning
    // may need to change id system
    pub fn enableBody(self: *PhysicsSystem, id: i32) void {
        var body = self.physicsBodyList[@as(usize, @intCast(id))];
        if (body.tag == PhysicsBodyTagEnum.PlayerBullet) {
            body.enabled = true;
        } else if (body.tag == PhysicsBodyTagEnum.Asteroid) {
            body.enabled = true;
        } else {
            body.enabled = true;
        }
    }

    pub fn disableBody(self: *PhysicsSystem, id: i32) void {
        self.physicsBodyList[@as(usize, @intCast(id))].enabled = false;
    }

    pub fn moveBody(self: *PhysicsSystem, id: i32, position: rl.Vector2, orient: f32) void {
        var body = self.physicsBodyList[@as(usize, @intCast(id))];
        body.position = position;
        body.orient = orient;
        body.velocity = std.mem.zeroes(rl.Vector2);
        body.isVisible = true;
    }

    pub fn applyForceToBody(self: *PhysicsSystem, id: i32, force: f32) void {
        var body = self.physicsBodyList[@as(usize, @intCast(id))];
        const direction = rl.Vector2{
            .x = math.sin(body.orient),
            .y = -math.cos(body.orient),
        };
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
        body.force = body.force.add(norm_vector.scale(force));
    }

    pub fn applyTorqueToBody(self: *PhysicsSystem, id: i32, torque: f32) void {
        self.physicsBodyList[@as(usize, @intCast(id))].torque += torque;
    }

    pub fn addBody(self: *PhysicsSystem, body: *PhysicsBody) i32 {
        body.id = @as(i32, @intCast(self.physicsBodyCount));
        self.physicsBodyList[self.physicsBodyCount] = body;
        self.physicsBodyCount += 1;
        return body.id;
    }

    pub fn tick(self: *PhysicsSystem, delta: f32, gravityScale: f32) void {
        for (0..self.physicsBodyCount) |i| {
            var body = self.physicsBodyList[i];
            if (!body.enabled) continue;

            // reset body
            body.isColliding = false;
            body.collidingWith = null;

            const gravityDirection = configZig.NATIVE_CENTER.subtract(body.position).normalize();
            body.orient += body.angularVelocity;

            // Increases gravity by how close it is
            const blackholeDistance = (1 / (body.position.distance(configZig.NATIVE_CENTER) + 0.1)) * 100.0;

            // Calculate force or Calculate gravity
            if (body.force.length() > 0) {
                body.velocity = body.velocity.add(body.force);
            } else {
                if (body.useGravity) {
                    body.velocity = body.velocity.add(gravityDirection.scale(body.mass * blackholeDistance * gravityScale * delta / 2));
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
        checkCollisions(self);
    }

    pub fn debug(self: PhysicsSystem) void {
        if (configZig.IS_DEBUG) {
            for (0..self.physicsBodyCount) |i| {
                const body = self.physicsBodyList[i];
                if (!body.enabled) continue;

                const color = if (body.isColliding) rl.Color.white else rl.Color.yellow;

                switch (body.shape) {
                    .Circular => |shape| {
                        rl.drawCircleLinesV(body.position, shape.radius, color);
                    },
                    .Polygon => |shape| {
                        rl.drawLineV(shape.points[0], shape.points[2], color);
                        rl.drawLineV(shape.points[2], shape.points[3], color);
                        rl.drawLineV(shape.points[3], shape.points[1], color);
                        rl.drawLineV(shape.points[1], shape.points[0], color);
                    },
                }
            }
        }
    }

    // TODO: Improve it if needed
    fn checkCollisions(self: *PhysicsSystem) void {
        for (0..self.physicsBodyCount) |i| {
            const leftBody = self.physicsBodyList[i];
            if (!leftBody.enabled) continue;
            for (0..self.physicsBodyCount) |j| {
                if (i == j) continue;
                const rightBody = self.physicsBodyList[j];
                if (!rightBody.enabled) continue;
                // check tag combination to see if can collide
                var shouldCollide = false;
                switch (leftBody.tag) {
                    .PlayerBullet => {
                        switch (rightBody.tag) {
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
                        switch (rightBody.tag) {
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
                        switch (rightBody.tag) {
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
                switch (leftBody.shape) {
                    .Circular => |leftShape| {
                        switch (rightBody.shape) {
                            .Circular => |rightShape| {
                                if (rl.checkCollisionCircles(
                                    leftBody.position,
                                    leftShape.radius,
                                    rightBody.position,
                                    rightShape.radius,
                                )) {
                                    setCollision(leftBody, rightBody);
                                }
                            },
                            .Polygon => |rightShape| {
                                const points = rightShape.points[0..rightShape.pointCount];
                                if (rl.checkCollisionPointPoly(
                                    leftBody.position,
                                    points,
                                )) {
                                    setCollision(leftBody, rightBody);
                                    continue;
                                }
                                if (rl.checkCollisionPointPoly(
                                    leftBody.position.add(.{
                                        .x = leftShape.radius / 2,
                                        .y = 0,
                                    }),
                                    points,
                                )) {
                                    setCollision(leftBody, rightBody);
                                    continue;
                                }
                                if (rl.checkCollisionPointPoly(
                                    leftBody.position.add(.{
                                        .x = -leftShape.radius / 2,
                                        .y = 0,
                                    }),
                                    points,
                                )) {
                                    setCollision(leftBody, rightBody);
                                    continue;
                                }
                                if (rl.checkCollisionPointPoly(
                                    leftBody.position.add(.{
                                        .x = 0,
                                        .y = leftShape.radius / 2,
                                    }),
                                    points,
                                )) {
                                    setCollision(leftBody, rightBody);
                                    continue;
                                }
                                if (rl.checkCollisionPointPoly(
                                    leftBody.position.add(.{
                                        .x = 0,
                                        .y = -leftShape.radius / 2,
                                    }),
                                    points,
                                )) {
                                    setCollision(leftBody, rightBody);
                                    continue;
                                }
                            },
                        }
                    },
                    // TODO: implement polygon collisions
                    .Polygon => {
                        switch (leftBody.shape) {
                            .Circular => {},
                            .Polygon => {},
                        }
                    },
                }
            }
        }
    }
    fn setCollision(bodyFrom: *PhysicsBody, bodyTo: *PhysicsBody) void {
        bodyFrom.isColliding = true;
        bodyFrom.collidingWith = bodyTo;
        bodyTo.isColliding = true;
        bodyTo.collidingWith = bodyFrom;
    }
};

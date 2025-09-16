const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");

pub const PhysicsBodyTagEnum = enum {
    Player,
    Asteroid,
    PlayerBullet,
    Blackhole,
    Phaser,
    PickupItem,

    pub fn getName(self: PhysicsBodyTagEnum) c_int {
        return switch (self) {
            .Player => 0,
            .Asteroid => 1,
            .PlayerBullet => 2,
            .Blackhole => 3,
            .Phaser => 4,
            .PickupItem => 5,
        };
    }
};

pub const PhysicsShapeCircular = struct {
    radius: f32 = 0.0,

    fn draw(self: PhysicsShapeCircular, position: rl.Vector2, color: rl.Color) void {
        rl.drawCircleLinesV(position, self.radius, color);
    }
};

// Set only 4 points for now add more if needed
pub const PhysicsShapePolygon = struct {
    pointCount: usize = 0,
    points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2),

    fn draw(self: PhysicsShapePolygon, _: rl.Vector2, color: rl.Color) void {
        rl.drawLineV(self.points[0], self.points[2], color);
        rl.drawLineV(self.points[2], self.points[3], color);
        rl.drawLineV(self.points[3], self.points[1], color);
        rl.drawLineV(self.points[1], self.points[0], color);
    }
};

pub const PhysicsShapeUnion = union(enum) {
    Circular: PhysicsShapeCircular,
    Polygon: PhysicsShapePolygon,
};

pub const CollisionData = struct {
    tag: PhysicsBodyTagEnum = undefined,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    mass: f32 = 0.0, // Physics body mass
};

pub const PhysicsBody = struct {
    id: usize = undefined,
    tag: PhysicsBodyTagEnum = undefined,
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Physics body shape pivot
    velocity: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear velocity applied to position
    force: rl.Vector2 = std.mem.zeroes(rl.Vector2), // Current linear force (reset to 0 every step)
    speedLimit: f32 = configZig.MAX_BODY_VELOCITY,
    angularVelocity: f32 = 0.0, // Current angular velocity applied to orient
    torque: f32 = 0.0, // Current angular force (reset to 0 every step)
    orient: f32 = 0.0, // Rotation in radians
    mass: f32 = 0.0, // Physics body mass
    useGravity: bool = false, // Apply gravity force to dynamics
    isColliding: bool = false,
    collidingData: ?CollisionData = null,
    shape: PhysicsShapeUnion = undefined,
    enabled: bool = true,
    isWrapable: bool = false,
    isVisible: bool = true,
    isAlive: bool = true,
};

pub const PhysicsSystem = struct {
    physicsBodyCount: usize = 0,
    currentId: i32 = 0,
    physicsBodyList: [configZig.MAX_PHYSICS_OBJECTS]PhysicsBody = undefined,

    pub fn reset(self: *PhysicsSystem) void {
        self.physicsBodyCount = 3;

        self.physicsBodyList[0].speedLimit = configZig.MAX_BODY_VELOCITY;
        self.physicsBodyList[0].useGravity = true;
        self.physicsBodyList[2].enabled = false;
    }

    pub fn changeBodyShape(self: *PhysicsSystem, id: usize, shape: PhysicsShapeUnion) void {
        self.physicsBodyList[id].shape = shape;
    }

    // TODO: change EnableDesable system to resort the array to keep only enabled bodies on the beginning
    // may need to change id system
    pub fn enableBody(self: *PhysicsSystem, id: usize) void {
        self.physicsBodyList[id].enabled = true;
    }

    pub fn disableBody(self: *PhysicsSystem, id: usize) void {
        var body = &self.physicsBodyList[id];
        body.enabled = false;
        body.isColliding = false;
        body.collidingData = null;
    }

    pub fn moveBody(self: *PhysicsSystem, id: usize, position: rl.Vector2, orient: f32) void {
        const body = &self.physicsBodyList[id];
        body.position = position;
        body.orient = orient;
        body.velocity = std.mem.zeroes(rl.Vector2);
        body.isVisible = true;
    }

    // Apply force will project the body forward by orient
    pub fn applyForceToBody(self: *PhysicsSystem, id: usize, force: f32) void {
        const body = &self.physicsBodyList[id];
        const direction = rl.Vector2{
            .x = math.sin(body.orient),
            .y = -math.cos(body.orient),
        };
        const norm_vector: rl.Vector2 = rl.Vector2.normalize(direction);
        body.force = body.force.add(norm_vector.scale(force));
    }

    pub fn applyTorqueToBody(self: *PhysicsSystem, id: usize, torque: f32) void {
        self.physicsBodyList[id].torque += torque;
    }

    pub fn getBody(self: PhysicsSystem, id: usize) PhysicsBody {
        return self.physicsBodyList[id];
    }

    pub fn resetBody(self: *PhysicsSystem, id: usize) void {
        self.physicsBodyList[id].collidingData = null;
        self.physicsBodyList[id].isColliding = false;
    }

    pub fn setUseGravityBody(self: *PhysicsSystem, id: usize, value: bool) void {
        self.physicsBodyList[id].useGravity = value;
    }

    pub fn addBody(self: *PhysicsSystem, initBody: *PhysicsBody) usize {
        var body: PhysicsBody = initBody.*;
        for (0..self.physicsBodyCount) |i| {
            if (!self.physicsBodyList[i].isAlive) {
                body.id = i;
                self.physicsBodyList[i] = body;
                return i;
            }
        }
        body.id = self.physicsBodyCount;
        self.physicsBodyList[self.physicsBodyCount] = body;
        self.physicsBodyCount += 1;
        return body.id;
    }

    pub fn removeBody(self: *PhysicsSystem, id: usize) void {
        if (self.physicsBodyCount == 0) return;
        self.physicsBodyList[id].isAlive = false;
    }

    pub fn tick(self: *PhysicsSystem, delta: f32, gravityScale: f32) void {
        for (0..self.physicsBodyCount) |i| {
            var body = &self.physicsBodyList[i];
            if (!body.isAlive) continue;
            if (!body.enabled) continue;

            const gravityDirection = configZig.NATIVE_CENTER.subtract(body.position).normalize();
            body.angularVelocity = body.torque * 1 * (delta / 2.0);
            body.orient += body.angularVelocity;

            // Increases gravity by how close it is
            const BlackholeDistance = (0.5 / (body.position.distance(configZig.NATIVE_CENTER) + 0.1)) * 100.0;

            // Calculate force or Calculate gravity
            if (body.force.length() > 0) {
                body.velocity = body.velocity.add(body.force);
            } else {
                if (body.useGravity) {
                    body.velocity = body.velocity.add(gravityDirection.scale(body.mass * BlackholeDistance * gravityScale).scale(delta));
                }
            }
            body.velocity.x = math.clamp(body.velocity.x, -body.speedLimit, body.speedLimit);
            body.velocity.y = math.clamp(body.velocity.y, -body.speedLimit, body.speedLimit);
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
        // std.debug.print("Test {d}", .{self.physicsBodyCount});
        if (self.physicsBodyCount > 1) {
            self.checkCollisions();
        }
    }

    pub fn debug(self: PhysicsSystem) void {
        if (configZig.IS_DEBUG) {
            for (0..self.physicsBodyCount) |i| {
                const body = self.physicsBodyList[i];
                if (!body.isAlive) continue;
                if (!body.enabled) continue;

                const color = if (body.isColliding) rl.Color.white else rl.Color.yellow;

                switch (body.shape) {
                    inline else => |shape| shape.draw(body.position, color),
                }
            }
        }
    }

    // TODO: Improve it if needed
    fn checkCollisions(self: *PhysicsSystem) void {
        for (0..self.physicsBodyCount) |i| {
            const leftBody = &self.physicsBodyList[i];
            if (!leftBody.isAlive) continue;
            if (!leftBody.enabled) continue;
            for (0..self.physicsBodyCount) |j| {
                if (i == j) continue;
                const rightBody = &self.physicsBodyList[j];
                if (!rightBody.isAlive) continue;
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
                            .PickupItem => {
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
                    .PickupItem => {
                        switch (rightBody.tag) {
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
                                var collision = false;

                                const dx: f32 = rightBody.position.x - leftBody.position.x; // X distance between centers
                                const dy: f32 = rightBody.position.y - leftBody.position.y; // Y distance between centers

                                const distanceSquared: f32 = dx * dx + dy * dy; // Distance between centers squared
                                const radiusSum: f32 = leftShape.radius + rightShape.radius;

                                collision = (distanceSquared <= (radiusSum * radiusSum));
                                if (collision) {
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
        bodyFrom.collidingData = .{
            .tag = bodyTo.tag,
            .position = bodyTo.position,
            .velocity = bodyTo.velocity,
            .mass = bodyTo.mass,
        };
        bodyTo.isColliding = true;
        bodyTo.collidingData = .{
            .tag = bodyFrom.tag,
            .position = bodyFrom.position,
            .velocity = bodyFrom.velocity,
            .mass = bodyFrom.mass,
        };
    }
};

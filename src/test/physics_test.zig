const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;

test "PhysicsSystem physicsBodyCount should be 0 from start" {
    try testing.expectEqual(0, PhysicsZig.getPhysicsSystem().physicsBodyCount);
}

test "PhysicsSystem Create/Get Circular Body" {
    const physicsBodyInit: PhysicsBodyInitiator = .{
        .position = .{
            .x = 0,
            .y = 0,
        },
        .mass = 10,
        .useGravity = true,
        .velocity = .{ .x = 0, .y = 0 },
        .shape = .{
            .Circular = .{
                .radius = 5,
            },
        },
        .enabled = true,
        .isWrapable = false,
    };
    const id = PhysicsZig.getPhysicsSystem().createBody(physicsBodyInit);

    const body = PhysicsZig.getPhysicsSystem().getBody(id);
    if (body.shape == null) {
        try testing.expect(false);
        return;
    }
    switch (body.shape.?) {
        .Circular => |shape| {
            try testing.expectEqual(5, shape.radius);
        },
        else => {
            try testing.expect(false);
            return;
        },
    }
    try testing.expectEqual(10, body.mass);
}

test "PhysicsSystem Create/Get Polygon Body" {
    var points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2);
    points[0].x = 10;
    points[1].y = 10;
    const physicsCircularBodyInit: PhysicsBodyInitiator = .{
        .position = .{
            .x = 0,
            .y = 0,
        },
        .mass = 10,
        .useGravity = true,
        .velocity = .{ .x = 0, .y = 0 },
        .shape = .{
            .Circular = .{
                .radius = 10,
            },
        },
        .enabled = true,
        .isWrapable = false,
    };
    for (0..20) |_| {
        _ = PhysicsZig.getPhysicsSystem().createBody(physicsCircularBodyInit);
    }
    const physicsBodyInit: PhysicsBodyInitiator = .{
        .position = .{
            .x = 0,
            .y = 0,
        },
        .mass = 10,
        .useGravity = true,
        .velocity = .{ .x = 0, .y = 0 },
        .shape = .{
            .Polygon = .{
                .pointCount = 2,
                .points = points,
            },
        },
        .enabled = true,
        .isWrapable = false,
    };
    const id = PhysicsZig.getPhysicsSystem().createBody(physicsBodyInit);
    const body = PhysicsZig.getPhysicsSystem().getBody(id);
    if (body.shape == null) {
        try testing.expect(false);
    }
    switch (body.shape.?) {
        .Polygon => |shape| {
            try testing.expectEqual(2, shape.pointCount);
        },
        else => {
            try testing.expect(false);
        },
    }
    try testing.expectEqual(10, body.mass);
}

test "PhysicsSystem Body should be affecte by gravity" {
    const physicsCircularBodyInit: PhysicsBodyInitiator = .{
        .position = .{
            .x = 0,
            .y = 0,
        },
        .mass = 10,
        .useGravity = true,
        .velocity = .{ .x = 0, .y = 0 },
        .shape = .{
            .Circular = .{
                .radius = 10,
            },
        },
        .enabled = true,
        .isWrapable = false,
    };
    const id = PhysicsZig.getPhysicsSystem().createBody(physicsCircularBodyInit);
    PhysicsZig.getPhysicsSystem().moveBody(id, .{ .x = 101.0, .y = 102.0 }, 0.5);
    const body = PhysicsZig.getPhysicsSystem().getBody(id);
    try testing.expect(body.position.x > 100.0);
    try testing.expect(body.position.y > 101.0);
    PhysicsZig.getPhysicsSystem().tick(1, 10);
    const gravitedBody = PhysicsZig.getPhysicsSystem().getBody(id);

    // check if possition changed - X: 110.420334, Y: 105.35519
    try testing.expectEqual(0, body.position.equals(gravitedBody.position));
    try testing.expectApproxEqAbs(0.5, body.orient, 0.0);
}

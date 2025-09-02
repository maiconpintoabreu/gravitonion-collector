const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;

test "PhysicsSystem physicsBodyCount should be 0 from start" {
    try testing.expectEqual(0, PhysicsZig.getPhysicsSystem().physicsBodyCount);
}

test "PhysicsSystem Create/Get Circular Body" {
    var body: PhysicsBody = .{
        .mass = 10,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 5,
            },
        },
        .enabled = true,
    };
    PhysicsZig.getPhysicsSystem().addBody(&body);

    switch (body.shape) {
        .Circular => |shape| {
            try testing.expectEqual(5, shape.radius);
        },
        else => {
            try testing.expect(false);
            return;
        },
    }
    try testing.expectEqual(10, body.mass);
    try testing.expect(body.id >= 0);
}

test "PhysicsSystem Create/Get Polygon Body" {
    var points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2);
    points[0].x = 10;
    points[1].y = 10;
    var physicsCircularBody: PhysicsBody = .{
        .mass = 10,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 10,
            },
        },
        .enabled = true,
    };
    for (0..20) |_| {
        _ = PhysicsZig.getPhysicsSystem().addBody(&physicsCircularBody);
    }
    var body: PhysicsBody = .{
        .mass = 10,
        .useGravity = true,
        .shape = .{
            .Polygon = .{
                .pointCount = 2,
                .points = points,
            },
        },
        .enabled = true,
    };

    PhysicsZig.getPhysicsSystem().addBody(&body);

    switch (body.shape) {
        .Polygon => |shape| {
            try testing.expectEqual(2, shape.pointCount);
        },
        else => {
            try testing.expect(false);
        },
    }
    try testing.expectEqual(10, body.mass);
    try testing.expect(body.id >= 0);
}

test "PhysicsSystem Body should be affecte by gravity" {
    const initPosition: rl.Vector2 = .zero();
    var body: PhysicsBody = .{
        .position = initPosition,
        .mass = 10,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 10,
            },
        },
        .enabled = true,
    };
    PhysicsZig.getPhysicsSystem().addBody(&body);
    PhysicsZig.getPhysicsSystem().moveBody(body.id, .{ .x = 101.0, .y = 102.0 }, 0.5);
    try testing.expect(body.position.x > 100.0);
    try testing.expect(body.position.y > 101.0);
    PhysicsZig.getPhysicsSystem().tick(1.0, 10.0);

    // check if possition changed - X: 110.420334, Y: 105.35519
    try testing.expectEqual(0, initPosition.equals(body.position));
    try testing.expectApproxEqAbs(0.5, body.orient, 0.0);
}

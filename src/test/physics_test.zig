const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicsSystem = PhysicsZig.PhysicsSystem;

test "PhysicsSystem physicsBodyCount should be 0 from start" {
    const physics: PhysicsSystem = .{};
    try testing.expectEqual(0, physics.physicsBodyCount);
}

test "PhysicsSystem Create/Get Circular Body" {
    var physics: PhysicsSystem = .{};
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
    _ = physics.addBody(&body);

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
    var physics: PhysicsSystem = .{};
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
        _ = physics.addBody(&physicsCircularBody);
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

    const bodyId = physics.addBody(&body);
    const newBody = physics.getBody(bodyId);
    switch (newBody.shape) {
        .Polygon => |shape| {
            try testing.expectEqual(2, shape.pointCount);
        },
        else => {
            try testing.expect(false);
        },
    }
    try testing.expectEqual(10, newBody.mass);
    try testing.expect(newBody.id >= 0);
}

test "PhysicsSystem Body should be affected by gravity" {
    var physics: PhysicsSystem = .{};
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
    const bodyId = physics.addBody(&body);
    physics.moveBody(bodyId, .{ .x = 101.0, .y = 102.0 }, 0.5);
    physics.tick(1.0, 10.0);
    const newBody = physics.getBody(bodyId);

    // check if possition changed - X: 110.420334, Y: 105.35519
    try testing.expectEqual(0, initPosition.equals(newBody.position));
    try testing.expectApproxEqAbs(0.5, newBody.orient, 0.0);
}

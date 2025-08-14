const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const PhysicsBody = PhysicsZig.PhysicsBody;

test "PhysicsSystem physicsBodyCount should be 0 from start" {
    try testing.expectEqual(0, PhysicsZig.physicsSystem.physicsBodyCount);
}

test "PhysicsSystem Create Circular Body" {
    const id0 = PhysicsZig.physicsSystem.createCircularBody(.{
        .x = 0,
        .y = 0,
    }, 5, 10.0);
    const id1 = PhysicsZig.physicsSystem.createCircularBody(.{
        .x = 0,
        .y = 0,
    }, 5, 10.0);
    const id2 = PhysicsZig.physicsSystem.createCircularBody(.{
        .x = 0,
        .y = 0,
    }, 5, 10.0);

    try testing.expectEqual(0, id0);
    try testing.expectEqual(1, id1);
    try testing.expectEqual(2, id2);
}

test "PhysicsSystem Get Circular Body" {
    const id = PhysicsZig.physicsSystem.createCircularBody(
        .{
            .x = 0,
            .y = 0,
        },
        5,
        10.0,
    );
    const body = PhysicsZig.physicsSystem.getBody(id);
    if (body == null) {
        try testing.expect(false);
        return;
    }
    if (body.?.shape == null) {
        try testing.expect(false);
        return;
    }
    switch (body.?.shape.?) {
        .Circular => {
            try testing.expectEqual(5, body.?.shape.?.Circular.radius);
        },
        else => {
            try testing.expect(false);
            return;
        },
    }
    try testing.expectEqual(10, body.?.mass);
}

test "PhysicsSystem Get Polygon Body" {
    const pointCount = 2;
    var points: [configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2 = std.mem.zeroes([configZig.MAX_PHYSICS_POLYGON_POINTS]rl.Vector2);
    points[0].x = 10;
    points[1].y = 10;
    for (0..20) |_| {
        _ = PhysicsZig.physicsSystem.createCircularBody(.{
            .x = 0,
            .y = 0,
        }, 5, 10.0);
    }
    const id = PhysicsZig.physicsSystem.createPolygonBody(
        .{
            .x = 0,
            .y = 0,
        },
        points,
        pointCount,
        10,
    );
    const body = PhysicsZig.physicsSystem.getBody(id);
    if (body == null) {
        try testing.expect(false);
    }
    if (body.?.shape == null) {
        try testing.expect(false);
    }
    switch (body.?.shape.?) {
        .Polygon => {
            try testing.expectEqual(2, body.?.shape.?.Polygon.pointCount);
        },
        else => {
            try testing.expect(false);
        },
    }
    try testing.expectEqual(10, body.?.mass);
}

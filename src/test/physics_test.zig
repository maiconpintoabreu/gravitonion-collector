const std = @import("std");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;

test "PhysicsSystem physicsBodyCount should be 0 from start" {
    try testing.expectEqual(0, PhysicsZig.physicsSystem.physicsBodyCount);
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
    };
    const id = PhysicsZig.physicsSystem.createBody(physicsBodyInit);

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
        .Circular => |shape| {
            try testing.expectEqual(5, shape.radius);
        },
        else => {
            try testing.expect(false);
            return;
        },
    }
    try testing.expectEqual(10, body.?.mass);
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
    };
    for (0..20) |_| {
        _ = PhysicsZig.physicsSystem.createBody(physicsCircularBodyInit);
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
    };
    const id = PhysicsZig.physicsSystem.createBody(physicsBodyInit);
    const body = PhysicsZig.physicsSystem.getBody(id);
    if (body == null) {
        try testing.expect(false);
    }
    if (body.?.shape == null) {
        try testing.expect(false);
    }
    switch (body.?.shape.?) {
        .Polygon => |shape| {
            try testing.expectEqual(2, shape.pointCount);
        },
        else => {
            try testing.expect(false);
        },
    }
    try testing.expectEqual(10, body.?.mass);
}

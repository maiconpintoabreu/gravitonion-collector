const std = @import("std");
const rl = @import("raylib");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const configZig = @import("../config.zig");
const playerZig = @import("../game_logic/player.zig");
const Player = playerZig.Player;

test "PlayerZig bulletsCount should be 0 from start" {
    var physics: PhysicsSystem = .{};
    var player: Player = .{};
    try player.init(&physics, .zero());
    for (player.bullets) |bullet| {
        if (bullet.isAlive) {
            try testing.expect(false);
        }
    }
}

test "PlayerZig init" {
    var physics: PhysicsSystem = .{};
    var player: Player = .{};
    try player.init(&physics, .zero());
}

test "PlayerZig Physics Body init" {
    var physics: PhysicsSystem = .{};
    var player: Player = .{};
    try testing.expect(player.body.id >= 0);
    try player.init(&physics, .zero());
    try testing.expect(player.body.id > -1);
}

test "PlayerZig Move Player to start position" {
    var physics: PhysicsSystem = .{};
    var player: Player = .{};
    try testing.expect(player.body.id >= 0);
    try player.init(&physics, .zero());
    try testing.expect(player.body.id > -1);

    player.teleport(
        &physics,
        rl.Vector2{
            .x = 50,
            .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the Blackhole
        },
        0.0,
    );
    const playerPosition = player.getPosition();
    try testing.expectEqual(1, playerPosition.equals(.{ .x = 50, .y = configZig.NATIVE_HEIGHT / 2 }));
}

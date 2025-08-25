const std = @import("std");
const rl = @import("raylib");
const testing = std.testing;
const configZig = @import("../config.zig");
const playerZig = @import("../game_logic/player.zig");
const Player = playerZig.Player;

test "PlayerZig bulletsCount should be 0 from start" {
    const player: Player = .{};
    for (player.bullets) |bullet| {
        if (bullet.isAlive) {
            try testing.expect(false);
        }
    }
}

test "PlayerZig init" {
    var player: Player = .{};
    try player.init(.{ .x = 0, .y = 0 });
}

test "PlayerZig Physics Body init" {
    var player: Player = .{};
    try testing.expect(player.physicsId == -1);
    try player.init(.{ .x = 0, .y = 0 });
    try testing.expect(player.physicsId > -1);
}

test "PlayerZig Move Player to start position" {
    var player: Player = .{};
    try testing.expect(player.physicsId == -1);
    try player.init(.{ .x = 0, .y = 0 });
    try testing.expect(player.physicsId > -1);

    player.teleport(
        rl.Vector2{
            .x = 50,
            .y = configZig.NATIVE_HEIGHT / 2, // Put the player beside the blackhole
        },
        0.0,
    );
    const playerPosition = player.getPosition();
    try testing.expectEqual(1, playerPosition.equals(.{ .x = 50, .y = configZig.NATIVE_HEIGHT / 2 }));
}

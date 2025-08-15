const std = @import("std");
const testing = std.testing;
const playerZig = @import("../game_logic/player.zig");
const Player = playerZig.Player;

test "PlayerZig bulletsCount should be 0 from start" {
    const player: Player = .{};
    try testing.expect(player.bulletsCount == 0);
}

test "PlayerZig init" {
    var player: Player = .{};
    try player.init(.{ .x = 0, .y = 0 });
}

test "PlayerZig Physics Body init" {
    var player: Player = .{};
    try testing.expect(player.physicsBody == null);
    try player.init(.{ .x = 0, .y = 0 });
    try testing.expect(player.physicsBody.?.id != -1);
}

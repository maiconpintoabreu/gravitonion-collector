// Test Sample

const std = @import("std");
const testing = std.testing;
const gameZig = @import("../game.zig");

test "GameZig asteroidCount should be 0 from start" {
    const game: gameZig.Game = .{};
    try testing.expect(game.asteroidCount == 0);
}

test "GameZig projectiles should be 0 from start" {
    const game: gameZig.Game = .{};
    try testing.expect(game.projectilesCount == 0);
}

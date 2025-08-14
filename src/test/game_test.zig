const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");
const gameZig = @import("../game.zig");
const configZig = @import("../config.zig");

test "GameZig asteroidCount should be 0 from start" {
    const game: gameZig.Game = .{};
    try testing.expect(game.asteroidCount == 0);
}

test "Game Debug should be false when Releasing" {
    if (builtin.mode != .Debug) {
        try testing.expect(!configZig.IS_DEBUG);
        try testing.expect(!configZig.IS_DEBUG_MENU);
    }
}

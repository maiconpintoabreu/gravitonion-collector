const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");
const gameZig = @import("../game_logic/game_play.zig");
const configZig = @import("../config.zig");

test "GameZig asteroidCount should be 0 from start" {
    const game: gameZig.Game = .{};

    for (game.asteroids) |asteroid| {
        if (asteroid.isAlive) {
            try testing.expect(false);
        }
    }
}

test "Game Debug should be false when Releasing" {
    if (builtin.mode != .Debug) {
        try testing.expect(!configZig.IS_DEBUG);
        try testing.expect(!configZig.IS_DEBUG_MENU);
    }
}

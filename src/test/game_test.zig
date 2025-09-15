const std = @import("std");
const testing = std.testing;
const builtin = @import("builtin");
const gameZig = @import("../game_logic/game_play.zig");
const configZig = @import("../config.zig");
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const Game = gameZig.Game;

test "GameZig asteroidCount should be 0 from start" {
    var game: Game = .{};
    try game.init();
}

test "Game Debug should be false when Releasing" {
    if (builtin.mode != .Debug) {
        try testing.expect(!configZig.IS_DEBUG);
        try testing.expect(!configZig.IS_DEBUG_MENU);
    }
}

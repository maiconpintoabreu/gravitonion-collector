const rl = @import("raylib");
const gameZig = @import("game.zig");
const Game = gameZig.Game;
// Global Variables
var game: Game = .{};

pub fn initGame() bool {
    // Start main menu
    return true;
}

pub fn update() bool {}

pub fn closeGame() void {
    for (game.blackHole.textures) |blackhole| {
        if (blackhole.id > 0) {
            rl.unloadTexture(blackhole);
        }
    }
}

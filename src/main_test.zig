// import tests here to add in the test run
pub const game = @import("test/game_test.zig");
pub const physics = @import("test/physics_test.zig");
pub const player = @import("test/player_test.zig");
const configZig = @import("config.zig");

test {
    configZig.IS_TESTING = true;
    @import("std").testing.refAllDecls(@This());
}

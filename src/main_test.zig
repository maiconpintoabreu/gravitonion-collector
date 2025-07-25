// import tests here to add in the test run
pub const game = @import("test/game_test.zig");

test {
    @import("std").testing.refAllDecls(@This());
}

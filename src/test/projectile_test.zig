const std = @import("std");
const testing = std.testing;
const ProjectileZig = @import("../game_logic/projectile.zig");
const Projectile = ProjectileZig.Projectile;

test "projectileZig init" {
    var projectile: Projectile = .{};
    try projectile.init();
}

test "projectileZig Physics Body init" {
    var projectile: Projectile = .{};
    try testing.expect(projectile.physicsBody == null);
    try projectile.init();
    try testing.expect(projectile.physicsBody.?.id != -1);
}

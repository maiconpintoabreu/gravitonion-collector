const std = @import("std");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const ProjectileZig = @import("../game_logic/projectile.zig");
const Projectile = ProjectileZig.Projectile;

test "projectileZig init" {
    var projectile: Projectile = .{};
    try projectile.init();
}

test "projectileZig Physics Body init" {
    var projectile: Projectile = .{};
    try testing.expect(projectile.body.id >= 0);

    try projectile.init();
    try testing.expect(projectile.body.id > -1);
}

test "projectileZig Physics Body enable/desable" {
    var projectile: Projectile = .{};
    try testing.expect(projectile.body.id >= 0);

    try projectile.init();
    try testing.expect(projectile.body.id > -1);
    try testing.expect(projectile.body.enabled == false);

    PhysicsZig.getPhysicsSystem().enableBody(projectile.body.id);
    try testing.expect(projectile.body.enabled == true);

    PhysicsZig.getPhysicsSystem().disableBody(projectile.body.id);
    try testing.expect(projectile.body.enabled == false);
}

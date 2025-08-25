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
    try testing.expect(projectile.physicsId == -1);
    try projectile.init();
    try testing.expect(projectile.physicsId > -1);
}

test "projectileZig Physics Body enable/desable" {
    var projectile: Projectile = .{};
    try testing.expect(projectile.physicsId == -1);
    try projectile.init();
    try testing.expect(projectile.physicsId > -1);
    var body = PhysicsZig.getPhysicsSystem().getBody(projectile.physicsId);
    try testing.expect(body.enabled == false);
    PhysicsZig.getPhysicsSystem().enableBody(projectile.physicsId);
    body = PhysicsZig.getPhysicsSystem().getBody(projectile.physicsId);
    try testing.expect(body.enabled == true);
    PhysicsZig.getPhysicsSystem().disableBody(projectile.physicsId);
    body = PhysicsZig.getPhysicsSystem().getBody(projectile.physicsId);
    try testing.expect(body.enabled == false);
}

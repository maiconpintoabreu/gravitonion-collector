const std = @import("std");
const testing = std.testing;
const PhysicsZig = @import("../game_logic/physics.zig");
const ProjectileZig = @import("../game_logic/projectile.zig");
const Projectile = ProjectileZig.Projectile;
const PhysicsSystem = PhysicsZig.PhysicsSystem;

test "projectileZig init" {
    var physics: PhysicsSystem = .{};
    var projectile: Projectile = .{};
    projectile.init(&physics);
}

test "projectileZig Physics Body init" {
    var physics: PhysicsSystem = .{};
    var projectile: Projectile = .{};
    try testing.expect(projectile.body.id >= 0);

    projectile.init(&physics);
    try testing.expect(projectile.body.id > -1);
}

test "projectileZig Physics Body enable/desable" {
    var physics: PhysicsSystem = .{};
    var projectile: Projectile = .{};
    try testing.expect(projectile.body.id >= 0);

    projectile.init(&physics);
    try testing.expect(projectile.body.id > -1);
    try testing.expect(projectile.body.enabled == false);

    physics.enableBody(projectile.body.id);
    try testing.expect(projectile.body.enabled == true);

    physics.disableBody(projectile.body.id);
    try testing.expect(projectile.body.enabled == false);
}

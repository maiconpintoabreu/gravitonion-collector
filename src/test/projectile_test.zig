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
    try testing.expect(projectile.bodyId >= 0);

    projectile.init(&physics);
    try testing.expect(projectile.bodyId > -1);
}

test "projectileZig Physics Body enable/desable" {
    var physics: PhysicsSystem = .{};
    var projectile: Projectile = .{};
    try testing.expect(projectile.bodyId >= 0);

    projectile.init(&physics);
    try testing.expect(projectile.bodyId > -1);
    var body = physics.getBody(projectile.bodyId);
    try testing.expect(body.enabled == true);

    physics.disableBody(body.id);
    body = physics.getBody(projectile.bodyId);
    try testing.expect(body.enabled == false);

    physics.enableBody(body.id);
    body = physics.getBody(projectile.bodyId);
    try testing.expect(body.enabled == true);
}

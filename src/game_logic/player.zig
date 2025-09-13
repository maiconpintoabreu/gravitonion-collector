const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const projectileZig = @import("projectile.zig");
const PhysicsZig = @import("../game_logic/physics.zig");
const Game = @import("game_play.zig").Game;
const Item = @import("inventory/item.zig").Item;
const math = std.math;
const Projectile = projectileZig.Projectile;
const PhysicsBody = PhysicsZig.PhysicsBody;
const CollisionData = PhysicsZig.CollisionData;
const PhysicSystem = PhysicsZig.PhysicsSystem;
const Particle = @import("particle.zig").Particle;
const ResourceManagerZig = @import("../resource_manager.zig");

const MAX_HEALTH = 100;
const MAX_POWER = 100;

pub const Player = struct {
    parent: *Game = undefined,
    bullets: [configZig.MAX_PROJECTILES]Projectile = @splat(.{}),
    particles: [15]Particle = @splat(.{}),
    isAlive: bool = true,
    isTurningLeft: bool = false,
    isTurningRight: bool = false,
    isAccelerating: bool = false,
    isInvunerable: bool = false,
    invunerableDuration: f32 = 0,
    antiGravityDuration: f32 = 0,
    bodyId: usize = undefined,
    speed: f32 = configZig.PLAYER_SPEED_DEFAULT,
    rotationSpeed: f32 = configZig.PLAYER_ROTATION_SPEED_DEFAULT,
    gunSpeed: f32 = configZig.PLAYER_GUN_SPEED_DEFAULT,
    health: f32 = MAX_HEALTH,
    power: f32 = MAX_POWER,
    gunSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    rightTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    middleTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    leftTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    shootingCd: f32 = 0,

    fn colliding(self: *Player, data: CollisionData) void {
        switch (data.tag) {
            .PickupItem => {},
            .Player => {},
            else => {
                if (!self.isInvunerable) {
                    self.health = -1.0;
                    self.isAlive = false;
                }
            },
        }
    }

    pub fn init(self: *Player, physics: *PhysicSystem, initPosition: rl.Vector2) rl.RaylibError!void {
        var body: PhysicsBody = .{
            .position = initPosition,
            .mass = 5,
            .useGravity = true,
            .shape = .{
                .Circular = .{
                    .radius = 14,
                },
            },
            .enabled = true,
            .isWrapable = true,
            .tag = .Player,
        };
        self.bodyId = physics.addBody(&body);

        // Avoid opengl calls while testing
        if (builtin.is_test) return;

        rl.traceLog(.info, "Player init Completed", .{});
    }

    pub fn tick(self: *Player, physics: *PhysicSystem, delta: f32) void {
        if (!self.isAlive) return;
        const body: PhysicsBody = physics.*.getBody(self.bodyId);
        if (body.useGravity and self.antiGravityDuration > 0) {
            self.antiGravityDuration -= delta;

            if (self.antiGravityDuration < 0) {
                physics.setUseGravityBody(self.bodyId, true);
            } else physics.setUseGravityBody(self.bodyId, false);
        } else if (!body.useGravity) {
            physics.setUseGravityBody(self.bodyId, true);
        }
        if (self.isInvunerable) {
            self.invunerableDuration -= delta;

            if (self.invunerableDuration < 0) {
                self.isInvunerable = false;
            }
        } else {
            if (self.invunerableDuration > 0) {
                self.isInvunerable = true;
            }
        }
        self.updateSlots(body);

        if (body.collidingData) |otherBody| {
            rl.traceLog(.info, "Confirming PlayerCollision: %i", .{otherBody.tag.getName()});
            self.colliding(otherBody);
            physics.resetBody(body.id);
        }
        var isSpawningParticle = self.isAccelerating;
        for (&self.particles) |*particle| {
            if (!particle.isAlive) {
                if (isSpawningParticle) {
                    isSpawningParticle = false;
                    particle.spawn(self.middleTurbineSlot, 0.2); // it cannot be more than 1.0
                }
            }
            if (particle.isAlive) {
                particle.tick(delta);
            }
        }
    }

    pub fn pickupItem(self: *Player, item: Item) void {
        switch (item.type) {
            .AntiGravity => |antiGravity| {
                self.antiGravityDuration = antiGravity.antiGravityDuration;
            },
            .GunImprovement => |improvement| {
                self.gunSpeed += improvement.gunSpeedIncrease;
                rl.traceLog(.info, "Gun Speed Increased", .{});
            },
            .Shield => |shield| {
                self.invunerableDuration += shield.shieldDuration;
                rl.traceLog(.info, "Player is invunerable for %3.3fs", .{self.invunerableDuration});
            },
        }
    }

    pub fn updateSlots(self: *Player, body: PhysicsBody) void {
        const direction = rl.Vector2{
            .x = math.sin(body.orient),
            .y = -math.cos(body.orient),
        };
        self.gunSlot = body.position.add(direction.scale(8));
        const back = body.position.add(.{ .x = 0, .y = 14 });

        self.middleTurbineSlot = body.position.add(body.position.add(.{
            .x = 0,
            .y = 12,
        }).subtract(body.position).rotate(
            body.orient,
        ));

        self.rightTurbineSlot = body.position.add(back.subtract(body.position).rotate(
            body.orient - 0.8, // TODO: needs Adjust
        ));

        self.leftTurbineSlot = body.position.add(back.subtract(body.position).rotate(
            body.orient + 0.8, // TODO: needs Adjust
        ));
    }

    pub fn teleport(self: *Player, physics: *PhysicSystem, position: rl.Vector2, orient: f32) void {
        physics.moveBody(self.bodyId, position, orient);
    }

    pub fn accelerate(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyForceToBody(self.bodyId, self.speed * delta);
    }

    pub fn turnLeft(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyTorqueToBody(self.bodyId, -self.rotationSpeed * delta);
    }

    pub fn turnRight(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyTorqueToBody(self.bodyId, self.rotationSpeed * delta);
    }

    pub fn draw(self: Player, physics: PhysicSystem) void {
        if (!self.isAlive) return;
        const body = physics.getBody(self.bodyId);
        const resourceManager = ResourceManagerZig.resourceManager;
        {
            for (self.particles) |particle| {
                if (particle.isAlive) particle.draw();
            }
        }

        // const currentWidth = self.textureRec.width;
        // const currentHeight = self.textureRec.height;

        // inverted
        if (self.isTurningRight) {
            rl.drawCircleV(self.leftTurbineSlot, 1.0, .yellow);
        }
        if (self.isTurningLeft) {
            rl.drawCircleV(self.rightTurbineSlot, 1.0, .yellow);
        }

        resourceManager.textureSheet.drawPro(
            resourceManager.shipData.rec,
            .{
                .x = body.position.x,
                .y = body.position.y,
                .width = resourceManager.shipData.rec.width,
                .height = resourceManager.shipData.rec.height,
            },
            resourceManager.shipData.center,
            math.radiansToDegrees(body.orient),
            .white,
        );
        if (self.isInvunerable) {
            resourceManager.textureSheet.drawPro(
                resourceManager.shieldData.rec,
                .{
                    .x = body.position.x,
                    .y = body.position.y,
                    .width = resourceManager.shieldData.rec.width,
                    .height = resourceManager.shieldData.rec.height,
                },
                resourceManager.shieldData.center,
                math.radiansToDegrees(body.orient),
                .{
                    .r = 255,
                    .g = 255,
                    .b = 255,
                    .a = @as(u8, @intFromFloat(math.clamp(255 * self.invunerableDuration / 2, 0, 255))),
                },
            );
        }
    }

    pub fn shotBullet(self: *Player, physics: *PhysicSystem) void {
        const body = physics.getBody(self.bodyId);
        self.parent.spawnProjectile(self.gunSlot, body.orient, configZig.BULLET_SPEED_DEFAULT);
    }

    pub fn unload(self: *Player) void {
        _ = self;
    }
};

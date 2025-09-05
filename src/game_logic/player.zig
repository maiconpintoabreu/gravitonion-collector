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
    body: PhysicsBody = .{
        .mass = 5,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 7,
            },
        },
        .enabled = true,
        .isWrapable = true,
        .tag = .Player,
    },
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
    shoot: rl.Sound = std.mem.zeroes(rl.Sound),

    fn colliding(self: *Player, data: *PhysicsBody) void {
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
        self.body.position = initPosition;
        physics.addBody(&self.body);

        // Avoid opengl calls while testing
        if (builtin.is_test) return;

        for (&self.bullets) |*bullet| {
            bullet.init(physics);
        }
        self.shoot = try rl.loadSound("resources/shoot.wav");
        rl.setSoundVolume(self.shoot, 0.1);
        rl.traceLog(.info, "Player init Completed", .{});
    }

    pub fn tick(self: *Player, delta: f32) void {
        if (self.body.useGravity and self.antiGravityDuration > 0) {
            self.antiGravityDuration -= delta;

            if (self.antiGravityDuration < 0) {
                self.body.useGravity = false;
            }
        } else if (!self.body.useGravity) {
            self.body.useGravity = true;
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
        self.updateSlots(self.body);

        if (self.body.collidingWith) |otherBody| {
            self.colliding(otherBody);
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

        // kill if not visible
        for (&self.bullets) |*bullet| {
            if (!bullet.isAlive) return;

            if (!bullet.body.isVisible) {
                bullet.isAlive = false;
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
        const back = body.position.add(.{ .x = 0, .y = 8 });

        self.middleTurbineSlot = body.position.add(body.position.add(.{
            .x = 0,
            .y = 7,
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
        physics.moveBody(self.body.id, position, orient);
    }

    pub fn getPosition(self: Player) rl.Vector2 {
        return self.body.position;
    }

    pub fn accelerate(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyForceToBody(self.body.id, self.speed * delta);
    }

    pub fn turnLeft(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyTorqueToBody(self.body.id, -self.rotationSpeed * delta);
    }

    pub fn turnRight(self: *Player, physics: *PhysicSystem, delta: f32) void {
        physics.applyTorqueToBody(self.body.id, self.rotationSpeed * delta);
    }

    pub fn draw(self: Player) void {
        if (self.body.id < 0) return;
        if (!self.body.enabled) return;
        const resourceManager = ResourceManagerZig.resourceManager;
        {
            for (self.particles) |particle| {
                if (particle.isAlive) particle.draw();
            }
        }
        {
            // rl.beginBlendMode(.additive);
            // defer rl.endBlendMode();
            for (self.bullets) |projectile| {
                if (projectile.body.enabled) {
                    const rotation: f32 = math.radiansToDegrees(projectile.body.orient);
                    resourceManager.bulletTexture.drawPro(
                        resourceManager.bulletData.rec,
                        .{
                            .x = projectile.body.position.x,
                            .y = projectile.body.position.y,
                            .width = resourceManager.bulletData.rec.width / 2,
                            .height = resourceManager.bulletData.rec.height / 4,
                        },
                        resourceManager.bulletData.center,
                        rotation,
                        .white,
                    );
                }
            }
        }

        // const currentWidth = self.textureRec.width;
        // const currentHeight = self.textureRec.height;

        // inverted
        if (self.isTurningRight or self.isAccelerating) {
            rl.drawCircleV(self.leftTurbineSlot, 1.0, .yellow);
        }
        if (self.isTurningLeft or self.isAccelerating) {
            rl.drawCircleV(self.rightTurbineSlot, 1.0, .yellow);
        }

        resourceManager.textureSheet.drawPro(
            resourceManager.shipData.rec,
            .{
                .x = self.body.position.x,
                .y = self.body.position.y,
                .width = resourceManager.shipData.rec.width,
                .height = resourceManager.shipData.rec.height,
            },
            resourceManager.shipData.center,
            math.radiansToDegrees(self.body.orient),
            .white,
        );
    }

    pub fn shotBullet(self: *Player, physics: *PhysicSystem) void {
        for (&self.bullets) |*bullet| {
            if (!bullet.isAlive) {
                bullet.isAlive = true;
                bullet.teleport(physics, self.gunSlot, self.body.orient);

                physics.applyForceToBody(bullet.body.id, self.gunSpeed);
                physics.enableBody(bullet.body.id);
                rl.playSound(self.shoot);
                return;
            }
        }
    }

    pub fn unload(self: *Player) void {
        // remove only first as they are all the same
        if (rl.isSoundValid(self.shoot)) self.shoot.unload();
    }
};

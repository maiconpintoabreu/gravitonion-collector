const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");
const configZig = @import("../config.zig");
const projectileZig = @import("projectile.zig");
const PhysicsZig = @import("../game_logic/physics.zig");
const math = std.math;
const Projectile = projectileZig.Projectile;
const PhysicsBody = PhysicsZig.PhysicsBody;

const MAX_HEALTH = 100;
const MAX_POWER = 100;

pub const Player = struct {
    bullets: [configZig.MAX_PROJECTILES]Projectile = @splat(.{}),
    isAlive: bool = true,
    isTurningLeft: bool = false,
    isTurningRight: bool = false,
    isAccelerating: bool = false,
    body: PhysicsBody = .{
        .mass = 5,
        .useGravity = true,
        .shape = .{
            .Circular = .{
                .radius = 5,
            },
        },
        .enabled = true,
        .isWrapable = true,
        .tag = .Player,
    },
    speed: f32 = configZig.PLAYER_SPEED_DEFAULT,
    rotationSpeed: f32 = configZig.PLAYER_ROTATION_SPEED_DEFAULT,
    gunSpeed: f32 = configZig.PLAYER_GUN_SPEED_DEFAULT,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    health: f32 = MAX_HEALTH,
    power: f32 = MAX_POWER,
    gunSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    rightTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    leftTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    shootingCd: f32 = 0,
    shoot: rl.Sound = std.mem.zeroes(rl.Sound),

    fn colliding(self: *Player, data: *PhysicsBody) void {
        if (data.tag != .Player) {
            self.health = -1.0;
            self.isAlive = false;
        }
    }

    pub fn init(self: *Player, initPosition: rl.Vector2) rl.RaylibError!void {
        self.body.position = initPosition;
        PhysicsZig.getPhysicsSystem().addBody(&self.body);

        // Avoid opengl calls while testing
        if (builtin.is_test) return;
        const playerTexture = try rl.loadTexture("resources/ship.png");
        const playerTextureCenter = rl.Vector2{
            .x = @as(f32, @floatFromInt(playerTexture.width)) / 2,
            .y = @as(f32, @floatFromInt(playerTexture.height)) / 2 + 2,
        };
        const playerTextureRec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(playerTexture.width)),
            .height = @as(f32, @floatFromInt(playerTexture.height)),
        };
        self.textureCenter = playerTextureCenter;
        self.texture = playerTexture;
        self.textureRec = playerTextureRec;

        const bulletTexture = try rl.loadTexture("resources/bullet.png");
        const bulletTextureRec = rl.Rectangle{
            .x = 0,
            .y = 0,
            .width = @as(f32, @floatFromInt(bulletTexture.width)),
            .height = @as(f32, @floatFromInt(bulletTexture.height)),
        };
        for (&self.bullets) |*bullet| {
            bullet.texture = bulletTexture;
            bullet.textureRec = bulletTextureRec;
            try bullet.init();
        }
        self.shoot = try rl.loadSound("resources/shoot.wav");
        rl.setSoundVolume(self.shoot, 0.1);
        rl.traceLog(.info, "Player init Completed", .{});
    }
    pub fn tick(self: *Player, _: f32) void {
        self.updateSlots(self.body);

        if (self.body.collidingWith) |otherBody| {
            self.colliding(otherBody);
        }
        // kill if not visible
        for (&self.bullets) |*bullet| {
            if (!bullet.isAlive) return;

            if (!bullet.body.isVisible) {
                bullet.isAlive = false;
            }
        }
    }
    pub fn updateSlots(self: *Player, body: PhysicsBody) void {
        const direction = rl.Vector2{
            .x = math.sin(body.orient),
            .y = -math.cos(body.orient),
        };
        self.gunSlot = body.position.add(direction.scale(8));
        const back = body.position.add(.{ .x = 0, .y = 6 });

        self.rightTurbineSlot = body.position.add(back.subtract(body.position).rotate(
            body.orient - 0.5, // TODO: needs Adjust
        ));

        self.leftTurbineSlot = body.position.add(back.subtract(body.position).rotate(
            body.orient + 0.5, // TODO: needs Adjust
        ));
    }
    pub fn teleport(self: *Player, position: rl.Vector2, orient: f32) void {
        PhysicsZig.getPhysicsSystem().moveBody(self.body.id, position, orient);
    }
    pub fn getPosition(self: Player) rl.Vector2 {
        return self.body.position;
    }
    pub fn accelerate(self: *Player, delta: f32) void {
        PhysicsZig.getPhysicsSystem().applyForceToBody(self.body.id, self.speed * delta);
    }
    pub fn turnLeft(self: *Player, delta: f32) void {
        PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.body.id, -self.rotationSpeed * delta);
    }
    pub fn turnRight(self: *Player, delta: f32) void {
        PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.body.id, self.rotationSpeed * delta);
    }
    pub fn draw(self: Player) void {
        if (self.body.id < 0) return;
        if (!self.body.enabled) return;
        if (self.texture.id == 0) {
            return;
        }
        {
            // rl.beginBlendMode(.additive);
            // defer rl.endBlendMode();
            for (self.bullets) |projectile| {
                if (projectile.body.enabled) {
                    const rotation: f32 = math.radiansToDegrees(projectile.body.orient);
                    projectile.texture.drawPro(
                        .{
                            .x = 0,
                            .y = 0,
                            .width = @as(f32, @floatFromInt(projectile.texture.width)),
                            .height = @as(f32, @floatFromInt(projectile.texture.height)),
                        },
                        .{
                            .x = projectile.body.position.x,
                            .y = projectile.body.position.y,
                            .width = @as(f32, @floatFromInt(projectile.texture.width)) / 2,
                            .height = @as(f32, @floatFromInt(projectile.texture.height)) / 4,
                        },
                        .{
                            .x = @as(f32, @floatFromInt(projectile.texture.width)) / 4,
                            .y = @as(f32, @floatFromInt(projectile.texture.height)) / 4,
                        },
                        rotation,
                        .white,
                    );
                }
            }
        }

        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;

        // inverted
        if (self.isTurningRight or self.isAccelerating) {
            rl.drawCircleV(self.leftTurbineSlot, 1, .yellow);
        }
        if (self.isTurningLeft or self.isAccelerating) {
            rl.drawCircleV(self.rightTurbineSlot, 1, .yellow);
        }

        self.texture.drawPro(
            self.textureRec,
            .{
                .x = self.body.position.x,
                .y = self.body.position.y,
                .width = currentWidth,
                .height = currentHeight,
            },
            self.textureCenter,
            math.radiansToDegrees(self.body.orient),
            .white,
        );
    }

    pub fn shotBullet(self: *Player) void {
        for (&self.bullets) |*bullet| {
            if (!bullet.isAlive) {
                bullet.isAlive = true;
                bullet.teleport(self.gunSlot, self.body.orient);

                PhysicsZig.getPhysicsSystem().applyForceToBody(bullet.body.id, self.gunSpeed);
                PhysicsZig.getPhysicsSystem().enableBody(bullet.body.id);
                rl.playSound(self.shoot);
                return;
            }
        }
    }

    pub fn unload(self: *Player) void {
        if (self.texture.id > 0) {
            self.texture.unload();
        }
        // remove only first as they are all the same
        if (self.bullets[0].texture.id > 0) {
            self.bullets[0].texture.unload();
        }
        if (rl.isSoundValid(self.shoot)) self.shoot.unload();
    }
};

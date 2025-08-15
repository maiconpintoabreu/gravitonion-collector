const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const physicsZig = @import("physics_object.zig");
const PhysicsObject = physicsZig.PhysicsObject;
const projectileZig = @import("projectile.zig");
const Projectile = projectileZig.Projectile;
const PhysicsZig = @import("../game_logic/physics.zig");
const PhysicsSystem = PhysicsZig.PhysicsSystem;
const PhysicsBody = PhysicsZig.PhysicsBody;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;

const MAX_HEALTH = 100;
const MAX_POWER = 100;

pub const Player = struct {
    bullets: [configZig.MAX_PROJECTILES]Projectile = std.mem.zeroes([configZig.MAX_PROJECTILES]Projectile),
    physicsObject: PhysicsObject = .{
        .rotationSpeed = 200,
    },
    physicsId: i32 = -1,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    health: f32 = MAX_HEALTH,
    power: f32 = MAX_POWER,
    gunSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    rightTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    leftTurbineSlot: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    shootingCd: f32 = 0,
    bulletsCount: usize = 0,
    shoot: rl.Sound = std.mem.zeroes(rl.Sound),
    pub fn init(self: *Player, initPosition: rl.Vector2) rl.RaylibError!void {
        const physicsBodyInit: PhysicsBodyInitiator = .{
            .position = initPosition,
            .mass = 10,
            .useGravity = true,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Circular = .{
                    .radius = 10,
                },
            },
            .enabled = true,
        };
        self.physicsId = PhysicsZig.physicsSystem.createBody(physicsBodyInit);

        // Avoid opengl calls while testing
        if (configZig.IS_TESTING) return;
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
    pub fn tick(self: *Player) void {
        self.physicsObject.velocity = rl.Vector2.clampValue(
            self.physicsObject.velocity,
            0,
            1.8,
        );
        self.physicsObject.tick();
        self.updateSlots();
    }
    pub fn updateSlots(self: *Player) void {
        self.gunSlot = self.physicsObject.position.add(self.physicsObject.direction.scale(10));
        const back = self.physicsObject.position.add(.{ .x = 0, .y = 8 });

        self.rightTurbineSlot = self.physicsObject.position.add(back.subtract(self.physicsObject.position).rotate(
            math.degreesToRadians(self.physicsObject.rotation - 25),
        ));

        self.leftTurbineSlot = self.physicsObject.position.add(back.subtract(self.physicsObject.position).rotate(
            math.degreesToRadians(self.physicsObject.rotation + 25),
        ));
    }
    pub fn draw(self: *Player) void {
        if (self.texture.id == 0) {
            return;
        }
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;

        // inverted
        if (self.physicsObject.isTurningRight or self.physicsObject.isAccelerating) {
            rl.drawCircleV(self.leftTurbineSlot, 1, .yellow);
        }
        if (self.physicsObject.isTurningLeft or self.physicsObject.isAccelerating) {
            rl.drawCircleV(self.rightTurbineSlot, 1, .yellow);
        }
        self.texture.drawPro(
            self.textureRec,
            .{
                .x = self.physicsObject.position.x,
                .y = self.physicsObject.position.y,
                .width = currentWidth,
                .height = currentHeight,
            },
            .{ .x = currentWidth / 2, .y = currentHeight / 2 },
            self.physicsObject.rotation,
            .white,
        );
    }

    pub fn shotBullet(self: *Player) void {
        if (self.bulletsCount + 1 == configZig.MAX_PROJECTILES) {
            return;
        }
        const direction: rl.Vector2 = .{
            .x = math.sin(math.degreesToRadians(self.physicsObject.rotation)),
            .y = -math.cos(math.degreesToRadians(self.physicsObject.rotation)),
        };
        const norm_vector: rl.Vector2 = direction.normalize();
        self.bullets[self.bulletsCount].position = self.gunSlot;
        self.bullets[self.bulletsCount].rotation = self.physicsObject.rotation;
        self.bullets[self.bulletsCount].direction = norm_vector;
        self.bullets[self.bulletsCount].speed = 5;
        self.bullets[self.bulletsCount].size = 3;
        self.bulletsCount += 1;
        rl.playSound(self.shoot);
    }
    pub fn removeBullet(self: *Player, index: usize) void {
        if (self.bulletsCount == 0) return;
        self.bullets[index] = self.bullets[self.bulletsCount - 1];
        self.bulletsCount -= 1;
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

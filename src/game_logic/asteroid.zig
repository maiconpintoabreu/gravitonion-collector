const std = @import("std");
const rand = std.crypto.random;
const math = std.math;
const rl = @import("raylib");
const configZig = @import("../config.zig");
const PhysicsZig = @import("physics.zig");
const PhysicsObject = PhysicsZig.PhysicsBody;
const PhysicsBodyInitiator = PhysicsZig.PhysicsBodyInitiator;
const PhysicsBody = PhysicsZig.PhysicsBody;
const Collidable = PhysicsZig.Collidable;

pub const Asteroid = struct {
    // physicsObject: PhysicsObject = .{},
    physicsId: i32 = -1,
    isAlive: bool = true,
    textureRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    textureCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    texture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    collider: ?Collidable = null,

    fn colliding(ptr: *anyopaque, data: *PhysicsBody) void {
        const self: *Asteroid = @ptrCast(@alignCast(ptr));
        if (data.tag != .Asteroid) {
            PhysicsZig.getPhysicsSystem().disableBody(self.physicsId);
            self.isAlive = false;
        }
        switch (data.tag) {
            .Asteroid => {
                rl.traceLog(.info, "Asteroid Colliding with Asteroid", .{});
            },
            .Player => {
                rl.traceLog(.info, "Asteroid Colliding with Player", .{});
            },
            .Blackhole => {
                rl.traceLog(.info, "Asteroid Colliding with Blackhole", .{});
            },
            .PlayerBullet => {
                rl.traceLog(.info, "Asteroid Colliding with Bullet", .{});
            },
            .Phaser => {
                rl.traceLog(.info, "Asteroid Colliding with Phaser", .{});
            },
        }
    }

    pub fn create(self: *Asteroid) Collidable {
        return Collidable{
            .ptr = self,
            .impl = &.{ .collidingWith = colliding },
        };
    }

    pub fn init(self: *Asteroid) rl.RaylibError!void {
        self.collider = self.create();
        const physicsBodyInit: PhysicsBodyInitiator = .{
            .owner = &self.collider.?,
            .position = .{ .x = 0, .y = 0 },
            .mass = 2,
            .useGravity = true,
            .velocity = .{ .x = 0, .y = 0 },
            .shape = .{
                .Circular = .{
                    .radius = 6,
                },
            },
            .enabled = false,
            .isWrapable = false,
            .tag = PhysicsZig.PhysicsBodyTagEnum.Asteroid,
        };
        self.physicsId = PhysicsZig.getPhysicsSystem().createBody(physicsBodyInit);
    }
    pub fn tick(self: *Asteroid) void {
        self.physicsObject.velocity = rl.Vector2.clampValue(self.physicsObject.velocity, 0, 0.8);
        self.physicsObject.tick();
    }
    pub fn unSpawn(self: Asteroid) void {
        PhysicsZig.getPhysicsSystem().disableBody(self.physicsId);
    }

    pub fn spawn(self: Asteroid) void {
        var moveTo = std.mem.zeroes(rl.Vector2);
        if (rand.boolean()) {
            if (rand.boolean()) {
                moveTo.x = 0;
            } else {
                moveTo.x = configZig.NATIVE_WIDTH;
            }
            moveTo.y = rand.float(f32) * configZig.NATIVE_HEIGHT;
        } else {
            if (rand.boolean()) {
                moveTo.y = 0;
            } else {
                moveTo.y = configZig.NATIVE_HEIGHT;
            }
            moveTo.x = rand.float(f32) * configZig.NATIVE_WIDTH;
        }
        // self.asteroids[self.asteroidCount].physicsObject.velocity = rl.Vector2.clampValue(
        //     self.asteroids[self.asteroidCount].physicsObject.velocity,
        //     0,
        //     0.2,
        // );
        PhysicsZig.getPhysicsSystem().moveBody(self.physicsId, moveTo, 0.0);
        PhysicsZig.getPhysicsSystem().enableBody(self.physicsId);
    }

    pub fn draw(self: Asteroid) void {
        if (self.physicsId < 0) return;
        if (self.texture.id == 0) return;
        const currentWidth = self.textureRec.width;
        const currentHeight = self.textureRec.height;
        const body = PhysicsZig.getPhysicsSystem().getBody(self.physicsId);
        if (!body.enabled) return;
        rl.drawTexturePro(self.texture, self.textureRec, .{
            .x = body.position.x,
            .y = body.position.y,
            .width = currentWidth,
            .height = currentHeight,
        }, .{ .x = currentWidth / 2, .y = currentHeight / 2 }, body.orient, .white);
    }
};

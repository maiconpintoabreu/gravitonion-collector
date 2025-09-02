const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

const configZig = @import("../config.zig");

const PhysicsZig = @import("physics.zig");
const PhysicsShapeUnion = PhysicsZig.PhysicsShapeUnion;
const PhysicsBody = PhysicsZig.PhysicsBody;

const math = std.math;
const rand = std.crypto.random;

const shaderVersion = if (builtin.cpu.arch.isWasm()) "100" else "330";

const BLACK_HOLE_PHASER_CD: f32 = 15;
const BLACK_HOLE_PHASER_MIN_DURATION: f32 = 1;
const BLACK_HOLE_COLLISION_POINTS = 4;
const BLACK_HOLE_SIZE_PHASER_ACTIVE = 1.5;

const BLACK_DEFAULT_SIZE = 0.6;
const BLACK_HOLE_SCALE = 20;
const BLACK_HOLE_PHASER_ROTATION_SPEED: f32 = 0.1;
const BLACK_HOLE_PHASER_MAX_ROTATION: f32 = 360.0;

pub const Blackhole = struct {
    body: PhysicsBody = .{},
    phaserBody: PhysicsBody = .{},
    size: f32 = BLACK_DEFAULT_SIZE,
    finalSize: f32 = BLACK_DEFAULT_SIZE * BLACK_HOLE_SCALE,
    speed: f32 = BLACK_DEFAULT_SIZE,
    phasersCD: f32 = BLACK_HOLE_PHASER_CD,
    phasersMinDuration: f32 = BLACK_HOLE_PHASER_MIN_DURATION,
    isPhasing: bool = false,
    isDisturbed: bool = false,
    isRotatingRight: bool = false,
    phaserTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    blackholeincreasing: rl.Sound = std.mem.zeroes(rl.Sound),
    blackholeShader: rl.Shader = std.mem.zeroes(rl.Shader),
    blackholePhaserShader: rl.Shader = std.mem.zeroes(rl.Shader),
    blackholeTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D),
    resolutionLoc: i32 = 0,
    timeLoc: i32 = 0,
    radiusLoc: i32 = 0,
    speedLoc: i32 = 0,
    timePhaserLoc: i32 = 0,
    collisionpoints: [BLACK_HOLE_COLLISION_POINTS]rl.Vector2 = std.mem.zeroes([BLACK_HOLE_COLLISION_POINTS]rl.Vector2),

    fn colliding(self: *Blackhole, data: *PhysicsBody) void {
        if (data.tag == .Asteroid) {
            self.setSize(self.size + 0.1);
        } else if (data.tag == .PlayerBullet) {
            self.setSize(self.size + 0.02);
        }
        rl.traceLog(.info, "Blackhole Colliding", .{});
    }

    pub fn init(self: *Blackhole) rl.RaylibError!void {
        if (self.phaserTexture.id > 0) {
            return;
        }
        self.body = .{
            .position = configZig.NATIVE_CENTER,
            .shape = .{
                .Circular = .{
                    .radius = self.finalSize,
                },
            },
            .enabled = true,
            .isWrapable = true,
            .tag = .Blackhole,
        };
        PhysicsZig.getPhysicsSystem().addBody(&self.body);
        // Init Phaser
        const phaserImage = rl.Image.genColor(256 * 2, 10, .white);
        self.phaserTexture = try phaserImage.toTexture();
        phaserImage.unload();

        self.phaserBody = .{
            .position = configZig.NATIVE_CENTER,
            .shape = .{
                .Polygon = .{
                    .pointCount = 4,
                    .points = self.collisionpoints,
                },
            },
            .tag = .Phaser,
        };
        PhysicsZig.getPhysicsSystem().addBody(&self.phaserBody);

        self.blackholeincreasing = try rl.loadSound("resources/blackholeincreasing.mp3");
        self.blackholeShader = try rl.loadShader(
            rl.textFormat("resources/shaders%s/blackhole.vs", .{shaderVersion}),
            rl.textFormat("resources/shaders%s/blackhole.fs", .{shaderVersion}),
        );
        self.blackholePhaserShader = try rl.loadShader(
            null,
            rl.textFormat("resources/shaders%s/phaser.fs", .{shaderVersion}),
        );
        self.resolutionLoc = rl.getShaderLocation(self.blackholeShader, "resolution");
        self.timeLoc = rl.getShaderLocation(self.blackholeShader, "time");
        self.radiusLoc = rl.getShaderLocation(self.blackholeShader, "radius");
        self.speedLoc = rl.getShaderLocation(self.blackholeShader, "speed");
        self.timePhaserLoc = rl.getShaderLocation(self.blackholePhaserShader, "time");
        const BlackholeImage = rl.genImageColor(configZig.NATIVE_WIDTH, configZig.NATIVE_HEIGHT, .white);
        self.blackholeTexture = try BlackholeImage.toTexture();
        BlackholeImage.unload();
        const radius: f32 = 2.0;
        rl.setShaderValue(self.blackholeShader, self.radiusLoc, &radius, .float);

        rl.traceLog(.info, "Blackhole init Completed", .{});
    }
    pub fn tick(self: *Blackhole, delta: f32) void {
        self.isDisturbed = false;
        if (self.body.collidingWith) |otherBody| {
            self.colliding(otherBody);
        }
        self.phasersCD -= delta;
        if (self.isRotatingRight) {
            PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.body.id, 1);
        } else {
            PhysicsZig.getPhysicsSystem().applyTorqueToBody(self.body.id, -1);
        }
        if (self.isPhasing) {
            if (self.size < BLACK_DEFAULT_SIZE) {
                self.setSize(BLACK_DEFAULT_SIZE);
                PhysicsZig.getPhysicsSystem().disableBody(self.phaserBody.id);
                self.isPhasing = false;
            } else {
                self.setSize(self.size - (0.9 * self.size) * delta);
            }
        }
        if ((self.size > BLACK_HOLE_SIZE_PHASER_ACTIVE) and !self.isPhasing) {
            self.phasersCD = BLACK_HOLE_PHASER_CD;
            self.phasersMinDuration = BLACK_HOLE_PHASER_MIN_DURATION;
            PhysicsZig.getPhysicsSystem().enableBody(self.phaserBody.id);
            self.isPhasing = true;
            self.isRotatingRight = rand.boolean();
        }
        self.speed = rl.math.lerp(
            self.speed,
            if (self.isRotatingRight) self.size * -1 else self.size,
            0.5,
        );
        self.collisionpoints[0] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = -5 });
        self.collisionpoints[1] = configZig.NATIVE_CENTER.add(.{ .x = 0, .y = 5 });
        self.collisionpoints[2] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = -5 });
        self.collisionpoints[3] = configZig.NATIVE_CENTER.add(.{ .x = 1000, .y = 5 });

        self.collisionpoints[0] = self.body.position.add(self.collisionpoints[0].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[1] = self.body.position.add(self.collisionpoints[1].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[2] = self.body.position.add(self.collisionpoints[2].subtract(self.body.position).rotate(
            self.body.orient,
        ));
        self.collisionpoints[3] = self.body.position.add(self.collisionpoints[3].subtract(self.body.position).rotate(
            self.body.orient,
        ));

        PhysicsZig.getPhysicsSystem().changeBodyShape(self.phaserBody.id, PhysicsShapeUnion{
            .Polygon = .{
                .pointCount = 4,
                .points = self.collisionpoints,
            },
        });
    }
    pub fn setSize(self: *Blackhole, size: f32) void {
        self.size = size;
        self.finalSize = size * BLACK_HOLE_SCALE;
        PhysicsZig.getPhysicsSystem().changeBodyShape(self.body.id, PhysicsShapeUnion{
            .Circular = .{ .radius = self.finalSize },
        });
    }
    pub fn draw(self: Blackhole) void {
        const BlackholeBody = self.body;
        if (self.isPhasing) {
            self.blackholePhaserShader.activate();
            defer self.blackholePhaserShader.deactivate();
            self.phaserTexture.drawPro(
                .{
                    .x = 0,
                    .y = 0,
                    .width = @as(f32, @floatFromInt(self.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(self.phaserTexture.height)),
                },
                .{
                    .x = self.collisionpoints[0].x,
                    .y = self.collisionpoints[0].y,
                    .width = @as(f32, @floatFromInt(self.phaserTexture.width)),
                    .height = @as(f32, @floatFromInt(self.phaserTexture.height)),
                },
                rl.Vector2.zero(),
                math.radiansToDegrees(BlackholeBody.orient),
                .white,
            );
        } else {
            rl.drawLineEx(
                self.collisionpoints[0],
                self.collisionpoints[2],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
            rl.drawLineEx(
                self.collisionpoints[1],
                self.collisionpoints[3],
                1,
                .{ .r = 255, .g = 255, .b = 255, .a = 100 },
            );
        }
    }
    pub fn unload(self: *Blackhole) void {
        if (self.blackholeTexture.id > 0) {
            self.blackholeTexture.unload();
        }
        if (self.blackholeShader.id > 0) {
            self.blackholeShader.unload();
        }
        if (self.blackholePhaserShader.id > 0) {
            self.blackholePhaserShader.unload();
        }
        if (self.phaserTexture.id > 0) {
            self.phaserTexture.unload();
        }
    }
};

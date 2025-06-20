const std = @import("std");
const math = std.math;
const rl = @import("raylib");
const playerZig = @import("player.zig");
const Player = playerZig.Player;
const asteroidZig = @import("asteroid.zig");
const Asteroid = asteroidZig.Asteroid;
const rand = std.crypto.random;

var game: Game = .{};
var target: rl.RenderTexture2D = std.mem.zeroes(rl.RenderTexture2D);
var asteroidTexture: rl.Texture2D = std.mem.zeroes(rl.Texture2D);

// Screen consts
const NATIVE_WIDTH = 160 * 3;
const NATIVE_HEIGHT = 90 * 3;
const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };

const NATIVE_REC: rl.Rectangle = .{
    .x = 0,
    .y = 0,
    .width = NATIVE_WIDTH,
    .height = -NATIVE_HEIGHT,
};

// Game Costs
const MAX_PARTICLE_DISTANCE = 120;
const MAX_BLACKHOLE_PARTICLES = 20000;
const MAX_ASTEROIDS = 100;
const DEFAULT_ASTEROID_CD = 10;
const PixelParticles = struct {
    position: rl.Vector2 = std.mem.zeroes(rl.Vector2),
    anglePoint: f32 = 0,
    color: rl.Color = rl.Color.dark_gray,
    speed: f32 = 2,
    distanceCenter: rl.Vector2 = std.mem.zeroes(rl.Vector2),
};
const BlackHole = struct {
    size: f32 = 10,
    resizeCD: f32 = 2,
    particles: [MAX_BLACKHOLE_PARTICLES]PixelParticles = std.mem.zeroes([MAX_BLACKHOLE_PARTICLES]PixelParticles),
};

const Game = struct {
    player: Player = .{},
    blackHole: BlackHole = .{},
    asteroids: [MAX_ASTEROIDS]Asteroid = std.mem.zeroes([MAX_ASTEROIDS]Asteroid),
    screenRec: rl.Rectangle = std.mem.zeroes(rl.Rectangle),
    virtualRatio: f32 = 1,
    width: i32 = 800,
    height: i32 = 460,
    asteroidAmount: usize = 0,
    asteroidSpawnCd: f32 = DEFAULT_ASTEROID_CD,
    isPlaying: bool = false,
    isPaused: bool = false,
};

fn updateRatio() void {
    if (rl.isWindowFullscreen()) {
        game.width = rl.getMonitorWidth(rl.getCurrentMonitor());
        game.height = rl.getMonitorHeight(rl.getCurrentMonitor());
    } else {
        game.width = rl.getScreenWidth();
        game.height = rl.getScreenHeight();
    }
    game.virtualRatio = @as(f32, @floatFromInt(game.height)) / @as(f32, @floatFromInt(NATIVE_HEIGHT));
    rl.setMouseScale(1 / game.virtualRatio, 1 / game.virtualRatio);
}

pub fn startGame() bool {
    rl.initWindow(game.width, game.height, "Space Researcher");
    game.isPlaying = true;
    target = rl.loadRenderTexture(NATIVE_WIDTH, NATIVE_HEIGHT) catch |err| switch (err) {
        rl.RaylibError.LoadRenderTexture => {
            std.debug.print("LoadRenderTexture ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    const playerTexture = rl.loadTexture("resources/ship.png") catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture ship ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
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
    asteroidTexture = rl.loadTexture("resources/rock.png") catch |err| switch (err) {
        rl.RaylibError.LoadTexture => {
            std.debug.print("LoadTexture rock ERROR", .{});
            return false;
        },
        else => {
            std.debug.print("ERROR", .{});
            return false;
        },
    };
    game.player = Player{
        .physicsObject = .{
            .rotationSpeed = 200,
            .position = rl.Vector2{ .x = 20, .y = 20 },
            .speed = 0.2,
            .isFacingMovement = false,
        },
        .textureCenter = playerTextureCenter,
        .texture = playerTexture,
        .textureRec = playerTextureRec,
    };
    const asteroidTextureCenter = rl.Vector2{
        .x = @as(f32, @floatFromInt(playerTexture.width)) / 2,
        .y = @as(f32, @floatFromInt(playerTexture.height)) / 2 + 2,
    };
    const asteroidTextureRec = rl.Rectangle{
        .x = 0,
        .y = 0,
        .width = @as(f32, @floatFromInt(asteroidTexture.width)),
        .height = @as(f32, @floatFromInt(asteroidTexture.height)),
    };
    for (&game.asteroids) |*asteroid| {
        asteroid.texture = asteroidTexture;
        asteroid.textureCenter = asteroidTextureCenter;
        asteroid.textureRec = asteroidTextureRec;
    }
    for (0..MAX_BLACKHOLE_PARTICLES) |blackholeIndex| {
        const angle = rand.float(f32) * 2.0 * math.pi;
        const distanceCenter = rl.Vector2{
            .x = (rand.float(f32) + 0.01),
            .y = (rand.float(f32) + 0.01),
        };

        const particle: rl.Vector2 = .{
            .x = NATIVE_CENTER.x + (game.blackHole.size + distanceCenter.x * MAX_PARTICLE_DISTANCE) * math.cos(angle),
            .y = NATIVE_CENTER.y + (game.blackHole.size + distanceCenter.y * MAX_PARTICLE_DISTANCE) * math.sin(angle),
        };
        game.blackHole.particles[blackholeIndex].position = particle;
        game.blackHole.particles[blackholeIndex].anglePoint = angle;
        game.blackHole.particles[blackholeIndex].distanceCenter = distanceCenter;
        game.blackHole.particles[blackholeIndex].speed = rand.float(f32) + 0.1 * 5;
        const distanceCenterF = game.blackHole.particles[blackholeIndex].position.distance(NATIVE_CENTER);
        const baseColor = 30;
        if (distanceCenterF < 40) {
            game.blackHole.particles[blackholeIndex].color = rl.Color.init(baseColor, baseColor, baseColor, 255);
        } else if (distanceCenterF < 90) {
            game.blackHole.particles[blackholeIndex].color = rl.Color.init(baseColor + 5, baseColor + 5, baseColor + 5, 255);
        } else {
            game.blackHole.particles[blackholeIndex].color = rl.Color.init(baseColor + 10, baseColor + 10, baseColor + 10, 255);
        }
    }

    // Start with one asteroid
    spawnAsteroidRandom();

    return true;
}
pub fn closeGame() void {
    rl.unloadRenderTexture(target);
    game.player.unload();
    if (asteroidTexture.id > 0) {
        rl.unloadTexture(asteroidTexture);
    }
}
fn removeAsteroid(index: usize) void {
    game.asteroids[index] = game.asteroids[game.asteroidAmount - 1];
    game.asteroidAmount -= 1;
}
fn spawnAsteroidRandom() void {
    if (rl.getRandomValue(0, 1) > 0) {
        if (rl.getRandomValue(0, 1) > 0) {
            game.asteroids[game.asteroidAmount].physicsObject.position.x = 0;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.x = 100;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.y = 100;
        } else {
            game.asteroids[game.asteroidAmount].physicsObject.position.x = 480.0;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.x = -100;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.y = -100;
        }
        game.asteroids[game.asteroidAmount].physicsObject.position.y = @as(f32, @floatFromInt(rl.getRandomValue(0, 1))) / 1.0 * 270.0;
    } else {
        if (rl.getRandomValue(0, 1) > 0) {
            game.asteroids[game.asteroidAmount].physicsObject.position.y = 0;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.y = 100;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.x = 100;
        } else {
            game.asteroids[game.asteroidAmount].physicsObject.position.y = 270.0;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.x = -100;
            game.asteroids[game.asteroidAmount].physicsObject.velocity.x = -100;
        }
        game.asteroids[game.asteroidAmount].physicsObject.position.x = @as(f32, @floatFromInt(rl.getRandomValue(0, 100))) / 100.0 * 480.0;
    }
    game.asteroids[game.asteroidAmount].physicsObject.velocity = rl.Vector2.clampValue(game.asteroids[game.asteroidAmount].physicsObject.velocity, 0, 0.2);
    game.asteroidAmount += 1;
}
pub fn updateFrame() bool {
    if (rl.isWindowResized()) {
        updateRatio();
    }

    if (rl.isKeyPressed(.space)) {
        game.isPaused = !game.isPaused;
    }
    if (!game.isPaused) {
        // Tick
        const delta = rl.getFrameTime();
        game.asteroidSpawnCd -= delta;
        if (game.asteroidSpawnCd < 0) {
            game.asteroidSpawnCd = DEFAULT_ASTEROID_CD;
            spawnAsteroidRandom();
        }
        // Input
        if (rl.isKeyPressed(.enter)) {
            rl.toggleFullscreen();
            updateRatio();
        }
        if (rl.isKeyDown(.left)) {
            game.player.physicsObject.isTurningLeft = true;
            game.player.physicsObject.applyTorque(-1 * delta);
        } else {
            game.player.physicsObject.isTurningLeft = false;
        }
        if (rl.isKeyDown(.right)) {
            game.player.physicsObject.isTurningRight = true;
            game.player.physicsObject.applyTorque(1 * delta);
        } else {
            game.player.physicsObject.isTurningRight = false;
        }

        if (rl.isKeyDown(.up)) {
            game.player.physicsObject.isAccelerating = true;
            game.player.physicsObject.applyForce(1 * delta);
        } else {
            game.player.physicsObject.isAccelerating = false;
        }

        const direction = rl.Vector2.subtract(NATIVE_CENTER, game.player.physicsObject.position).normalize();
        game.player.physicsObject.applyDirectedForce(rl.Vector2.scale(direction, 0.1 * game.blackHole.size / 10 * delta));
        game.player.tick(delta);
        for (0..game.asteroidAmount) |asteroidIndex| {
            const asteroidDirection = rl.Vector2.subtract(NATIVE_CENTER, game.asteroids[asteroidIndex].physicsObject.position).normalize();
            game.asteroids[asteroidIndex].physicsObject.applyDirectedForce(rl.Vector2.scale(asteroidDirection, 0.1 * game.blackHole.size / 10 * delta));
            game.asteroids[asteroidIndex].tick(delta);
            if (rl.checkCollisionCircles(
                NATIVE_CENTER,
                game.blackHole.size,
                game.asteroids[asteroidIndex].physicsObject.position,
                game.asteroids[asteroidIndex].physicsObject.collisionSize,
            )) {
                removeAsteroid(asteroidIndex);
                game.blackHole.size += 1;
            } else if (rl.checkCollisionCircles(
                game.player.physicsObject.position,
                game.player.physicsObject.collisionSize,
                game.asteroids[asteroidIndex].physicsObject.position,
                game.asteroids[asteroidIndex].physicsObject.collisionSize,
            )) {
                removeAsteroid(asteroidIndex);
            }
        }

        for (0..MAX_BLACKHOLE_PARTICLES) |blackholeIndex| {
            game.blackHole.particles[blackholeIndex].anglePoint += 0.01 * delta;
            if (game.blackHole.particles[blackholeIndex].anglePoint > 2.0 * math.pi) {
                game.blackHole.particles[blackholeIndex].anglePoint -= 2.0 * math.pi;
            }
            game.blackHole.particles[blackholeIndex].position.x = NATIVE_CENTER.x + (game.blackHole.size + game.blackHole.particles[blackholeIndex].distanceCenter.x * MAX_PARTICLE_DISTANCE) * math.cos(game.blackHole.particles[blackholeIndex].anglePoint);
            game.blackHole.particles[blackholeIndex].position.y = NATIVE_CENTER.y + (game.blackHole.size + game.blackHole.particles[blackholeIndex].distanceCenter.y * MAX_PARTICLE_DISTANCE) * math.sin(game.blackHole.particles[blackholeIndex].anglePoint);
        }
    }
    {
        rl.beginTextureMode(target);
        defer rl.endTextureMode();
        rl.clearBackground(rl.Color.init(20, 20, 20, 255));
        rl.drawCircleV(NATIVE_CENTER, game.blackHole.size, .black);
        for (game.blackHole.particles) |particle| {
            rl.drawPixelV(particle.position, particle.color);
        }

        for (0..game.asteroidAmount) |asteroidIndex| {
            game.asteroids[asteroidIndex].draw();
        }
        game.player.draw();
        // Debug player center
        // rl.drawCircleV(game.player.physicsObject.position, 1, .yellow);
    }
    rl.beginDrawing();
    rl.clearBackground(.black);

    // Define the destination rectangle on the screen (the entire screen)
    game.screenRec = rl.Rectangle{
        .x = -game.virtualRatio,
        .y = -game.virtualRatio,
        .width = @as(f32, @floatFromInt(game.width)) + (game.virtualRatio * 2),
        .height = @as(f32, @floatFromInt(game.height)) + (game.virtualRatio * 2),
    };
    // Draw the render texture to the screen, scaled up, with nearest-neighbor filtering
    rl.drawTexturePro(target.texture, // The texture to draw
        NATIVE_REC, // Part of the texture to draw (entire texture)
        game.screenRec, // Where on the screen to draw it
        rl.Vector2{ .x = 0.0, .y = 0.0 }, // Origin for rotation (top-left)
        0.0, // Rotation angle
        .white // Tint color (use WHITE to draw as is)
    );
    // Start Debug
    rl.drawFPS(10, 10);
    // End Debug
    rl.endDrawing(); // Ensure drawing is ended
    if (rl.isKeyDown(rl.KeyboardKey.escape) or rl.windowShouldClose()) {
        game.isPlaying = false;
    }
    return game.isPlaying;
}

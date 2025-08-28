const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

// This is like a config file

// Screen consts
pub const NATIVE_WIDTH = 640;
pub const NATIVE_HEIGHT = 360;
pub const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };
pub const MIN_WINDOW_SIZE_WIDTH = 400;
pub const MIN_WINDOW_SIZE_HEIGHT = 225;
pub const BACKGROUND_COLOR = rl.Color.init(20, 20, 20, 255);

// Game consts
pub const MAX_PROJECTILES = 50; // enough for now
pub const MAX_ASTEROIDS = 20;
pub const MAX_PHYSICS_OBJECTS: comptime_int = MAX_PROJECTILES + MAX_ASTEROIDS + 3;
pub const MAX_PHYSICS_POLYGON_POINTS = 4;
pub const DEFAULT_ASTEROID_CD = 5;
pub const DEFAULT_SHOOTING_CD = 0.1;
pub const PHYSICS_TICK_SPEED = 0.02;

// Debug
pub const IS_DEBUG = true and builtin.mode == .Debug;
pub const IS_DEBUG_MENU: bool = false and builtin.mode == .Debug;

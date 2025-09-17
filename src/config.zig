const std = @import("std");
const builtin = @import("builtin");
const rl = @import("raylib");

// This is like a config file

// Screen consts
pub const NATIVE_WIDTH = 800;
pub const NATIVE_HEIGHT = 450;
pub const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };
pub const MIN_WINDOW_SIZE_WIDTH = 400;
pub const MIN_WINDOW_SIZE_HEIGHT = 225;
pub const BACKGROUND_COLOR = rl.Color.init(20, 20, 20, 255);

// Game consts
pub const MAX_POWERUP_TEXTURES = 3;
pub const MAX_PLAYER_PARTICLES = 15;
pub const MAX_GAME_OBJECTS: comptime_int = 30;
pub const MAX_PHYSICS_OBJECTS: comptime_int = MAX_GAME_OBJECTS;
pub const MAX_PHYSICS_POLYGON_POINTS = 4;
pub const DEFAULT_ASTEROID_CD = 5;
pub const DEFAULT_SHOOTING_CD = 0.2;
pub const PHYSICS_TICK_SPEED = 0.02;
pub const MAX_BODY_VELOCITY = 2;
pub const PICKUP_LIFETIME_DURATION = 10.0;

// Player consts
pub const PLAYER_SPEED_DEFAULT = 2.0;
pub const PLAYER_ROTATION_SPEED_DEFAULT = 200.0;
pub const PLAYER_GUN_SPEED_DEFAULT = 5.0;
pub const BULLET_SPEED_DEFAULT = 10.0;

// Debug
pub const IS_DEBUG = true and builtin.mode == .Debug;
pub const IS_DEBUG_MENU: bool = true and builtin.mode == .Debug;

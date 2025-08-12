const rl = @import("raylib");

// This is like a config file

// Screen consts
pub const NATIVE_WIDTH = 640;
pub const NATIVE_HEIGHT = 360;
pub const NATIVE_CENTER = rl.Vector2{ .x = NATIVE_WIDTH / 2, .y = NATIVE_HEIGHT / 2 };
pub const BACKGROUND_COLOR = rl.Color.init(20, 20, 20, 255);

// Game consts
pub const MAX_PROJECTILES = 200;
pub const MAX_ASTEROIDS = 50;
pub const DEFAULT_ASTEROID_CD = 5;
pub const DEFAULT_SHOOTING_CD = 0.1;
pub const PHYSICS_TICK_SPEED = 0.02;

// Debug
pub const IS_DEBUG = false;
pub const IS_DEBUG_MENU: bool = false;

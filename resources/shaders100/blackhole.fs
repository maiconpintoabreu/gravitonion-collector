#version 100

// GLSL ES requires a default precision for float types.
precision highp float;

// Varying from vertex shader (replaces 'in')
varying vec2 fragTexCoord;

// Uniforms passed from the Zig program
// Note: Large uniform arrays may not be supported on all older hardware.
uniform vec2 resolution;
uniform float time;
uniform vec2 blackhole_center;
uniform int particle_count = 2048;
uniform vec2 particles[2048]; // Max particles

// --- Helper Functions ---

// Generates a pseudo-random number from a 2D vector
float random(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

// 2D noise function based on the random function
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    float a = random(i);
    float b = random(i + vec2(1.0, 0.0));
    float c = random(i + vec2(0.0, 1.0));
    float d = random(i + vec2(1.0, 1.0));

    // Smooth interpolation
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.y * u.x;
}

// Draws a smoothed circle
float smooth_circle(vec2 uv, float radius, float smoothness) {
    return 1.0 - smoothstep(radius - smoothness, radius + smoothness, length(uv));
}

// Custom atan(y, x) function, as it's not available in GLSL 100
float atan2(float y, float x) {
    return x == 0.0 ? sign(y)*1.5707963 : atan(y, x);
}

void main() {
    // --- Setup UVs and Coordinates ---
    // Use fragment texture coordinates, mapping them to a -1.0 to 1.0 range
    vec2 uv = (fragTexCoord - 0.5) * 2.0;
    // Correct for aspect ratio
    uv.x *= resolution.x / resolution.y;

    // Center the coordinates on the black hole
    vec2 centered_uv = uv - blackhole_center;

    // --- Gravitational Lensing ---
    float dist_to_center = length(centered_uv);
    // Strength of the lensing effect. Inversely proportional to distance.
    // The 0.15 is the "mass" or intensity of the black hole.
    float lens_strength = 0.15 / (dist_to_center + 0.001); // add small value to avoid division by zero
    // Apply the distortion by pulling the UV coordinates towards the center
    vec2 distorted_uv = centered_uv * (1.0 - lens_strength);

    // --- Main Visual Components ---
    vec3 col = vec3(0.0); // Start with a black background

    // 1. Accretion Disk
    // We use the distorted coordinates to create the swirling effect
    float disk_dist = length(distorted_uv);
    // Create a ring shape for the disk
    float disk_mask = smooth_circle(distorted_uv, 0.5, 0.1) - smooth_circle(distorted_uv, 0.25, 0.05);
    if (disk_mask > 0.0) {
        // Create a swirling pattern using noise and time
        float angle = atan2(distorted_uv.y, distorted_uv.x);
        float swirl = noise(vec2(disk_dist * 5.0, angle * 2.0 + time * 0.5));
        
        // Color the disk with fiery colors based on distance and swirl
        vec3 disk_color = mix(vec3(1.0, 0.5, 0.1), vec3(0.8, 0.1, 0.0), swirl);
        col += disk_color * disk_mask * 1.5;
    }

    // 2. Stars/Background
    // Use the original, non-distorted UVs for the background stars
    float star_noise = noise(uv * 20.0);
    if (star_noise > 0.95) {
        col += vec3(0.8, 0.8, 1.0) * (star_noise - 0.95) * 5.0;
    }

    // 3. Particles
    // Loop through the particle array and draw each one
    for (int i = 0; i < 2048; i++) {
        if (i >= particle_count) break; // Exit loop if we've processed all active particles
        vec2 particle_pos = particles[i];
        // Center the particle position relative to the black hole
        vec2 particle_uv = (particle_pos - 0.5) * 2.0;
        particle_uv.x *= resolution.x / resolution.y;
        
        // Draw a small, bright circle for each particle
        float particle_shape = smooth_circle(centered_uv - (particle_uv - blackhole_center), 0.015, 0.01);
        col += vec3(1.0, 0.9, 0.7) * particle_shape;
    }

    // 4. Event Horizon (the black center)
    // This should be drawn last to obscure everything behind it
    float event_horizon = smooth_circle(centered_uv, 0.2, 0.01);
    col = mix(col, vec3(0.0), event_horizon); // Mix with black

    // --- Final Output ---
    // Use the built-in gl_FragColor instead of a custom 'out' variable
    gl_FragColor = vec4(col, 1.0);
}

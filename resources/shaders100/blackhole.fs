#version 100

precision mediump float;

varying vec2 fragTexCoord;

varying vec4 fragColor;

// Uniforms to control the effect
uniform vec2 resolution;
uniform float time;
uniform float radius;
uniform float speed;

// A simple random number generator for procedural noise
vec2 random2(vec2 st){
    st = vec2( dot(st,vec2(127.1,311.7)),
              dot(st,vec2(269.5,183.3)) );
    return -1.0 + 2.0*fract(sin(st)*43758.5453123);
}

// Gradient Noise by Inigo Quilez - iq/2013
// This is the core of our procedural textures
float noise(vec2 st) {
    vec2 i = floor(st);
    vec2 f = fract(st);

    vec2 u = f*f*(3.0-2.0*f);

    return mix( mix( dot( random2(i + vec2(0.0,0.0) ), f - vec2(0.0,0.0) ),
                     dot( random2(i + vec2(1.0,0.0) ), f - vec2(1.0,0.0) ), u.x),
                mix( dot( random2(i + vec2(0.0,1.0) ), f - vec2(0.0,1.0) ),
                     dot( random2(i + vec2(1.0,1.0) ), f - vec2(1.0,1.0) ), u.x), u.y);
}

// A 2D rotation matrix
mat2 rotate2d(float _angle){
    return mat2(cos(_angle),-sin(_angle),
                sin(_angle),cos(_angle));
}

void main()
{
    // Normalize coordinates and adjust for screen aspect ratio
    vec2 uv = fragTexCoord;
    vec2 centeredUv = uv - vec2(0.5);
    centeredUv.x *= resolution.x / resolution.y;

    float r = length(centeredUv); // Distance from the center
    float rInverted = 1.0 / r / 4.0;

    float lensFactor = 1.0 / (r * r + 0.05); 
    vec2 warpedUv = uv + centeredUv * lensFactor * 5.0;

    // --- 2. Starfield Background ---
    vec2 starfieldUv = warpedUv * 15.0;
    float starfieldNoise = noise(starfieldUv + time * 1.0);
    float stars = smoothstep(0.1, 1.0, starfieldNoise);
    vec3 backgroundColor = vec3(r / radius * 0.3);

    // Make the rotation speed depend on the radius (r).
    float rotationSpeed = 4.0 * speed * (1.0 + 0.5 / (r + 0.1));
    vec2 diskUv = rotate2d(rotationSpeed) * centeredUv; // Swirl the coordinates
    
    // Create the ring shape and add turbulent noise
    float ring = smoothstep(0.4, 0.45, length(diskUv));
    ring *= 1.0 - smoothstep(0.2, 0.25, length(diskUv));
    ring += noise(diskUv * 15.0 + time * 0.8) * 0.5;
    ring += noise(diskUv * 5.0 + time * 0.2) * 0.05;

    // --- 4. Black Hole and Color ---
    // Smooth transition to the black center (event horizon)
    float blackHole = 0.5;
    
    // Combine the background and disk, then apply the black hole mask
    vec3 finalColor = mix(backgroundColor, vec3(rInverted), ring);
    finalColor *= blackHole;
    gl_FragColor = vec4(finalColor, 1.0);
}

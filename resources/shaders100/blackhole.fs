#version 100

precision mediump float;

varying vec2 fragTexCoord;

varying vec4 fragColor;

// Uniforms to control the effect
uniform vec2 screenResolution = vec2(800, 460);
uniform float iTime;
uniform float radius = 2;
uniform float speed = 0.6;

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
    centeredUv.x *= screenResolution.x / screenResolution.y;

    float r = length(centeredUv); // Distance from the center

    float lensFactor = 1.0 / (r * r + 0.05); 
    vec2 warpedUv = uv + centeredUv * lensFactor * 10.0;

    // --- 2. Starfield Background ---
    vec2 starfieldUv = warpedUv * 100.0;
    float starfieldNoise = noise(starfieldUv + iTime * 0.03);
    float stars = smoothstep(0.1, 1.0, starfieldNoise);
    vec3 backgroundColor = vec3(stars * 0.5);

    // Make the rotation speed depend on the radius (r).
    float rotationSpeed = 4 * speed * (1 + 0.5 / (r + 0.1)) ;
    vec2 diskUv = rotate2d(rotationSpeed) * centeredUv; // Swirl the coordinates
    
    // Create the ring shape and add turbulent noise
    float ring = smoothstep(0.4, 0.45, length(diskUv));
    ring *= 1.0 - smoothstep(0.2, 0.25, length(diskUv));
    ring += noise(diskUv * 15.0 + iTime * 0.8) * 0.1;
    ring += noise(diskUv * 5.0 + iTime * 0.2) * 0.05;

    // --- 4. Black Hole and Color ---
    // Smooth transition to the black center (event horizon)
    float blackHole = 1.0;
    float rInverted = 1 / r / 4;
    float edge = 0.5f;
    float alpha = smoothstep(radius, radius - edge, r);
    // Combine the background and disk, then apply the black hole mask
    vec3 finalColor = mix(backgroundColor, vec3(rInverted), ring);
    finalColor *= blackHole;
    gl_FragColor = vec4(finalColor, alpha);
}

#version 100

precision highp float;

// Input vertex attributes (from vertex shader)
varying vec2 fragTexCoord;
varying vec4 fragColor;

// Input uniform values
uniform sampler2D texture0;
uniform vec4 colDiffuse;

// Output fragment color
varying vec4 finalColor;

uniform float time;

float random (in float x) {
    return fract(sin(x)*1e4);
}

void main() {

    // Texel color fetching from texture sampler
    vec2 st = fragTexCoord;

    // Calculate final fragment color
    gl_FragColor = vec4(1.0,1.0,1.0,random(st.x + st.y + time));
}

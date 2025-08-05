#version 330

layout (location = 0) in vec3 vertexPosition;
in vec2 vertexTexCoord;
in vec4 vertexColor;

uniform mat4 mvp;

out vec2 fragTexCoord;
out vec4 fragColor;


void main()
{
    // Send vertex attributes to fragment shader
    fragTexCoord = vertexTexCoord;
    fragColor = vertexColor;
    vec4 position = vec4(vertexPosition, 1.0);
    // position.xy = position.xy * 2. - 1.;
    // Calculate final vertex position
    gl_Position =  mvp*position;
}
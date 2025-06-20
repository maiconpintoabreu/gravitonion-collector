const float size   =    4.00; // fat pixel size
const float zoom   =    4.00; // upper zoom range
const float radius =   64.00; // scroll radius
const float speed  =    0.10; // speed

////////////////////////////////////////////////////////////////////////////////////////////////////

void mainImage(out vec4 col, in vec2 pos)
{
    float mtime = iTime * speed;
    float scale = size + (cos(mtime) + 1.0) * (zoom - 1.0) * size * 0.5;
	vec2 offset = vec2(cos(mtime), sin(mtime)) * radius;
	vec2 center = iResolution.xy / 2.0;

    // FOR BETTER READABILITY, SEE MAIN SHADER:
    // https://www.shadertoy.com/view/MlB3D3

    vec2 pix = (pos + offset - center) / scale + center;

    if (pos.x < center.x - 1.0)          pix = floor(pix) + 0.5;                                      // regular point sampling (emulated)
    else if (pos.x > center.x)           pix = floor(pix) + min(fract(pix) / fwidth(pix), 1.0) - 0.5; // custom antialiased point sampling

    else { col = vec4(0.0); return; }

    col = texture(iChannel0, pix / iChannelResolution[0].xy);
}
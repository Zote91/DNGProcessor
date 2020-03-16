#version 300 es

precision mediump float;

uniform sampler2D bilateral;
uniform sampler2D intermediate;
uniform sampler2D hist;

uniform float boost;

// Out
out vec3 processed;

float histEq(float inVal) {
    return texture(hist, vec2(inVal, 0.5f)).x;
}

void main() {
    ivec2 xy = ivec2(gl_FragCoord.xy);

    vec3 intermediateValXyz = texelFetch(intermediate, xy, 0).xyz;
    vec3 bilateralValXyz = texelFetch(bilateral, xy, 0).xyz;

    float intermediateVal = intermediateValXyz.z;
    float bilateralVal = bilateralValXyz.z;
    float detailVal = intermediateVal - bilateralVal;

    float zEqDiff = bilateralVal < 1.f
        ? histEq(bilateralVal) - bilateralVal
        : 0.f;

    // Background + Correction + Detail
    float z = bilateralVal
        + boost * (zEqDiff * pow(intermediateVal, 0.5f))
        + (1.f + boost) * detailVal;

    // Copy chroma from background.
    processed.xy = bilateralValXyz.xy;

    // Set new luma.
    processed.z = z;
}

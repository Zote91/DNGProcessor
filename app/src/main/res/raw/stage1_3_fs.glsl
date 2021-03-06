#version 300 es

precision mediump float;

uniform sampler2D rawBuffer;
uniform sampler2D greenBuffer;
uniform int rawWidth;
uniform int rawHeight;

// Sensor and picture variables
uniform sampler2D gainMap;
uniform int cfaPattern; // The Color Filter Arrangement pattern used
uniform vec4 neutralLevel; // Neutrallevel of sensor
uniform vec3 neutralPoint; // The camera neutral

// Transform
uniform mat3 sensorToXYZ; // Color transform from sensor to XYZ.

const int demosaicArray[16] = int[](
    0, 1, 2, 3,
    1, 0, 3, 2,
    2, 3, 0, 1,
    3, 2, 1, 0
);

// Out
out vec3 intermediate;

#include sigmoid
#include load3x3
#include xyztoxyy
#include xyytoxyz

int ind(int x, int y) {
    int dim = 3;
    return x + dim / 2 + (y + dim / 2) * dim;
}

// Apply bilinear-interpolation to demosaic
vec3 demosaic(ivec2 xy, inout float[9] inputArray, inout float[9] greenArray) {
    int x = xy.x;
    int y = xy.y;

    int index = (x & 1) | ((y & 1) << 1);
    index |= (cfaPattern << 2);
    vec3 pRGB;
    int pxType = demosaicArray[index]; -1;

    /*
    switch (index) {
        case 0:
        case 5:
        case 10:
        case 15:
            pxType = 0; // GRG
            break;
        case 1:
        case 4:
        case 11:
        case 14:
            pxType = 1; // RGR
            break;
        case 2:
        case 7:
        case 8:
        case 13:
            pxType = 2; // BGB
            break;
        case 3:
        case 6:
        case 9:
        case 12:
            pxType = 3; // GBG
            break;
    }
    */

    // We already computed green
    pRGB.g = greenArray[ind(0, 0)];
    float minG = 0.01f;

    if (pxType == 0 || pxType == 3) {
        float p = inputArray[ind(0, 0)];

        float crosstl = inputArray[ind(-1, -1)] / max(greenArray[ind(-1, -1)], minG),
            crosstr = inputArray[ind(1, -1)] / max(greenArray[ind(1, -1)], minG),
            crossbl = inputArray[ind(-1, 1)] / max(greenArray[ind(-1, 1)], minG),
            crossbr = inputArray[ind(1, 1)] / max(greenArray[ind(1, 1)], minG);

        float cross = 0.25f * max(pRGB.g, minG) * (crosstl + crosstr + crossbl + crossbr);
        if (pxType == 0) {
            // Red centered
            // B # B
            // # R #
            // B # B
            pRGB.r = p;
            pRGB.b = cross;
        } else {
            // Blue centered
            // R # R
            // # B #
            // R # R
            pRGB.r = cross;
            pRGB.b = p;
        }
    } else if (pxType == 1 || pxType == 2) {
        float horzl = inputArray[ind(-1, 0)] / max(greenArray[ind(-1, 0)], minG),
            horzr = inputArray[ind(1, 0)] / max(greenArray[ind(1, 0)], minG);
        float horz = 0.5f * max(pRGB.g, minG) * (horzl + horzr);

        float vertt = inputArray[ind(0, -1)] / max(greenArray[ind(0, -1)], minG),
            vertb = inputArray[ind(0, 1)] / max(greenArray[ind(0, 1)], minG);
        float vert = 0.5f * max(pRGB.g, minG) * (vertt + vertb);

        if (pxType == 1) {
            // Green centered w/ horizontally adjacent Red
            // # B #
            // R # R
            // # B #
            pRGB.r = horz;
            pRGB.b = vert;
        } else {
            // Green centered w/ horizontally adjacent Blue
            // # R #
            // B # B
            // # R #
            pRGB.r = vert;
            pRGB.b = horz;
        }
    }

    return pRGB;
}


vec3 convertSensorToIntermediate(ivec2 xy, vec3 sensor) {    // Use gainmap to increase dynamic range.
    sensor = min(sensor, neutralPoint);
    //return XYZtoxyY(sensorToXYZ * sensor);

    vec2 xyInterp = vec2(float(xy.x) / float(rawWidth), float(xy.y) / float(rawHeight));
    vec4 gains = texture(gainMap, xyInterp);
    vec3 neutralScaled = min(min(gains.x, gains.y), min(gains.z, gains.w)) * neutralPoint;

    vec3 npf = sensor / neutralScaled;
    sensor = min(sensor, neutralScaled);

    // When both red and blue channels are above white point, assume green is too
    // So extend dynamic range by scaling white point
    // Use a bias so only high green values become higher
    // In highlights, bias should be one
    float bias = npf.g * npf.g * npf.g;
    sensor *= mix(1.f, max(npf.r + npf.b, 2.f) * 0.5f, bias);

    vec3 XYZ = sensorToXYZ * sensor;
    vec3 intermediate = XYZtoxyY(XYZ);

    intermediate.z = sigmoid(intermediate.z, 0.75f);
    return intermediate;
    //return xyYtoXYZ(intermediate);
}

void main() {
    ivec2 xy = ivec2(gl_FragCoord.xy);
    ivec2 xyClamped = clamp(xy, ivec2(1), ivec2(rawWidth, rawHeight) - 2);

    float[9] rawPatch = load3x3(xyClamped, rawBuffer);
    float[9] greenPatch = load3x3(xyClamped, greenBuffer);
    vec3 sensor = demosaic(xyClamped, rawPatch, greenPatch);
    intermediate = convertSensorToIntermediate(xy, sensor);
}

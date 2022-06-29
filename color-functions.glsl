
//                          0.3127/0.3290  1.0  (1.0-0.3127-0.3290)/0.329
const vec3 D65_WHITE = vec3(0.95045592705, 1.0, 1.08905775076);
//                          0.3457/0.3585  1.0  (1.0-0.3457-0.3585)/0.3585
const vec3 D50_WHITE = vec3(0.96429567643, 1.0, 0.82510460251);

// sets reference white for all conversions
vec3 WHITE = D50_WHITE;

//========// TRANSFORMATION MATRICES //========//

// chromatic adaptation D65<->D50
const mat3 XYZ_TO_XYZ50 = mat3(
    1.0479298208405488, 0.022946793341019088, -0.05019222954313557,
    0.029627815688159344, 0.990434484573249, -0.01707382502938514,
    -0.009243058152591178, 0.015055144896577895, 0.7518742899580008
);
const mat3 XYZ50_TO_XYZ = mat3(
    0.9554734527042182, -0.023098536874261423, 0.0632593086610217,
    -0.028369706963208136, 1.0099954580058226, 0.021041398966943008,
    0.012314001688319899, -0.020507696433477912, 1.3303659366080753
);

// RGB<->XYZ
const mat3 RGB_TO_XYZ_M = mat3(
    0.41239079926595934, 0.357584339383878, 0.1804807884018343,
    0.21263900587151027, 0.715168678767756, 0.07219231536073371,
    0.01933081871559182, 0.11919477979462598, 0.9505321522496607
);
const mat3 XYZ_TO_RGB_M = mat3(
    3.2409699419045226, -1.537383177570094, -0.4986107602930034,
    -0.9692436362808796, 1.8759675015077202, 0.04155505740717559,
    0.05563007969699366, -0.20397695888897652, 1.0569715142428786
);


//========// CONVERSION FUNCTIONS //========//

// converts sRGB floats to RGB
float UNCOMPAND_SRGB(float a) {
    return (a > 0.04045) ? pow((a + 0.055) / 1.055, 2.4) : (a / 12.92);
}
vec3 SRGB_TO_RGB(vec3 srgb) {
    return vec3(UNCOMPAND_SRGB(srgb.x), UNCOMPAND_SRGB(srgb.y), UNCOMPAND_SRGB(srgb.z));
}

// converts RGB to sRGB
float COMPAND_RGB(float a) {
    return (a <= 0.0031308) ? (12.92 * a) : (1.055 * pow(a, 0.41666666666) - 0.055);
}
vec3 RGB_TO_SRGB(vec3 rgb) {
    return vec3(COMPAND_RGB(rgb.x), COMPAND_RGB(rgb.y), COMPAND_RGB(rgb.z));
}

vec3 RGB_TO_XYZ(vec3 rgb) {
    return WHITE == D65_WHITE ? (rgb * RGB_TO_XYZ_M) : ((rgb * RGB_TO_XYZ_M) * XYZ_TO_XYZ50);
}
vec3 XYZ_TO_RGB(vec3 xyz) {
    return WHITE == D65_WHITE ? (xyz * XYZ_TO_RGB_M) : ((xyz * XYZ50_TO_XYZ) * XYZ_TO_RGB_M);
}

// L*a*b*/CIELAB
float XYZ_TO_LAB_F(float x) {
    //          (24/116)^3                         1/(3*(6/29)^2)     4/29
    return x > 0.00885645167 ? pow(x, 0.333333333) : 7.78703703704 * x + 0.13793103448;
}
vec3 XYZ_TO_LAB(vec3 xyz) {
    vec3 xyz_scaled = xyz / WHITE;
    return vec3(
        (116.0 * xyz_scaled.y) - 16.0,
        500.0 * (xyz_scaled.x - xyz_scaled.y),
        200.0 * (xyz_scaled.y - xyz_scaled.z)
    );
}

float LAB_TO_XYZ_F(float x) {
    //                               3*(6/29)^2         4/29
    return (x > 0.206897) ? x * x * x : (0.12841854934 * (x - 0.137931034));
}
vec3 LAB_TO_XYZ(vec3 Lab) {
    float w = (Lab.x + 16.0) / 116.0;
    return WHITE * vec3(
        LAB_TO_XYZ_F(w + Lab.y / 500.0),
        LAB_TO_XYZ_F(w),
        LAB_TO_XYZ_F(w - Lab.z / 200.0)
    );
}
vec3 LAB_TO_LCH(vec3 Lab) {
    return vec3(
        Lab.x,
        sqrt(dot(Lab.yz, Lab.yz)),
        atan(Lab.z, Lab.y * 180.0 / 3.14159265359)
    );
}
vec3 LCH_TO_LAB(vec3 LCh) {
    return vec3(
        LCh.x,
        LCh.y * cos(LCh.z),
        LCh.y * sin(LCh.z)
    );
}


// xyY conversions
vec3 XYZ_TO_XYY(vec3 xyz) {
    return vec3(
        xyz.x / (xyz.x + xyz.y + xyz.z),
        xyz.y / (xyz.x + xyz.y + xyz.z),
        xyz.y
    );
}
vec3 XYY_TO_XYZ(vec3 xyY) {
    return vec3(
        xyY.z * xyY.x / xyY.y,
        xyY.z,
        xyY.z * (1.0 - xyY.x - xyY.y) / xyY.y
    );
}
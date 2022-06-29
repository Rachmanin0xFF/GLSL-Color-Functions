// @author Adam Lastowka
//                          0.3127/0.3290  1.0  (1.0-0.3127-0.3290)/0.329
const vec3 D65_WHITE = vec3(0.95045592705, 1.0, 1.08905775076);
//                          0.3457/0.3585  1.0  (1.0-0.3457-0.3585)/0.3585
const vec3 D50_WHITE = vec3(0.96429567643, 1.0, 0.82510460251);

// sets reference white for all conversions
vec3 WHITE = D65_WHITE;

//========// TRANSFORMATION MATRICES //========//

// Chromatic adaptation between D65<->D50
// XYZ color space does not depend on a reference white, but all other matrices here
// assume D65. These "restretch" XYZ to the D50 reference white so the others can sitll work with D50.
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

// sRGB<->RGB
// sRGB is standard "monitor" space, and the standard colorspace of the internet.
float UNCOMPAND_SRGB(float a) {
    return (a > 0.04045) ? pow((a + 0.055) / 1.055, 2.4) : (a / 12.92);
}
vec3 SRGB_TO_RGB(vec3 srgb) {
    return vec3(UNCOMPAND_SRGB(srgb.x), UNCOMPAND_SRGB(srgb.y), UNCOMPAND_SRGB(srgb.z));
}
float COMPAND_RGB(float a) {
    return (a <= 0.0031308) ? (12.92 * a) : (1.055 * pow(a, 0.41666666666) - 0.055);
}
vec3 RGB_TO_SRGB(vec3 rgb) {
    return vec3(COMPAND_RGB(rgb.x), COMPAND_RGB(rgb.y), COMPAND_RGB(rgb.z));
}

// RGB<->XYZ
// XYZ is the classic tristimulus color space developed in 1931 by the International Commission on Illumination (CIE, confusingly).
// Most conversions between color spaces end up going through XYZ; it is a central 'hub' in the color space landscape.
vec3 RGB_TO_XYZ(vec3 rgb) {
    return WHITE == D65_WHITE ? (rgb * RGB_TO_XYZ_M) : ((rgb * RGB_TO_XYZ_M) * XYZ_TO_XYZ50);
}
vec3 XYZ_TO_RGB(vec3 xyz) {
    return WHITE == D65_WHITE ? (xyz * XYZ_TO_RGB_M) : ((xyz * XYZ50_TO_XYZ) * XYZ_TO_RGB_M);
}

// L*a*b*/CIELAB
// CIELAB was developed in 1976 in an attempt to make a perceptually uniform color space.
// While it doesn't always do a great job of this (especially in the deep blues), it is still frequently used.
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
    //                                     3*(6/29)^2         4/29
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

// LCh
// LCh is simply L*a*b* converted to polar coordinates.
// Note: by convention, h is in degrees!
vec3 LAB_TO_LCH(vec3 Lab) {
    return vec3(
        Lab.x,
        sqrt(dot(Lab.yz, Lab.yz)),
        atan(Lab.z, Lab.y * 57.2957795131)
    );
}
vec3 LCH_TO_LAB(vec3 LCh) {
    return vec3(
        LCh.x,
        LCh.y * cos(LCh.z * 0.01745329251),
        LCh.y * sin(LCh.z * 0.01745329251)
    );
}

// xyY
// This is the color space used in chromaticity diagrams.
// x and y encode chromaticity, while Y encodes luminance.
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

//========// OTHER UTILITY FUNCTIONS //========//

// Cubic approximation of the planckian (black body) locus. This is a very good approximation for most purposes.
// Returns chromaticity vec2 (x/y, no luminance) in xyY space.
// Technically only designed for 1667K < T < 25000K, but you can push it further.

// Credit to B. Kang et al. (2002) (https://api.semanticscholar.org/CorpusID:4489377)
// Note: there may be a patent associated with this function
// TODO: if()s are not shader-friendly. find faster method.
vec2 PLANCKIAN_LOCUS_CUBIC_XY(float T) {
    vec2 xy = vec2(0.0, 0.0);
    if(T < 4000.0) {
        xy.x = -0.2661239*1000000000.0/(T*T*T) - 0.2343589*1000000.0/(T*T) + 0.8776956*1000.0/T + 0.179910;

        if(T < 2222.0) xy.y = -1.1063814*xy.x*xy.x*xy.x - 1.34811020*xy.x*xy.x + 2.18555832*xy.x - 0.20219683; 
        else           xy.y = -0.9549476*xy.x*xy.x*xy.x - 1.37418593*xy.x*xy.x + 2.09137015*xy.x -  0.16748867;
    } else {
        xy.x = -3.0258469*1000000000.0/(T*T*T) + 2.1070379*1000000.0/(T*T) + 0.2226347*1000.0/T + 0.24039;

        xy.y = 3.08175806*xy.x*xy.x*xy.x - 5.8733867*xy.x*xy.x + 3.75112997*xy.x - 0.37001483;
    }
    return xy;
}

// Finds the temperature of a color.
// Approximation good to +/-3K for colors on the locus
// Note: For colors past isotherm intersection points, temperatures bifurcate and have less meaning.
// Only use this method to interperet colors near the locus.

// TODO: Implement method with Robertson isotherms
// TODO: Implement Bruce Lindbloom's excellent approximation: http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_T.html
float XYY_MCCAMY_COLOR_TEMPERATURE(vec3 xyY) {
    float n = (xyY.x - 0.3320)/(0.1858 - xyY.y);
    return 449.0*n*n*n + 3525.0*n*n + 6823.3*n + 5520.33;
}
float XYZ_MCCAMY_COLOR_TEMPERATURE(vec3 XYZ) {
    vec3 xyY = XYY_TO_XYZ(XYZ);
    return XYY_MCCAMY_COLOR_TEMPERATURE(xyY);
}
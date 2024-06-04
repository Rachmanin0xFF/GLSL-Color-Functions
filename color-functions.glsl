// @author Adam Lastowka
// DISCLAIMER: I am not a color scientist, please correct the code if it is wrong anywhere!

// precision highp float; // :)

#ifndef PI
#define PI 3.14159265359
#endif
#ifndef TWO_PI
#define TWO_PI 6.28318530718
#endif

// A note on white points:
//      All the matrices shown here assume D65.
//      If you are making something with GLSL, there is a 99% chance it will appear on a monitor, not in print.
//      D65 is is the most common white point for computer displays, so I make it the default.
//      You can change the WHITE variable here, but it will only afffect RGB<->XYZ and XYZ<->L*a*b* conversions.
//      If you do end up needing to use D50 for printing or something, that should hopefully be sufficient.

// ALSO: The chromatic adaptation matrices are NOT calculated on-the-fly!!!
//       If you want to use a custom white point, you will have to do it yourself, sorry!

//                          0.3127/0.3290  1.0  (1.0-0.3127-0.3290)/0.329
const vec3 D65_WHITE = vec3(0.95045592705, 1.0, 1.08905775076);
//                          0.3457/0.3585  1.0  (1.0-0.3457-0.3585)/0.3585
const vec3 D50_WHITE = vec3(0.96429567643, 1.0, 0.82510460251);

vec3 WHITE = D65_WHITE;

// sRGB / ITU-R BT.709 spec
const vec3 LUMA_VEC = vec3(0.2126, 0.7152, 0.0722);

//========// TRANSFORMATION MATRICES //========//

// Chromatic adaptation between D65<->D50
// XYZ color space does not depend on a reference white, but all other matrices here
// assume D65. These "restretch" XYZ to the D50 reference white so the others can sitll work with D50.

// from https://www.color.org/sRGB.pdf
const mat3 XYZ_TO_XYZ50_M = mat3(
    1.0479298208405488, 0.022946793341019088, -0.05019222954313557,
    0.029627815688159344, 0.990434484573249, -0.01707382502938514,
    -0.009243058152591178, 0.015055144896577895, 0.7518742899580008
);
const mat3 XYZ50_TO_XYZ_M = mat3(
    0.9554734527042182, -0.023098536874261423, 0.0632593086610217,
    -0.028369706963208136, 1.0099954580058226, 0.021041398966943008,
    0.012314001688319899, -0.020507696433477912, 1.3303659366080753
);

// RGB<->XYZ
// from IEC 61966-2-1:1999/AMD1:2003 (sRGB color amendment 1)
const mat3 RGB_TO_XYZ_M = mat3(
    0.4124, 0.3576, 0.1805,
    0.2126, 0.7152, 0.0722,
    0.0193, 0.1192, 0.9505
);
const mat3 XYZ_TO_RGB_M = mat3(
    3.2406255, -1.5372080, -0.4986286,
    -0.9689307, 1.8757561, 0.0415175,
    0.0557101, -0.2040211, 1.0569959
);

// P3Linear <-> XYZ
const mat3 P3LINEAR_TO_XYZ_M = mat3(
    0.4865709486482162, 0.26566769316909306, 0.1982172852343625,
    0.2289745640697488, 0.6917385218365064, 0.079286914093745,
    0.0000000000000000, 0.04511338185890264, 1.043944368900976
);
const mat3 XYZ_TO_P3LINEAR_M = mat3(
    2.493496911941425, -0.9313836179191239, -0.40271078445071684,
    -0.8294889695615747, 1.7626640603183463, 0.023624685841943577,
    0.03584583024378447, -0.07617238926804182, 0.9568845240076872
);

// From https://www.color.org/sYCC.pdf
// This matrix is actually also used in the ITU-R BT.601 specification
const mat3 SRGB_TO_SYCC_M = mat3(
    0.2990,   0.5870,  0.1140,
    -0.1687, -0.3312,  0.5,
    0.5,     -0.4187, -0.0813
);

const mat3 SYCC_TO_SRGB_M = mat3(
    1.0,       -0.0000368,   1.40198757,
    1.0000344, -0.34412512, -0.71412839,
    0.9998228,  1.77203910, -0.00000804
);

// OKLab Stuff
// The "M_1" matrix in Ottosson's specification
const mat3 XYZ_TO_OKLAB_LMS = mat3(
    0.8189330101, 0.0329845436, 0.0482003018,
    0.3618667424, 0.9293118715, 0.2643662691,
    -0.1288597137, 0.0361456387, 0.6338517070
);
// The "M_2" matrix in Ottosson's specification
const mat3 OKLAB_LMS_TO_OKLAB = mat3(
    0.2104542553, 1.97799849510, 0.0259040371,
    0.793617785, -2.4285922050, 0.7827717662,
    -0.0040720468, 0.4505937099, -0.8086757660
);

// Inverse M_1
const mat3 OKLAB_LMS_TO_XYZ = mat3(
    1.227013851, -0.040580178, -0.076381285,
    -0.557799981, 1.11225687, -0.421481978,
    0.281256149, -0.071676679, 1.58616322
);
// Inverse M_2
const mat3 OKLAB_TO_OKLAB_LMS = mat3(
    1.0, 1.0, 1.0,
    0.396337792, -0.105561342, -0.089484182,
    0.215803758, -0.063854175, -1.291485538
);

//========// CONVERSION FUNCTIONS //========//

// sRGB<->RGB
// sRGB is standard "monitor" space, and the standard colorspace of the internet.
// The EOTF is roughly equivalent to a gamma of 2.2, but it acts differently in low values.
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
    return WHITE == D65_WHITE ? (rgb * RGB_TO_XYZ_M) : ((rgb * RGB_TO_XYZ_M) * XYZ_TO_XYZ50_M);
}
vec3 XYZ_TO_RGB(vec3 xyz) {
    return WHITE == D65_WHITE ? (xyz * XYZ_TO_RGB_M) : ((xyz * XYZ50_TO_XYZ_M) * XYZ_TO_RGB_M);
}

// P3<->XYZ
vec3 P3LINEAR_TO_XYZ(vec3 p3linear) {
    return p3linear * P3LINEAR_TO_XYZ_M;
}
vec3 XYZ_TO_P3LINEAR(vec3 xyz) {
    return xyz * XYZ_TO_P3LINEAR_M;
}
// Display P3 uses the sRGB TRC (gamma function).
// It also uses the D65 white point.
vec3 P3LINEAR_TO_DISPLAYP3(vec3 p3linear) {
    return vec3(COMPAND_RGB(p3linear.x), COMPAND_RGB(p3linear.y), COMPAND_RGB(p3linear.z));
}
vec3 DISPLAYP3_TO_P3LINEAR(vec3 displayp3) {
     return vec3(UNCOMPAND_SRGB(displayp3.x), UNCOMPAND_SRGB(displayp3.y), UNCOMPAND_SRGB(displayp3.z));
}
vec3 XYZ_TO_DISPLAYP3(vec3 xyz) {
    return P3LINEAR_TO_DISPLAYP3(XYZ_TO_P3LINEAR(xyz));
}
vec3 DISPLAYP3_TO_XYZ(vec3 xyz) {
    return P3LINEAR_TO_XYZ(DISPLAYP3_TO_P3LINEAR(xyz));
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
    xyz_scaled = vec3(
        XYZ_TO_LAB_F(xyz_scaled.x),
        XYZ_TO_LAB_F(xyz_scaled.y),
        XYZ_TO_LAB_F(xyz_scaled.z)
    );
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
        atan(Lab.z, Lab.y) * 57.2957795131
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

// Björn Ottosson's OkLab
// Details here https://bottosson.github.io/posts/oklab/
// Next comes OkHSL / OkHSV
vec3 XYZ_TO_OKLAB(vec3 xyz) {
    vec3 lms = XYZ_TO_OKLAB_LMS*xyz;
    return OKLAB_LMS_TO_OKLAB*pow(lms, vec3(1.0)/3.0);
}

vec3 OKLAB_TO_XYZ(vec3 OkLab) {
    vec3 lms0 = OKLAB_TO_OKLAB_LMS*OkLab;
    return OKLAB_LMS_TO_XYZ*(lms0*lms0*lms0);
}

// Think of sYCC as a fast way to get from sRGB to a more perceptual color space that encodes chroma seperately from luma.
// Output format: vec3(luma, blue-difference chroma, red-difference chroma)

// sYCC is a part of the YCbCr color space family, and was formally introduced in 2003 by the ICC.
// It uses the same transformation matrix as BT.601.
// Note that JPEG uses the BT.601 matrix, too, just slightly modified (I assume to properly handle rounding), and it maps to [0...255] instead.
vec3 SRGB_TO_SYCC(vec3 srgb) {
    return srgb*SRGB_TO_SYCC_M;
}
vec3 SYCC_TO_SRGB(vec3 sycc) {
    return sycc*SYCC_TO_SRGB_M;
}

// Composite function one-liners
vec3 SRGB_TO_XYZ(vec3 srgb) { return RGB_TO_XYZ(SRGB_TO_RGB(srgb)); }
vec3 XYZ_TO_SRGB(vec3 xyz)  { return RGB_TO_SRGB(XYZ_TO_RGB(xyz));  }

vec3 SRGB_TO_LAB(vec3 srgb) { return XYZ_TO_LAB(SRGB_TO_XYZ(srgb)); }
vec3 LAB_TO_SRGB(vec3 lab)  { return XYZ_TO_SRGB(LAB_TO_XYZ(lab));  }

vec3 SRGB_TO_LCH(vec3 srgb) { return LAB_TO_LCH(SRGB_TO_LAB(srgb)); }
vec3 LCH_TO_SRGB(vec3 lch)  { return LAB_TO_SRGB(LCH_TO_LAB(lch));  }

vec3 OKLAB_TO_SRGB(vec3 OkLab) { return XYZ_TO_SRGB(OKLAB_TO_XYZ(OkLab)); }
vec3 SRGB_TO_OKLAB(vec3 srgb)  { return XYZ_TO_OKLAB(SRGB_TO_XYZ(srgb));  }

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
// Approximation good to +/-3K for colors on the locus.
// Note: For colors past isotherm intersection points, temperature has little meaning;
//       only use this method to interperet colors near the locus.

// TODO: Implement method with Robertson isotherms
// TODO: Implement Bruce Lindbloom's excellent approximation:
//       http://www.brucelindbloom.com/index.html?Eqn_XYZ_to_T.html
float XYY_MCCAMY_COLOR_TEMPERATURE(vec3 xyY) {
    float n = (xyY.x - 0.3320)/(0.1858 - xyY.y);
    return 449.0*n*n*n + 3525.0*n*n + 6823.3*n + 5520.33;
}
float XYZ_MCCAMY_COLOR_TEMPERATURE(vec3 XYZ) {
    vec3 xyY = XYY_TO_XYZ(XYZ);
    return XYY_MCCAMY_COLOR_TEMPERATURE(xyY);
}

// This function gives you the *perceptual* difference between two colors in L*a*b* space.
// Most implementations of it online are are actually wrong!!!
//
// Additionally, although it is often hailed as the current "most accurate" color difference
// formula, it actually contains a pretty decent-sized discontinuity for colors with opposite hues.
//     See "The CIEDE2000 Color-DifferenceFormula: Implementation Notes,
//     Supplementary Test Data, and Mathematical Observations"
//     by G. Sharma et al. for more information. Link:
//     http://www2.ece.rochester.edu/~gsharma/ciede2000/ciede2000noteCRNA.pdf
//
float LAB_DELTA_E_CIE2000(vec3 lab1, vec3 lab2) {
    // b = bar
    // p = prime
    float Cb7 = pow((sqrt(lab1.y*lab1.y + lab1.z*lab1.z) + sqrt(lab1.y*lab1.y + lab1.z*lab1.z))*0.5, 7.0);
    //                                 25^7
    float G = 0.5*(1.0-sqrt(Cb7/(Cb7 + 6103515625.0)));

    float ap1 = lab1.y*(1.0 + G);
    float ap2 = lab2.y*(1.0 + G);

    float Cp1 = sqrt(ap1*ap1 + lab1.z*lab1.z);
    float Cp2 = sqrt(ap2*ap2 + lab2.z*lab2.z);
    
    float hp1 = atan(lab1.z, ap1);
    float hp2 = atan(lab2.z, ap2);
    if(hp1 < 0.0) hp1 = TWO_PI + hp1;
    if(hp2 < 0.0) hp2 = TWO_PI + hp2;
    
    float dLp = lab2.x - lab1.x;
    float dCp = Cp2 - Cp1;
    float dhp = hp2 - hp1;
    dhp += (dhp>PI) ? -TWO_PI: (dhp<-PI) ? TWO_PI : 0.0;
    // don't need to handle Cp1*Cp2==0 case because it's implicitly handled by the next line
    float dHp = 2.0*sqrt(Cp1*Cp2)*sin(dhp/2.0);
    
    float Lbp = (lab1.x + lab2.x)*0.5;
    float Cbp = sqrt(Cp1 + Cp2)/2.0;
    float Cbp7 = pow(Cbp, 7.0);
    
    // CIEDE 2000 Color-Difference \Delta E_{00}
    // This where everyone messes up (because it's a pain)
    // it's also the source of the discontinuity...
    
    // We need to average the angles h'_1 and h'_2 (hp1 and hp2) here.
    // This is a surprisingly nontrivial task.
    // Credit to https://stackoverflow.com/a/1159336 for the succinct formula.
    float hbp = mod( ( hp1 - hp2 + PI), TWO_PI ) - PI;
    hbp = mod((hp2 + ( hbp / 2.0 ) ), TWO_PI);
    if(Cp1*Cp2 == 0.0) hbp = hp1 + hp2;
    
    //                             30 deg                                                  6 deg                            63 deg
    float T = 1.0 - 0.17*cos(hbp - 0.52359877559) + 0.24*cos(2.0*hbp) + 0.32*cos(3.0*hbp + 0.10471975512) - 0.2*cos(4.0*hbp - 1.09955742876);
    
    float dtheta = 30.0*exp(-(hbp - 4.79965544298)*(hbp - 4.79965544298)/25.0);
    float RC = 2.0*sqrt(Cbp7/(Cbp7 + 6103515625.0));
    
    float Lbp2 = (Lbp-50.0)*(Lbp-50.0);
    float SL = 1.0 + 0.015*Lbp2/sqrt(20.0 + Lbp2);
    float SC = 1.0 + 0.045*Cbp;
    float SH = 1.0 + 0.015*Cbp*T;
    
    float RT = -RC*sin(2.0*dtheta)/TWO_PI;
    
    return sqrt(dLp*dLp/(SL*SL) + dCp*dCp/(SC*SC) + dHp*dHp/(SH*SH) + RT*dCp*dHp/(SC*SH));
}

float XYZ_DELTA_E_CIE2000(vec3 xyz1, vec3 xyz2) {
    return LAB_DELTA_E_CIE2000(XYZ_TO_LAB(xyz1), XYZ_TO_LAB(xyz2));
}

float SRGB_DELTA_E_CIE2000(vec3 srgb1, vec3 srgb2) {
    return LAB_DELTA_E_CIE2000(SRGB_TO_LAB(srgb1), SRGB_TO_LAB(srgb2));
}

// The most computationally expensive (and maybe the best?) way to tell how bright a color appears.
// Calculates L* as "the perceptual difference between pure black and the input color".
float SRGB_PERCEPTUAL_LIGHTNESS_DE2000(vec3 srgb) {
    return LAB_DELTA_E_CIE2000(SRGB_TO_LAB(srgb), vec3(0.0, 0.0, 0.0));
}

// Just returns the L* component after L*a*b* conversion
// Warning: resultant L* is in L*a*b* space (0 to 100)
float SRGB_PERCEPTUAL_LIGHTNESS_LAB(vec3 srgb) {
    return SRGB_TO_LAB(srgb).x;
}

// These functions are very similar, but I am keeping them seperate to ensure they are used properly.
// Luma is the weighted sum of GAMMA-COMPRESSED RGB components, while
// Luminance (relative luminance) is the weighted sum of LINEAR RGB components.
float SRGB_LUMA(vec3 srgb) {
    return dot(srgb, LUMA_VEC);
}
float RGB_RELATIVE_LUMINANCE(vec3 rgb) {
    return dot(rgb, LUMA_VEC);
}

// if you use this function and want to display it, make sure you gamma-compress the result with COMPAND_RGB(float x)
float SRGB_RELATIVE_LUMINANCE(vec3 srgb) {
    return dot(SRGB_TO_RGB(srgb), LUMA_VEC);
}

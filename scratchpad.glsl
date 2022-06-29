// P3Linear <-> XYZ
const mat3 P3LINEAR_TO_XYZ65_M = mat3(
    0.4865709486482162, 0.26566769316909306, 0.1982172852343625,
    0.2289745640697488, 0.6917385218365064, 0.079286914093745,
    0.0000000000000000, 0.04511338185890264, 1.043944368900976
);
const mat3 XYZ65_TO_P3LINEAR_M = mat3(
    2.493496911941425, -0.9313836179191239, -0.40271078445071684,
    -0.8294889695615747, 1.7626640603183463, 0.023624685841943577,
    0.03584583024378447, -0.07617238926804182, 0.9568845240076872
);

void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    // Normalized pixel coordinates (from 0 to 1)
    vec2 uv = 1.1*fragCoord / iResolution.x;

    vec3 inno = vec3(uv.x, uv.y, abs(sin(iTime)));
    inno = XYY_TO_XYZ(inno);
    // Time varying pixel color
    vec3 col = RGB_TO_SRGB(XYZ_TO_RGB(inno));
    inno = vec3(0.745, 0.423, 0.705);
    //col = inno;

    // Output to screen
    fragColor = vec4(col, 1.0);
    if(col.x < 0.0 || col.y < 0.0 || col.z < 0.0 || col.x > 1.0 || col.y > 1.0 || col.z > 1.0) fragColor = vec4(0.0, 0.0, 0.0, 1.0);
}
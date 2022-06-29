
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
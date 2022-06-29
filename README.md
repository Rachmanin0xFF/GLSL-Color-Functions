# GLSL-Color-Functions

Color space conversions, metrics, and other utility functions for color in GLSL.

Still very much a work-in-progress! If you see anything wrong, please let me know (or make a new branch if you're feeling nice).

## Currently Included
Color Spaces:
* XYZ
* sRGB
* RGB
* L\*a\*b\* (CIELAB)
* LCh (CIELCh)

White Points:
* D50
* D65

Other:
* Color from temperature (cubic approximation)
* Temperature from color (McCamy approximation)

## Credits

Inspired by [tobspr's](https://github.com/tobspr) [GLSL-Color-Spaces](https://github.com/tobspr/GLSL-Color-Spaces).
Algorithms and math from:
* [Bruce Lindbloom](http://www.brucelindbloom.com/)
* [Color.js](https://colorjs.io/)

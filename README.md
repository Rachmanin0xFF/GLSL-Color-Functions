# GLSL-Color-Functions

![LCh color space sRGB gamut](screenshot2.png?raw=true "sRGB Gamut in LCh Color Space")

Color space conversions, metrics, and other utility functions for color in GLSL.

Still very much a work-in-progress! If you see anything wrong, please let me know (or make a new branch if you're feeling nice).

## Currently Included
Color Spaces:
* XYZ
* sRGB
* RGB
* L\*a\*b\* (CIELAB)
* LCh (CIELCh)
* P3 Display

Other:
* A (proper) implementation of CIE Delta-E 2000
* Color from temperature (cubic approximation)
* Temperature from color (McCamy approximation)
* D65/D50 white point option for RGB<->XYZ and L\*a\*b\*<->XYZ

## Credits

Inspired by [tobspr's](https://github.com/tobspr) [GLSL-Color-Spaces](https://github.com/tobspr/GLSL-Color-Spaces).
Algorithms and math from:
* [Bruce Lindbloom](http://www.brucelindbloom.com/)
* [Color.js](https://colorjs.io/)

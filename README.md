# `glsl-color-spaces`

Utility functions to convert between various color spaces in GLSL.
Exported as modules using [`glslify`](https://github.com/glslify/glslify).

Experimental, not yet ready for consumption.

## Supported Conversions

**d** = directly implemented

**x** = Implemented using two or more direct implementions

 From / To  | RGB | sRGB | XYZ | xyY | HCV | HUE | HSV | HSL | HCY | YCbCr |
|---        |-----|------|-----|-----|-----|-----|-----|-----|-----|-------|
| **RGB**   |  d  |  d   |  d  |  d  |  d  |     |  d  |  d  |  d  |   d   |
| **sRGB**  |  d  |  d   |  x  |  x  |  x  |     |  x  |  x  |  x  |   x   |
| **XYZ**   |  d  |  x   |  d  |  d  |  x  |     |  x  |  x  |  x  |   x   |
| **xyY**   |  d  |  x   |  d  |  d  |  x  |     |  x  |  x  |  x  |   x   |
| **HCV**   |     |      |     |     |  d  |     |     |     |     |       |
| **HUE**   |  d  |  x   |  x  |  x  |  x  |  d  |  x  |  x  |  x  |   x   |
| **HSV**   |  d  |  x   |  x  |  x  |  x  |     |  d  |  x  |  x  |   x   |
| **HSL**   |  d  |  x   |  x  |  x  |  x  |     |  x  |  d  |  x  |   x   |
| **HCY**   |  d  |  x   |  x  |  x  |  x  |     |  x  |  x  |  d  |   x   |
| **YCbCr** |  d  |  x   |  x  |  x  |  x  |     |  x  |  x  |  x  |   d   |

## To-do

- Fix bugs:
    - `rgb != hsl_to_rgb(rgb_to_hsl(rgb))`
- Divide functions into files for lighter `glslify` imports.

## See Also

- [`glslify`](https://github.com/glslify/glslify).

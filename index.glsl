/*
GLSL Color Space Utility Functions
(c) 2015 tobspr

-------------------------------------------------------------------------------

The MIT License (MIT)

Copyright (c) 2015

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

-------------------------------------------------------------------------------

Most formulae/matrices are from:
https://en.wikipedia.org/wiki/SRGB

Some are from:
http://www.chilliant.com/rgb2hsv.html
https://www.fourcc.org/fccyvrgb.php
*/

// Constants
const float HCV_EPSILON = 1e-10;
const float HSL_EPSILON = 1e-10;
const float HCY_EPSILON = 1e-10;

const float SRGB_GAMMA = 1.0/2.2;
const float SRGB_INVERSE_GAMMA = 2.2;
const float SRGB_ALPHA = 0.055;

// Used to convert from linear RGB to XYZ space
const mat3 RGB_2_XYZ = mat3(
    0.4124564, 0.3575761, 0.1804375,
    0.2126729, 0.7151522, 0.0721750,
    0.0193339, 0.1191920, 0.9503041
);

// Used to convert from XYZ to linear RGB space
const mat3 XYZ_2_RGB = mat3(
    3.2404542, -1.5371385, -0.4985314,
    -0.9692660, 1.8760108, 0.0415560,
    0.0556434, -0.2040259, 1.0572252
);

const vec3 LUMA_COEFFS = vec3(0.2126, 0.7152, 0.0722);

// Returns the luminance of a !! linear !! rgb color
float get_luminance(vec3 rgb) {
    return dot(LUMA_COEFFS, rgb);
}
#pragma glslify: export(get_luminance);

// Converts a linear rgb color to a srgb color (approximated, but fast)
vec3 rgb_to_srgb_approx(vec3 rgb) {
    return pow(rgb, vec3(SRGB_GAMMA));
}
#pragma glslify: export(rgb_to_srgb_approx);

// Converts a srgb color to a rgb color (approximated, but fast)
vec3 srgb_to_rgb_approx(vec3 srgb) {
    return pow(srgb, vec3(SRGB_INVERSE_GAMMA));
}
#pragma glslify: export(srgb_to_rgb_approx);

// Converts a single linear channel to srgb
float linear_to_srgb(float channel) {
    return ((channel <= 0.0031308)? 12.92*channel
        :   (1.0+SRGB_ALPHA)*pow(channel, 1.0/2.4)-SRGB_ALPHA);
}
#pragma glslify: export(linear_to_srgb);

// Converts a single srgb channel to rgb
float srgb_to_linear(float channel) {
    return ((channel <= 0.04045)? channel/12.92
        :   pow((channel+SRGB_ALPHA)/(1.0+SRGB_ALPHA), 2.4));
}
#pragma glslify: export(srgb_to_linear);

// Converts a linear rgb color to a srgb color (exact, not approximated)
vec3 rgb_to_srgb(vec3 rgb) {
    return vec3(
        linear_to_srgb(rgb.r),
        linear_to_srgb(rgb.g),
        linear_to_srgb(rgb.b)
    );
}
#pragma glslify: export(rgb_to_srgb);

// Converts a srgb color to a linear rgb color (exact, not approximated)
vec3 srgb_to_rgb(vec3 srgb) {
    return vec3(
        srgb_to_linear(srgb.r),
        srgb_to_linear(srgb.g),
        srgb_to_linear(srgb.b)
    );
}
#pragma glslify: export(srgb_to_rgb);

// Converts a color from linear RGB to XYZ space
vec3 rgb_to_xyz(vec3 rgb) {
    return RGB_2_XYZ*rgb;
}
#pragma glslify: export(rgb_to_xyz);

// Converts a color from XYZ to linear RGB space
vec3 xyz_to_rgb(vec3 xyz) {
    return XYZ_2_RGB*xyz;
}
#pragma glslify: export(xyz_to_rgb);

// Converts a color from XYZ to xyY space (Y is luminosity)
vec3 xyz_to_xyY(vec3 xyz) {
    float Y = xyz.y;
    float x = xyz.x/(xyz.x+xyz.y+xyz.z);
    float y = xyz.y/(xyz.x+xyz.y+xyz.z);

    return vec3(x, y, Y);
}
#pragma glslify: export(xyz_to_xyY);

// Converts a color from xyY space to XYZ space
vec3 xyY_to_xyz(vec3 xyY) {
    float Y = xyY.z;
    float x = Y*xyY.x/xyY.y;
    float z = Y*(1.0-xyY.x-xyY.y)/xyY.y;

    return vec3(x, Y, z);
}
#pragma glslify: export(xyY_to_xyz);

// Converts a color from linear RGB to xyY space
vec3 rgb_to_xyY(vec3 rgb) {
    vec3 xyz = rgb_to_xyz(rgb);

    return xyz_to_xyY(xyz);
}
#pragma glslify: export(rgb_to_xyY);

// Converts a color from xyY space to linear RGB
vec3 xyY_to_rgb(vec3 xyY) {
    vec3 xyz = xyY_to_xyz(xyY);

    return xyz_to_rgb(xyz);
}
#pragma glslify: export(xyY_to_rgb);

// Converts a value from linear RGB to HCV (Hue, Chroma, Value)
vec3 rgb_to_hcv(vec3 rgb) {
    // Based on work by Sam Hocevar and Emil Persson
    vec4 p = ((rgb.g < rgb.b)? vec4(rgb.bg, -1.0, 2.0/3.0)
        :   vec4(rgb.gb, 0.0, -1.0/3.0));

    vec4 q = ((rgb.r < p.x)? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx));
    float c = q.x-min(q.w, q.y);
    float h = abs((q.w-q.y)/((6.0*c)+HCV_EPSILON)+q.z);

    return vec3(h, c, q.x);
}
#pragma glslify: export(rgb_to_hcv);

// Converts from pure Hue to linear RGB
vec3 hue_to_rgb(float hue) {
    return clamp(vec3(
            abs((hue*6.0)-3.0)-1.0,
            2.0-abs((hue*6.0)-2.0),
            2.0-abs((hue*6.0)-4.0)
        ),
        0.0, 1.0);
}
#pragma glslify: export(hue_to_rgb);

// Converts from HSV to linear RGB
vec3 hsv_to_rgb(vec3 hsv) {
    vec3 rgb = hue_to_rgb(hsv.x);

    return (((rgb-1.0)*hsv.y)+1.0)*hsv.z;
}
#pragma glslify: export(hsv_to_rgb);

// Converts from HSL to linear RGB
vec3 hsl_to_rgb(vec3 hsl) {
    vec3 rgb = hue_to_rgb(hsl.x);
    float c = (1.0-abs((2.0*hsl.z)-1.0))*hsl.y;

    return ((rgb-0.5)*c)+hsl.z;
}
#pragma glslify: export(hsl_to_rgb);

// Converts from HCY to linear RGB
vec3 hcy_to_rgb(vec3 hcy) {
    const vec3 hcyWts = vec3(0.299, 0.587, 0.114);
    vec3 rgb = hue_to_rgb(hcy.x);
    float z = dot(rgb, hcyWts);

    if(hcy.z < z) {
        hcy.y *= hcy.z/z;
    }
    else if(z < 1.0) {
        hcy.y *= (1.0-hcy.z)/(1.0-z);
    }

    return ((rgb-z)*hcy.y)+hcy.z;
}
#pragma glslify: export(hcy_to_rgb);

// Converts from linear RGB to HSV
vec3 rgb_to_hsv(vec3 rgb) {
    vec3 hcv = rgb_to_hcv(rgb);
    float s = hcv.y/(hcv.z+HCV_EPSILON);

    return vec3(hcv.x, s, hcv.z);
}
#pragma glslify: export(rgb_to_hsv);

// Converts from linear rgb to HSL
vec3 rgb_to_hsl(vec3 rgb) {
    vec3 hcv = rgb_to_hcv(rgb);
    float l = hcv.z-(hcv.y*0.5);
    float s = hcv.y/(1.0-abs((l*2.0)-1.0)+HSL_EPSILON);

    return vec3(hcv.x, s, l);
}
#pragma glslify: export(rgb_to_hsl);

// Converts from rgb to hcy (Hue, Chroma, Luminance)
vec3 rgb_to_hcy(vec3 rgb) {
    const vec3 hcyWts = vec3(0.299, 0.587, 0.114);
    // Corrected by David Schaeffer
    vec3 hcv = rgb_to_hcv(rgb);
    float y = dot(rgb, hcyWts);
    float z = dot(hue_to_rgb(hcv.x), hcyWts);

    if(y < z) {
      hcv.y *= z/(HCY_EPSILON+y);
    }
    else {
      hcv.y *= (1.0-z)/(HCY_EPSILON+1.0-y);
    }

    return vec3(hcv.x, hcv.y, y);
}
#pragma glslify: export(rgb_to_hcy);

// RGB to YCbCr, ranges [0, 1]
vec3 rgb_to_ycbcr(vec3 rgb) {
    float y = (0.299*rgb.r)+(0.587*rgb.g)+(0.114*rgb.b);
    float cb = (rgb.b-y)*0.565;
    float cr = (rgb.r-y)*0.713;

    return vec3(y, cb, cr);
}
#pragma glslify: export(rgb_to_ycbcr);

// YCbCr to RGB
vec3 ycbcr_to_rgb(vec3 yuv) {
    return vec3(
        yuv.x+(1.403*yuv.z),
        yuv.x-(0.344*yuv.y)-(0.714*yuv.z),
        yuv.x+(1.770*yuv.y)
    );
}
#pragma glslify: export(ycbcr_to_rgb);

// Additional conversions converting to rgb first and then to the desired
// color space.

// To srgb

vec3 xyz_to_srgb(vec3 xyz) { return rgb_to_srgb(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_srgb);

vec3 xyY_to_srgb(vec3 xyY) { return rgb_to_srgb(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_srgb);

vec3 hue_to_srgb(float hue) { return rgb_to_srgb(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_srgb);

vec3 hsv_to_srgb(vec3 hsv) { return rgb_to_srgb(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_srgb);

vec3 hsl_to_srgb(vec3 hsl) { return rgb_to_srgb(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_srgb);

vec3 hcy_to_srgb(vec3 hcy) { return rgb_to_srgb(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_srgb);

vec3 ycbcr_to_srgb(vec3 yuv) { return rgb_to_srgb(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_srgb);

// To xyz

vec3 srgb_to_xyz(vec3 srgb) { return rgb_to_xyz(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_xyz);

vec3 hue_to_xyz(float hue) { return rgb_to_xyz(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_xyz);

vec3 hsv_to_xyz(vec3 hsv) { return rgb_to_xyz(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_xyz);

vec3 hsl_to_xyz(vec3 hsl) { return rgb_to_xyz(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_xyz);

vec3 hcy_to_xyz(vec3 hcy) { return rgb_to_xyz(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_xyz);

vec3 ycbcr_to_xyz(vec3 yuv) { return rgb_to_xyz(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_xyz);

// To xyY

vec3 srgb_to_xyY(vec3 srgb) { return rgb_to_xyY(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_xyY);

vec3 hue_to_xyY(float hue) { return rgb_to_xyY(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_xyY);

vec3 hsv_to_xyY(vec3 hsv) { return rgb_to_xyY(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_xyY);

vec3 hsl_to_xyY(vec3 hsl) { return rgb_to_xyY(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_xyY);

vec3 hcy_to_xyY(vec3 hcy) { return rgb_to_xyY(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_xyY);

vec3 ycbcr_to_xyY(vec3 yuv) { return rgb_to_xyY(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_xyY);

// To HCV

vec3 srgb_to_hcv(vec3 srgb) { return rgb_to_hcv(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_hcv);

vec3 xyz_to_hcv(vec3 xyz) { return rgb_to_hcv(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_hcv);

vec3 xyY_to_hcv(vec3 xyY) { return rgb_to_hcv(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_hcv);

vec3 hue_to_hcv(float hue) { return rgb_to_hcv(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_hcv);

vec3 hsv_to_hcv(vec3 hsv) { return rgb_to_hcv(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_hcv);

vec3 hsl_to_hcv(vec3 hsl) { return rgb_to_hcv(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_hcv);

vec3 hcy_to_hcv(vec3 hcy) { return rgb_to_hcv(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_hcv);

vec3 ycbcr_to_hcv(vec3 yuv) { return rgb_to_hcy(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_hcv);

// To HSV

vec3 srgb_to_hsv(vec3 srgb) { return rgb_to_hsv(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_hsv);

vec3 xyz_to_hsv(vec3 xyz) { return rgb_to_hsv(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_hsv);

vec3 xyY_to_hsv(vec3 xyY) { return rgb_to_hsv(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_hsv);

vec3 hue_to_hsv(float hue) { return rgb_to_hsv(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_hsv);

vec3 hsl_to_hsv(vec3 hsl) { return rgb_to_hsv(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_hsv);

vec3 hcy_to_hsv(vec3 hcy) { return rgb_to_hsv(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_hsv);

vec3 ycbcr_to_hsv(vec3 yuv) { return rgb_to_hsv(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_hsv);

// To HSL

vec3 srgb_to_hsl(vec3 srgb) { return rgb_to_hsl(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_hsl);

vec3 xyz_to_hsl(vec3 xyz) { return rgb_to_hsl(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_hsl);

vec3 xyY_to_hsl(vec3 xyY) { return rgb_to_hsl(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_hsl);

vec3 hue_to_hsl(float hue) { return rgb_to_hsl(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_hsl);

vec3 hsv_to_hsl(vec3 hsv) { return rgb_to_hsl(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_hsl);

vec3 hcy_to_hsl(vec3 hcy) { return rgb_to_hsl(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_hsl);

vec3 ycbcr_to_hsl(vec3 yuv) { return rgb_to_hsl(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_hsl);

// To HCY

vec3 srgb_to_hcy(vec3 srgb) { return rgb_to_hcy(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_hcy);

vec3 xyz_to_hcy(vec3 xyz) { return rgb_to_hcy(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_hcy);

vec3 xyY_to_hcy(vec3 xyY) { return rgb_to_hcy(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_hcy);

vec3 hue_to_hcy(float hue) { return rgb_to_hcy(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_hcy);

vec3 hsv_to_hcy(vec3 hsv) { return rgb_to_hcy(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_hcy);

vec3 hsl_to_hcy(vec3 hsl) { return rgb_to_hcy(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_hcy);

vec3 ycbcr_to_hcy(vec3 yuv) { return rgb_to_hcy(ycbcr_to_rgb(yuv)); }
#pragma glslify: export(ycbcr_to_hcy);

// YCbCr

vec3 srgb_to_ycbcr(vec3 srgb) { return rgb_to_ycbcr(srgb_to_rgb(srgb)); }
#pragma glslify: export(srgb_to_ycbcr);

vec3 xyz_to_ycbcr(vec3 xyz) { return rgb_to_ycbcr(xyz_to_rgb(xyz)); }
#pragma glslify: export(xyz_to_ycbcr);

vec3 xyY_to_ycbcr(vec3 xyY) { return rgb_to_ycbcr(xyY_to_rgb(xyY)); }
#pragma glslify: export(xyY_to_ycbcr);

vec3 hue_to_ycbcr(float hue) { return rgb_to_ycbcr(hue_to_rgb(hue)); }
#pragma glslify: export(hue_to_ycbcr);

vec3 hsv_to_ycbcr(vec3 hsv) { return rgb_to_ycbcr(hsv_to_rgb(hsv)); }
#pragma glslify: export(hsv_to_ycbcr);

vec3 hsl_to_ycbcr(vec3 hsl) { return rgb_to_ycbcr(hsl_to_rgb(hsl)); }
#pragma glslify: export(hsl_to_ycbcr);

vec3 hcy_to_ycbcr(vec3 hcy) { return rgb_to_ycbcr(hcy_to_rgb(hcy)); }
#pragma glslify: export(hcy_to_ycbcr);


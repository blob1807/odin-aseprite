package aseprite_file_handler_utility

import "base:runtime"
import "core:slice"
import "core:log"
import "core:math"
import "core:fmt"


slow_alpha :: proc(#any_int a: int, b: ..int) -> (res: int) {
    // α = α * A1 *..An / 255^n
    if len(b) == 0 { return a }
    if len(b) == 1 { return a * b[0] / 255}
    res = a
    d := 255
    for i in b {
        res *= i
        d *= 255
    }
    res /= d
    return
}

alpha :: mul
mul :: proc(#any_int a, b: int) -> byte {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67
    // return byte(a * b / 255)
    t := a * b + 128
    return byte(((t >> 8 ) + t ) >> 8)
}

div :: proc(#any_int a, b: int) -> byte {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L70
    return byte(a * 255 + (b / 2) / b)
}


/* ---------------------------------------------------------------------------------- */
// Everything below's License to be Found in .\Licenses

blend :: proc(last, cur: Pixel, opacity: byte, mode: Blend_Mode) -> (res: Pixel) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp
    pix: [4]byte
    switch mode {
    case .Addition:    pix = blend_addition(last, cur, opacity)
    case .Color:       pix = blend_color(last, cur, opacity)
    case .Color_Burn:  pix = blend_color_burn(last, cur, opacity)
    case .Color_Dodge: pix = blend_color_dodge(last, cur, opacity)
    case .Darken:      pix = blend_darken(last, cur, opacity)
    case .Difference:  pix = blend_difference(last, cur, opacity)
    case .Divide:      pix = blend_divide(last, cur, opacity)
    case .Exclusion:   pix = blend_exclusion(last, cur, opacity)
    case .Hard_Light:  pix = blend_hard_light(last, cur, opacity)
    case .Hue:         pix = blend_hue(last, cur, opacity)
    case .Lighten:     pix = blend_lighten(last, cur, opacity)
    case .Luminosity:  pix = blend_luminosity(last, cur, opacity)
    case .Multiply:    pix = blend_multiply(last, cur, opacity)
    case .Normal:      pix = blend_normal(last, cur, opacity)
    case .Overlay:     pix = blend_overlay(last, cur, opacity)
    case .Saturation:  pix = blend_saturation(last, cur, opacity)
    case .Screen:      pix = blend_screen(last, cur, opacity)
    case .Soft_Light:  pix = blend_soft_light(last, cur, opacity)
    case .Subtract:    pix = blend_subtract(last, cur, opacity)
    case: 
        log.error("Invalid Bland Mode provided:", mode)
        return last
    }
    normal := blend_normal(last, pix, opacity)

    if last.a != 0 {
        norm_merge := blend_merge(normal, pix, last.a)
        pix_alpha := alpha(cur.a, opacity)
        com_alpha := alpha(last.a, pix_alpha)
        return blend_merge(norm_merge, pix, com_alpha)
    }
    return normal
}


/* ------------------------------------------------------------------- */
// RGB Blenders

blend_normal :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    cur: [4]byte = cur
    if cur.a == 0 { 
        return last
    }

    cur.a = alpha(cur.a, opacity)
    if last.a == 0 {
        return cur
    }

    res.a = cur.a + last.a - alpha(last.a, cur.a)
    res.r = last.r + (cur.r - last.r) * cur.a / res.a
    res.g = last.g + (cur.g - last.g) * cur.a / res.a
    res.b = last.b + (cur.b - last.b) * cur.a / res.a
    return res
}

blend_src :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) { 
    return last
}

blend_merge :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {

    if last.a == 0 {
        res.rgb = cur.rgb
    } else if cur.a == 0 {
        res.rgb = last.rgb
    } else {
        res.r = last.r + mul((cur.r - last.r), opacity)
        res.g = last.g + mul((cur.g - last.g), opacity)
        res.b = last.b + mul((cur.b - last.b), opacity)
    }

    res.a = last.a + alpha((cur.a - last.a), opacity)
    if res.a == 0 {
        res.rgb = 0
    }

    return
}

blend_neg_bw :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    if rgba_luma(last) < 128{
        return {255, 255, 255, 255}
    }
    return {0, 0, 0, 255}
}

blend_red_tint :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    cur: [4]byte = cur
    luma := rgba_luma(cur)
    cur = { byte((255 + luma)/2), byte(luma/2), byte(luma/2), last.a}
    return blend_normal(last, cur, opacity)
}

blend_blue_tint :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    luma := rgba_luma(cur)
    res = { byte(luma/2), byte(luma/2), byte((255 + luma)/2), last.a}
    return blend_normal(last, res, opacity)
}

blend_normal_dst_over :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.a = alpha(cur.a, opacity)
    return blend_normal(last, res, opacity)
}


blend_multiply :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = mul(last.r, cur.r)
    res.b = mul(last.b, cur.b)
    res.g = mul(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_screen :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = last.r + cur.r - mul(last.r, cur.r)
    res.b = last.b + cur.b - mul(last.b, cur.b)
    res.g = last.g + cur.g - mul(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_overlay :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_darken :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = min(last.r, cur.r)
    res.b = min(last.b, cur.b)
    res.g = min(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_lighten :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_dodge :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    cd :: proc(#any_int b, s: int) -> byte {
        if b == 0 {
            return 0
        }
        s := 255 - s
        if b >= s {
            return 255
        }
        return div(b, s)
    }

    res.r = cd(last.r, cur.r)
    res.b = cd(last.b, cur.b)
    res.g = cd(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_burn :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    cb :: proc(#any_int b, s: int) -> byte {
        if b == 255 {
            return 255
        }
        b := 255 - b
        if b >= s {
            return 0
        }
        return 255 - div(b, s)
    }

    res.r = cb(last.r, cur.r)
    res.b = cb(last.b, cur.b)
    res.g = cb(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_hard_light :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    hl :: proc(#any_int b, s: int) -> byte {
        if s < 128 {
            return mul(b, s<<1)
        }
        return mul(b, s<<1 - 255)
    }

    res.r = hl(last.r, cur.r)
    res.b = hl(last.b, cur.b)
    res.g = hl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_soft_light :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    sl :: proc(#any_int b, s: int) -> byte {
        b := f64(b) / 255
        s := f64(s) / 255
        r, d: f64

        if b <= 0.25 {
            d = ((16 * b - 12) * b + 4) * b
        } else {
            d = math.sqrt(b)
        }

        if s <= 0.5 {
            r = b - (1 - 2 * s) * b * (1 - b)
        } else {
            r = b + (2 * s - 1) * (d - b)
        }
        return byte(r * 255 + 0.5)
    }

    res.r = sl(last.r, cur.r)
    res.b = sl(last.b, cur.b)
    res.g = sl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_difference :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = byte(abs(int(last.r) - int(cur.r)))
    res.b = byte(abs(int(last.b) - int(cur.b)))
    res.g = byte(abs(int(last.g) - int(cur.g)))
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_exclusion :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    ex :: proc(#any_int b, s: int) -> byte {
        return byte(b + s - 2 * int(mul(b, s)))
    }
    res.r = ex(last.r, cur.r)
    res.b = ex(last.b, cur.b)
    res.g = ex(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// HSV Blenders

blend_hue :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    r := f64(last.r) / 255
    g := f64(last.g) / 255
    b := f64(last.b) / 255

    s := hsv_sat(r, g, b)
    l := hsv_luma(r, g, b)

    r = f64(cur.r) / 255
    g = f64(cur.g) / 255
    b = f64(cur.b) / 255

    r, g, b = set_sat(r, g, b, s)
    r, g, b = set_luma(r, g, b, l)

    res = {byte(255 * r), byte(255 * g), byte(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_saturation :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    r := f64(cur.r) / 255
    g := f64(cur.g) / 255
    b := f64(cur.b) / 255
    s := hsv_sat(r, g, b)

    r = f64(last.r) / 255
    g = f64(last.g) / 255
    b = f64(last.b) / 255
    l := hsv_luma(r, g, b)

    r, g, b = set_sat(r, g, b, s)
    r, g, b = set_luma(r, g, b, l)

    res = {byte(255 * r), byte(255 * g), byte(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_color :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    r := f64(last.r) / 255
    g := f64(last.g) / 255
    b := f64(last.b) / 255
    l := hsv_luma(r, g, b)

    r = f64(cur.r) / 255
    g = f64(cur.g) / 255
    b = f64(cur.b) / 255
    r, g, b = set_luma(r, g, b, l)

    res = {byte(255 * r), byte(255 * g), byte(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_luminosity :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    r := f64(cur.r) / 255
    g := f64(cur.g) / 255
    b := f64(cur.b) / 255
    l := hsv_luma(r, g, b)

    r = f64(last.r) / 255
    g = f64(last.g) / 255
    b = f64(last.b) / 255
    r, g, b = set_luma(r, g, b, l)

    res = {byte(255 * r), byte(255 * g), byte(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_addition :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = byte(min(int(last.r) + int(cur.r), 255))
    res.g = byte(min(int(last.g) + int(cur.r), 255))
    res.b = byte(min(int(last.b) + int(cur.b), 255))
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_subtract :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    res.r = byte(max(int(last.r) - int(cur.r), 0))
    res.g = byte(max(int(last.g) - int(cur.r), 0))
    res.b = byte(max(int(last.b) - int(cur.b), 0))
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_divide :: proc(last, cur: Pixel, opacity: byte) -> (res: Pixel) {
    bd :: proc(b, s: byte) -> byte {
        if b == 0 {
            return 0
        } else if b >= s {
            return 255
        }
        return div(b, s)
    }

    res.r = div(last.r, cur.r)
    res.g = div(last.g, cur.g)
    res.b = div(last.b, cur.b)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// RGB Helpers

rgba_luma :: proc(pix: Pixel) -> int {
    return rgb_luma(pix.r, pix.b, pix.g)
}

rgb_luma :: proc(#any_int r, b, g: int) -> int {
    return (r*2126 + g*7152 + b*722) / 10000
}

/* ------------------------------------------------------------------- */
// HSV Helpers

hsv_luma :: proc(r, g, b: f64) -> f64 {
    return 0.3*r + 0.59*g + 0.11*b
}

hsv_sat :: proc(r, g, b: f64) -> f64 {
    return max(r, g, b) - min(r, g, b)
}

clip_color :: proc(r, g, b: f64) -> (f64, f64, f64) {
    r, g, b := r, g, b
    l := hsv_luma(r, g, b)
    n := min(r, g, b)
    x := max(r, g, b)

    if n < 0 {
        r = l + (((r - l) * l) / (l - n))
        g = l + (((g - l) * l) / (l - n))
        b = l + (((b - l) * l) / (l - n))
    }

    if x > 0 {
        r = l + (((r - l) * l) / (x - l))
        g = l + (((g - l) * l) / (x - l))
        b = l + (((b - l) * l) / (x - l))
    }

    return r, g, b
}

set_luma :: proc(r, g, b, l: f64) -> (f64, f64, f64) {
    d := l - hsv_luma(r, g, b)
    return clip_color(r+d, g+d, b+d)
}

set_sat :: proc(r, g, b, s: f64) -> (f64, f64, f64) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp#L400
    // TODO: IDK what this is ment to be doing. Pointer logic maybe??
    sma := min(r, g, b)
    big := max(r, g, b)
    mid := r > g ? (g > b ? g : (r > b ? b : r)) : (g > b ? (b > r ? b : r): g)

    if big > sma {
        mid = (mid - sma) * s / (big - sma)
        big = s
    } else {
        mid, big = 0, 0
    }
    sma = 0
    return r, g, b
}
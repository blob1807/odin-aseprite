package aseprite_file_handler_utility

import "core:log"
import "core:math"
// import "core:fmt"


slow_alpha :: proc(a: int, b: ..int) -> (res: int) {
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
mul :: proc{mul_u8, mul_u16, mul_int}
mul_u16 :: proc(a, b: u16) -> u16 {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67
    //return a * b / 255

    t := a * b + 128
    return ((t >> 8 ) + t ) >> 8
}

mul_int :: proc(a, b: int) -> u16 {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67
    //return a * b / 255

    t := a * b + 128
    return u16(((t >> 8 ) + t ) >> 8)
}

mul_u8 :: proc(a, b: byte) -> u16 {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67
    //return a * b / 255

    t := a * b + 128
    return u16(((t >> 8 ) + t ) >> 8)
}


div :: proc(a, b: u16) -> u16 {
    // License to be Found in .\Licenses
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L70
    return a * 255 + (b / 2) / b
}


/* ---------------------------------------------------------------------------------- */
// Everything below's License to be Found in .\Licenses

blend :: proc(last, cur: Pixel, opacity: u16, mode: Blend_Mode) -> (res: Pixel, err: Blend_Error) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp
    // FIXME: Blend mode is not working
    if last.a == 0 {
        res.rgb = cur.rgb
        res.a = byte(mul(u16(cur.a), opacity))
        return
    }

    back: [4]u16 = {u16(last.r), u16(last.g), u16(last.b), u16(last.a)}
    pix: [4]u16 = {u16(cur.r), u16(cur.g), u16(cur.b), u16(cur.a)}

    blen: [4]u16
    switch mode {
    case .Src:         blen = blend_src(back, pix, opacity)
    case .Merge:       blen = blend_merge(back, pix, opacity)
    case .Neg_BW:      blen = blend_neg_bw(back, pix, opacity)
    case .Red_Tint:    blen = blend_red_tint(back, pix, opacity)
    case .Blue_Tint:   blen = blend_blue_tint(back, pix, opacity)
    case .Dst_Over:    blen = blend_normal_dst_over(back, pix, opacity)
    case .Addition:    blen = blend_addition(back, pix, opacity)
    case .Color:       blen = blend_color(back, pix, opacity)
    case .Color_Burn:  blen = blend_color_burn(back, pix, opacity)
    case .Color_Dodge: blen = blend_color_dodge(back, pix, opacity)
    case .Darken:      blen = blend_darken(back, pix, opacity)
    case .Difference:  blen = blend_difference(back, pix, opacity)
    case .Divide:      blen = blend_divide(back, pix, opacity)
    case .Exclusion:   blen = blend_exclusion(back, pix, opacity)
    case .Hard_Light:  blen = blend_hard_light(back, pix, opacity)
    case .Hue:         blen = blend_hue(back, pix, opacity)
    case .Lighten:     blen = blend_lighten(back, pix, opacity)
    case .Luminosity:  blen = blend_luminosity(back, pix, opacity)
    case .Multiply:    blen = blend_multiply(back, pix, opacity)
    case .Normal:      blen = blend_normal(back, pix, opacity)
    case .Overlay:     blen = blend_overlay(back, pix, opacity)
    case .Saturation:  blen = blend_saturation(back, pix, opacity)
    case .Screen:      blen = blend_screen(back, pix, opacity)
    case .Soft_Light:  blen = blend_soft_light(back, pix, opacity)
    case .Subtract:    blen = blend_subtract(back, pix, opacity)
    case .Unspecified: fallthrough
    case: 
        log.error("Invalid Bland Mode provided:", mode)
        return last, .Invalid_Mode
    }

    normal := blend_normal(back, pix, opacity)
    norm_merge := blend_merge(normal, blen, back.a)
    total_alpha := alpha(pix.a, opacity)
    com_alpha := alpha(back.a, total_alpha)
    blen = blend_merge(norm_merge, blen, com_alpha)

    return {byte(blen.r), byte(blen.g), byte(blen.b), byte(blen.a)}, nil
}


/* ------------------------------------------------------------------- */
// RGB Blenders

blend_normal :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    if last.a == 0 {
        res = cur
        res.a = alpha(cur.a, opacity)
    } else if cur.a == 0 {
        return last
    }

    cur := cur
    cur.a = alpha(cur.a, opacity)

    res.a = cur.a + last.a - alpha(last.a, cur.a)
    res.r = last.r + (cur.r - last.r) * cur.a / res.a
    res.g = last.g + (cur.g - last.g) * cur.a / res.a
    res.b = last.b + (cur.b - last.b) * cur.a / res.a
    return res
}

blend_src :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) { 
    return last
}

blend_merge :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {

    if last.a == 0 {
        res.rgb = cur.rgb
    } else if cur.a == 0 {
        res.rgb = last.rgb
    } else {
        res.r = last.r + mul((cur.r - last.r), opacity)
        res.g = last.g + mul((cur.g - last.g), opacity)
        res.b = last.b + mul((cur.b - last.b), opacity)
    }

    res.a = last.a + mul((cur.a - last.a), opacity)
    if res.a == 0 {
        res.rgb = 0
    }

    return
}

blend_neg_bw :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    if rgba_luma(last) < 128{
        return {255, 255, 255, 255}
    }
    return {0, 0, 0, 255}
}

blend_red_tint :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    cur := cur
    luma := rgba_luma(cur)
    cur = { (255 + luma)/2, luma/2, luma/2, last.a }
    return blend_normal(last, cur, opacity)
}

blend_blue_tint :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    luma := rgba_luma(cur)
    res = { luma/2, luma/2, (255 + luma)/2, last.a}
    return blend_normal(last, res, opacity)
}

blend_normal_dst_over :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.a = alpha(cur.a, opacity)
    return blend_normal(last, res, opacity)
}


blend_multiply :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = mul(last.r, cur.r)
    res.b = mul(last.b, cur.b)
    res.g = mul(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_screen :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = last.r + cur.r - mul(last.r, cur.r)
    res.b = last.b + cur.b - mul(last.b, cur.b)
    res.g = last.g + cur.g - mul(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_overlay :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_darken :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = min(last.r, cur.r)
    res.b = min(last.b, cur.b)
    res.g = min(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_lighten :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_dodge :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    cd :: proc(b, s: u16) -> u16 {
        if b == 0 {
            return 0
        }
        s1 := 255 - s
        if b >= s1 {
            return 255
        }
        return div(b, s1)
    }

    res.r = cd(last.r, cur.r)
    res.b = cd(last.b, cur.b)
    res.g = cd(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_burn :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    cb :: proc(b, s: u16) -> u16 {
        if b == 255 {
            return 255
        }
        b1 := 255 - b
        if b1 >= s {
            return 0
        }
        return 255 - div(b1, s)
    }

    res.r = cb(last.r, cur.r)
    res.b = cb(last.b, cur.b)
    res.g = cb(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_hard_light :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    hl :: proc(b, s: u16) -> u16 {
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

blend_soft_light :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    sl :: proc(b, s: u16) -> u16 {
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
        return u16(r * 255 + 0.5)
    }

    res.r = sl(last.r, cur.r)
    res.b = sl(last.b, cur.b)
    res.g = sl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_difference :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = abs(last.r - cur.r)
    res.b = abs(last.b - cur.b)
    res.g = abs(last.g - cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_exclusion :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    ex :: proc(b, s: u16) -> u16 {
        return b + s - 2 * mul(b, s)
    }
    res.r = ex(last.r, cur.r)
    res.b = ex(last.b, cur.b)
    res.g = ex(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// HSV Blenders

blend_hue :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
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

    res = {u16(255 * r), u16(255 * g), u16(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_saturation :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
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

    res = {u16(255 * r), u16(255 * g), u16(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_color :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    r := f64(last.r) / 255
    g := f64(last.g) / 255
    b := f64(last.b) / 255
    l := hsv_luma(r, g, b)

    r = f64(cur.r) / 255
    g = f64(cur.g) / 255
    b = f64(cur.b) / 255
    r, g, b = set_luma(r, g, b, l)

    res = {u16(255 * r), u16(255 * g), u16(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_luminosity :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    r := f64(cur.r) / 255
    g := f64(cur.g) / 255
    b := f64(cur.b) / 255
    l := hsv_luma(r, g, b)

    r = f64(last.r) / 255
    g = f64(last.g) / 255
    b = f64(last.b) / 255
    r, g, b = set_luma(r, g, b, l)

    res = {u16(255 * r), u16(255 * g), u16(255 * b), cur.a}
    return blend_normal(last, res, opacity)
}

blend_addition :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = min(last.r + cur.r, 255)
    res.g = min(last.g + cur.r, 255)
    res.b = min(last.b + cur.b, 255)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_subtract :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    res.r = max(last.r - cur.r, 0)
    res.g = max(last.g - cur.r, 0)
    res.b = max(last.b - cur.b, 0)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_divide :: proc(last, cur: B_Pixel, opacity: u16) -> (res: B_Pixel) {
    bd :: proc(b, s: u16) -> u16 {
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

rgba_luma :: proc(pix: B_Pixel) -> u16 {
    return rgb_luma(pix.r, pix.b, pix.g)
}

rgb_luma :: proc(#any_int r, b, g: int) -> u16 {
    return u16((r*2126 + g*7152 + b*722) / 10000)
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
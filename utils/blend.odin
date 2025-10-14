package aseprite_file_handler_utility

import "core:math"

@(require) import "core:fmt"
@(require) import "core:log"


ASE_USE_BUGGED_SAT :: #config(ASE_USE_BUGGED_SAT, false)


// https://printtechnologies.org/standards/files/pdf-reference-1.6-addendum-blend-modes.pdf

@(private)
slow_alpha :: proc(a: int, b: ..int) -> (res: int) {
    // α = α1 * α2 *..αn / 255^(n-1)
    if len(b) == 0 { return a }
    if len(b) == 1 { return a * b[0] / 255}
    res = a
    d := 255
    for i in b {
        res *= i
        d *= 255
    }
    return res / d
}


// Modifies current Image (`cur`)
blend_images :: proc(last, cur: Image, opacity: int, mode: Blend_Mode) -> (err: Blend_Error) {
    if len(last.data) != len(cur.data) {
        return Blend_Error.Unequal_Image_Sizes
    }
    return blend_bytes(last.data, cur.data, opacity, mode)
}

// Modifies current Image (`cur`)
blend_bytes :: proc(last, cur: []byte, opacity: int, mode: Blend_Mode) -> (err: Blend_Error) {
    if len(last) != len(cur) {
        return Blend_Error.Unequal_Image_Sizes
    }

    for pix in 0..<len(cur)/4 {
        pos := pix * 4
        l_pix, c_pix: [4]u8

        copy(l_pix[:], last[pos:pos+4])
        copy(c_pix[:], cur[pos:pos+4])

        r_pix := blend(l_pix, c_pix, i32(opacity), mode) or_return

        copy(cur[pos:pos+4], r_pix[:])
    }
    return
}


alpha :: mul
mul :: proc{mul_u8, mul_i32, mul_int, mul_vec4, mul_vec3}

mul_vec4 :: proc(a, b: [4]i32) -> [4]i32 {
    t := a * b + 128
    return {
        ((t.r >> 8) + t.r) >> 8,
        ((t.g >> 8) + t.g) >> 8,
        ((t.b >> 8) + t.b) >> 8,
        ((t.a >> 8) + t.a) >> 8,
    }
}

mul_vec3 :: proc(a, b: [3]i32) -> [3]i32 {
    t := a * b + 128
    return {
        ((t.r >> 8) + t.r) >> 8,
        ((t.g >> 8) + t.g) >> 8,
        ((t.b >> 8) + t.b) >> 8,
    }
}


mul_i32 :: proc(a, b: i32) -> i32 {
    // License `.\3rd party licenses\libpixman license`
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67

    t := a * b + 128
    return ((t >> 8 ) + t ) >> 8
}

mul_int :: proc(a, b: int) -> i32 {
    // License `.\3rd party licenses\libpixman license`
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67

    t := a * b + 128
    return i32(((t >> 8 ) + t ) >> 8)
}

mul_u8 :: proc(a, b: byte) -> i32 {
    // License `.\3rd party licenses\libpixman license`
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L67

    t := a * b + 128
    return i32(((t >> 8 ) + t ) >> 8)
}


div :: proc( #any_int a, b: u16) -> u16 {
    // License `.\3rd party licenses\libpixman license`
    // https://github.com/libpixman/pixman/blob/master/pixman/pixman-combine32.h#L70
    return (a * 255 + (b / 2)) / b
}

blend :: proc(last, cur: Pixel, opacity: i32, mode: Blend_Mode) -> (res: Pixel, err: Blend_Error) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp
    if last.a == 0 {
        res.rgb = cur.rgb
        res.a = byte(mul(i32(cur.a), opacity))
        return
    }

    back: [4]i32 = {i32(last.r), i32(last.g), i32(last.b), i32(last.a)}
    pix:  [4]i32 = {i32(cur.r),  i32(cur.g),  i32(cur.b),  i32(cur.a)}

    blen: [4]i32
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
    blen = blend_merge(norm_merge, blen, alpha(back.a, alpha(pix.a, opacity)))

    return {u8(blen.r), u8(blen.g), u8(blen.b), u8(blen.a)}, nil
}


/* ------------------------------------------------------------------- */
// RGB Blenders
blend_normal :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    if last.a == 0 {
        res = cur
        res.a = alpha(cur.a, opacity)
    } else if cur.a == 0 {
        return last
    }

    cur := cur
    cur.a = alpha(cur.a, opacity)

    res.a = cur.a + last.a - alpha(last.a, cur.a) 
    res.rgb = last.rgb + (cur.rgb - last.rgb) * cur.a / res.a

    return res
}

blend_src :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) { 
    return last
}

blend_merge :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {

    if last.a == 0 {
        res.rgb = cur.rgb

    } else if cur.a == 0 {
        res.rgb = last.rgb

    } else {
        op: [4]i32 = opacity
        res = last + mul((cur - last), op) 
    }

    res.a = last.a + mul((cur.a - last.a), opacity)
    if res.a == 0 {
        res.rgb = 0
    }

    return
}

blend_neg_bw :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    if rgba_luma(last) < 128{
        return { 255, 255, 255, 255 }
    }
    return { 0, 0, 0, 255 }
}

blend_red_tint :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    cur := cur
    luma := rgba_luma(cur)
    cur = { (255 + luma) >> 1, luma >> 1, luma >> 1, last.a }
    return blend_normal(last, cur, opacity)
}

blend_blue_tint :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    luma := rgba_luma(cur)
    res = { luma >> 1, luma >> 1, (255 + luma) >> 1, last.a }
    return blend_normal(last, res, opacity)
}

blend_normal_dst_over :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.a = alpha(cur.a, opacity)
    return blend_normal(last, res, opacity)
}


blend_multiply :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res = mul(last, cur)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_screen :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res = last + cur - mul(last, cur)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_overlay :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    hl :: proc(b, s: i32) -> i32 {
        if s < 128 {
            return mul(b, s<<1)
        }
        return b + ((s<<1)-255) - mul(b, (s<<1)-255)
    }

    res.r = hl(cur.r, last.r)
    res.b = hl(cur.b, last.b)
    res.g = hl(cur.g, last.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_darken :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.r = min(last.r, cur.r)
    res.b = min(last.b, cur.b)
    res.g = min(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_lighten :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_dodge :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    cd :: proc( #any_int b, s: u32) -> i32 {
        if b == 0 {
            return 0
        }
        s1 := 255 - s
        if b >= s1 {
            return 255
        }
        return i32(div(b, s1))
    }

    res.r = cd(last.r, cur.r)
    res.b = cd(last.b, cur.b)
    res.g = cd(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_burn :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    cb :: proc( #any_int b, s: u32) -> i32 {
        if b == 255 {
            return 255
        }
        b1 := 255 - b
        if b1 >= s {
            return 0
        }
        return i32(255 - div(b1, s))
    }

    res.r = cb(last.r, cur.r)
    res.b = cb(last.b, cur.b)
    res.g = cb(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_hard_light :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    hl :: proc(b, s: i32) -> i32 {
        if s < 128 {
            return mul(b, s<<1)
        }
        return b + ((s<<1)-255) - mul(b, (s<<1)-255)
    }

    res.r = hl(last.r, cur.r)
    res.b = hl(last.b, cur.b)
    res.g = hl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_soft_light :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    sl :: proc(b, s: i32) -> i32 {
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
        return i32(r * 255 + 0.5)
    }

    res.r = sl(last.r, cur.r)
    res.b = sl(last.b, cur.b)
    res.g = sl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_difference :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.r = abs(last.r - cur.r)
    res.b = abs(last.b - cur.b)
    res.g = abs(last.g - cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_exclusion :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    ex :: proc(b, s: i32) -> i32 {
        return b + s - (mul(b, s) << 1)
    }
    
    res.r = ex(last.r, cur.r)
    res.b = ex(last.b, cur.b)
    res.g = ex(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// HSV Blenders
blend_hue :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    /*
    https://github.com/alpine-alpaca/asefile/blob/main/src/blend.rs#L392
    https://drafts.fxtf.org/compositing-1/#blendinghue
    https://printtechnologies.org/standards/files/pdf-reference-1.6-addendum-blend-modes.pdf
    https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp#L425
    https://gitlab.freedesktop.org/pixman/pixman/-/blob/master/pixman/pixman-combine-float.c?ref_type=heads#L908
    */

    lpix := [3]f64{f64(last.r), f64(last.g), f64(last.b)} / 255
    sat := hsv_sat(lpix)
    lum := hsv_luma(lpix)

    cpix := [3]f64{f64(cur.r), f64(cur.g), f64(cur.b)} / 255
    cpix = set_sat(cpix, sat)
    cpix = set_luma(cpix, lum)
    cpix *= 255

    return blend_normal(last, {i32(cpix.r), i32(cpix.g), i32(cpix.b), cur.a}, opacity)
}


blend_saturation :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    pix := [3]f64{ f64(cur.r), f64(cur.g), f64(cur.b) }
    pix /= 255
    s := hsv_sat(pix)

    pix = { f64(last.r), f64(last.g), f64(last.b) }
    pix /= 255
    l := hsv_luma(pix)

    pix = set_luma(set_sat(pix, s), l)

    pix *= 255
    res = { i32(pix.r), i32(pix.g), i32(pix.b), cur.a }

    return blend_normal(last, res, opacity)
}


blend_color :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    pix := [3]f64{ f64(last.r), f64(last.g), f64(last.b) }
    pix /= 255
    l := hsv_luma(pix)

    pix = { f64(cur.r), f64(cur.g), f64(cur.b)}
    pix /= 255
    pix = set_luma(pix, l)

    pix *= 255
    res = { i32(pix.r), i32(pix.g), i32(pix.b), cur.a }

    return blend_normal(last, res, opacity)
}


blend_luminosity :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    pix := [3]f64{ f64(cur.r), f64(cur.g), f64(cur.b) }
    pix /= 255
    l := hsv_luma(pix)

    pix = { f64(last.r), f64(last.g), f64(last.b) }
    pix /= 255
    pix = set_luma(pix, l)

    pix *= 255
    res = { i32(pix.r), i32(pix.g), i32(pix.b), cur.a }

    return blend_normal(last, res, opacity)
}


blend_addition :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.r = min(last.r + cur.r, 255)
    res.g = min(last.g + cur.g, 255)
    res.b = min(last.b + cur.b, 255)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_subtract :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    res.r = max(last.r - cur.r, 0)
    res.g = max(last.g - cur.g, 0)
    res.b = max(last.b - cur.b, 0)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_divide :: proc(last, cur: B_Pixel, opacity: i32) -> (res: B_Pixel) {
    bd :: proc( #any_int b, s: u32) -> i32 {
        if b == 0 {
            return 0
        } else if b >= s {
            return 255
        }
        return i32(div(b, s))
    }

    res.r = bd( last.r, cur.r )
    res.g = bd( last.g, cur.g )
    res.b = bd( last.b, cur.b )
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// RGB Helpers

rgba_luma :: proc(pix: B_Pixel) -> i32 {
    return rgb_luma(pix.r, pix.b, pix.g)
}

rgb_luma :: proc(#any_int r, b, g: int) -> i32 {
    return i32(( r*2126 + g*7152 + b*722 ) / 10000 )
}

/* ------------------------------------------------------------------- */
// HSV Helpers

hsv_luma :: proc(p: [3]f64) -> f64 {
    return 0.3*p.r + 0.59*p.g + 0.11*p.b
}

hsv_sat :: proc(p: [3]f64) -> f64 {
    return max(p.r, p.g, p.b) - min(p.r, p.g, p.b)
}

clip_color :: proc(pix: [3]f64) -> [3]f64 {
    p := pix
    lum := hsv_luma(p)
    n := min(p.r, p.g, p.b)
    x := max(p.r, p.g, p.b)

    if n < 0 {
        p = lum + (((p - lum) * lum) / (lum - n))
    }

    if x > 1 {
        p = lum + (((p - lum) * (1 - lum)) / (x - lum))
    }

    return p
}

set_luma :: proc(p: [3]f64, l: f64) -> [3]f64 {
    d := l - hsv_luma(p)
    return clip_color(p + d)
}


set_sat :: proc(p: [3]f64, s: f64) -> (res: [3]f64) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp#L400
    // The chosen solution is a mix a asefile & pixman
    // https://github.com/alpine-alpaca/asefile/blob/main/src/blend.rs#L522
    // https://gitlab.freedesktop.org/pixman/pixman/-/blob/master/pixman/pixman-combine-float.c#L831


    when ASE_USE_BUGGED_SAT == true {
        res = p
        MIN :: proc(x, y: ^f64) -> ^f64 {
            return (x^ < y^) ? x : y
        }
        MAX :: proc(x, y: ^f64) -> ^f64 {
            return (x^ > y^) ? x : y
        }

        r, g, b := &res.r, &res.g, &res.b
        min := MIN(r, MIN(g, b))
        max := MAX(r, MAX(g, b))
        mid := r > g ? (g > b ? g : (r > b ? b : r)) : (g > b ? (b > r ? b : r): g)

        if max > min {
            mid^ = ((mid^ - min^) * s) / (max^ - min^)
            max^ = s
        } else {
            mid^ = 0
            max^ = 0
        }
        min^ = 0

    } else {
        val: [3]struct{v: f64, p: int} = {
            {p.r, 0}, {p.g, 1}, {p.b, 2},
        }
        val.rg = val.r.v < val.g.v ? val.rg : val.gr
        val.rb = val.r.v < val.b.v ? val.rb : val.br
        val.gb = val.g.v < val.b.v ? val.gb : val.bg
        min, mid, max := val.r.p, val.g.p, val.b.p

        if (p[max] - p[min]) != 0 {
            res[mid] = ( (p[mid] - p[min]) * s ) / ( p[max] - p[min] )
            res[max] = s
        }
    }

    return
}


/*
    The following is for mine (blob) record keeping:

    The way aseprite does set_set is very much bugged.
    First the sorting doesn't work when if r == g  and g < b

        MIN :: proc(x, y: ^f64) -> ^f64 {
            return (x^ < y^) ? x : y
        }
        MAX :: proc(x, y: ^f64) -> ^f64 {
            return (y^ < x^) ? x : y
        }

        r, g, b := &pix.r, &pix.g, &pix.b
        min := MIN(r, MIN(g, b))
        max := MAX(r, MAX(g, b))
        mid := r > g ? (g > b ? g : (r > b ? b : r)) : (g > b ? (b > r ? b : r): g)

    Second the way it's value calculations is also wrong & only leaves the blue channel
        if max > min {
            mid^ = ((mid^ - min^) * s) / (max^ - min^)
            max^ = s
        } else {
            mid^ = 0
            max^ = 0
        }

    The sullotion griven by asefile
        //  r --*--*----- min 
        //      |  |          
        //  g --*--|--*-- mid 
        //         |  |       
        //  b -----*--*-- max 

        res = p
        val := [3][2]f64{{p.r, 0}, {p.g, 1}, {p.b, 2}}

        val.rg = val.r[0] < val.g[0] ? val.rg : val.gr
        val.rb = val.r[0] < val.b[0] ? val.rb : val.br
        val.gb = val.g[0] < val.b[0] ? val.gb : val.bg
        min, mid, max := int(val.r[1]), int(val.g[1]), int(val.b[1])
        

        if max > min {
            res[mid] = ((res[mid] - res[min]) * s) / (res[max] - res[min])
            res[max] = s
        } else {
            res[mid], res[max] = 0, 0
        }
        res[min] = 0

    Pointer based version og working sullotion from pixman
        res = p
        min, mid, max: ^f64
        if p.r > p.g {
            if p.r > p.b {
                max = &res.r
                if p.g > p.b {
                    mid = &res.g
                    min = &res.b

                } else {
                    mid = &res.b
                    min = &res.g
                }

            } else {
                max = &res.b
                mid = &res.r
                min = &res.g
            }

        } else {
            if p.r > p.b {
                max = &res.g
                mid = &res.r
                min = &res.b

            } else {
                min = &res.r
                if p.g > p.b {
                    max = &res.g
                    mid = &res.b

                } else {
                    max = &res.b
                    mid = &res.g
                }
            }
        }


        if (max^ - min^) == 0 {
            mid^ = 0
            max^ = 0
        } else {
            mid^ = ((mid^ - min^) * s) / (max^ - min^)
            max^ = s
        }
        min^ = 0
    
    
    Pointerless pixman
        min, mid, max: int
        if p.r > p.g {
            if p.r > p.b {
                max = 0
                if p.g > p.b {
                    mid = 1
                    min = 2

                } else {
                    mid = 2
                    min = 1
                }

            } else {
                max = 2
                mid = 0
                min = 1
            }

        } else {
            if p.r > p.b {
                max = 1
                mid = 0
                min = 2

            } else {
                min = 0
                if p.g > p.b {
                    max = 1
                    mid = 2

                } else {
                    max = 2
                    mid = 1
                }
            }
        }

        if (p[max] - p[min]) != 0 {
            res[mid] = ((p[mid] - p[min]) * s) / (p[max] - p[min])
            res[max] = s
        }
*/

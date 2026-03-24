package aseprite_file_handler_utility

import "core:math"

@(require) import "core:fmt"
@(require) import "core:log"


ASE_USE_BUGGED_SAT :: #config(ASE_USE_BUGGED_SAT, false)


// https://printtechnologies.org/standards/files/pdf-reference-1.6-addendum-blend-modes.pdf


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

        r_pix := blend(l_pix, c_pix, f64(opacity), mode) or_return

        copy(cur[pos:pos+4], r_pix[:])
    }
    return
}

pixel_to_f64 :: proc(p: Pixel) -> F_Pixel {
    return {f64(p.r), f64(p.g), f64(p.b), f64(p.a)} / 255
}
pixel_from_f64 :: proc(fp: F_Pixel) -> Pixel {
    p := fp * 255
    return {u8(p.r), u8(p.g), u8(p.b), u8(p.a)}
}

blend :: proc(last, cur: Pixel, opacity: f64, mode: Blend_Mode) -> (res: Pixel, err: Blend_Error) {
    // https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp
    if last.a == 0 {
        res.rgb = cur.rgb
        res.a = byte((f64(cur.a)/255 * opacity)*255)
        return
    }

    back := pixel_to_f64(last)
    pix := pixel_to_f64(cur)

    blen: [4]f64
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
    blen = blend_merge(norm_merge, blen, (back.a * pix.a * opacity))

    return pixel_from_f64(blen), nil
}


/* ------------------------------------------------------------------- */
// RGB Blenders
blend_normal :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    if last.a == 0 {
        res = cur
        res.a = cur.a * opacity
    } else if cur.a == 0 {
        return last
    }

    cur := cur
    cur.a *= opacity

    res.a = cur.a + last.a - (last.a * cur.a) 
    res.rgb = last.rgb + (cur.rgb - last.rgb) * cur.a / res.a

    return res
}

blend_src :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) { 
    return last
}

blend_merge :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {

    if last.a == 0 {
        res.rgb = cur.rgb

    } else if cur.a == 0 {
        res.rgb = last.rgb

    } else {
        op: [4]f64 = opacity
        res = last + ((cur - last) * op) 
    }

    res.a = last.a + ((cur.a - last.a) * opacity)
    if res.a == 0 {
        res.rgb = 0
    }

    return
}

blend_neg_bw :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    if rgba_luma(last) < 128{
        return { 255, 255, 255, 255 }
    }
    return { 0, 0, 0, 255 }
}

blend_red_tint :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    cur := cur
    luma := rgba_luma(cur)
    cur = { luma + 1, luma/2, luma/2, last.a }
    return blend_normal(last, cur, opacity)
}

blend_blue_tint :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    luma := rgba_luma(cur)
    res = { luma/2, luma/2,  luma + 1, last.a }
    return blend_normal(last, res, opacity)
}

blend_normal_dst_over :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.a = cur.a * opacity
    return blend_normal(last, res, opacity)
}


blend_multiply :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res = last * cur
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_screen :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res = last + cur - (last * cur)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_overlay :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    return blend_hard_light(last, res, opacity)
}

blend_darken :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.r = min(last.r, cur.r)
    res.b = min(last.b, cur.b)
    res.g = min(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_lighten :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.r = max(last.r, cur.r)
    res.b = max(last.b, cur.b)
    res.g = max(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_dodge :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    cd :: proc(b, s: f64) -> f64 {
        if s == 1 {
            return 1
        }
        return min(1, b / (1 - s))
    }

    res.r = cd(last.r, cur.r)
    res.b = cd(last.b, cur.b)
    res.g = cd(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_color_burn :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    cb :: proc(b, s: f64) -> f64 {
        if s == 0 {
            return 0
        }
        return min(1, b / (1 - s))
    }

    res.r = cb(last.r, cur.r)
    res.b = cb(last.b, cur.b)
    res.g = cb(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_hard_light :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    hl :: proc(b, s: f64) -> f64 {
        if s <= 0.5 {
            return b * (2 * s)
        }
        return b + s - (b * s)
    }

    res.r = hl(last.r, cur.r)
    res.b = hl(last.b, cur.b)
    res.g = hl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_soft_light :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    sl :: proc(b, s: f64) -> f64 {
        d: f64

        if b <= 0.25 {
            d = ((16 * b - 12) * b + 4) * b
        } else {
            d = math.sqrt(b)
        }

        if s <= 0.5 {
            return b - (1 - 2 * s) * b * (1 - b)
        }
        return b + (2 * s - 1) * (d - b)
    }

    res.r = sl(last.r, cur.r)
    res.b = sl(last.b, cur.b)
    res.g = sl(last.g, cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_difference :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.r = abs(last.r - cur.r)
    res.b = abs(last.b - cur.b)
    res.g = abs(last.g - cur.g)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_exclusion :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    b := last.rgb
    s := cur.rgb
    res.rgb = b + s - ( 2 * b * s )
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// HSV Blenders
blend_hue :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    /*
    https://github.com/alpine-alpaca/asefile/blob/main/src/blend.rs#L392
    https://drafts.fxtf.org/compositing-1/#blendinghue
    https://printtechnologies.org/standards/files/pdf-reference-1.6-addendum-blend-modes.pdf
    https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp#L425
    https://gitlab.freedesktop.org/pixman/pixman/-/blob/master/pixman/pixman-combine-float.c?ref_type=heads#L908
    */

    sat := hsv_sat(last.rgb)
    lum := hsv_luma(last.rgb)

    cpix := cur.rgb
    cpix = set_sat(cpix, sat)
    cpix = set_luma(cpix, lum)

    return blend_normal(last, {cpix.r, cpix.g, cpix.b, cur.a}, opacity)
}


blend_saturation :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    pix := cur.rgb
    s := hsv_sat(pix)

    pix = last.rgb
    l := hsv_luma(pix)
    pix = set_luma(set_sat(pix, s), l)

    return blend_normal(last, { pix.r, pix.g, pix.b, cur.a }, opacity)
}


blend_color :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    pix := last.rgb
    l := hsv_luma(pix)

    pix = cur.rgb
    pix = set_luma(pix, l)

    return blend_normal(last, { pix.r, pix.g, pix.b, cur.a }, opacity)
}


blend_luminosity :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    pix := cur.rgb
    l := hsv_luma(pix)

    pix = last.rgb
    pix = set_luma(pix, l)

    return blend_normal(last, { pix.r, pix.g, pix.b, cur.a }, opacity)
}


blend_addition :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.r = min(last.r + cur.r, 255)
    res.g = min(last.g + cur.g, 255)
    res.b = min(last.b + cur.b, 255)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_subtract :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    res.r = max(last.r - cur.r, 0)
    res.g = max(last.g - cur.g, 0)
    res.b = max(last.b - cur.b, 0)
    res.a = cur.a
    return blend_normal(last, res, opacity)
}

blend_divide :: proc(last, cur: F_Pixel, opacity: f64) -> (res: F_Pixel) {
    bd :: proc( b, s: f64) -> f64 {
        if b == 0 {
            return 0
        } else if b >= s {
            return 1
        }
        return b / s
    }

    res.r = bd( last.r, cur.r )
    res.g = bd( last.g, cur.g )
    res.b = bd( last.b, cur.b )
    res.a = cur.a
    return blend_normal(last, res, opacity)
}



/* ------------------------------------------------------------------- */
// RGB Helpers

rgba_luma :: proc(pix: F_Pixel) -> f64 {
    return hsv_luma(pix.rgb)
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
        val: [3]struct{v: f64, p: u8} = {
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

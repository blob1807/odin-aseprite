package aseprite_file_handler_utility

import "base:runtime"
import "core:mem"
import "core:slice"
import "core:image"

@(require) import "core:fmt"
@(require) import "core:log"

import ase ".."


UTILS_DEBUG_MODE :: #config(ASE_UTILS_DEBUG, ODIN_DEBUG)


/* ================================== Destruction procs ================================== */
destroy_frame :: proc(frame: Frame, alloc := context.allocator) -> runtime.Allocator_Error {
    for &cel in frame.cels {
        destroy(&cel, alloc) or_return
    }
    return delete(frame.cels, alloc)
}

destroy_frames :: proc(frames: []Frame, alloc := context.allocator) -> runtime.Allocator_Error {
    for frame in frames {
        for &cel in frame.cels {
            destroy(&cel, alloc) or_return
        }
        delete(frame.cels, alloc) or_return
    }
    return delete(frames, alloc)
}

destroy_image :: proc(img: Image, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(img.data, alloc)
}

destroy_images :: proc(imgs: []Image, alloc := context.allocator) -> runtime.Allocator_Error {
    for img in imgs {
        delete(img.data, alloc) or_return
    }
    return delete(imgs, alloc)
}

destroy_image_bytes :: proc(imgs: [][]byte, alloc := context.allocator) -> runtime.Allocator_Error {
    for img in imgs {
        delete(img, alloc) or_return
    }
    return delete(imgs, alloc)
}

destroy_animation :: proc(anim: ^Animation, alloc := context.allocator) -> runtime.Allocator_Error {
    for frame in anim.frames {
        delete(frame, alloc) or_return
    }
    return delete(anim.frames, alloc)
}

destroy_info :: proc(info: ^Info) -> runtime.Allocator_Error {
    context.allocator = info.allocator
    destroy_frames(info.frames) or_return
    delete(info.layers) or_return
    delete(info.palette) or_return
    delete(info.tags) or_return
    delete(info.tilesets) or_return
    destroy_slices(info.slices) or_return
    return nil
}

destroy_cel :: proc(cel: ^Cel, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(cel.tilemap.tiles, alloc)
}

destroy_layers :: proc(lay: []Layer, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(lay, alloc)
}

destroy_palette :: proc(pal: Palette, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(pal)
}

destroy_slices :: proc(sls: []Slice, alloc := context.allocator) -> runtime.Allocator_Error {
    for sl in sls {
        destroy_slice(sl, alloc) or_return
    }
    return delete(sls)
}

destroy_slice :: proc(sl: Slice, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(sl.keys)
}

destroy :: proc {
    destroy_frames, 
    destroy_image, 
    destroy_animation, 
    destroy_image_bytes, 
    destroy_images,
    destroy_info,
    destroy_cel,
    destroy_frame,
    destroy_layers, 
    destroy_palette,
    destroy_slices,
    destroy_slice,
}
/* ======================================================================================= */


get_metadata :: proc(header: ase.File_Header) -> (md: Metadata) {
    return {
        int(header.width), 
        int(header.height), 
        Pixel_Depth(header.color_depth),
        u8(header.transparent_index),
    }
}


// Use with slice.sort_by, .sort_by_with_indices, .stable_sort_by, .is_sorted_by & .reverse_sort_by
cel_less :: proc(i, j: Cel) -> bool {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    ior := i.layer + i.z_index
    jor := j.layer + j.z_index
    return ior < jor || (ior == jor && i.z_index < j.z_index )
}

// Use with slice.sort_by_cmp, .stable_sort_by_cmp, .is_sorted_cmp & .reverse_sort_by_cmp
cel_cmp :: proc(i, j: Cel) -> slice.Ordering {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    iz  := i.z_index
    jz  := j.z_index
    ior := i.layer + iz
    jor := j.layer + jz

         if ior < jor { return .Less } 
    else if ior > jor { return .Greater } 
    else if iz < jz   { return .Less }
    else if iz > jz   { return .Greater }
    return .Equal
}


has_new_palette :: proc(doc: ^ase.Document) -> bool {
    for f in doc.frames {
        for c in f.chunks {
            _ = c.(ase.Palette_Chunk) or_continue
            return true
        }
    }
    return false
}


has_tileset :: proc(doc: ^ase.Document) -> bool {
    for f in doc.frames {
        for c in f.chunks {
            _ = c.(ase.Tileset_Chunk) or_continue
            return true
        }
    }
    return false
}


// Uses Nearest-neighbor Upscaling
upscale_image_from_bytes :: proc(img: []byte, md: Metadata, factor := 10, alloc := context.allocator) -> (res: []byte, res_md: Metadata, err: Errors) {
    ch := int(md.bpp) >> 3
    if len(img) != (md.width * md.height * ch) {
        fast_log(.Error, "image size doesn't match metadata")
        err = .Buffer_Size_Not_Match_Metadata
        return
    }

    res = make([]byte, len(img) * factor * factor, alloc) or_return
    res_md = {md.width*factor, md.height*factor, md.bpp, md.trans_idx}

    for h in 0..<md.height {
        for w in 0..<md.width {
            start := (h*md.width*factor + w) * factor * ch
            first := res[start:start + factor * ch]

            copy(first[:ch], img[(h*md.width + w) * ch:])

            for x in 1..<factor {
                copy(res[start + x * ch:][:ch], first)
            }

            for y in 1..<factor {
                copy(res[start + (y*md.width*factor*ch):], first)
            }
        }
    }

    return
}

// Uses Nearest-neighbor Upscaling
upscale_image_from_img :: proc(img: Image, factor := 10, alloc := context.allocator) -> (res: Image, err: Errors) {
    res.data, res.md = upscale_image_from_bytes(img.data, img.md, factor, alloc) or_return
    return
}

// Uses Nearest-neighbor Upscaling
upscale_image :: proc { upscale_image_from_img, upscale_image_from_bytes }


upscale_all_from_imgs :: proc(imgs: []Image, factor := 10, alloc := context.allocator) -> (res: []Image, err: Errors) {
    res = make([]Image, len(imgs), alloc) or_return
    for img, pos in imgs {
        res[pos] = upscale_image_from_img(img, factor, alloc) or_return
    }
    return
}

upscale_all_from_byte:: proc(imgs: [][]byte, md: Metadata, factor := 10, alloc := context.allocator) -> (res: [][]byte, res_md: Metadata, err: Errors) {
    res = make([][]byte, len(imgs), alloc) or_return
    if len(imgs) == 0 { return }
    res[0], res_md = upscale_image_from_bytes(imgs[0], md, factor, alloc) or_return

    for img, pos in imgs[1:] {
        res[pos], _ = upscale_image_from_bytes(img, md, factor, alloc) or_return
    }
    return
}

upscale_all :: proc{ upscale_all_from_imgs, upscale_all_from_byte }


compute_alpha :: proc(img: []u8, alloc := context.allocator) -> (res: []u8, err: Errors) {
    if len(img) % 4 != 0 {
        fast_log(.Error, "Given buffer isn't RGBA")
        return nil, .Buffer_Not_RGBA
    }

    img_buf := mem.slice_data_cast([][4]u8, img)
    buf := make([][3]u8, len(img_buf), alloc) or_return

    for p, pos in img_buf {
        bp := [4]i32{ i32(p.r), i32(p.g), i32(p.b), i32(p.a) }
        bp.rgb = bp.rgb * bp.a / (255 + bp.a - alpha(bp.a, 255))
        buf[pos] = { u8(bp.r), u8(bp.g), u8(bp.b) }
    }

    return mem.slice_data_cast([]u8, buf), nil
}


remove_alpha :: proc(img: []u8, alloc := context.allocator) -> (res: []u8, err: Errors) {
    if len(img) % 4 != 0 {
        fast_log(.Error, "Given buffer isn't RGBA")
        return nil, .Buffer_Not_RGBA
    }

    img_buf := mem.slice_data_cast([][4]u8, img)
    buf := make([][3]u8, len(img_buf), alloc) or_return

    for p, pos in img_buf {
        buf[pos] = p.rgb
    }

    return mem.slice_data_cast([]u8, buf), nil
}


// Converts `utils.Image` to a `core:image.Image` with allocation
to_core_image :: proc(buf: []byte, md: Metadata, alloc := context.allocator) -> (img: image.Image, err: runtime.Allocator_Error) {
    img.width      = md.width
    img.height     = md.height
    img.depth      = 8
    img.channels   = 4
    img.pixels.buf = make([dynamic]byte, len(buf), alloc) or_return

    copy(img.pixels.buf[:], buf)
    return
}

// Converts `utils.Image` to a `core:image.Image` with no allocation
to_core_image_non_alloc :: proc(buf: []byte, md: Metadata) -> (img: image.Image) {
    img.width    = md.width
    img.height   = md.height
    img.depth    = 8
    img.channels = 4

    raw := runtime.Raw_Dynamic_Array {
        data      = raw_data(buf),
        len       = len(buf),
        cap       = len(buf),
        allocator = runtime.nil_allocator()
    }

    img.pixels.buf = transmute([dynamic]byte)raw
    return
}


find_pixel_bounds :: proc(img: Image, bg_colour: [4]u8 = 0, check_trans := true) -> (bounds: Bounds) {
    assert(img.md.bpp == .RGBA)
    raw := mem.slice_data_cast([][4]u8, img.data)

    min_pos, max_pos := find_pixel_bounds_min_max(raw, img.width, img.height, bg_colour, check_trans)

    return { pos = min_pos, width = max_pos.x - min_pos.x, height = max_pos.y - min_pos.y }
}


find_pixel_bounds_min_max :: proc(img: [][4]u8, width, height: int, bg_colour: [4]u8, check_trans: bool) -> (min_pos, max_pos: [2]int) {

    min_pos = { width, height }
    max_pos = { 0, 0 }

    for y in 0..<height {
        for x in 0..<width {
            pix := img[y * width + x]
            if (pix.a == 0 && check_trans) || pix == bg_colour {
                continue
            }

            min_pos = { min(x, min_pos.x), min(y, min_pos.y) }
            max_pos = { max(x, max_pos.x), max(y, max_pos.y) }
        }
    }

    max_pos += 1

    return
}


draw_sheet_grid :: proc(sheet: Sprite_Sheet, colour: [4]u8) {
    fill_sheet_spacing(sheet, colour, true)
}


fill_sheet_spacing :: proc(sheet: Sprite_Sheet, colour: [4]u8, always_fill: bool) {
    img := sheet.img
    info := sheet.info
    assert(img.bpp == .RGBA)

    raw := slice.reinterpret([][4]u8, img.data)

    row_count := (img.height - info.size.y - (info.boarder.y * 2)) / ( info.size.y + info.spacing.y )
    if 0 < row_count {
        row_block := img.width * info.size.y
        row_space := img.width * info.spacing.y
        row_step  := row_block + row_space 
        row_fill  := always_fill ? max(img.width, row_space) : row_space

        row_offset := row_block + img.width * info.boarder.x
        base := raw[row_offset:][:row_fill]

        slice.fill(base, colour)

        for row in 1..<row_count {
            start := row_step * row + row_offset
            copy(raw[start:], base)
        }
    }

    col_count := info.count - 1
    if 0 < col_count {
        col_block := info.size.x + info.spacing.x
        col_fill  := always_fill ? max(1, info.spacing.y) : info.spacing.y
        col_offset := info.size.x + info.boarder.x

        base := raw[col_offset:][:col_fill]
        slice.fill(base, colour)

        for col in 1..<col_count {
            pos := col_block * col + col_offset
            copy(raw[pos:], base)
        }

        for y in 1..<img.height {
            start := img.width * y + col_offset
            for col in 0..<col_count {
                pos := col_block * col + start
                copy(raw[pos:], base)
            }
        }
    }

    return
}


fill_sheet_boarder :: proc(sheet: Sprite_Sheet, colour: [4]u8) {
    img := sheet.img
    info := sheet.info
    assert(img.bpp == .RGBA)

    raw := slice.reinterpret([][4]u8, img.data)

    if 0 < info.boarder.y {
        base := raw[:img.width * info.boarder.y]
        slice.fill(base, colour)
        copy(raw[(img.height - info.boarder.y) * img.width:], base)
    }

    if 0 < info.boarder.x {
        base_start := img.width * info.boarder.y
        base := raw[base_start:][:info.boarder.x]
        count := img.height - (info.boarder.y * 2)

        slice.fill(base, colour)
        copy(raw[base_start + img.width - info.boarder.x:], base)

        for pos in 0..<count {
            start := base_start + (img.width * pos)
            copy(raw[start:], base)
            copy(raw[start + img.width - info.boarder.x:], base)
        }
    }

    return
}


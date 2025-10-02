package aseprite_file_handler_utility

import "base:runtime"
import "core:slice"

@require import "core:fmt"
@require import "core:log"

import ase ".."


create_sprite_sheet :: proc {
    create_sprite_sheet_from_doc,
    create_sprite_sheet_from_info,
}


/*
Creates internal allocation on `context.temp_allocator`, will attempt to clean up after itself.
*/
create_sprite_sheet_from_doc :: proc (
    doc: ^ase.Document, s_info: Sprite_Info, 
    write_rules := DEFAULT_SPRITE_WRITE_RULES, alloc := context.allocator
) -> (res: Sprite_Sheet, err: Errors) {

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(context.allocator == context.temp_allocator)
    info: Info
    get_info(doc, &info, context.temp_allocator) or_return

    return create_sprite_sheet_from_info(info, s_info, write_rules, alloc)
}


/*
Creates internal allocation on `context.temp_allocator`, will attempt to clean up after itself.
*/
create_sprite_sheet_from_info :: proc (
    info: Info, s_info: Sprite_Info, 
    write_rules := DEFAULT_SPRITE_WRITE_RULES, alloc := context.allocator
) -> (res: Sprite_Sheet, err: Errors) {

    switch {
    case write_rules.align < min(Sprite_Alignment) || max(Sprite_Alignment) < write_rules.align:
        err = .Invalid_Alignment
        return

    case s_info.size.x < write_rules.offset.x || s_info.size.y < write_rules.offset.y:
        err = .Invalid_Offset
        return
    
    case s_info.spacing.x < 0 || s_info.spacing.y < 0:
        err = .Invalid_Spacing
        return

    case s_info.boarder.x < 0 || s_info.boarder.y < 0:
        err = .Invalid_Boarder
        return

    case s_info.count <= 0:
        err = .Invalid_Count
        return

    case (s_info.size.x * s_info.size.y) < (info.md.width * info.md.height):
        if !write_rules.ingore_sprite_size {
            err = .Sprite_Size_to_Small
            return
        }
        if !write_rules.shrink_to_pixels {
            fast_log(.Warning, "Sprite smaller than Frame. Ingoring & continuing.")
        }
    }

    // Note(blob):
    // Gets the clostest multiple of `s_info.count` that's `>=` to `len(info.frames)`.
    // Allows for `len(info.frames)` to not be a multiple of `s_info.count`;
    // and still make a valid grid.
    frame_count := len(info.frames) + (s_info.count - ((len(info.frames) - 1) %% s_info.count + 1))

    y_count := max( 1, frame_count / s_info.count )
    width   := ( s_info.count * s_info.size.x ) + ( (s_info.count - 1) * s_info.spacing.x )
    height  := ( y_count * s_info.size.y ) + ( (y_count - 1) * s_info.spacing.y )


    img_width  := width  + (s_info.boarder.x * 2)
    img_height := height + (s_info.boarder.y * 2)
    img_size   := img_width * img_height * 4

    res.info = s_info
    res.img  = {
        width  = img_width,
        height = img_height,
        bpp    = .RGBA,
        data   = make([]u8, img_size, alloc) or_return,
    }

    defer {
        if err != nil {
            delete(res.img.data, alloc)
        }
    }
    

    if write_rules.use_index_bg_colour && info.md.bpp == .Indexed && !info.layers[0].is_background {
        img_p := slice.reinterpret([]Pixel, res.img.data)
        c := info.palette[info.md.trans_idx].color
        c.a = 0
        slice.fill(img_p, c)
    
    } else {
        fill_colour(res.img.data, write_rules.background_colour)
    }

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(context.allocator == context.temp_allocator)
    tileset_alloc := context.temp_allocator

    sprite_pos: [2]int
    sw, sh := s_info.size.x, s_info.size.y

    for frame in info.frames {
        defer {
            sprite_pos.x += s_info.size.x + s_info.spacing.x
            if width <= sprite_pos.x {
                sprite_pos.x = 0
                sprite_pos.y += s_info.size.y + s_info.spacing.y
            }

            if height + s_info.spacing.y < sprite_pos.y {
                panic("Sprite Y Pos is OOB. This shouldn't happen... send help.")
            }
        }

        if len(frame.cels) == 0 {
            continue
        }

        if !slice.is_sorted_by(frame.cels, cel_less) {
            slice.sort_by(frame.cels, cel_less)
        }

        fw, fh := info.md.width, info.md.height
        fp: [2]int = 0

        if write_rules.shrink_to_pixels {
            min_pos := [2]int{fw, fh}
            max_pos: [2]int

            for cel in frame.cels {
                layer := info.layers[cel.layer]
                skip := (!layer.visiable) || (write_rules.ingore_bg_layers && layer.is_background)
                if skip { continue }

                size := [2]int{cel.width, cel.height}
                if cel.tilemap.tiles != nil {
                    ts := info.tilesets[layer.tileset]
                    size = {ts.width, ts.height}
                }
                
                min_pos = { 
                    min(min_pos.x, cel.pos.x), 
                    min(min_pos.y, cel.pos.y), 
                }
                max_pos = { 
                    max(max_pos.x, cel.pos.x + size.x), 
                    max(max_pos.y, cel.pos.y + size.y), 
                }
            }

            frame_size := max_pos - min_pos

            fw, fh = frame_size.x, frame_size.y
            fp = min_pos
        }

        cel_offset := write_rules.offset + s_info.boarder + sprite_pos - fp
        

        for cel in frame.cels {
            layer := info.layers[cel.layer]
            skip := (!layer.visiable) || (write_rules.ingore_bg_layers && layer.is_background)
            if skip { continue }

            s_cel := cel
            if cel.tilemap.tiles != nil {
                ts := info.tilesets[layer.tileset]
                s_cel = cel_from_tileset(cel, ts, info.md.bpp, tileset_alloc) or_return
            }
            
            // Sprite Sheet Aligment https://www.desmos.com/geometry/miqzk9ijus
            switch write_rules.align {
            case .Top_Left:   // Default Alignment
            case .Top_Center: s_cel.pos.x += (sw - fw) / 2
            case .Top_Right:  s_cel.pos.x += (sw - fw)
            
            case .Mid_Left:   s_cel.pos.y +=   (sh - fh) / 2
            case .Mid_Center: s_cel.pos   += { (sw - fw) / 2, (sh - fh) / 2 }
            case .Mid_Right:  s_cel.pos   += { (sw - fw),     (sh - fh) / 2 }

            case .Bot_Left:   s_cel.pos.y +=    sh - fh
            case .Bot_Center: s_cel.pos   += { (sw - fw) / 2, sh - fh }
            case .Bot_Right:  s_cel.pos   += { (sw - fw),     sh - fh }
            
            case:
                err = .Invalid_Alignment
                return
            }

            s_cel.pos += cel_offset
            // Make sure we don't pass a negitive position.
            s_cel.pos = { max(s_cel.pos.x, 0), max(s_cel.pos.y, 0) }

            write_cel(res.img.data, s_cel, layer, res.img.md, info.palette) or_return
        }
    }

    return
}


// Finds the smallest Sprite size need to fit all visable pixels.
// Ingores Background Layers
find_min_sprite_size :: proc(info: Info, make_square := true) -> (res: [2]int) {

    for frame in info.frames {
        for cel in frame.cels {
            layer := info.layers[cel.layer]
            if !layer.visiable || layer.is_background { continue }

            size := [2]int{ cel.width, cel.height }
            if cel.tilemap.tiles != nil {
                ts := info.tilesets[layer.tileset]
                size = {ts.width, ts.height}
            }

            res.x = max(res.x, size.x)
            res.y = max(res.y, size.y)
        }
    }

    if make_square {
        res = max(res.x, res.y)
    }

    return
}


draw_sheet_grid :: proc(sheet: ^Sprite_Sheet, colour: [4]u8) {
    draw_sheet_spacing(sheet, colour, true)
}


draw_sheet_spacing :: proc(sheet: ^Sprite_Sheet, colour: [4]u8, always_draw: bool) {
    img := sheet.img
    info := sheet.info
    assert(img.bpp == .RGBA)

    raw := slice.reinterpret([][4]u8, img.data)

    row_count := (img.height - info.size.y - (info.boarder.y * 2)) / ( info.size.y + info.spacing.y )
    if 0 < row_count {
        row_block := img.width * info.size.y
        row_space := img.width * info.spacing.y
        row_step  := row_block + row_space 
        row_fill  := always_draw ? max(img.width, row_space) : row_space

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
        col_fill  := always_draw ? max(1, info.spacing.y) : info.spacing.y
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


draw_sheet_boarder :: proc(sheet: ^Sprite_Sheet, colour: [4]u8) {
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


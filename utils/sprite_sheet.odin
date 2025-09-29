package aseprite_file_handler_utility

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:mem/virtual"

import ase ".."


Sprite_Sheet :: struct {
    using img: Image,
    info: Sprite_Info
}

Sprite_Info :: struct {
    size:    [2]int, // Size of a sprite.
    spacing: [2]int, // Spacing between each sprite.
    boarder: [2]int, // Boarder between sheet & image edge.
    count:   int,    // Sprites per row.
}

// Govern's how Frames are writen a Sprite
Sprite_Write_Rules :: struct {

    // What point on the Frame & Sprite to align. 
    // Effective when Frame.size < Sprite.Size.
    align:  Sprite_Alignment,

    // Offset from the alignment point
    offset: [2]int,

    // Shrinks Frame to the bounds of visable pixels
    shrink_to_pixels: bool,

    // Resulting sheet's Background Colour
    background_colour: [4]u8,

    // Whether to use the Background Colour
    // of the ase file or use `background_colour`;
    // Only used for `Indexed` colour mode.
    use_index_bg_colour: bool,

    // Whether to ignore Background layers.
    ingore_bg_layers: bool,
}

Sprite_Alignment :: enum {
    Top_Left, Top_Center, Top_Right,
    Mid_Left, Mid_Center, Mid_Right,
    Bot_Left, Bot_Center, Bot_Right,

    Center = Mid_Center,
    // Sprite Sheet Alignment https://www.desmos.com/geometry/miqzk9ijus
}

DEFAULT_SPRITE_WRITE_RULES :: Sprite_Write_Rules {
    align  = .Center,
    offset = 0,
    shrink_to_pixels = false,
}


/*
https://github.com/houmain/rect_pack
https://www.david-colson.com/2020/03/10/exploring-rect-packing.html
https://github.com/ThomasMiz/RectpackSharp
https://cran.r-project.org/web/packages/rectpacker/rectpacker.pdf
https://link.springer.com/chapter/10.1007/978-3-642-21827-9_29
*/

create_sprite_sheet :: proc {
    sprite_sheet_from_doc,
    sprite_sheet_from_info,
}


// Creates internal allocation on `context.temp_allocator`, will attempt to clean up after itself.
sprite_sheet_from_doc :: proc (
    doc: ^ase.Document, s_info: Sprite_Info, 
    write_rules := DEFAULT_SPRITE_WRITE_RULES, alloc := context.allocator
) -> (res: Sprite_Sheet, err: Errors) {

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(context.allocator == context.temp_allocator)
    info := get_info(doc, context.temp_allocator) or_return

    return sprite_sheet_from_info(info, s_info, write_rules, alloc)
}


// Creates internal allocation on `context.temp_allocator`, will attempt to clean up after itself.
sprite_sheet_from_info :: proc (
    info: Info, s_info: Sprite_Info, 
    write_rules := DEFAULT_SPRITE_WRITE_RULES, alloc := context.allocator
) -> (res: Sprite_Sheet, err: Errors) {

    if write_rules.align < min(Sprite_Alignment) || max(Sprite_Alignment) < write_rules.align {
        err = .Invalid_Alignment
        return
    }
    if s_info.size.x < write_rules.offset.x || s_info.size.y < write_rules.offset.y {
        err = .Invalid_Offset
        return
    }

    if (s_info.size.x * s_info.size.y) <= (info.md.width * info.md.height) {
        log.error("Be warned. If a `cel.size < sprite.size``, it'll error.")
        log.debug("I am working on it though")
    }

    if len(info.frames) %% s_info.count != 0 {
        log.error("Currently only works if `mod(len(frames), count) == 0.")
        log.debug("I am working on it though")
    }

    y_count := max( 1, len(info.frames) / s_info.count )
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
        data   = make([]u8, img_size, alloc) or_return
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

    for frame, f_idx in info.frames {
        defer {
            // fmt.println(f_idx, sprite_pos)
            sprite_pos.x += s_info.size.x + s_info.spacing.x
            if width <= sprite_pos.x {
                sprite_pos.x = 0
                sprite_pos.y += s_info.size.y + s_info.spacing.y
            }

            if height + s_info.spacing.y < sprite_pos.y {
                panic("This shouldn't happen... help.")
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
        

        /*if s_info.size.x < frame_size.x || s_info.size.y < frame_size.y {
            fmt.println(frame_size)
            err = .Frame_To_Big
            return
        }*/

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

            write_cel(res.img.data, s_cel, layer, res.img.md, info.palette) or_return
        }
    }

    return
}


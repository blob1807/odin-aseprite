package aseprite_file_handler_utility

import "base:runtime"
import "core:c"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:mem/virtual"

import ase ".."


Sprite_Sheet :: struct {
    img: Image,
    info: Sprite_Info
}

Sprite_Info :: struct {
    size:    [2]int, // Size of a sprite.
    spacing: [2]int, // Spacing between each sprite.
    count:   int,    // Sprites per row.
}


Sprite_Write_Rules :: struct {
    align:  Sprite_Alignment, // What point on the Frame & Sprite to align 
    offset: [2]int,           // Offset from the aligment point
    allow_oversize: bool,
}

Sprite_Alignment :: enum {
    Top_Left, Top_Center, Top_Right,
    Mid_Left, Mid_Center, Mid_Right,
    Bot_Left, Bot_Center, Bot_Right,

    Center = Mid_Center,
    // https://www.desmos.com/geometry/zstbhwznmu
}

DEFAULT_SPRITE_WRITE_RULES :: Sprite_Write_Rules {
    align  = .Top_Left,
    offset = 0,
    allow_oversize = false
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

sprite_sheet_from_doc :: proc (
    doc: ^ase.Document, s_info: Sprite_Info, 
    write_rules := DEFAULT_SPRITE_WRITE_RULES, alloc := context.allocator
) -> (res: Sprite_Sheet, err: Errors) {

    runtime.DEFAULT_TEMP_ALLOCATOR_TEMP_GUARD(context.allocator == context.temp_allocator)
    info := get_info(doc, context.temp_allocator) or_return

    return sprite_sheet_from_info(info, s_info, write_rules, alloc)
}


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

    y_count := max( 1, len(info.frames) / s_info.count )
    width   := ( s_info.count * s_info.size.x ) + ( (s_info.count - 1) * s_info.spacing.x )
    height  := ( y_count * s_info.size.y ) + ( (y_count - 1) * s_info.spacing.y )

    fmt.println(y_count, width, height)
    
    sprite_size  := s_info.size.x * s_info.size.y * 4
    img_size     := (width * height * 4)

    res.info = s_info
    res.img  = {
        width  = width,
        height = height,
        bpp    = .RGBA,
        data   = make([]u8, img_size, alloc) or_return
    }

    if !info.layers[0].is_background && info.md.bpp == .Indexed {
        img_p := slice.reinterpret([]Pixel, res.img.data)
        c := info.palette[info.md.trans_idx].color
        c.a = 0
        slice.fill(img_p, c)
    }

    tileset_arena: virtual.Arena
    _ = virtual.arena_init_growing(&tileset_arena)
    tileset_alloc := virtual.arena_allocator(&tileset_arena)
    defer virtual.arena_destroy(&tileset_arena)

    sprite_pos: [2]int

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

        min_pos, max_pos: [2]int

        for cel in frame.cels {
            layer := info.layers[cel.layer]
            if !layer.visiable { continue }

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

        frame_pos  := min_pos
        frame_size := max_pos - min_pos

        if !write_rules.allow_oversize \
        && (s_info.size.x < frame_size.x || s_info.size.y < frame_size.y ) {
            err = .Frame_To_Big
            return
        }

        for cel in frame.cels {
            layer := info.layers[cel.layer]
            if !layer.visiable { continue }

            s_cel := cel
            if cel.tilemap.tiles != nil {
                ts := info.tilesets[layer.tileset]
                s_cel = cel_from_tileset(cel, ts, info.md.bpp, tileset_alloc) or_return
            }

            // https://www.desmos.com/geometry/zstbhwznmu
            sp := sprite_pos
            cp := s_cel.pos
            sw, sh := s_info.size.x, s_info.size.y
            cw, ch := s_cel.width, s_cel.height

            switch write_rules.align {
            case .Top_Left:   s_cel.pos = sprite_pos + s_cel.pos - frame_pos
            case .Top_Center: s_cel.pos = { sp.x + sw/2, sp.y } + { cp.x - cw/2, cp.y } - frame_pos
            case .Top_Right:  s_cel.pos = { sp.x + sw  , sp.y } + { cp.x - cw  , cp.y } - frame_pos
            
            case .Mid_Left:   s_cel.pos = { sp.x       , sp.y - sh/2 } + { cp.x       , cp.y + ch/2 } - frame_pos
            case .Mid_Center: s_cel.pos = { sp.x + sw/2, sp.y - sh/2 } + { cp.x - cw/2, cp.y + ch/2 } - frame_pos
            case .Mid_Right:  s_cel.pos = { sp.x + sw  , sp.y - sh/2 } + { cp.x - cw  , cp.y + ch/2 } - frame_pos

            case .Bot_Left:   s_cel.pos = { sp.x       , sp.y - sh } + { cp.x       , cp.y + ch } - frame_pos
            case .Bot_Center: s_cel.pos = { sp.x + sw/2, sp.y - sh } + { cp.x - cw/2, cp.y + ch } - frame_pos
            case .Bot_Right:  s_cel.pos = { sp.x + sw  , sp.y - sh } + { cp.x - cw  , cp.y + ch } - frame_pos
            
            case:
                err = .Invalid_Alignment
                return
            }

            s_cel.pos += write_rules.offset

            write_cel(res.img.data, s_cel, layer, res.img.md, info.palette) or_return
        }
    }

    return
}


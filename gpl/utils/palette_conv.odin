package aseprite_extended_gpl_utility

import ase "../.."
import gpl ".."
import "../../utils"
import "core:slice"

// TODO: Move to parent folder

gpl_to_ase :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (pal: ase.Palette_Chunk, err: gpl.Errors) {
    pal.entries = make([]ase.Palette_Entry, len(gpl_pal.colors)) or_return
    pal.size = ase.DWORD(len(gpl_pal.colors))
    pal.last_index = pal.size

    for &en, i in pal.entries {
        en.color = gpl_pal.colors[i].color
        if gpl_pal.colors[i].name != "" {
            en.name = gpl_pal.colors[i].name
        }
    }

    return
}

gpl_to_old_packet :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (pack: []ase.Old_Palette_Packet, err: gpl.Errors) { 
    context.allocator = alloc
    buf := make([dynamic]ase.Old_Palette_Packet, 0, len(gpl_pal.colors) / 256 + 1) or_return

    size := len(gpl_pal.colors)
    pos: int
    for size > 256 { 
        pal: ase.Old_Palette_Packet
        pal.num_colors = 0
        pal_buf := make([]ase.Color_RGB, 256) or_return

        for i in 0..<256 {
            pal_buf[i] = gpl_pal.colors[pos].color.rgb
            pos += 1
        }

        pal.colors = pal_buf[:]
        
        append(&buf, pal) or_return
        size -= 256
    }

    if size > 0 {
        pal: ase.Old_Palette_Packet
        pal.num_colors = 0
        pal_buf := make([]ase.Color_RGB, size) or_return

        for i in 0..<size {
            pal_buf[i] = gpl_pal.colors[pos].color.rgb
            pos += 1
        }

        pal.colors = pal_buf[:]
        
        append(&buf, pal) or_return
    }

    return 
}

gpl_to_old_256 :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (res: ase.Old_Palette_256_Chunk, err: gpl.Errors) {
    buf := gpl_to_old_packet(gpl_pal, alloc) or_return
    res = transmute(ase.Old_Palette_256_Chunk)buf
    return
}

gpl_to_old_64 :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (res: ase.Old_Palette_64_Chunk, err: gpl.Errors) {
    buf := gpl_to_old_packet(gpl_pal, alloc) or_return
    res = transmute(ase.Old_Palette_64_Chunk)buf
    return
}


doc_to_gpl :: proc(doc: ^ase.Document, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    has_new := utils.has_new_palette(doc)
    for frame in doc.frames {
        for chunk in frame.chunks {
            #partial switch &cel in chunk {
            case ase.Palette_Chunk:
                new_to_gpl(&cel, gpl_pal, alloc) or_return
            case ase.Old_Palette_256_Chunk:
                if !has_new {
                    old_256_to_gpl(cel, gpl_pal, alloc) or_return
                }
            case ase.Old_Palette_64_Chunk:
                if !has_new {
                    old_64_to_gpl(cel, gpl_pal, alloc) or_return
                }
                
            }
        }
    }
    return
}

new_to_gpl :: proc(data: ^ase.Palette_Chunk, pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    pal.rgba = true
    reserve(&pal.colors, len(data.entries)) or_return

    for c in data.entries {
        append_elem(&pal.colors, gpl.Color{color=c.color}) or_return
    }

    return
}

old_packet_to_gpl :: proc(pack: []ase.Old_Palette_Packet, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) { 
    for p in pack {
        for c in p.colors {
            append(&gpl_pal.colors, gpl.Color{color={c.r, c.g, c.b, 255}})
        }
    }
    return 
}

old_64_to_gpl :: proc(pal: ase.Old_Palette_64_Chunk, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    return ase_to_gpl(transmute([]ase.Old_Palette_Packet)pal, gpl_pal, alloc)
}

old_256_to_gpl :: proc(pal: ase.Old_Palette_256_Chunk, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    return ase_to_gpl(transmute([]ase.Old_Palette_Packet)pal, gpl_pal, alloc)
}

ase_to_gpl :: proc{doc_to_gpl, new_to_gpl, old_64_to_gpl, old_packet_to_gpl, old_256_to_gpl}


gpl_to_utils :: proc(gpl_pal: ^gpl.GPL_Palette) -> (pal: utils.Palette) {
    return slice.reinterpret(utils.Palette, gpl_pal.colors[:])
}

utils_to_gpl :: proc(pal: utils.Palette, gpl_pal: ^gpl.GPL_Palette, name := "", alloc := context.allocator) -> (err: gpl.Errors) {
    gpl_pal.rgba = true
    if name != "" {
        gpl_pal.name = name
    }
    append(&gpl_pal.colors, ..slice.reinterpret([]gpl.Color, pal)) or_return
    return nil
}
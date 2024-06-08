package aseprite_extended_gpl_utility

import ase "../.."
import gpl ".."
import "../../utils"
import "core:slice"

// TODO: Move to parent folder

gpl_to_ase :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (pal: ase.Palette_Chunk, ok: bool) {
    return
}

gpl_to_old_packet :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (pack: []ase.Old_Palette_Packet, ok: bool) { 
    return 
}

gpl_to_old_256 :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (res: ase.Old_Palette_64_Chunk, ok: bool) {
    // Old isn't a single palette but a bunch of Packets
    return
}

gpl_to_old_64 :: proc(gpl_pal: gpl.GPL_Palette, alloc := context.allocator) -> (res: ase.Old_Palette_64_Chunk, ok: bool) {
    // Old isn't a single palette but a bunch of Packets
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
        append_elem(&pal.colors, 
            gpl.Color{color={
                c.color.r, 
                c.color.g, 
                c.color.b, 
                c.color.a}
            }
        ) or_return
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
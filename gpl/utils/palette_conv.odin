package aseprite_extended_gpl_utility

import ase "../.."
import gpl ".."

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
    return
}

palette_to_gpl :: proc(data: ^ase.Palette_Chunk, pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    pal.rgba = true
    reserve(&pal.colors, len(data.entries)) or_return

    for c in data.entries {
        append_elem(&pal.colors, 
            gpl.Color{color={
                int(c.color.r), 
                int(c.color.g), 
                int(c.color.b), 
                int(c.color.a)}
            }
        ) or_return
    }

    return
}

old_packet_to_gpl :: proc(pack: []ase.Old_Palette_Packet, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) { 
    return 
}

old_64_to_gpl :: proc(pal: ase.Old_Palette_64_Chunk, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    return ase_to_gpl(transmute([]ase.Old_Palette_Packet)pal, gpl_pal, alloc)
}

old_256_to_gpl :: proc(pal: ase.Old_Palette_256_Chunk, gpl_pal: ^gpl.GPL_Palette, alloc := context.allocator) -> (err: gpl.Errors) {
    return ase_to_gpl(transmute([]ase.Old_Palette_Packet)pal, gpl_pal, alloc)
}

ase_to_gpl :: proc{doc_to_gpl, palette_to_gpl, old_64_to_gpl, old_packet_to_gpl, old_256_to_gpl}
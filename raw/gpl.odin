package raw_aseprite_file_handler

import "base:runtime"
import gpl "../extended_gpl"


from_old_256_to_gpl :: proc(data: Old_Palette_256_Chunk, pal: ^gpl.gpl_palette) -> (err: runtime.Allocator_Error) {
    pal.rgba = true
    size: int
    for pak in data.packets {
        size += int(pak.num_colors)
    }
    reserve_dynamic_array(&pal.colors, size) or_return

    for pak in data.packets {
        for c in pak.colors {
            color: gpl.gpl_color
            color.r = int(c[0])
            color.g = int(c[1])
            color.b = int(c[2])
            color.a = 255
            append(&pal.colors, color) or_return
        }
    }
    return
}

from_old_64_to_gpl :: proc(data: Old_Palette_64_Chunk, pal: ^gpl.gpl_palette) -> (err: runtime.Allocator_Error) {
    pal.rgba = true
    size: int
    for pak in data.packets {
        size += int(pak.num_colors)
    }
    reserve_dynamic_array(&pal.colors, size) or_return

    for pak in data.packets {
        for c in pak.colors {
            color: gpl.gpl_color
            color.r = int(c[0])
            color.g = int(c[1])
            color.b = int(c[2])
            color.a = 255
            append(&pal.colors, color)  or_return
        }
    }
    return
}
from_palette_to_gpl:: proc(data: Palette_Chunk, pal: ^gpl.gpl_palette) -> (err: runtime.Allocator_Error){
    pal.rgba = true
    reserve_dynamic_array(&pal.colors, len(data.entries)) or_return

    for c in data.entries {
        color: gpl.gpl_color
        color.r = int(c.red)
        color.g = int(c.green)
        color.b = int(c.blue)
        color.a = int(c.alpha)
        append(&pal.colors, color)  or_return
    }

    return
}

to_gpl :: proc{from_old_256_to_gpl, from_old_64_to_gpl, from_palette_to_gpl}


from_gpl_to_old_256 :: proc(data: gpl.gpl_palette, pal: ^Old_Palette_256_Chunk, allocator := context.allocator)-> (err: runtime.Allocator_Error) {
    size := len(data.colors)
    pals := size / 256 + 1
    cols := size % 256
    pos: int

    pal.packets = make_slice([]Old_Palette_Packet, pals, allocator) or_return
    pal.size = WORD(pals)

    for &pak in pal.packets {
        pak.colors = make_slice([][3]BYTE, cols, allocator) or_return
        pak.num_colors = BYTE(cols)

        for &c in pak.colors {
            c[0] = BYTE(data.colors[pos].r)
            c[1] = BYTE(data.colors[pos].g)
            c[2] = BYTE(data.colors[pos].b)
            pos += 1
        }
        size -= 256
        cols = size % 256
    }

    return
}

from_gpl_to_old_64 :: proc(data: gpl.gpl_palette, pal: ^Old_Palette_64_Chunk, allocator := context.allocator) -> (err: runtime.Allocator_Error) {
    size := len(data.colors)
    pals := size / 256 + 1
    cols := size % 256
    pos: int

    pal.packets = make_slice([]Old_Palette_Packet, pals, allocator) or_return
    pal.size = WORD(pals)

    for &pak in pal.packets {
        pak.colors = make_slice([][3]BYTE, cols, allocator) or_return
        pak.num_colors = BYTE(cols)

        for &c in pak.colors {
            c[0] = BYTE(data.colors[pos].r)
            c[1] = BYTE(data.colors[pos].g)
            c[2] = BYTE(data.colors[pos].b)
            pos += 1
        }
        size -= 256
        cols = size % 256
    }

    return
}
from_gpl_to_palette :: proc(data: gpl.gpl_palette, pal: ^Palette_Chunk, allocator := context.allocator) -> (err: runtime.Allocator_Error) {
    pal.entries = make_slice([]Palette_Entry, len(data.colors), allocator) or_return
    pal.size = DWORD(len(data.colors))

    for c, pos in data.colors {
        pal.entries[pos].red = BYTE(c.r)
        pal.entries[pos].green = BYTE(c.g)
        pal.entries[pos].blue = BYTE(c.b)
        pal.entries[pos].alpha = BYTE(c.a)
    }

    return
}

from_gpl :: proc{from_gpl_to_old_256, from_gpl_to_old_64, from_gpl_to_palette}
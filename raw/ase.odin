package raw_aseprite_file_handler

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:encoding/endian"
import "core:slice"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

ASE_Unmarshal_Errors :: enum{}
ASE_Unmarshal_Error :: union #shared_nil {ASE_Unmarshal_Errors, runtime.Allocator_Error}

ase_unmarshal :: proc(data: []byte, doc: ^ASE_Document, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    last: int
    pos := size_of(DWORD)
    // ========= FILE HEADER =========
    h: File_Header
    h.size, _ = endian.get_u32(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.magic, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.frames, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.width, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.height, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.color_depth, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(DWORD)
    h.flags, _ = endian.get_u32(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.speed, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(DWORD)
    last = pos
    pos += size_of(DWORD)

    last = pos
    pos += size_of(BYTE)
    h.transparent_index = data[pos]

    last =  pos + 3
    pos += size_of(WORD) + 3
    h.num_of_colors, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(BYTE)
    h.ratio_width = data[pos]

    last = pos
    pos += size_of(BYTE)
    h.ratio_height = data[pos]

    last = pos
    pos += size_of(SHORT)
    h.x, _ = endian.get_i16(data[last:pos], .Little)

    last = pos
    pos += size_of(SHORT)
    h.y, _ = endian.get_i16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.grid_width, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.grid_height, _ = endian.get_u16(data[last:pos], .Little)

    last = pos + 84
    pos += size_of(BYTE) + 84
    doc.header = h

    doc.frames = make_slice([]Frame, int(doc.header.frames), allocator)

    // ======= Frames ========
    for header_count in 0..<h.frames {
        fh: Frame_Header
        last = pos
        pos += size_of(DWORD)
        fh.size, _ = endian.get_u32(data[last:pos], .Little)

        last = pos
        pos += size_of(WORD)
        fh.magic, _ = endian.get_u16(data[last:pos], .Little)

        last = pos
        pos += size_of(WORD)
        fh.old_num_of_chunks, _ = endian.get_u16(data[last:pos], .Little)

        last = pos
        pos += size_of(WORD)
        fh.duration, _ = endian.get_u16(data[last:pos], .Little)

        last = pos + 2
        pos += size_of(DWORD) + 2
        fh.num_of_chunks, _ = endian.get_u32(data[last:pos], .Little)

        frame_count: int
        if fh.num_of_chunks == 0 {
            frame_count = int(fh.old_num_of_chunks)
        } else {
            frame_count = int(fh.num_of_chunks)
        }

        doc.frames[header_count].header = fh
        doc.frames[header_count].chunks = make_slice([]Chunk, frame_count, allocator)

        /*for frame in 0..<frame_count {
            c: Chunk
            last = pos
            pos += size_of(DWORD)
            c.size, _ = endian.get_u32(data[last:pos], .Little)

            last = pos
            pos += size_of(WORD)
            t_c_type, _ := endian.get_u16(data[last:pos], .Little)
            c.type = Chunk_Types(t_c_type)

            #partial switch c.type {
                case:
            }

            doc.frames[header_count].chunks[frame] = c
        }*/
    }

    
    return
}
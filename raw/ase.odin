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

    last = pos
    pos += size_of(BYTE) * 3

    last =  pos
    pos += size_of(WORD)
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

    last = pos
    pos += size_of(BYTE)*84
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

        last = pos
        pos += size_of(BYTE) * 2

        last = pos
        pos += size_of(DWORD)
        fh.num_of_chunks, _ = endian.get_u32(data[last:pos], .Little)

        frame_count: int
        if fh.num_of_chunks == 0 {
            frame_count = int(fh.old_num_of_chunks)
        } else {
            frame_count = int(fh.num_of_chunks)
        }

        doc.frames[header_count].header = fh
        doc.frames[header_count].chunks = make_slice([]Chunk, frame_count, allocator)

        for frame in 0..<frame_count {
            c: Chunk
            t_pos := pos
            last = pos
            pos += size_of(DWORD)
            c.size, _ = endian.get_u32(data[last:pos], .Little)

            last = pos
            pos += size_of(WORD)
            t_c_type, _ := endian.get_u16(data[last:pos], .Little)
            c.type = Chunk_Types(t_c_type)

            switch c.type {
            case .old_palette_256:
                last = pos
                pos += size_of(WORD)
                ct: Old_Palette_256_Chunk
                ct.size, _ = endian.get_u16(data[last:pos], .Little)
                ct.packets = make_slice([]Old_Palette_Packet, int(ct.size))

                for p in 0..<ct.size {
                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].entries_to_skip = data[pos]

                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].num_colors = data[pos]
                    ct.packets[p].colors = make_slice([][3]BYTE, ct.packets[p].num_colors)

                    for color in 0..<int(ct.packets[p].num_colors){
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][0] = data[pos]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][1] = data[pos]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][2] = data[pos]
                    }
                }

                c.data = ct

            case .old_palette_64:
                last = pos
                pos += size_of(WORD)
                ct: Old_Palette_64_Chunk
                ct.size, _ = endian.get_u16(data[last:pos], .Little)

                for p in 0..<ct.size {
                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].num_colors = data[pos]
                    ct.packets[p].colors = make_slice([][3]BYTE, ct.packets[p].num_colors)

                    for color in 0..<int(ct.packets[p].num_colors){
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][0] = data[pos]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][1] = data[pos]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][2] = data[pos]
                    }
                }
                c.data = ct

            case .layer:
                last = pos
                pos += size_of(WORD)
                ct: Layer_Chunk
                ct.flags, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.type, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.child_level, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.default_width, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.default_height, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.blend_mode, _ = endian.get_u16(data[last:pos], .Little)

                if (h.flags & 1) == 1 {
                    last = pos
                    pos += size_of(BYTE)
                    ct.opacity = data[pos]
                }

                last = pos
                pos += size_of(WORD)
                ct.name.length, _ = endian.get_u16(data[last:pos], .Little)
                ct.name.data = make_slice([]BYTE, int(ct.name.length))
                
                for sl in 0..<ct.name.length{
                    last = pos
                    pos += size_of(BYTE)
                    ct.name.data[sl] = data[pos]
                }

                if ct.type == 2 {
                    last = pos
                    pos += size_of(DWORD)
                    ct.tileset_index, _ = endian.get_u32(data[last:pos], .Little)
                }

                c.data = ct

            case .cel:
                last = pos
                pos += size_of(WORD)
                ct: Cel_Chunk

                c.data = ct

            case .cel_extra:
                last = pos
                pos += size_of(WORD)
                ct: Cel_Extra_Chunk

                c.data = ct

            case .color_profile:
                last = pos
                pos += size_of(WORD)
                ct: Color_Profile_Chunk

                c.data = ct

            case .external_files:
                last = pos
                pos += size_of(DWORD)
                ct: External_Files_Chunk

                c.data = ct

            case .mask:
                last = pos
                pos += size_of(SHORT)
                ct: Mask_Chunk

                c.data = ct

            case .path:
                ct: Path_Chunk
                c.data = ct

            case .tags:
                last = pos
                pos += size_of(WORD)
                ct: Tags_Chunk

                c.data = ct

            case .palette:
                last = pos
                pos += size_of(DWORD)
                ct: Palette_Chunk

                c.data = ct

            case .user_data:
                last = pos
                pos += size_of(WORD)
                ct: User_Data_Chunk

                c.data = ct

            case .slice:
                last = pos
                pos += size_of(DWORD)
                ct: Slice_Chunk

                c.data = ct

            case .tileset:
                last = pos
                pos += size_of(DWORD)
                ct: Tileset_Chunk

                c.data = ct

            case .none:
            case: unreachable()
            }
            last = pos
            pos = t_pos + int(c.size)

            doc.frames[header_count].chunks[frame] = c
        }
    }

    
    return
}
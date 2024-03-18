package raw_aseprite_file_handler

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:encoding/endian"
import "core:slice"
import "core:log"
import "core:compress/zlib"
import "core:bytes"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

ase_unmarshal :: proc(data: []byte, doc: ^ASE_Document, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    last: int
    pos := size_of(DWORD)
    // ========= FILE HEADER =========
    h: File_Header
    h.size, _ = endian.get_u32(data[last:pos], .Little)

    last = pos
    pos += size_of(WORD)
    h.magic, _ = endian.get_u16(data[last:pos], .Little)

    if h.magic != 0xA5E0 {
        return .Bad_File_Magic_Number
    }

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
    h.transparent_index = data[last]

    last = pos
    pos += size_of(BYTE) * 3

    last =  pos
    pos += size_of(WORD)
    h.num_of_colors, _ = endian.get_u16(data[last:pos], .Little)

    last = pos
    pos += size_of(BYTE)
    h.ratio_width = data[last]

    last = pos
    pos += size_of(BYTE)
    h.ratio_height = data[last]

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

    doc.frames = make_slice([]Frame, int(doc.header.frames), allocator) or_return

    // ======= Frames ========
    for header_count in 0..<h.frames {
        fh: Frame_Header
        last = pos
        pos += size_of(DWORD)
        fh.size, _ = endian.get_u32(data[last:pos], .Little)

        last = pos
        pos += size_of(WORD)
        fh.magic, _ = endian.get_u16(data[last:pos], .Little)

        if fh.magic != 0xF1FA {
            return .Bad_Frame_Magic_Number
        }

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
        doc.frames[header_count].chunks = make_slice([]Chunk, frame_count, allocator) or_return

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

            // ============ Chunks =============
            switch c.type {
            case .old_palette_256:
                skip: int
                ct: Old_Palette_256_Chunk

                last = pos
                pos += size_of(WORD)
                ct.size, _ = endian.get_u16(data[last:pos], .Little)
                ct.packets = make_slice([]Old_Palette_Packet, int(ct.size)) or_return

                
                for p in 0..<int(ct.size) {
                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].entries_to_skip = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].num_colors = data[last]
                    count := int(data[last])
                    if count == 0 {
                        count = 256
                    }

                    ct.packets[p].colors = make_slice([][3]BYTE, count, allocator) or_return

                    for c in 0..<count{
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[c][2] = data[last]

                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[c][1] = data[last]

                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[c][0] = data[last]
                    }
                }

                c.data = ct

            case .old_palette_64:
                skip: int
                ct: Old_Palette_64_Chunk
                last = pos
                pos += size_of(WORD)
                
                ct.size, _ = endian.get_u16(data[last:pos], .Little)

                for p in 0..<ct.size {
                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].entries_to_skip = data[last]
                    //skip += int(data[last])
                    
                    last = pos
                    pos += size_of(BYTE)
                    ct.packets[p].num_colors = data[last]
                    count := int(data[last])
                    if count == 0 {
                        count = 256
                    }

                    ct.packets[p].colors = make_slice([][3]BYTE, count) or_return
                    
                    //count += skip
                    for color in 0..<count{ 
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][2] = data[last]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][1] = data[last]
                        last = pos
                        pos += size_of(BYTE)
                        ct.packets[p].colors[color][0] = data[last]
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

                last = pos
                pos += size_of(BYTE)*3

                if (h.flags & 1) == 1 {
                    last = pos
                    pos += size_of(BYTE)
                    ct.opacity = data[last]
                }

                last = pos
                pos += size_of(WORD)
                ct.name.length, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += int(ct.name.length)
                ct.name.data = data[last:pos]

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
                ct.layer_index, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(SHORT)
                ct.x, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(SHORT)
                ct.y, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(BYTE)
                ct.opacity_level = data[last]

                last = pos
                pos += size_of(WORD)
                ct.type, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(SHORT)
                ct.z_index, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(BYTE)*5

                if ct.type == 0 {
                    cel: Raw_Cel
                    last = pos
                    pos += size_of(WORD)
                    cel.width, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(WORD)
                    cel.height, _ = endian.get_u16(data[last:pos], .Little)
                    cel.pixel = make_slice([]PIXEL, cel.height*cel.width) or_return

                    for px in 0..<int(cel.height*cel.width) {
                        last = pos
                        pos += size_of(BYTE)
                        cel.pixel[px] = data[last]
                    }
                    ct.cel = cel

                }else if ct.type == 1 {
                    last = pos
                    pos += size_of(WORD)
                    cel, _ := endian.get_u16(data[last:pos], .Little)
                    ct.cel = Linked_Cel(cel)

                }else if ct.type == 2 {
                    cel: Com_Image_Cel
                    last = pos
                    pos += size_of(WORD)
                    cel.width, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(WORD)
                    cel.height, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos = t_pos + int(c.size)

                    buf: bytes.Buffer
                    defer bytes.buffer_destroy(&buf)

                    expected_size := int(h.color_depth / 8 * cel.height * cel.width)
                    com_err := zlib.inflate(data[last:pos], &buf, expected_output_size=expected_size)

                    if com_err != nil {
                        cel.pixel = data[last:pos]
                        log.errorf("Unable to Uncompressed Image. Writing raw data of %v bytes.", pos-last)
                    } else {
                        //cel.pixel = make_slice([]u8, expected_size, allocator) or_return
                        //copy(cel.pixel[:], buf.buf[:])
                        cel.pixel = slice.clone(buf.buf[:], allocator) or_return
                        cel.did_com = true
                    }


                    ct.cel = cel

                }else if ct.type == 3 {
                    cel: Com_Tilemap_Cel
                    last = pos
                    pos += size_of(WORD)
                    cel.width, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(WORD)
                    cel.height, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(WORD)
                    cel.bits_per_tile, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    cel.bitmask_id, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    cel.bitmask_x, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    cel.bitmask_y, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    cel.bitmask_diagonal, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(BYTE)*10

                    last = pos
                    pos = t_pos + int(c.size)

                    buf: bytes.Buffer
                    defer bytes.buffer_destroy(&buf)

                    expected_size := int(h.color_depth / 8 * cel.height * cel.width)
                    com_err := zlib.inflate(data[last:pos], &buf, expected_output_size=expected_size)

                    if com_err != nil {
                        cel.tiles = data[last:pos]
                        log.errorf("Unable to Uncompressed Tilemap. Writing raw data of %v bytes.", pos-last)
                    } else {
                        //cel.tiles = make_slice([]u8, expected_size, allocator) or_return
                        cel.tiles = slice.clone(buf.buf[:], allocator) or_return
                        cel.did_com = true
                    }

                    ct.cel = cel
                }

                c.data = ct

            case .cel_extra:
                last = pos
                pos += size_of(WORD)
                ct: Cel_Extra_Chunk
                ct.flags, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(FIXED)
                t, _ := endian.get_i32(data[last:pos], .Little)
                ct.x = auto_cast t

                last = pos
                pos += size_of(FIXED)
                t, _ = endian.get_i32(data[last:pos], .Little)
                ct.y = auto_cast t

                last = pos
                pos += size_of(FIXED)
                t, _ = endian.get_i32(data[last:pos], .Little)
                ct.width = auto_cast t

                last = pos
                pos += size_of(FIXED)
                t, _ = endian.get_i32(data[last:pos], .Little)
                ct.height = auto_cast t

                last = pos
                pos += size_of(BYTE)*16

                c.data = ct

            case .color_profile:
                last = pos
                pos += size_of(WORD)
                ct: Color_Profile_Chunk
                ct.type, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.flags, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(FIXED)
                t, _ := endian.get_i32(data[last:pos], .Little)
                ct.fixed_gamma = FIXED(t)

                last = pos
                pos += size_of(BYTE)*8

                if ct.type == 2 {

                    last = pos
                    pos += size_of(DWORD)
                    ct.icc.length, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += int(ct.icc.length)
                    ct.icc.data = data[last:pos]

                    log.warnf("Embedded ICC Color Profiles are currently not supported. Writing %v raw byte instead.", ct.icc.length)
                }

                c.data = ct

            case .external_files:
                last = pos
                pos += size_of(DWORD)
                ct: External_Files_Chunk
                ct.length, _ = endian.get_u32(data[last:pos], .Little)
                ct.entries = make_slice([]External_Files_Entry, ct.length, allocator) or_return

                last = pos
                pos += size_of(BYTE) * 8

                for file in 0..<int(ct.length) {
                    last = pos
                    pos += size_of(DWORD)
                    ct.entries[file].id, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(BYTE)
                    ct.entries[file].type = data[last]

                    last = pos
                    pos += size_of(BYTE) * 7

                    last = pos
                    pos += size_of(WORD)
                    sl, _ := endian.get_u16(data[last:pos], .Little)
                    ct.entries[file].file_name_or_id.length = sl
                    // ct.entries[file].file_name_or_id.data = make_slice([]u8, sl, allocator) or_return

                    last = pos
                    pos += int(sl)
                    ct.entries[file].file_name_or_id.data = data[last:pos]
                }

                c.data = ct

            case .mask:
                last = pos
                pos += size_of(SHORT)
                ct: Mask_Chunk
                ct.x, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(SHORT)
                ct.y, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.width, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.height, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(BYTE)*8

                last = pos
                pos += size_of(WORD)
                ct.name.length, _ = endian.get_u16(data[last:pos], .Little)
                // ct.name.data = make_slice([]u8, ct.name.length, allocator) or_return

                last = pos
                pos += int(ct.name.length)
                ct.name.data = data[last:pos]

                last = pos
                pos += int(ct.height * ((ct.width + 7) / 8))
                ct.bit_map_data = data[last:pos]

                c.data = ct

            case .path:
                ct: Path_Chunk
                c.data = ct

            case .tags:
                last = pos
                pos += size_of(WORD)
                ct: Tags_Chunk
                ct.number, _ = endian.get_u16(data[last:pos], .Little)
                ct.tags = make_slice([]Tag, int(ct.number), allocator) or_return

                last = pos
                pos += size_of(BYTE) * 8

                for tag in 0..<int(ct.number) {
                    last = pos
                    pos += size_of(WORD)
                    ct.tags[tag].from_frame, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(WORD)
                    ct.tags[tag].to_frame, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(BYTE)
                    ct.tags[tag].loop_direction = data[last]

                    last = pos
                    pos += size_of(WORD)
                    ct.tags[tag].repeat, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(BYTE) * 6

                    last = pos
                    pos += size_of(BYTE)
                    ct.tags[tag].tag_color[2] = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.tags[tag].tag_color[1] = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.tags[tag].tag_color[0] = data[last]

                    last = pos
                    pos += size_of(BYTE)

                    last = pos
                    pos += size_of(WORD)
                    ct.tags[tag].name.length, _ = endian.get_u16(data[last:pos], .Little)
                    // ct.tags[tag].name.data = make_slice([]u8, ct.tags[tag].name.length, allocator) or_return

                    last = pos
                    pos += int(ct.tags[tag].name.length)
                    ct.tags[tag].name.data = data[last:pos]
                }

                c.data = ct

            case .palette:
                last = pos
                pos += size_of(DWORD)
                ct: Palette_Chunk
                ct.size, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)
                ct.first_index, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)
                ct.last_index, _ = endian.get_u32(data[last:pos], .Little)

                length := int(ct.last_index - ct.first_index + 1)
                ct.entries = make_slice([]Palette_Entry, length, allocator) or_return

                last = pos
                pos += size_of(BYTE) * 8

                for entry in 0..<length {
                    last = pos
                    pos += size_of(WORD)
                    ct.entries[entry].flags, _ = endian.get_u16(data[last:pos], .Little)

                    last = pos
                    pos += size_of(BYTE)
                    ct.entries[entry].red = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.entries[entry].green = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.entries[entry].blue = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    ct.entries[entry].alpha = data[last]

                    if (ct.entries[entry].flags & 1) == 1 {
                        last = pos
                        pos += size_of(WORD)
                        ct.entries[entry].name.length, _ = endian.get_u16(data[last:pos], .Little)

                        last = pos
                        pos += int(ct.entries[entry].name.length)
                        ct.entries[entry].name.data = data[last:pos]
                    }
                    
                }

                c.data = ct

            case .user_data:
                last = pos
                pos += size_of(DWORD)
                ct: User_Data_Chunk
                ct.flags, _ = endian.get_u32(data[last:pos], .Little)

                if (ct.flags & 1) == 1 {
                    str: STRING
                    last = pos
                    pos += size_of(WORD)
                    str.length, _ = endian.get_u16(data[last:pos], .Little)
                    // str.data = make_slice([]u8, int(str.length), allocator) or_return

                    last = pos
                    pos += int(str.length)
                    str.data = data[last:pos]

                    ct.text = str
                }
                
                if (ct.flags & 2) == 2 {
                    color: UB_Bit_2
                    last = pos
                    pos += size_of(BYTE)
                    color[3] = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    color[2] = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    color[1] = data[last]

                    last = pos
                    pos += size_of(BYTE)
                    color[0] = data[last]
                }
                
                if (ct.flags & 4) == 4 {
                    bit_4: UD_Bit_4
                    last = pos
                    pos += size_of(DWORD)
                    bit_4.size, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    bit_4.num, _ = endian.get_u32(data[last:pos], .Little)
                    bit_4.properties_map = make_slice([]UD_Properties_Map, int(bit_4.size), allocator) or_return

                    for n in 0..<int(bit_4.num) {
                        bit_4.properties_map[n], last, pos = _read_ud_map(last, pos, data[:], allocator) or_return
                    }

                    last = pos
                    pos += int(bit_4.size)

                    ct.properties = bit_4
                }

                c.data = ct

            case .slice:
                last = pos
                pos += size_of(DWORD)
                ct: Slice_Chunk
                ct.num_of_keys, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)
                ct.flags, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)

                last = pos
                pos += size_of(WORD)
                ct.name.length, _ = endian.get_u16(data[last:pos], .Little)
                // ct.name.data = make_slice([]u8, int(ct.name.length), allocator) or_return

                last = pos
                pos += int(ct.name.length)
                ct.name.data = data[last:pos]

                ct.data = make_slice([]Slice_Key, int(ct.num_of_keys), allocator) or_return

                for key in 0..<ct.num_of_keys{
                    last = pos
                    pos += size_of(DWORD)
                    ct.data[key].frame_num, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(LONG)
                    ct.data[key].x, _ = endian.get_i32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(LONG)
                    ct.data[key].y, _ = endian.get_i32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    ct.data[key].width, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    ct.data[key].height, _ = endian.get_u32(data[last:pos], .Little)
                    
                    if (ct.flags & 1) == 1 {
                        center: Slice_Center
                        last = pos
                        pos += size_of(LONG)
                        center.x, _ = endian.get_i32(data[last:pos], .Little)

                        last = pos
                        pos += size_of(LONG)
                        center.y, _ = endian.get_i32(data[last:pos], .Little)

                        last = pos
                        pos += size_of(DWORD)
                        center.width, _ = endian.get_u32(data[last:pos], .Little)

                        last = pos
                        pos += size_of(DWORD)
                        center.height, _ = endian.get_u32(data[last:pos], .Little)

                        ct.data[key].center = center
                    }

                    if (ct.flags & 2) == 2 {
                        pivot: Slice_Pivot
                        last = pos
                        pos += size_of(LONG)
                        pivot.x, _ = endian.get_i32(data[last:pos], .Little)

                        last = pos
                        pos += size_of(LONG)
                        pivot.y, _ = endian.get_i32(data[last:pos], .Little)

                        ct.data[key].pivot = pivot
                    }

                }

                c.data = ct

            case .tileset:
                last = pos
                pos += size_of(DWORD)
                ct: Tileset_Chunk
                ct.id, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)
                ct.flags, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(DWORD)
                ct.num_of_tiles, _ = endian.get_u32(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.width, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(WORD)
                ct.height, _ = endian.get_u16(data[last:pos], .Little)

                last = pos
                pos += size_of(SHORT)
                ct.base_index, _ = endian.get_i16(data[last:pos], .Little)

                last = pos
                pos += size_of(BYTE) * 14

                last = pos
                pos += size_of(WORD)
                ct.name.length, _ = endian.get_u16(data[last:pos], .Little)
                // ct.name.data = make_slice([]u8, int(ct.name.length), allocator) or_return

                last = pos
                pos += int(ct.name.length)
                ct.name.data = data[last:pos]

                if (ct.flags & 1) == 1 {
                    ext: Tileset_External
                    last = pos
                    pos += size_of(DWORD)
                    ext.file_id, _ = endian.get_u32(data[last:pos], .Little)

                    last = pos
                    pos += size_of(DWORD)
                    ext.tileset_id, _ = endian.get_u32(data[last:pos], .Little)

                    ct.external = ext
                }
                if (ct.flags & 2) == 2 {
                    img_set: Tileset_Compressed
                    last = pos
                    pos += size_of(DWORD)
                    img_set.length, _ = endian.get_u32(data[last:pos], .Little)
                    // img_set.data = make_slice([]u8, int(img_set.length), allocator) or_return

                    last = pos
                    pos += int(img_set.length)
                    img_set.tiles = data[last:pos]

                    buf: bytes.Buffer
                    defer bytes.buffer_destroy(&buf)

                    expected_size := int(ct.width) * int(ct.height) * int(ct.num_of_tiles) 
                    com_err := zlib.inflate(data[last:pos], &buf, expected_output_size=expected_size)

                    if com_err != nil {
                        img_set.tiles = data[last:pos]
                        log.errorf("Unable to Uncompressed Tilemap. Writing raw data of %v bytes.", pos-last)
                    } else {
                        //cel.tiles = make_slice([]u8, expected_size, allocator) or_return
                        img_set.tiles = slice.clone(buf.buf[:], allocator) or_return
                        img_set.did_com = true
                    }

                    ct.compressed = img_set
                    
                }
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

@(private="file")
_read_property_value :: proc(old_last, old_pos: int, type: WORD, data: []u8, allocator := context.allocator) -> 
    (value: UD_Property_Value, last, pos: int, err: ASE_Unmarshal_Error) 
{
    last = old_last
    pos = old_pos
    
    switch type {
    case 0x0001, 0x0002, 0x0003:
        last = pos
        pos += size_of(BYTE)
        value = data[last]

    case 0x0004:
        last = pos
        pos += size_of(SHORT)
        value, _ = endian.get_i16(data[last:pos], .Little)

    case 0x0005:
        last = pos
        pos += size_of(WORD)
        value, _ = endian.get_u16(data[last:pos], .Little)

    case 0x0006:
        last = pos
        pos += size_of(LONG)
        value, _ = endian.get_i32(data[last:pos], .Little)

    case 0x0007:
        last = pos
        pos += size_of(DWORD)
        value, _ = endian.get_u32(data[last:pos], .Little)

    case 0x0008:
        last = pos
        pos += size_of(LONG64)
        value, _ = endian.get_i64(data[last:pos], .Little)

    case 0x0009:
        last = pos
        pos += size_of(QWORD)
        value, _ = endian.get_u64(data[last:pos], .Little)

    case 0x000A:
        last = pos
        pos += size_of(FIXED)
        t, _ := endian.get_i32(data[last:pos], .Little)
        value = FIXED(t)

    case 0x000B:
        last = pos
        pos += size_of(FLOAT)
        value, _ = endian.get_f32(data[last:pos], .Little)

    case 0x000C:
        last = pos
        pos += size_of(DOUBLE)
        value, _ = endian.get_f64(data[last:pos], .Little)

    case 0x000D:
        st: STRING
        last = pos
        pos += size_of(WORD)
        st.length, _ = endian.get_u16(data[last:pos], .Little)

        last = pos
        pos += int(st.length)
        st.data = data[last:pos]

        value = st

    case 0x000E:
        pt: POINT
        last = pos
        pos += size_of(LONG)
        pt.x, _ = endian.get_i32(data[last:pos], .Little)

        last = pos
        pos += size_of(LONG)
        pt.y, _ = endian.get_i32(data[last:pos], .Little)

        value = pt

    case 0x000F:
        st: SIZE
        last = pos
        pos += size_of(LONG)
        st.w, _ = endian.get_i32(data[last:pos], .Little)

        last = pos
        pos += size_of(LONG)
        st.h, _ = endian.get_i32(data[last:pos], .Little)

        value = st

    case 0x0010:
        rt: RECT
        last = pos
        pos += size_of(LONG)
        rt.origin.x, _ = endian.get_i32(data[last:pos], .Little)

        last = pos
        pos += size_of(LONG)
        rt.origin.y, _ = endian.get_i32(data[last:pos], .Little)

        last = pos
        pos += size_of(LONG)
        rt.size.w, _ = endian.get_i32(data[last:pos], .Little)

        last = pos
        pos += size_of(LONG)
        rt.size.h, _ = endian.get_i32(data[last:pos], .Little)

        value = rt

    case 0x0011:
        vect: UD_Vec
        last = pos
        pos += size_of(DWORD)
        vect.num, _ = endian.get_u32(data[last:pos], .Little)

        last = pos
        pos += size_of(WORD)
        vect.type, _ = endian.get_u16(data[last:pos], .Little)

        if vect.type == 0 {
            dt := make_slice([]Vec_Diff, int(vect.num), allocator) or_return

            for n in 0..<int(vect.num) {
                last = pos
                pos += size_of(WORD)
                dt[n].type, _ = endian.get_u16(data[last:pos], .Little)

                dt[n].data, last, pos = _read_property_value(last, pos, dt[n].type, data[:], allocator) or_return
            }

            vect.data = dt            

        } else {
            dt := make_slice([]UD_Property_Value, int(vect.num), allocator) or_return

            for n in 0..<int(vect.num) {
                dt[n], last, pos = _read_property_value(last, pos, vect.type, data[:], allocator) or_return
            }

            vect.data = dt  
        }

        value = vect

    case 0x0012:
        pmt: UD_Properties_Map
        last = pos
        pos += size_of(DWORD)
        pmt.num, _ = endian.get_u32(data[last:pos], .Little)
        pmt.properties = make_slice([]UD_Property, int(pmt.num), allocator) or_return

        for n in 0..<int(pmt.num) {
            last = pos
            pos += size_of(WORD)
            pmt.properties[n].name.length, _ = endian.get_u16(data[last:pos], .Little)

            last = pos
            pos += int(pmt.properties[n].name.length)
            pmt.properties[n].name.data = data[last:pos]

            last = pos
            pos += size_of(WORD)
            pmt.properties[n].type, _ = endian.get_u16(data[last:pos], .Little)

            pmt.properties[n].data, last, pos = _read_property_value(last, pos, pmt.properties[n].type, data[:]) or_return
        }

        value = pmt

    case 0x0013:
        last = pos
        pos += size_of(UUID)
        value = transmute(UUID)data[last:pos]

    case:
        log.errorf("Unable to continue. Unkown User Data Property Type of %v found at: %v-%v", type, last, pos)
        err = .Bad_User_Data_Type
        return
    }
    return
}

@(private="file")
_read_ud_map :: proc(old_last, old_pos: int, data: []u8, allocator := context.allocator) -> 
    (p_map: UD_Properties_Map, last, pos: int, err: ASE_Unmarshal_Error) 
{   
    last = old_last
    pos = old_pos

    last = pos
    pos += size_of(DWORD)
    p_map.key, _ = endian.get_u32(data[last:pos], .Little)

    last = pos
    pos += size_of(DWORD)
    p_map.num, _ = endian.get_u32(data[last:pos], .Little)
    p_map.properties = make_slice([]UD_Property, int(p_map.num), allocator) or_return

    for p in 0..<int(p_map.num) {
        last = pos
        pos += size_of(WORD)
        p_map.properties[p].name.length, _ = endian.get_u16(data[last:pos], .Little)

        last = pos
        pos += int(p_map.properties[p].name.length)
        p_map.properties[p].name.data = data[last:pos]

        last = pos
        pos += size_of(WORD)
        p_map.properties[p].type, _ = endian.get_u16(data[last:pos], .Little)

        p_map.properties[p].data, last, pos = _read_property_value(last, pos, p_map.properties[p].type, data[:], allocator) or_return
    }

    return
}
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
import "core:compress/gzip"
import "core:bytes"
import vzlib "vendor:zlib"


// The size of buf is expectd to be greater than or
// equal to `doc.header.file_size`
//
// pos: Size fo buf writen to buf
ase_marshal :: proc(buf: []byte, doc: ^ASE_Document, update := true, allocator := context.allocator) -> (pos: int, err: ASE_Marshal_Error) {
    if update { update_doc(doc) }
    if len(buf) < int(doc.header.size) { return 0, .Buffer_Not_Big_Enough }

    next := size_of(DWORD)
    endian.put_u32(buf[pos:next], .Little, doc.header.size)

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.magic) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.frames) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.width) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.height) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.color_depth) 

    pos = next
    next += size_of(DWORD)
    endian.put_u32(buf[pos:next], .Little, doc.header.flags) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.speed) 

    pos = next
    next += size_of(DWORD)
    pos = next
    next += size_of(DWORD)

    pos = next
    next += size_of(BYTE)
    buf[pos] = doc.header.transparent_index

    pos = next
    next += size_of(BYTE) * 3

    pos =  next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.num_of_colors) 

    pos = next
    next += size_of(BYTE)
    buf[pos] = doc.header.ratio_width

    pos = next
    next += size_of(BYTE)
    buf[pos] = doc.header.ratio_height

    pos = next
    next += size_of(SHORT)
    endian.put_i16(buf[pos:next], .Little, doc.header.x) 

    pos = next
    next += size_of(SHORT)
    endian.put_i16(buf[pos:next], .Little, doc.header.y) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.grid_width) 

    pos = next
    next += size_of(WORD)
    endian.put_u16(buf[pos:next], .Little, doc.header.grid_height) 

    pos = next
    next += size_of(BYTE)*84

    for frame in doc.frames {
        pos = next
        next += size_of(DWORD)
        endian.put_u32(buf[pos:next], .Little, frame.header.size)

        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, frame.header.magic)

        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, frame.header.old_num_of_chunks)

        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, frame.header.duration)

        pos = next
        next += size_of(BYTE) * 2

        pos = next
        next += size_of(DWORD)
        endian.put_u32(buf[pos:next], .Little, frame.header.num_of_chunks)

        for chunk in frame.chunks {
            t_next := next
            pos = next
            next += size_of(DWORD)
            endian.put_u32(buf[pos:next], .Little, chunk.size)

            pos = next
            next += size_of(WORD)
            endian.put_u16(buf[pos:next], .Little, WORD(chunk.type))
            
            switch value in chunk.data {
            case Old_Palette_256_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.size)

                for p in value.packets { // TODO: Rework to support skips??
                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = p.entries_to_skip

                    pos = next
                    next += size_of(BYTE)
                    if len(p.colors) == 256 {
                        buf[pos] = 0
                    } else {
                        buf[pos] = p.num_colors
                    }

                    for c in p.colors{
                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[2]

                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[1]

                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[0]
                    }
                }
            case Old_Palette_64_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.size)
                
                for p in value.packets {
                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = p.entries_to_skip

                    pos = next
                    next += size_of(BYTE)
                    
                    if len(p.colors) == 256 {
                        buf[pos] = 0
                    } else {
                        buf[pos] = p.num_colors
                    }

                    for c in p.colors{ // TODO: Rework to support skips??
                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[2]

                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[1]

                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = c[0]
                    }
                }
            case Layer_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.flags)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.type)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.child_level)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.default_width)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.default_height)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.blend_mode)

                pos = next
                next += size_of(BYTE)*3

                if (doc.header.flags & 1) == 1 {
                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = value.opacity
                }

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.name.length)

                pos = next
                next += int(value.name.length)
                copy_slice(buf[pos:next], value.name.data[:])

                if value.type == 2 {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.tileset_index)
                }

            case Cel_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.layer_index)

                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.x)

                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.y)

                pos = next
                next += size_of(BYTE)
                buf[pos] = value.opacity_level

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.type)

                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.z_index)

                pos = next
                next += size_of(BYTE)*5

                switch cel in value.cel {
                case Raw_Cel:
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.width)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.height)

                    // TODO: Need to be actule pixel not u8, maybe?
                    for px in cel.pixel {
                        pos = next
                        next += size_of(BYTE)
                        buf[pos] = px
                    }

                case Linked_Cel:
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, u16(cel))

                case Com_Image_Cel:
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.width)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.height)

                    if cel.did_com {
                        pos = next
                        next = t_next + int(chunk.size)

                        com_buf := make_slice([]byte, len(cel.pixel), allocator) or_return
                        defer delete(com_buf)
                        data_rd: [^]u8 = raw_data(cel.pixel[:])

                        com_buf_rd: [^]u8 = raw_data(com_buf[:])

                        config := vzlib.z_stream{
                            avail_in=vzlib.uInt(len(cel.pixel)), 
                            next_in=&data_rd[0],
                            avail_out=vzlib.uInt(len(cel.pixel)),
                            next_out=&com_buf_rd[0],
                        }

                        vzlib.deflateInit(&config, vzlib.BEST_COMPRESSION)
                        vzlib.deflate(&config, vzlib.FINISH)
                        vzlib.deflateEnd(&config)

                        copy_slice(buf[pos:next], com_buf[:])

                    } else {
                        pos = next
                        next += len(cel.pixel) 
                        copy_slice(buf[pos:next], cel.pixel[:])

                    }

                case Com_Tilemap_Cel:
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.width)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.height)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, cel.bits_per_tile)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, cel.bitmask_id)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, cel.bitmask_x)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, cel.bitmask_y)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, cel.bitmask_diagonal)

                    pos = next
                    next += size_of(BYTE)*10

                    if cel.did_com {
                        pos = next
                        next = t_next + int(chunk.size)

                        com_buf := make_slice([]byte, len(cel.tiles), allocator) or_return
                        defer delete(com_buf)
                        data_rd: [^]u8 = raw_data(cel.tiles[:])

                        com_buf_rd: [^]u8 = raw_data(com_buf[:])

                        config := vzlib.z_stream{
                            avail_in=vzlib.uInt(len(cel.tiles)), 
                            next_in=&data_rd[0],
                            avail_out=vzlib.uInt(len(cel.tiles)),
                            next_out=&com_buf_rd[0],
                        }

                        vzlib.deflateInit(&config, vzlib.BEST_COMPRESSION)
                        vzlib.deflate(&config, vzlib.FINISH)
                        vzlib.deflateEnd(&config)

                        copy_slice(buf[pos:next], com_buf[:])

                    } else {
                        pos = next
                        next += len(cel.tiles) 
                        copy_slice(buf[pos:next], cel.tiles[:])

                    }
                }

            case Cel_Extra_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.flags)

                pos = next
                next += size_of(FIXED)
                endian.put_i32(buf[pos:next], .Little, i32(value.x))
                
                pos = next
                next += size_of(FIXED)
                endian.put_i32(buf[pos:next], .Little, i32(value.y))
                
                pos = next
                next += size_of(FIXED)
                endian.put_i32(buf[pos:next], .Little, i32(value.width))
                
                pos = next
                next += size_of(FIXED)
                endian.put_i32(buf[pos:next], .Little, i32(value.height))

                pos = next
                next += size_of(BYTE)*16

            case Color_Profile_Chunk: 
                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.type)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.flags)

                pos = next
                next += size_of(FIXED)
                endian.put_i32(buf[pos:next], .Little, i32(value.fixed_gamma))

                pos = next
                next += size_of(BYTE)*8

                if value.type == 2 {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.icc.length)

                    pos = next
                    next += int(value.icc.length)
                    copy(buf[pos:next], value.icc.data[:])
                }

            case External_Files_Chunk: 
                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.length)

                pos = next
                next += size_of(BYTE) * 8

                for file in value.entries {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, file.id)

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = file.type

                    pos = next
                    next += size_of(BYTE) * 7

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, file.file_name_or_id.length)

                    pos = next
                    next += int(file.file_name_or_id.length)
                    copy(buf[pos:next], file.file_name_or_id.data[:])
                }

            case Mask_Chunk: 
                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.x)

                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.y)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.width)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.height)

                pos = next
                next += size_of(BYTE)*8

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.name.length)

                pos = next
                next += len(value.name.data)
                copy(buf[pos:next], value.name.data[:])

                pos = next
                next += len(value.bit_map_data)
                copy(buf[pos:next], value.bit_map_data[:])

            case Path_Chunk: 
                // Never implemented

            case Tags_Chunk: 
                pos = next
                next += size_of(WORD)
                 endian.put_u16(buf[pos:next], .Little, value.number)

                pos = next
                next += size_of(BYTE) * 8

                for tag in value.tags {
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, tag.from_frame)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, tag.to_frame)

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = tag.loop_direction

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, tag.repeat)

                    pos = next
                    next += size_of(BYTE) * 6

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = tag.tag_color[2]

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = tag.tag_color[1]

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = tag.tag_color[0]

                    pos = next
                    next += size_of(BYTE)

                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, tag.name.length)

                    pos = next
                    next += len(tag.name.data)
                    copy(buf[pos:next], tag.name.data[:])
                }

            case Palette_Chunk: 
                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.size)

                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.first_index)

                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.last_index)

                pos = next
                next += size_of(BYTE) * 8

                for entry in value.entries {
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, entry.flags)

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = entry.red

                    pos = next
                    next += size_of(BYTE)
                    buf[pos]= entry.green

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = entry.blue

                    pos = next
                    next += size_of(BYTE)
                    buf[pos]= entry.alpha

                    if (entry.flags & 1) == 1 {
                        pos = next
                        next += size_of(WORD)
                        endian.put_u16(buf[pos:next], .Little, entry.name.length)

                        pos = next
                        next += len(entry.name.data)
                        copy(buf[pos:next], entry.name.data[:])
                    }
                    
                }

            case User_Data_Chunk: 
                pos = next
                next += size_of(DWORD)
                ct: User_Data_Chunk
                endian.put_u32(buf[pos:next], .Little, value.flags)

                if (value.flags & 1) == 1 {
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little,  value.text.length)

                    pos = next
                    next += len(value.text.data)
                    copy(buf[pos:next], value.text.data[:])
                }
                
                if (value.flags & 2) == 2 {
                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = value.color[3]

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = value.color[2]

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = value.color[1]

                    pos = next
                    next += size_of(BYTE)
                    buf[pos] = value.color[0]
                }
                
                if (value.flags & 4) == 4 {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.properties.size)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.properties.num)

                    for prop in value.properties.properties_map {
                        pos, next = _write_ud_map(prop, pos, next, buf[:])
                    }

                    pos = next
                    next += int(value.properties.size)
                }
            case Slice_Chunk: 
                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.num_of_keys)

                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.flags)

                pos = next
                next += size_of(DWORD)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.name.length)

                pos = next
                next += len(value.name.data)
                copy(buf[pos:next], value.name.data[:])

                for key in value.data{
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, key.frame_num)

                    pos = next
                    next += size_of(LONG)
                    endian.put_i32(buf[pos:next], .Little, key.x)

                    pos = next
                    next += size_of(LONG)
                    endian.put_i32(buf[pos:next], .Little, key.y)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, key.width)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, key.height)
                    
                    if (value.flags & 1) == 1 {
                        pos = next
                        next += size_of(LONG)
                        endian.put_i32(buf[pos:next], .Little, key.center.x)

                        pos = next
                        next += size_of(LONG)
                        endian.put_i32(buf[pos:next], .Little, key.center.y)

                        pos = next
                        next += size_of(DWORD)
                        endian.put_u32(buf[pos:next], .Little, key.center.width)

                        pos = next
                        next += size_of(DWORD)
                        endian.put_u32(buf[pos:next], .Little, key.center.height)
                    }

                    if (value.flags & 2) == 2 {
                        pos = next
                        next += size_of(LONG)
                        endian.put_i32(buf[pos:next], .Little, key.pivot.x)

                        pos = next
                        next += size_of(LONG)
                        endian.put_i32(buf[pos:next], .Little, key.pivot.y)
                    }

                }

            case Tileset_Chunk: 
                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.id)

                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.flags)

                pos = next
                next += size_of(DWORD)
                endian.put_u32(buf[pos:next], .Little, value.num_of_tiles)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.width)

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.height)

                pos = next
                next += size_of(SHORT)
                endian.put_i16(buf[pos:next], .Little, value.base_index)

                pos = next
                next += size_of(BYTE) * 14

                pos = next
                next += size_of(WORD)
                endian.put_u16(buf[pos:next], .Little, value.name.length)

                pos = next
                next += len(value.name.data)
                copy(buf[pos:next], value.name.data[:])

                if (value.flags & 1) == 1 {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.external.file_id)

                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.external.file_id)
                }
                if (value.flags & 2) == 2 {
                    pos = next
                    next += size_of(DWORD)
                    endian.put_u32(buf[pos:next], .Little, value.compressed.length)

                    if value.compressed.did_com {
                        pos = next
                        next = t_next + int(chunk.size)

                        com_buf := make_slice([]byte, len(value.compressed.tiles), allocator) or_return
                        defer delete(com_buf)
                        data_rd: [^]u8 = raw_data(value.compressed.tiles[:])

                        com_buf_rd: [^]u8 = raw_data(com_buf[:])

                        config := vzlib.z_stream{
                            avail_in=vzlib.uInt(len(value.compressed.tiles)), 
                            next_in=&data_rd[0],
                            avail_out=vzlib.uInt(len(value.compressed.tiles)),
                            next_out=&com_buf_rd[0],
                        }

                        vzlib.deflateInit(&config, vzlib.BEST_COMPRESSION)
                        vzlib.deflate(&config, vzlib.FINISH)
                        vzlib.deflateEnd(&config)

                        copy_slice(buf[pos:next], com_buf[:])

                    } else {
                        pos = next
                        next += len(value.compressed.tiles) 
                        copy_slice(buf[pos:next], value.compressed.tiles[:])

                    }   
                }

            case:
                err = ASE_Marshal_Errors.Invalid_Chunk_Type
                return
            }
            pos = next
            next = t_next + int(chunk.size)
        }
    }
    return
}

@(private="file")
_write_property_value :: proc(prop: UD_Property_Value, old_pos, old_next: int, buf: []u8) -> 
    (pos, next: int) 
{
    pos = old_pos
    next = old_next
    
    switch pt in prop {
    case BYTE:
        pos = next
        next += size_of(BYTE)
        buf[pos] = pt

    case SHORT:
        pos = next
        next += size_of(SHORT)
        endian.put_i16(buf[pos:next], .Little, pt)

    case WORD:
        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, pt)

    case LONG:
        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt)

    case DWORD:
        pos = next
        next += size_of(DWORD)
        endian.put_u32(buf[pos:next], .Little, pt)

    case LONG64:
        pos = next
        next += size_of(LONG64)
        endian.put_i64(buf[pos:next], .Little, pt)

    case QWORD:
        pos = next
        next += size_of(QWORD)
        endian.put_u64(buf[pos:next], .Little, pt)

    case FIXED:
        pos = next
        next += size_of(FIXED)
        endian.put_i32(buf[pos:next], .Little, i32(pt))

    case FLOAT:
        pos = next
        next += size_of(FLOAT)
        endian.put_f32(buf[pos:next], .Little, pt)

    case DOUBLE:
        pos = next
        next += size_of(DOUBLE)
        endian.put_f64(buf[pos:next], .Little, pt)

    case STRING:
        st: STRING
        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, pt.length)

        pos = next
        next += len(pt.data)
        copy(buf[pos:next], pt.data[:])

    case POINT:
        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.x)

        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.y)

    case SIZE:
        st: SIZE
        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.w)

        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.h)

    case RECT:
        rt: RECT
        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.origin.x)

        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.origin.y)

        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.size.w)

        pos = next
        next += size_of(LONG)
        endian.put_i32(buf[pos:next], .Little, pt.size.h)

    case UD_Vec:
        vect: UD_Vec
        pos = next
        next += size_of(DWORD)
        endian.put_u32(buf[pos:next], .Little, pt.num)

        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, pt.type)

        switch vt in pt.data {
            case []Vec_Diff:
                for diff in vt {
                    pos = next
                    next += size_of(WORD)
                    endian.put_u16(buf[pos:next], .Little, diff.type)

                    pos, next = _write_property_value(diff.data, pos, next, buf[:])
                }

            case []UD_Property_Value:
                for diff in vt {
                    pos, next = _write_property_value(diff, pos, next, buf[:])
                }
        }

    case UD_Properties_Map:
        pos = next
        next += size_of(DWORD)
        endian.put_u32(buf[pos:next], .Little, pt.num)

        for n in pt.properties {
            pos = next
            next += size_of(WORD)
            endian.put_u16(buf[pos:next], .Little, n.name.length)

            pos = next
            next += len(n.name.data)
            copy(buf[pos:next], n.name.data[:])

            pos = next
            next += size_of(WORD)
            endian.put_u16(buf[pos:next], .Little, n.type)

            pos, next = _write_property_value(n.data, pos, next, buf[:])
        }

    case UUID:
        pos = next
        next += len(pt)
        copy_slice(buf[pos:next], (transmute([]u8)pt)[:])
    }
    return
}

@(private="file")
_write_ud_map :: proc(pm: UD_Properties_Map, old_pos, old_next: int, buf: []u8) -> 
    (pos, next: int) 
{   
    pos = old_pos
    next = old_next

    pos = next
    next += size_of(DWORD)
    endian.put_u32(buf[pos:next], .Little, pm.key)

    pos = next
    next += size_of(DWORD)
    endian.put_u32(buf[pos:next], .Little, pm.num)

    for p in pm.properties {
        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, p.name.length)

        pos = next
        next += len(p.name.data)
        copy(buf[pos:next], p.name.data[:])

        pos = next
        next += size_of(WORD)
        endian.put_u16(buf[pos:next], .Little, p.type)

        pos, next = _write_property_value(p.data, pos, next, buf[:])
    }
    return
}
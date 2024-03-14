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


// The size of buf is expectd to be greater than or
// equal to `doc.header.file_size`
//
// pos: Size fo data writen to buf
ase_marshal :: proc(buf: []byte, doc: ASE_Document, allocator := context.allocator) -> (pos: int, err: ASE_Marshal_Error) {
    if len(buf) >= int(doc.header.size) {
        return 0 , .Buffer_Not_Big_Enough
    }
    pos = 0
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
        for chunk in frame.chunks {
            switch value in chunk.data {
                case Old_Palette_256_Chunk: 
                case Old_Palette_64_Chunk: 
                case Layer_Chunk: 
                case Cel_Chunk: 
                case Cel_Extra_Chunk: 
                case Color_Profile_Chunk: 
                case External_Files_Chunk: 
                case Mask_Chunk: 
                case Path_Chunk: 
                case Tags_Chunk: 
                case Palette_Chunk: 
                case User_Data_Chunk: 
                case Slice_Chunk: 
                case Tileset_Chunk:
                case:
                    return pos, .Invalid_Chunk_Type
            }
        }
    }

    return
}
package aseprite_file_handler

import "base:runtime"
import "core:os"
import "core:io"
import "core:fmt"
import "core:bufio"
import "core:bytes"
import "core:slice"
import "core:strings"
import "core:strconv"
import "core:compress/zlib"
import "core:encoding/endian"


write_byte :: proc(w: io.Writer, data: BYTE) -> (size: int, err: Write_Error) { 
    return 1, io.write_byte(w, data)
}

write_word :: proc(w: io.Writer, data: WORD) -> (size: int, err: Write_Error) { 
    buf: [2]byte
    if !endian.put_u16(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 2 {
        err = .Wrong_Write_Size
    }
    return
}

write_short :: proc(w: io.Writer, data: SHORT) -> (size: int, err: Write_Error) {
    buf: [2]byte
    if !endian.put_i16(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 2 {
        err = .Wrong_Write_Size
    }
    return
}

write_dword :: proc(w: io.Writer, data: DWORD) -> (size: int, err: Write_Error) { 
    buf: [4]byte
    if !endian.put_u32(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_long :: proc(w: io.Writer, data: LONG) -> (size: int, err: Write_Error) { 
    buf: [4]byte
    if !endian.put_i32(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_fixed :: proc(w: io.Writer, data: FIXED) -> (size: int, err: Write_Error) { 
    return 4 , nil
}

write_float :: proc(w: io.Writer, data: FLOAT) -> (size: int, err: Write_Error) {
    buf: [4]byte 
    if !endian.put_f32(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 4 {
        err = .Wrong_Write_Size
    }
    return
}

write_double :: proc(w: io.Writer, data: DOUBLE) -> (size: int, err: Write_Error) { 
    buf: [8]byte
    if !endian.put_f64(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_qword :: proc(w: io.Writer, data: QWORD) -> (size: int, err: Write_Error) { 
    buf: [8]byte
    if !endian.put_u64(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_long64 :: proc(w: io.Writer, data: LONG64) -> (size: int, err: Write_Error) {
    buf: [8]byte
    if !endian.put_i64(buf[:], .Little, data) {
        return 0, .Unable_To_Encode_Data
    }

    size = io.write(w, buf[:]) or_return
    if size != 8 {
        err = .Wrong_Write_Size
    }
    return
}

write_string :: proc(w: io.Writer, data: STRING) -> (size: int, err: Write_Error) {
    size = write_word(w, WORD(len(data))) or_return
    if size != 2 {
        return size, .Wrong_Write_Size
    }

    size += write_bytes(w, transmute([]u8)data) or_return
    if size != 2 + len(data) {
        err = .Wrong_Write_Size
    }
    return
}

write_point :: proc(w: io.Writer, data: POINT) -> (size: int, err: Write_Error) { 
    size = write_long(w, data.x) or_return
    if size != 4 {
        return size, .Wrong_Write_Size
    }
    size += write_long(w, data.y) or_return
    if size != 8 {
        return size, .Wrong_Write_Size
    }
    return
}

write_size :: proc(w: io.Writer, data: SIZE) -> (size: int, err: Write_Error) { 
    size = write_long(w, data.w) or_return
    if size != 4 {
        return size, .Wrong_Write_Size
    }
    size += write_long(w, data.h) or_return
    if size != 8 {
        return size, .Wrong_Write_Size
    }
    return
}

write_rect :: proc(w: io.Writer, data: RECT) -> (size: int, err: Write_Error) { 
    write_point(w, data.origin) or_return
    write_size(w, data.size) or_return
    return
}

write_uuid:: proc(w: io.Writer, data: UUID) -> (size: int, err: Write_Error) { 
    data := data
    size = io.write(w, data[:]) or_return
    if size != 16 {
        err = .Wrong_Write_Size
    }
    return
}

write_pixel :: proc(w: io.Writer, data: PIXEL) -> (size: int, err: Write_Error) {
    return write_byte(w, data)
}

write_pixels :: proc(w: io.Writer, data: []PIXEL) -> (size: int, err: Write_Error) {
    return write_bytes(w, data[:])
}

write_tile :: proc(w: io.Writer, data: TILE) -> (size: int, err: Write_Error) { 
    switch v in data {
    case BYTE:
        size, err = write_byte(w, v)
    case WORD:
        size, err = write_word(w, v)
    case DWORD:
        size, err = write_dword(w, v)
    }
    return  
}

write_tiles :: proc(r: io.Writer, data: []TILE) -> (size: int, err: Write_Error) {
    if len(data) == 0 {
        return 0, .Array_To_Small
    }

    for tile in data {
        switch v in tile {
        case BYTE:
            size += write_byte(r, v) or_return
        case WORD:
            size += write_word(r, v) or_return
        case DWORD:
            size += write_dword(r, v) or_return
        }
    }
    return 
}

write_bytes :: proc(w: io.Writer, data: []u8) -> (size: int, err: Write_Error) {
    size = io.write(w, data[:]) or_return
    if size != len(data) {
        err = .Wrong_Write_Size
    }
    return 
}

write :: proc{
    write_byte, write_word, write_short, write_dword, write_long, write_fixed, 
    write_float, write_double, write_qword, write_long64, write_string, 
    write_point, write_size, write_rect, write_uuid, write_tile, write_bytes,
}



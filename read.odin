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

read_byte :: proc(r: io.Reader) -> (data: BYTE, err: io.Error) {
    return io.read_byte(r)
}

read_word :: proc(r: io.Reader) -> (data: WORD, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:2]) or_return
    if n != 2 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_u16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err
}

read_short :: proc(r: io.Reader) -> (data: SHORT, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:2]) or_return
    if n != 2 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_i16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err
}

read_dword :: proc(r: io.Reader) -> (data: DWORD, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:4]) or_return
    if n != 4 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_u32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_long :: proc(r: io.Reader) -> (data: LONG, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:4]) or_return
    if n != 4 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_i32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_fixed :: proc(r: io.Reader) -> (data: FIXED, err: Read_Error) { 
    buf: [8]byte
    return 
}

read_float :: proc(r: io.Reader) -> (data: FLOAT, err: Read_Error) {
    buf: [8]byte 
    n := io.read(r, buf[:4]) or_return
    if n !=42 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_f32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_double :: proc(r: io.Reader) -> (data: DOUBLE, err: Read_Error) {
    buf: [8]byte 
    n := io.read(r, buf[:8]) or_return
    if n != 8 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_f64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_qword :: proc(r: io.Reader) -> (data: QWORD, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:8]) or_return
    if n != 8 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_u64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_long64 :: proc(r: io.Reader) -> (data: LONG64, err: Read_Error) {
    buf: [8]byte
    n := io.read(r, buf[:8]) or_return
    if n != 8 {
        err = .Wrong_Read_Size
        return
    }

    v, ok := endian.get_i64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }

    return v, err 
}

read_string :: proc(r: io.Reader, allocator := context.allocator) -> (data: STRING, err: Read_Error) {
    size := int(read_word(r) or_return)

    buf := make([]byte, size, allocator) or_return
    defer delete(buf)
    n := io.read(r, buf[:]) or_return
    if n != size {
        err = .Wrong_Read_Size
    }

    data = string(buf[:])
    return
}

read_point :: proc(r: io.Reader) -> (data: POINT, err: Read_Error) { 
    data.x = read_long(r) or_return
    data.y = read_long(r) or_return
    return 
}

read_size :: proc(r: io.Reader) -> (data: SIZE, err: Read_Error) {
    data.w = read_long(r) or_return
    data.h = read_long(r) or_return 
    return 
}

read_rect :: proc(r: io.Reader) -> (data: RECT, err: Read_Error) { 
    data.origin = read_point(r) or_return
    data.size = read_size(r) or_return
    return 
}

read_uuid:: proc(r: io.Reader, data: []byte) -> (err: Read_Error) { 
    n := io.read(r, data[:]) or_return
    if n != 16 {
        err = .Wrong_Read_Size
    }
    return 
}

read_pixel :: proc(r: io.Reader) -> (data: PIXEL, err: Read_Error) { 
    return read_byte(r)
}

read_pixels :: proc(r: io.Reader, data: []PIXEL) -> (err: Read_Error) {
    return read_bytes(r, data[:])
}

read_tile :: proc(r: io.Reader, type: Tile_ID) -> (data: TILE, err: Read_Error) { 
    switch type {
    case .byte:
        data, err = read_byte(r)
    case .word:
        data, err = read_word(r)
    case .dword:
        data, err = read_dword(r)
    }
    return 
}

read_tiles :: proc(r: io.Reader, data: []TILE, type: Tile_ID) -> (err: Read_Error) {
    size := len(data)
    if len(data) == 0 {
        return
    }

    switch type {
    case .byte:
        for i in 0..<size {
            data[i] = read_byte(r) or_return
        }
    case .word:
        for i in 0..<size {
            data[i] = read_word(r) or_return
        }
    case .dword:
        for i in 0..<size {
            data[i] = read_dword(r) or_return
        }
    }
    return 
}

read_bytes :: proc(r: io.Reader, data: []byte) -> (err: Read_Error) {
    n := io.read(r, data[:]) or_return
    if n != len(data) {
        err = .Wrong_Read_Size
    }
    return 
}
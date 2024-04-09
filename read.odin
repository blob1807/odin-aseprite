package aseprite_file_handler

import "core:io"
import "core:fmt"
import "core:math/fixed"
import "core:encoding/endian"

read_bool :: proc(r: io.Reader) -> (data: bool, err: Read_Error) {
    return bool(read_byte(r) or_return), nil
}

read_i8 :: proc(r: io.Reader) -> (data: i8, err: Read_Error) {
    return i8(read_byte(r) or_return), nil
}

read_byte :: proc(r: io.Reader) -> (data: BYTE, err: Read_Error) {
    return io.read_byte(r)
}

read_word :: proc(r: io.Reader) -> (data: WORD, err: Read_Error) { 
    buf: [2]byte
    n := io.read(r, buf[:]) or_return
    if n != 2 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err
}

read_short :: proc(r: io.Reader) -> (data: SHORT, err: Read_Error) { 
    buf: [2]byte
    n := io.read(r, buf[:]) or_return
    if n != 2 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_i16(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err
}

read_dword :: proc(r: io.Reader) -> (data: DWORD, err: Read_Error) { 
    buf: [4]byte
    n := io.read(r, buf[:]) or_return
    if n != 4 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }   return v, err 
}

read_long :: proc(r: io.Reader) -> (data: LONG, err: Read_Error) { 
    buf: [4]byte
    n := io.read(r, buf[:]) or_return
    if n != 4 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_i32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_fixed :: proc(r: io.Reader) -> (data: FIXED, err: Read_Error) { 
    buf: [4]byte
    n := io.read(r, buf[:]) or_return
    if n != 4 {
        return data, .Wrong_Read_Size
    }

    v, ok := endian.get_i32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
        return
    }
    data.i = v
    return 
}

read_float :: proc(r: io.Reader) -> (data: FLOAT, err: Read_Error) {
    buf: [4]byte 
    n := io.read(r, buf[:]) or_return
    if n !=42 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_f32(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_double :: proc(r: io.Reader) -> (data: DOUBLE, err: Read_Error) {
    buf: [8]byte 
    n := io.read(r, buf[:]) or_return
    if n != 8 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_f64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_qword :: proc(r: io.Reader) -> (data: QWORD, err: Read_Error) { 
    buf: [8]byte
    n := io.read(r, buf[:]) or_return
    if n != 8 {
        return 0, .Wrong_Read_Size
    }

    v, ok := endian.get_u64(buf[:], .Little)
    if !ok {
        err = .Unable_To_Decode_Data
    }
    return v, err 
}

read_long64 :: proc(r: io.Reader) -> (data: LONG64, err: Read_Error) {
    buf: [8]byte
    n := io.read(r, buf[:]) or_return
    if n != 8 {
        return 0, .Wrong_Read_Size
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

read_uuid:: proc(r: io.Reader, data: UUID) -> (err: Read_Error) { 
    n := io.read(r, cast([]u8)data[:]) or_return
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
        data = read_byte(r) or_return
    case .word:
        data = read_word(r) or_return
    case .dword:
        data = read_dword(r) or_return
    }
    return 
}

read_tiles :: proc(r: io.Reader, data: []TILE, type: Tile_ID) -> (err: Read_Error) {
    size := len(data)
    if len(data) == 0 {
        return
    }
    for i in 0..<size {
        data[i] = read_tile(r, type) or_return
    }
    return 
}

read_bytes :: proc(r: io.Reader, data: []byte) -> (err: Read_Error) {
    n := io.read(r, data[:]) or_return
    if n != len(data) {
        fmt.println(n, len(data))
        err = .Wrong_Read_Size
    }
    return 
}

/*read_skip :: proc(r: io.Reader, set: io.Stream_Mode_Set, to_skip: i64) -> (err: Read_Error) {
    if io.Stream_Mode.Seek in set {
        seeker, ok := io.to_seeker(r)
        if !ok {
            return .Unable_Make_Seeker
        }
        n := io.seek(seeker, to_skip, .Current) or_return
    } else {
        for _ in 0..<to_skip {
            io.read_byte(r) or_return
        }
    }
    return
}*/

read_skip :: proc(r: io.Reader, to_skip: int) -> (err: Read_Error) {
    for _ in 0..<to_skip {
        io.read_byte(r) or_return
    }
    return
}

read_ud_value :: proc(r: io.Reader, type: UD_Property_Type, allocator := context.allocator) -> (val: UD_Property_Value, err: Unmarshal_Error) {
    switch type {
    case .Null:   return nil, nil
    case .Bool:   return read_bool(r)
    case .I8:     return read_i8(r)
    case .U8:     return read_byte(r)
    case .I16:    return read_short(r)
    case .U16:    return read_word(r)
    case .I32:    return read_long(r)
    case .U32:    return read_dword(r)
    case .I64:    return read_long64(r)
    case .U64:    return read_qword(r)
    case .Fixed:  return read_fixed(r)
    case .F32:    return read_float(r)
    case .F64:    return read_double(r)
    case .String: return read_string(r, allocator)
    case .Point:  return read_point(r)
    case .Size:   return read_size(r)
    case .Rect:   return read_rect(r)
    case .UUID:
        val = make(UUID, 16, allocator) or_return
        read_uuid(r, val.(UUID)[:]) or_return

    case .Vector:
        num := int(read_dword(r) or_return)
        val = make(UD_Vec, num, allocator) or_return
        for i in 0..<num {
            type := UD_Property_Type(read_word(r) or_return)
            val.(UD_Vec)[i] = read_ud_value(r, type) or_return
        }

    case .Properties:
        size := int(read_dword(r) or_return)
        // FIXME: Is leaking. Not writing data?
        val = make(UD_Properties, size, allocator) or_return

        #partial switch &v in val {
        case UD_Properties:
            for i in 0..<size {
                key := read_string(r, allocator) or_return
                type := UD_Property_Type(read_word(r) or_return)
                v[key] = read_ud_value(r, type, allocator) or_return
            }
        }
    }
    return
}
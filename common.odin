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


write_byte :: proc(data: BYTE) -> (size: int) { 
    return 1 
}

write_word :: proc(data: WORD) -> (size: int) { 
    return 2 
}

write_short :: proc(data: SHORT) -> (size: int) { 
    return 2 
}

write_dword :: proc(data: DWORD) -> (size: int) { 
    return 4 
}

write_long :: proc(data: LONG) -> (size: int) { 
    return 4 
}

write_fixed :: proc(data: FIXED) -> (size: int) { 
    return 4 
}

write_float :: proc(data: FLOAT) -> (size: int) { 
    return 4 
}

write_double :: proc(data: DOUBLE) -> (size: int) { 
    return 8 
}

write_qword :: proc(data: QWORD) -> (size: int) { 
    return 8 
}

write_long64 :: proc(data: LONG64) -> (size: int) {
    return 8 
}

write_string :: proc(data: STRING) -> (size: int) { 
    return 2 + len(data)
}

write_point :: proc(data: POINT) -> (size: int) { 
    return 16
}

write_size :: proc(data: SIZE) -> (size: int) { 
    return 16
}

write_rect :: proc(data: RECT) -> (size: int) { 
    return 32
}

write_uuid:: proc(data: UUID) -> (size: int) { 
    return 16
}

write_pixel :: write_byte

write_tile :: proc(data: TILE) -> (size: int) { 
    return 
}

write_bytes :: proc(data: []u8) -> (size: int) {
    return len(data)
}

write :: proc{
    write_byte, write_word, write_short, write_dword, write_long, write_fixed, 
    write_float, write_double, write_qword, write_long64, write_string, 
    write_point, write_size, write_rect, write_uuid, write_tile, write_bytes,
}


read_byte :: proc() -> (data: BYTE) { 
    return
}

read_word :: proc() -> (data: WORD) { 
    return
}

read_short :: proc() -> (data: SHORT) { 
    return
}

read_dword :: proc() -> (data: DWORD) { 
    return 
}

read_long :: proc() -> (data: LONG) { 
    return 
}

read_fixed :: proc() -> (data: FIXED) { 
    return 
}

read_float :: proc() -> (data: FLOAT) { 
    return 
}

read_double :: proc() -> (data: DOUBLE) { 
    return 
}

read_qword :: proc() -> (data: QWORD) { 
    return 
}

read_long64 :: proc() -> (data: LONG64) {
    return 
}

read_string :: proc() -> (data: STRING) { 
    return 
}

read_point :: proc() -> (data: POINT) { 
    return 
}

read_size :: proc() -> (data: SIZE) { 
    return 
}

read_rect :: proc() -> (data: RECT) { 
    return 
}

read_uuid:: proc(allocator := context.allocator) -> (data: UUID) { 
    return 
}

read_pixel :: proc() -> (data: PIXEL) { 
    return
}

read_tile :: proc() -> (data: TILE) { 
    return 
}

read_bytes :: proc() -> (data: []u8) {
    return
}
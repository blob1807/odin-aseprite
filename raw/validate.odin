package raw_aseprite_file_handler

import "base:runtime"

Wrong :: struct {
    name: string,
    doc: any,
    data, ref: []u8,
    pos: int,
}

validate :: proc(data, ref: []u8, doc: ^ASE_Document, allocator := context.allocator) -> (wrong: []Wrong, err: runtime.Allocator_Error) {
    buf := make([dynamic]Wrong, allocator) or_return
    defer delete(buf)

    

    if len(buf) > 0 {
        wrong = make([]Wrong, len(buf), allocator) or_return
        copy(wrong[:], buf[:])
    }
    return
}
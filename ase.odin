package aseprite_file_handler

import "base:runtime"
import "base:intrinsics"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:slice"
import "core:unicode/utf8"
import "core:encoding/endian"

// https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md
// https://github.com/alpine-alpaca/asefile
// https://github.com/AristurtleDev/AsepriteDotNet/blob/main/source/AsepriteDotNet/Document/UserData.cs

ASE_Unmarshal_Errors :: enum{}
ASE_Unmarshal_Error :: union #shared_nil {ASE_Unmarshal_Errors, runtime.Allocator_Error}

ase_unmarshal :: proc(data: []byte, doc: ^ASE_Document, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    return
}

// repalse with endian.get_*(data[:], .Little)
decode_into :: proc(data: []u8, $T: typeid) -> (res: T, ok: bool) \
where intrinsics.type_is_numeric(T) #no_bounds_check  #optional_ok {
    if len(data) != size_of(T) {
        return
    }
    for n, p in data {
        res |= T(n) << uint(p*8)
    }
    return res, true
}

// repalse with endian.set_*(n, .Little)
encode_from :: proc(num: $T, buf: []byte) -> (ok: bool) \
where intrinsics.type_is_numeric(T) #no_bounds_check {
    if len(buf) != size_of(T) {
        return
    }
    num := num

    for i in 0..<len(buf) {
        buf[i] = byte(num)
        num >>= 8
    }
    return true
}
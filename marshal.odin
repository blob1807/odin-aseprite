package aseprite_file_handler

import "base:runtime"
import "core:io"
import "core:os"
import "core:bytes"
import "core:slice"
import "core:strings"
import "core:encoding/endian"


marshal_to_bytes_buff :: proc(b: ^bytes.Buffer, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    return marshal(bytes.buffer_to_stream(b), doc)
}

marshal_to_string_builder :: proc(b: ^strings.Builder, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    return marshal(strings.to_writer(b), doc)
}

marshal_to_handle :: proc(h: os.Handle, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    return marshal(os.stream_from_handle(h), doc)
}

marshal_to_slice :: proc(b: []byte, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    buf: bytes.Buffer
    defer bytes.buffer_destroy(&buf)
    marshal(&buf, doc) or_return
    copy(b[:], bytes.buffer_to_bytes(&buf)[:])
    return
}

marshal_to_dynamic :: proc(b: ^[dynamic]byte, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    buf: bytes.Buffer
    defer bytes.buffer_destroy(&buf)
    marshal(&buf, doc) or_return
    append(b, ..buf.buf[:])
    return
}

marshal :: proc{
    marshal_to_bytes_buff, marshal_to_string_builder, marshal_to_slice, 
    marshal_to_handle, marshal_to_dynamic, marshal_to_writer,
}

marshal_to_writer :: proc(w: io.Writer, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) { 
    buf: [8]byte

    return
}
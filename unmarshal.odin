package aseprite_file_handler

import "base:runtime"
import "core:io"
import "core:os"
import "core:bytes"
import "core:slice"
import "core:strings"
import "core:encoding/endian"


unmarshal_from_bytes_buff :: proc(r: ^bytes.Reader, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    return unmarshal(bytes.reader_to_stream(r), doc)
}

unmarshal_from_string_reader :: proc(r: ^strings.Reader, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    rr, _ := io.to_reader(strings.reader_to_stream(r))
    return unmarshal(rr, doc)
}

unmarshal_from_string :: proc(s: string, doc: ^Document, allocator := context.allocator)-> (err: Unmarshal_Error) {
    r: strings.Reader
    return unmarshal(strings.to_reader(&r, s), doc)
}

unmarshal_from_handle :: proc(h: os.Handle, doc: ^Document, allocator := context.allocator) -> (err: Unmarshal_Error) {
    return unmarshal(os.stream_from_handle(h), doc)
}

unmarshal_from_buff :: proc(b: []byte, doc: ^Document, allocator := context.allocator) -> (err: Unmarshal_Error) {
    r: bytes.Reader
    bytes.reader_init(&r, b[:])
    return unmarshal(&r, doc)
}

unmarshal :: proc{
    unmarshal_from_bytes_buff, unmarshal_from_string_reader, unmarshal_from_string, 
    unmarshal_from_buff, unmarshal_from_handle, unmarshal_from_reader,
}

unmarshal_from_reader :: proc(r: io.Reader, doc: ^Document, allocator := context.allocator) -> (err: Unmarshal_Error) {
    buf: [8]byte
    return
}

package example

import "core:io"
import "core:os"
import "core:log"
import "core:fmt"
import "core:slice"
import "core:bytes"

import ase ".."

main :: proc() {
    logger := log.create_console_logger()
    defer log.destroy_console_logger(logger)
    context.logger = logger

    ase_example()
}

ase_example :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    read, un_err := ase.unmarshal(data[:], &doc)
    if read != int(doc.header.size) {
        fmt.eprintln("Failed to Unmarshal my beloved, geralt.", read, doc.header.size)
    }
    if un_err != nil {
        fmt.eprintln("Failed to Unmarshal my beloved, geralt.", un_err)
        return
    }

    fmt.println("Successfully Unmarshaled my beloved, geralt.")

    buf: [dynamic]byte
    defer delete(buf)

    written, m_err := ase.marshal(&buf, &doc)
    if m_err != nil {
        fmt.eprintln("Failed to Marshal my beloved, geralt.", m_err)
        return
    }

    fmt.println("Successfully Marshaled my beloved, geralt.")

    sus := os.write_entire_file("./out.aseprite", buf[:])
    if !sus {
        fmt.eprintln("Failed to Write my beloved, geralt.")
        return
    }
    
    fmt.println("Successfully Wrote my beloved, geralt.")
}

read_only :: proc() {
    data := #load("../tests/blob/geralt.aseprite")

    r: bytes.Reader
    bytes.reader_init(&r, data[:])
    ir, ok := io.to_reader(bytes.reader_to_stream(&r))

    c_buf := make([dynamic]ase.Cel_Chunk)
    defer { 
        for c in c_buf { 
            ase.destroy_chunk(c) 
        }
        delete(c_buf)
    }
    _, cerr := ase.unmarshal_chunk(ir, &c_buf)

    cs_buf := make([dynamic]ase.Chunk)
    defer {
        for c in cs_buf {
            #partial switch v in c {
            case ase.Cel_Chunk:       ase.destroy_chunk(v)
            case ase.Cel_Extra_Chunk: ase.destroy_chunk(v)
            case ase.Tileset_Chunk:   ase.destroy_chunk(v)
            }
        }
        delete(cs_buf)
    }
    set := ase.Chunk_Set{.cel, .cel_extra, .tileset}
    _, cserr := ase.unmarshal_chunks(ir, &cs_buf, set)
}
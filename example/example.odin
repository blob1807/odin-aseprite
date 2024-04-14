package example

import "core:os"
import "core:log"
import "core:fmt"
import "core:slice"

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
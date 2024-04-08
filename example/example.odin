package example

import "core:fmt"
import "core:slice"

import ase ".."

main :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    un_err := ase.unmarshal(data[:], &doc)
    if un_err != nil {
        fmt.eprintln("Failed to Unmarshal my beloved, geralt.", un_err)
        return
    }

    fmt.println("Successfully Unmarshaled my beloved, geralt.")

    buf: [dynamic]byte
    defer delete(buf)

    m_err := ase.marshal(&buf, &doc)
    if m_err != nil {
        fmt.eprintln("Failed to Marshal my beloved, geralt.", m_err)
        return
    } 
    if !slice.equal(data[:], buf[:]) {
        fmt.eprintln("My beloved geralt!! WHAT HAVE I DONE!! =(")
        return
    }

    fmt.println("Successfully Marshaled my beloved, geralt.")

}

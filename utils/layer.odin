package aseprite_file_handler_utility

import ase ".."


get_layers :: proc(frame: ase.Frame)  -> (layers: []Layer) {
    lays := make([dynamic]Layer)

    doc_lays := make([dynamic]ase.Layer_Chunk)
    defer delete(doc_lays)
    doc_cel := make([dynamic]ase.Cel_Chunk)
    defer delete(doc_cel)
    doc_ext := make([dynamic]ase.Cel_Extra_Chunk)
    defer delete(doc_ext)

    for chunk in frame.chunks {
        #partial switch v in chunk {
        case ase.Layer_Chunk:
            append(&doc_lays, v)
        case ase.Cel_Chunk:
            append(&doc_cel, v)
        case ase.Cel_Extra_Chunk:
            append(&doc_ext, v)
        }
    }

    return lays[:]
}
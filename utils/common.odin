package aseprite_file_handler_utility

import ase ".."

metadata_from_doc :: proc(doc: ^ase.Document) -> (md: Metadata) {
    return {
        int(doc.header.width), 
        int(doc.header.height), 
        int(doc.header.color_depth),
    }
}
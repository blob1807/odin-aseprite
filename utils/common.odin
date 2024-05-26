package aseprite_file_handler_utility

import "core:fmt"
import ase ".."

get_metadata :: metadata_from_doc
metadata_from_doc :: proc(doc: ^ase.Document) -> (md: Metadata) {
    return {
        int(doc.header.width), 
        int(doc.header.height), 
        Color_Depth(doc.header.color_depth),
    }
}
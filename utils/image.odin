package aseprite_file_handler_utility

import "base:runtime"
import "core:image"

import ase ".."

// TODO: Should read in External Files when needed

// Only Uses the first frame
image_from_doc :: proc(doc: ^ase.Document) {
    md := metadata_from_doc(doc)
    raw_frame := frame_from_doc_frame(doc.frames[0], md)
    image_from_frame(raw_frame)
}

image_from_doc_frame :: proc(frame: ase.Frame, metadata: Metadata) {
    raw_frame := frame_from_doc_frame(frame, metadata)
    image_from_frame(raw_frame)
}

image_from_frame :: proc(frame: Frame) {
    image_from_layers(frame.layers, frame.md)
}

get_image :: proc{
    image_from_doc_frame, 
    image_from_frame, 
    image_from_layers, 
}

image_from_layers :: proc(layers: []Layer, metadata: Metadata) {}
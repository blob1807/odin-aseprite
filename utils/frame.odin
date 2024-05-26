package aseprite_file_handler_utility

import "core:fmt"
import ase ".."

// TODO: Should read in External Files when needed

frames_from_doc :: proc(doc: ^ase.Document, frames: ^[dynamic]Frame) {
    md := metadata_from_doc(doc)
    get_frames(doc.frames, md, frames, .Layer_Opacity in doc.header.flags)
    return
}

frames_from_doc_frames :: proc(data: []ase.Frame, metadata: Metadata, frames: ^[dynamic]Frame, layer_valid_opacity := false) {
    for frame in data {
        append(frames, get_frame(frame, metadata, layer_valid_opacity))
    }
    return
}

get_frames :: proc {
    frames_from_doc, 
    frames_from_doc_frames, 
}

get_frame :: frame_from_doc_frame

// TODO: Need destruction & alloctor passing
frame_from_doc_frame :: proc(data: ase.Frame, metadata: Metadata, layer_valid_opacity := false) -> (frame: Frame) {
    frame.md = metadata
    frame.duration = i64(data.header.duration)
    frame.layers = get_layers(data, layer_valid_opacity)

    doc_tag := make([dynamic]ase.Tag)
    defer delete(doc_tag)

    doc_ud := make([dynamic]User_Data)
    defer delete(doc_ud)


    return
}

package aseprite_file_handler_utility

import ase ".."

// TODO: Should read in External Files when needed

frames_from_doc :: proc(doc: ^ase.Document, frames: ^[dynamic]Frame) {
    md := metadata_from_doc(doc)
    for frame in doc.frames {
        append(frames, get_frame(frame, md))
    }
}

frames_from_doc_frames :: proc(data: []ase.Frame, metadata: Metadata, frames: ^[dynamic]Frame) {
    for frame in data {
        append(frames, get_frame(frame, metadata))
    }
    return
}

get_frames :: proc {
    frames_from_doc, 
    frames_from_doc_frames, 
}

get_frame :: frame_from_doc_frame

frame_from_doc_frame :: proc(data: ase.Frame, metadata: Metadata) -> (frame: Frame) {
    frame.md = metadata
    frame.duration = i64(data.header.duration)
    frame.layers = get_layers(data)

    doc_tag := make([dynamic]ase.Tag)
    defer delete(doc_tag)

    doc_ud := make([dynamic]User_Data)
    defer delete(doc_ud)


    return
}
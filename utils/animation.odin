package aseprite_file_handler_utility

import "base:runtime"
import "core:image"
import "core:slice"

import ase ".."

// TODO: ALL Animation procs should respect Tags
// TODO: Allow for the spesicaction of what tag to use

get_animation_from_doc :: proc(doc: ^ase.Document, anim: ^Animation) {
    md := get_metadata(doc)
    frames := get_frames(doc)
    defer destroy_frames(frames)

    layers := get_layers(doc)
    defer delete(layers)

    pal := get_palette(doc)
    defer delete(pal)

    get_animation(frames, layers, md, anim, pal)
    return
}


get_animation_from_frames :: proc(frames: []Frame, layers: []Layer, md: Metadata, anim: ^Animation, pal: Palette = nil) {
    if anim.fps == 0 {
        anim.fps = 30
    }
    anim.md = md
    anim_frames := make([dynamic][]byte)

    for frame in frames {
        img := get_image_bytes_from_frame(frame, layers, md, pal)
        append_elem(&anim_frames, img)
        to_add := f64(frame.duration) / ( 1000 / f64(anim.fps) )
        
        for _ in 1..<to_add {
            append_elem(&anim_frames, slice.clone(img))
        }
    }

    anim.frames = anim_frames[:]
    return
}

// Assumes 30 FPS & 100ms Frame Duration
get_animation_from_images :: proc(imgs: []Image, md: Metadata, anim: ^Animation) {
    anim.fps = 30
    anim.md = md
    frames := make([dynamic][]byte)

    for img in imgs {
        frame := slice.clone(img.data)
        append_elem(&frames, frame)

        frame = slice.clone(img.data)
        append_elem(&frames, frame)

        frame = slice.clone(img.data)
        append_elem(&frames, frame)
    }

    anim.frames = frames[:]
    return
}


get_animation :: proc {
    get_animation_from_doc, 
    get_animation_from_frames, 
    get_animation_from_images, 
}

package aseprite_file_handler_utility

import "core:fmt"
import "core:slice"

import ase ".."


get_metadata :: proc(doc: ^ase.Document) -> (md: Metadata) {
    return {
        int(doc.header.width), 
        int(doc.header.height), 
        Pixel_Depth(doc.header.color_depth),
    }
}


// Use with slice.sort_by, .sort_by_with_indices, .stable_sort_by, .is_sorted_by & .reverse_sort_by
cel_less :: proc(i, j: Cel) -> bool {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    ior := i.layer + i.z_index
    jor := j.layer + j.z_index
    return ior < jor || (ior == jor && i.z_index < j.z_index )
}

// Use with slice.sort_by_cmp, .stable_sort_by_cmp, .is_sorted_cmp & .reverse_sort_by_cmp
cel_cmp :: proc(i, j: Cel) -> slice.Ordering {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    iz, jz := i.z_index, j.z_index
    ior := i.layer + iz
    jor := j.layer + jz

    if ior < jor { return .Less } 
    else if ior > jor { return .Greater} 
    else if iz < jz { return .Less}
    else if iz > jz { return .Greater}
    return .Equal
}


has_new_palette :: proc(doc: ^ase.Document) -> bool {
    for f in doc.frames {
        for c in f.chunks {
            _ = c.(ase.Palette_Chunk) or_continue
            return true
        }
    }
    return false
}


// Linearly resizes an Image.
// Not work as on right now
resize_image :: scale_image

// Linearly scale an Image.
// Not work as on right now
scale_image :: proc(img: []byte, md: Metadata, factor: int = 10) -> (res: []byte) {
    assert(size_of(img) == md.height * md.height * 4)
    res = make([]byte, size_of(img) * factor)

    for y in 0..<md.height {
        for x in 0..<md.width {
            x := (y * md.height + x) * 4
            xi := x * factor
            pix := img[x:x+4]
            copy(img[xi:xi+4], pix)
        }
    }

    return
}


destroy_frames :: proc(frames: []Frame) {
    for frame in frames {
        delete(frame.cels)
    }
    delete(frames)
}

destroy_image :: proc(img: Image) {
    delete(img.data)
}

destroy_animation :: proc(anim: Animation) {
    for frame in anim.frames {
        delete(frame)
    }
    delete(anim.frames)
}

destroy_frame :: delete_slice 
destroy_cels :: delete_slice
destroy_layers :: delete_slice
destroy_palette :: delete_slice

destroy :: proc {
    delete_slice, 
    destroy_frames, 
    destroy_image, 
    destroy_animation, 
}
package aseprite_file_handler_utility

import "core:slice"
import "core:fmt"

import ase ".."

_::fmt


get_metadata :: proc(header: ase.File_Header) -> (md: Metadata) {
    return {
        int(header.width), 
        int(header.height), 
        Pixel_Depth(header.color_depth),
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

    for h in 0..<md.height {
        for w in 0..<md.width {
            x := (h * md.height + w) * 4
            xi := x * factor
            pix := img[x:x+4]
            copy(img[xi:xi+4], pix)
        }
    }

    return
}


destroy_frames :: proc(frames: []Frame, alloc := context.allocator) {
    for frame in frames {
        delete(frame.cels, alloc)
    }
    delete(frames, alloc)
}

destroy_image :: proc(img: ^Image, alloc := context.allocator) {
    delete(img.data, alloc)
}

destroy_images :: proc(imgs: []Image, alloc := context.allocator) {
    for img in imgs {
        delete(img.data, alloc)
    }
    delete(imgs, alloc)
}

destroy_image_bytes :: proc(imgs: [][]byte, alloc := context.allocator) {
    for img in imgs {
        delete(img, alloc)
    }
    delete(imgs, alloc)
}

destroy_animation :: proc(anim: ^Animation, alloc := context.allocator) {
    for frame in anim.frames {
        delete(frame, alloc)
    }
    delete(anim.frames, alloc)
}

destroy_frame :: delete_slice 
destroy_cels :: delete_slice
destroy_layers :: delete_slice
destroy_palette :: delete_slice

destroy :: proc {
    destroy_frames, 
    destroy_image, 
    destroy_animation, 
    destroy_image_bytes, 
    destroy_images,
}

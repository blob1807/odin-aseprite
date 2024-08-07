package aseprite_file_handler_utility

import "base:runtime"
import "core:slice"
import "core:strings"

@(require) import "core:fmt"
@(require) import "core:log"

import ase ".."



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


has_tileset :: proc(doc: ^ase.Document) -> bool {
    for f in doc.frames {
        for c in f.chunks {
            _ = c.(ase.Tileset_Chunk) or_continue
            return true
        }
    }
    return false
}


// Uses Nearest-neighbor Upscaling
upscale_image_from_bytes :: proc(img: []byte, md: Metadata, factor: int = 10, alloc := context.allocator) -> (res: []byte, res_md: Metadata, err: runtime.Allocator_Error) {
    assert(len(img) == (md.height * md.height * 4), "image size doesn't match metadata") // TODO: replace with an error
    res = make([]byte, len(img) * factor * factor) or_return
    res_md = {md.width*factor, md.height*factor, md.bpp}

    for h in 0..<md.height {
        for w in 0..<md.width {
            start := (h*md.width*factor + w) * factor * 4
            first := res[start:start + factor * 4]
            copy(first[:4], img[(h*md.width + w) * 4:])

            for x in 1..<factor {
                copy(res[start + x * 4:], first[:4])
            }
            for y in 1..<factor {
                copy(res[start + (y*md.width*factor*4):], first)
            }
        }
    }

    return
}

// Uses Nearest-neighbor Upscaling
upscale_image_from_img :: proc(img: Image, factor := 10, alloc := context.allocator) -> (res: Image, err: runtime.Allocator_Error) {
    res.data, res.md = upscale_image_from_bytes(img.data, img.md, factor, alloc) or_return
    return
}

// Uses Nearest-neighbor Upscaling
upscale_image :: proc{upscale_image_from_img, upscale_image_from_bytes}



destroy_frame :: proc(frame: Frame, alloc := context.allocator) -> runtime.Allocator_Error {
    for &cel in frame.cels {
        destroy(&cel, alloc) or_return
    }
    return delete(frame.cels, alloc)
}

destroy_frames :: proc(frames: []Frame, alloc := context.allocator) -> runtime.Allocator_Error {
    for frame in frames {
        for &cel in frame.cels {
            destroy(&cel, alloc) or_return
        }
        delete(frame.cels, alloc) or_return
    }
    return delete(frames, alloc)
}

destroy_image :: proc(img: ^Image, alloc := context.allocator) -> runtime.Allocator_Error {
    return delete(img.data, alloc)
}

destroy_images :: proc(imgs: []Image, alloc := context.allocator) -> runtime.Allocator_Error {
    for img in imgs {
        delete(img.data, alloc) or_return
    }
    return delete(imgs, alloc)
}

destroy_image_bytes :: proc(imgs: [][]byte, alloc := context.allocator) -> runtime.Allocator_Error {
    for img in imgs {
        delete(img, alloc) or_return
    }
    return delete(imgs, alloc)
}

destroy_animation :: proc(anim: ^Animation, alloc := context.allocator) -> runtime.Allocator_Error {
    for frame in anim.frames {
        delete(frame, alloc) or_return
    }
    return delete(anim.frames, alloc)
}

destroy_info :: proc(info: ^Info) -> runtime.Allocator_Error {
    context.allocator = info.allocator
    destroy_frames(info.frames) or_return
    delete(info.layers) or_return
    delete(info.palette) or_return
    delete(info.tags) or_return
    return nil
}

destroy_cel :: proc(cel: ^Cel, alloc := context.allocator) -> runtime.Allocator_Error {
    delete(cel.tilemap.tiles, alloc) or_return
    return nil
}

destroy_layers :: delete_slice
destroy_palette :: delete_slice

destroy :: proc {
    destroy_frames, 
    destroy_image, 
    destroy_animation, 
    destroy_image_bytes, 
    destroy_images,
    destroy_info,
    destroy_cel,
    destroy_frame,
    delete_slice,
}

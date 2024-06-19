package aseprite_file_handler_utility

import "core:time"
import "core:slice"
import "core:fmt"

import ase ".."

_::fmt

// TODO: ALL Animation procs should respect Tags
// TODO: Allow for the spesicaction of what tag to use

get_animation_from_doc :: proc(doc: ^ase.Document, anim: ^Animation, alloc := context.allocator) -> (err: Errors) {
    context.allocator = alloc
    md, lays, fras, pal, tags := get_all(doc) or_return
    defer {
        destroy_frames(fras)
        delete(lays)
        delete(pal)
        delete(tags)
    }
    return get_animation(fras, lays, md, anim, tags, pal)
}


get_animation_from_frames :: proc (
    frames: []Frame, layers: []Layer, md: Metadata, 
    anim: ^Animation, tags: []Tag = nil, pal: Palette = nil, 
    alloc := context.allocator
) -> (err: Errors) {
    context.allocator = alloc

    if anim.fps == 0 {
        anim.fps = 30
    }

    anim.md = md
    anim_frames := make([dynamic][]byte) or_return

    for frame in frames {
        img := get_image_bytes_from_frame(frame, layers, md, pal) or_return
        to_add := f64(frame.duration) * f64(anim.fps) / 1000 
        for _ in 0..<to_add {
            append_elem(&anim_frames, slice.clone(img)) or_return
        }
    }

    anim.frames = anim_frames[:]
    anim.length = time.Second * time.Duration(len(anim_frames) / anim.fps)
    return
}

// Assumes 30 FPS & 100ms Frame Duration
get_animation_from_images :: proc(imgs: []Image, md: Metadata, anim: ^Animation, alloc := context.allocator) -> (err: Errors) {
    context.allocator = alloc
    anim.fps = 30
    anim.md = md
    anim.length = time.Second * time.Duration(len(imgs) / 10)
    frames := make([dynamic][]byte, 0, 3 * len(imgs)) or_return

    for img in imgs {
        frame := slice.clone(img.data) or_return
        append_elem(&frames, frame) or_return

        frame = slice.clone(img.data) or_return
        append_elem(&frames, frame) or_return

        frame = slice.clone(img.data) or_return
        append_elem(&frames, frame) or_return
    }

    anim.frames = frames[:]
    return
}


get_animation :: proc {
    get_animation_from_doc, 
    get_animation_from_frames, 
    get_animation_from_images, 
}


// Returns a new image set with Red/Blue Tint or Merge Onion Skin
apply_onion_skin :: proc(
    imgs: []Image, opacity := 69, merge := false, 
    alloc := context.allocator
) -> (frames: []Image, err: Errors) {
    context.allocator = alloc

    frames = make([]Image, len(imgs)) or_return
    blank := make([]byte, len(imgs[0].data)) or_return
    defer delete(blank)
    
    cur, next: []byte
    last := blank
    defer if cur != nil do delete(cur)

    for img, pos in imgs {
        if pos < len(imgs)-1 {
            next = imgs[pos+1].data
        } else {
            next = blank
        }

        cur = slice.clone(img.data) or_return
        if merge {
            blend_bytes(last, cur, opacity, .Merge) or_return
            blend_bytes(next, cur, opacity, .Merge) or_return
        } else {
            blend_bytes(last, cur, opacity, .Red_Tint) or_return
            blend_bytes(next, cur, opacity, .Blue_Tint) or_return
        }
        

        frames[pos] = img
        frames[pos].data = cur
        last = cur
    }

    return
}

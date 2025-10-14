package aseprite_file_handler_utility


import "core:time"
import "core:slice"

@(require) import "core:fmt"
@(require) import "core:log"

import ase ".."

get_animation_from_doc :: proc(
    doc: ^ase.Document, anim: ^Animation, 
    use_tag := "", alloc := context.allocator
) -> (err: Errors) {
    info: Info 
    get_info(doc, &info, alloc) or_return
    defer destroy(&info)
    return get_animation_from_info(info, anim, use_tag)
}


get_animation_from_info :: proc (
    info: Info, anim: ^Animation, use_tag := "",
) -> (err: Errors) {
    context.allocator = info.allocator

    s, f := 0, len(info.frames)
    tag: Tag
    
    if use_tag != "" {
        for t in info.tags {
            if t.name == use_tag {
                if len(info.frames) < t.to || len(info.frames) < t.from {
                    return Animation_Error.Tag_Index_Out_Of_Bounds
                }
                tag = t
                s = t.from
                f = t.to+1
                break
            }
        }

        if tag == {} {
            return Animation_Error.Tag_Not_Found
        }
    }

    if anim.fps == 0 {
        anim.fps = 30
    }

    anim.md = info.md
    anim_frames := make([dynamic][]byte) or_return
    defer if err != nil { delete(anim_frames) }

    pos: int

    for frame in info.frames[s:f] {
        img := get_image_bytes_from_frame(frame, info) or_return
        defer delete(img)

        to_add := f64(frame.duration) * f64(anim.fps) / 1000 
        for _ in 0..<to_add {
            append_elem(&anim_frames, slice.clone(img) or_return) or_return
            pos += 1
        }
    }

    if tag.direction == .Reverse || tag.direction == .Ping_Pong_Reverse {
        slice.reverse(anim_frames[:])
    }

    if tag.direction == .Ping_Pong || tag.direction == .Ping_Pong_Reverse {
        rev := slice.clone(anim_frames[:])
        defer delete(rev)
        
        slice.reverse(rev)
        append_elems(&anim_frames, ..rev) or_return
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
    defer if err != nil { delete(frames) }

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

// Assumes 30 FPS & 100ms Frame Duration
get_animation_from_bytes :: proc(imgs: [][]byte, md: Metadata, anim: ^Animation, alloc := context.allocator) -> (err: Errors) {
    context.allocator = alloc
    anim.fps = 30
    anim.md = md
    anim.length = time.Second * time.Duration(len(imgs) / 10)

    frames := make([dynamic][]byte, 0, 3 * len(imgs)) or_return
    defer if err != nil { delete(frames) }

    for img in imgs {
        append_elem(&frames, slice.clone(img) or_return) or_return
        append_elem(&frames, slice.clone(img) or_return) or_return
        append_elem(&frames, slice.clone(img) or_return) or_return
    }

    anim.frames = frames[:]
    return
}


get_animation :: proc {
    get_animation_from_doc, 
    get_animation_from_info, 
    get_animation_from_images, 
    get_animation_from_bytes, 
}


// Returns a new image set with Red/Blue Tint or Merge Onion Skin
apply_onion_skin :: proc(
    imgs: []Image, opacity := 69, merge := false, 
    alloc := context.allocator
) -> (frames: []Image, err: Errors) {
    context.allocator = alloc

    frames = make([]Image, len(imgs)) or_return
    defer if err != nil { delete(frames) }
    
    blank := make([]byte, len(imgs[0].data)) or_return
    defer delete(blank)
    
    cur, next: []byte
    last := blank
    defer if cur != nil { delete(cur) }

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

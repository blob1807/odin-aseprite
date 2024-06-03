package aseprite_file_handler_utility

import "core:slice"
import "core:fmt"

import ase ".."

cels_from_doc :: proc(doc: ^ase.Document) -> (res: []Cel) {
    cels := make([dynamic]Cel)

    for frame in doc.frames {
        f_cels := get_cels(frame)
        append(&cels, ..f_cels)
        delete(f_cels)
    }

    return cels[:]
}

cels_from_doc_frame :: proc(frame: ase.Frame) -> (res: []Cel) {
    cels := make([dynamic]Cel)

    for chunk in frame.chunks {
        #partial switch c in chunk {
        case ase.Cel_Chunk:
            cel := Cel {
                pos = {int(c.x), int(c.y)},
                opacity = int(c.opacity_level),
                z_index = int(c.z_index),
                layer = int(c.layer_index)
            }
    
            switch v in c.cel {
            case ase.Com_Image_Cel:
                cel.width = int(v.width)
                cel.height = int(v.height)
                cel.raw = v.pixel
            case ase.Raw_Cel:
                cel.width = int(v.width)
                cel.height = int(v.height)
                cel.raw = v.pixel
            case ase.Com_Tilemap_Cel:
            case ase.Linked_Cel:
                cel.link = int(v)
            }
            append(&cels, cel)
        }
    }

    return cels[:]
}

get_cels :: proc{cels_from_doc_frame, cels_from_doc}


layers_from_doc :: proc(doc: ^ase.Document) -> (res: []Layer) {
    layers := make([dynamic]Layer)

    for frame in doc.frames {
        f_lays := get_layers(frame, .Layer_Opacity in doc.header.flags)
        append(&layers, ..f_lays)
        delete(f_lays)
    }

    return layers[:]
}

layers_from_doc_frame :: proc(frame: ase.Frame, layer_valid_opacity := false) -> (res: []Layer) {
    layers := make([dynamic]Layer)

    for chunk in frame.chunks {
        #partial switch v in chunk {
        case ase.Layer_Chunk:
            lay := Layer {
                name = v.name, 
                opacity = int(v.opacity) if layer_valid_opacity else 255,
                index = len(layers),
                blend_mode = Blend_Mode(v.blend_mode),
                visiable = .Visiable in v.flags
            }
            append(&layers, lay)
        }
    }

    return layers[:]
}

get_layers :: proc{layers_from_doc_frame, layers_from_doc}


tags_from_doc :: proc(doc: ^ase.Document) -> (res: []Tag) {
    tags := make([dynamic]Tag)

    for frame in doc.frames {
        f_tags := get_tags(frame)
        append(&tags, ..f_tags)
        delete(f_tags)
    }

    return tags[:]
}

tags_from_doc_frame :: proc(frame: ase.Frame) -> (res: []Tag) {
    tags := make([dynamic]Tag)

    for chunk in frame.chunks {
        #partial switch v in chunk {
        case ase.Tags_Chunk:
            for t in v {
                tag := Tag {
                    int(t.from_frame), 
                    int(t.to_frame), 
                    t.loop_direction, 
                    t.name, 
                }
                append(&tags, tag)
            }
        }
    }

    return tags[:]
}

get_tags :: proc{tags_from_doc_frame, tags_from_doc}


frames_from_doc :: proc(doc: ^ase.Document) -> (frames: []Frame) {
    md := get_metadata(doc)
    return get_frames(doc.frames, md)
}

frames_from_doc_frames :: proc(data: []ase.Frame, metadata: Metadata) -> (frames: []Frame) {
    res := make([dynamic]Frame)
    for frame in data {
        append(&res, get_frame(frame, metadata))
    }
    return
}

get_frames :: proc {
    frames_from_doc, 
    frames_from_doc_frames, 
}

get_frame :: proc(data: ase.Frame, metadata: Metadata) -> (frame: Frame) {
    // frame.md = metadata
    frame.duration = i64(data.header.duration)
    frame.cels = get_cels(data)
    return
}


palette_from_doc :: proc(doc: ^ase.Document) -> Palette {
    pal := make([dynamic]Color)
    
    for frame in doc.frames {
        get_palette(frame, &pal, has_new_palette(doc))
    }

    return pal[:]
}

palette_from_doc_frame:: proc(frame: ase.Frame, pal: ^[dynamic]Color, has_new: bool) { 
    for chunk in frame.chunks {
        #partial switch c in chunk {
        case ase.Palette_Chunk:
            if int(c.last_index) >= len(pal) {
                resize(pal, int(c.last_index))
            }
            for i in c.first_index..<c.last_index {
                if int(i) >= len(pal) { 
                    /* error plaese */
                }
                
                if n, ok := c.entries[i].name.(string); ok {
                    pal[i].name = n
                }
                pal[i].color = c.entries[i].color

            }

        case ase.Old_Palette_256_Chunk:
            if has_new { continue }
            for p in c {
                first := int(p.entries_to_skip)
                last := first + len(p.colors)
                if last >= len(pal) {
                    resize(pal, last)
                }

                for i in first..<last {
                    if i >= len(pal) { 
                        /* error plaese */
                    }
                    pal[i].color.rgb = p.colors[i]
                    pal[i].color.a = 255
                }
            }

        case ase.Old_Palette_64_Chunk:
            if has_new { continue }
            for p in c {
                first := int(p.entries_to_skip)
                last := first + len(p.colors)
                if last >= len(pal) {
                    resize(pal, last)
                }

                for i in first..<last {
                    if i >= len(pal) { 
                        /* error plaese */
                    }
                    pal[i].color.rgb = p.colors[i]
                    pal[i].color.a = 255
                }
            }
        }
    }
}

get_palette :: proc{palette_from_doc, palette_from_doc_frame}


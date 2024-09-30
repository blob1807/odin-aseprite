package aseprite_file_handler_utility

import "core:slice"
import "core:mem"

@(require) import "core:fmt"
@(require) import "core:log"

import ase ".."


// Only Uses the first frame
get_image_from_doc :: proc(doc: ^ase.Document, frame := 0, alloc := context.allocator)  -> (img: Image, err: Errors) {
    context.allocator = alloc

    if len(doc.frames) <= frame {
        return {}, Image_Error.Frame_Index_Out_Of_Bounds
    }

    info := get_info(doc) or_return
    defer destroy(&info)
    
    return get_image_from_frame(info.frames[frame], info)
}

get_image_from_doc_frame :: proc(
    frame: ase.Frame, info: Info
)  -> (img: Image, err: Errors) {

    raw_frame := get_frame(frame, info.allocator) or_return
    defer delete(raw_frame.cels, info.allocator)

    return get_image_from_frame(raw_frame, info)
}

get_image_from_cel :: proc(
    cel: Cel, layer: Layer, info: Info,
) -> (img: Image, err: Errors) {
    img.width = cel.width
    img.height = cel.height
    img.bpp = .RGBA
        
    if cel.tilemap.tiles != nil {
        ts := info.tilesets[layer.tileset]
        c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
        defer delete(c.raw)

        img.data = make([]byte, c.width * c.height * 4, info.allocator) or_return
        if !layer.is_background && info.md.bpp == .Indexed {
            img_p := mem.slice_data_cast([]Pixel, img.data)
            c := info.palette[info.md.trans_idx].color
            c.a = 0
            slice.fill(img_p, c)
        }
        write_cel(img.data[:], c, layer, info.md, info.palette) or_return

    } else {
        img.data = make([]byte, cel.width * cel.height * 4, info.allocator) or_return
        if !layer.is_background && info.md.bpp == .Indexed {
            img_p := mem.slice_data_cast([]Pixel, img.data)
            c := info.palette[info.md.trans_idx].color
            c.a = 0
            slice.fill(img_p, c)
        }
        write_cel(img.data[:], cel, layer, info.md, info.palette) or_return
    }

    return
}

get_image_from_frame :: proc(
    frame: Frame, info: Info,
) -> (img: Image, err: Errors) {
    
    img.md = info.md
    img.bpp = .RGBA
    img.data = get_image_bytes(frame, info) or_return
    return
}

get_image :: proc {
    get_image_from_doc, 
    get_image_from_doc_frame, 
    get_image_from_frame, 
    get_image_from_cel, 
}


// Only Uses the First Frame
get_image_bytes_from_doc :: proc(doc: ^ase.Document, frame := 0, alloc := context.allocator)  -> (img: []byte, err: Errors) {
    context.allocator = alloc
    md := get_metadata(doc.header)

    raw_frame := get_frame(doc.frames[frame]) or_return
    defer delete(raw_frame.cels)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    ts := get_tileset(doc) or_return
    defer delete(ts)

    info := Info{layers=layers, palette=palette, tilesets=ts, allocator=alloc, md=md}

    return get_image_bytes(raw_frame, info)
}

get_image_bytes_from_doc_frame :: proc(
    frame: ase.Frame, info: Info,
)  -> (img: []byte, err: Errors) {

    raw_frame := get_frame(frame) or_return
    return get_image_bytes(raw_frame, info)
}

get_image_bytes_from_cel :: proc ( 
    cel: Cel, layer: Layer, info: Info,
) -> (img: []byte, err: Errors) {
    if cel.tilemap.tiles != nil {
        ts := info.tilesets[layer.tileset]
        c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
        defer delete(c.raw)

        img = make([]byte, c.width * c.height * 4, info.allocator) or_return
        if !layer.is_background && info.md.bpp == .Indexed {
            img_p := mem.slice_data_cast([]Pixel, img)
            c := info.palette[info.md.trans_idx].color
            c.a = 0
            slice.fill(img_p, c)
        }
        write_cel(img, c, layer, info.md, info.palette) or_return

    } else {
        img = make([]byte, cel.width * cel.height * 4, info.allocator) or_return
        if !layer.is_background && info.md.bpp == .Indexed {
            img_p := mem.slice_data_cast([]Pixel, img)
            c := info.palette[info.md.trans_idx].color
            c.a = 0
            slice.fill(img_p, c)
        }
        write_cel(img, cel, layer, info.md, info.palette) or_return
    }

    return
}

get_image_bytes_from_frame :: proc(
    frame: Frame, info: Info,
) -> (img: []byte, err: Errors) {
    context.allocator = info.allocator
    
    img = make([]byte, info.md.width * info.md.height * 4) or_return
    if len(frame.cels) == 0 { return }

    if !slice.is_sorted_by(frame.cels, cel_less) {
        slice.sort_by(frame.cels, cel_less)
    }
    
    if !info.layers[0].is_background && info.md.bpp == .Indexed {
        img_p := mem.slice_data_cast([]Pixel, img)
        c := info.palette[info.md.trans_idx].color
        c.a = 0
        slice.fill(img_p, c)
    }

    for cel in frame.cels {
        lay := info.layers[cel.layer]
        if !lay.visiable { continue }

        if cel.tilemap.tiles != nil {
            ts := info.tilesets[lay.tileset]
            c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
            defer delete(c.raw)

            write_cel(img, c, lay, info.md, info.palette) or_return

        } else {
            write_cel(img, cel, lay, info.md, info.palette) or_return
        }
    }

    return
}

get_image_bytes :: proc {
    get_image_bytes_from_doc,
    get_image_bytes_from_doc_frame,
    get_image_bytes_from_cel,
    get_image_bytes_from_frame,
}


get_all_images :: proc(doc: ^ase.Document, alloc := context.allocator) -> (imgs: []Image, err: Errors) {
    context.allocator = alloc
    imgs = make([]Image, len(doc.frames)) or_return
    defer if err != nil { destroy(imgs)}

    info := get_info(doc) or_return
    defer destroy(&info)

    for frame, p in info.frames {
        imgs[p] = get_image(frame, info) or_return
    }

    return 
}

get_all_images_bytes :: proc(doc: ^ase.Document, alloc := context.allocator) -> (imgs: [][]byte, err: Errors) {
    context.allocator = alloc
    imgs = make([][]byte, len(doc.frames)) or_return
    defer if err != nil { destroy(imgs) }
    
    md := get_metadata(doc.header)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    ts := get_tileset(doc) or_return
    defer delete(ts)

    info := Info{layers=layers, palette=palette, tilesets=ts, allocator=alloc, md=md}

    for frame, p in doc.frames {
        imgs[p] = get_image_bytes(frame, info) or_return
    }

    return
}


get_cels_as_imgs :: proc(doc: ^ase.Document, frame_idx := 0, alloc := context.allocator) -> (res: []Image, err: Errors) {
    context.allocator = alloc

    info := get_info(doc) or_return
    defer destroy(&info)

    if len(info.frames) < frame_idx {
        return nil, .Frame_Index_Out_Of_Bounds
    }

    frame := info.frames[frame_idx]

    res = make([]Image, len(frame.cels)) or_return
    if len(frame.cels) == 0 { return }

    if !slice.is_sorted_by(frame.cels, cel_less) {
        slice.sort_by(frame.cels, cel_less)
    }

    for cel, i in frame.cels {
        lay := info.layers[cel.layer]
        if !lay.visiable { continue }

        img := make([]byte, cel.width * cel.height * 4) or_return

        if cel.tilemap.tiles != nil {
            ts := info.tilesets[lay.tileset]
            c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
            defer delete(c.raw)

            write_cel(img, c, lay, info.md, info.palette) or_return

        } else {
            write_cel(img, cel, lay, info.md, info.palette) or_return
        }

        res[i] = Image{{cel.width, cel.height, .RGBA, 0}, img}
    }

    return
}


get_all_cels_as_imgs :: proc(doc: ^ase.Document, alloc := context.allocator) -> (res: []Image, err: Errors) {
    context.allocator = alloc

    info := get_info(doc) or_return
    defer destroy(&info)

    imgs := make([dynamic]Image) or_return

    for frame in info.frames {
        if len(frame.cels) == 0 { continue }

        if !slice.is_sorted_by(frame.cels, cel_less) {
            slice.sort_by(frame.cels, cel_less)
        }

        for cel in frame.cels {
            lay := info.layers[cel.layer]
            if !lay.visiable { continue }

            img := make([]byte, cel.width * cel.height * 4) or_return

            if cel.tilemap.tiles != nil {
                ts := info.tilesets[lay.tileset]
                c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
                defer delete(c.raw)

                write_cel(img, c, lay, info.md, info.palette) or_return

            } else {
                write_cel(img, cel, lay, info.md, info.palette) or_return
            }
            
            append(&imgs, Image{{cel.width, cel.height, .RGBA, 0}, img})
        } 
    }

    return imgs[:], nil
}

cel_from_tileset :: proc(cel: Cel, ts: Tileset, chans: Pixel_Depth, alloc := context.allocator) -> (c: Cel, err: Errors) {
    c = cel
    c.width = cel.tilemap.width * ts.width
    c.height = cel.tilemap.height * ts.height
    ch := int(chans)/8

    if (ts.height * ts.width * len(c.tilemap.tiles) * ch) != (c.width * c.height * ch) {
        return {}, .Tileset_Cel_Sizes_Mismatch
    }
    
    c.raw = make([]byte, ts.height * ts.width * len(c.tilemap.tiles) * ch, alloc) or_return

    for h in 0..<c.tilemap.height {
        for w in 0..<c.tilemap.width {
            s := (h * c.tilemap.width * ts.height + w) * ts.width * ch
            s1 := c.tilemap.tiles[h * c.tilemap.width + w] * ts.width * ts.height * ch
            
            for y in 0..<ts.height {
                copy(c.raw[s+(y*ts.width*c.tilemap.width*ch):][:ch*ts.width], ts.tiles[s1+(y*ts.width*ch):])
            }
        }
    }
    
    return
}

// Write a cel to an image's data. Assumes tilemaps & linked cels have already been handled.
write_cel :: proc (
    buf: []byte, cel: Cel, layer: Layer, md: Metadata, 
    pal: Palette = nil,
) -> (err: Errors) {
    if len(cel.raw) <= 0 {
        fast_log(.Debug, "No Cel data to write.")
        return
    }

    if len(buf) < (md.height * md.width * 4) {
        fast_log(.Error, "Image buffer size is smaller than Metadata.")
        return .Buffer_To_Small
    }

    when ODIN_DEBUG {
        switch md.bpp {
        case .Indexed:
            if pal == nil {
                fast_log(.Error, "Indexed Color Mode. No Palette")
                return .Indexed_BPP_No_Palette
            }
            fallthrough 
        case .Grayscale, .RGBA:
            if len(cel.raw) % (int(md.bpp) / 8) != 0 {
                fast_log(.Error, "Size of cel not a multipule of channels. ")
                return .Cel_Size_Not_Of_BPP
            }
        case:
            fast_log(.Error, "Invalid Color Mode: ", md.bpp)
            return .Invalid_BPP
        }
    }
    
    _cel := cel

    offset := [2]int {
        abs(cel.x) if cel.x < 0 else 0,
        abs(cel.y) if cel.y < 0 else 0,
    }

    _cel.x = clamp(cel.x, 0, md.width)
    _cel.y = clamp(cel.y, 0, md.height)
    _cel.width = clamp(cel.width, 0, md.width)
    _cel.height = clamp(cel.height, 0, md.height)

    when ODIN_DEBUG {
        if !(_cel.x <= md.width && _cel.y <= md.height \
        && _cel.width <= md.width && _cel.height <= md.height \
        && offset.x <= md.width && offset.y <= md.height\
        && _cel.x >= 0 && _cel.y >= 0 \
        && _cel.width >= 0 && _cel.height >= 0 \
        && offset.x >= 0 && offset.y >= 0) {
            fast_log(.Error, "Cel out of bounds of Image bounds.")
            return .Frame_Index_Out_Of_Bounds, 
        }
    }

    for y in 0..<_cel.height {
        for x in 0..<_cel.width {
            pix: [4]byte
            idx := (y + offset.y) * cel.width + x + offset.x

            // Convert to RGBA
            switch md.bpp {
            case .Indexed:
                if cel.raw[idx] == md.trans_idx {
                    continue
                }
                pix = pal[cel.raw[idx]].color

            case .Grayscale:
                pix.rgb = cel.raw[(idx) * 2]
                pix.a = cel.raw[(idx) * 2 + 1]

            case .RGBA:
                // Note(blob):
                // This is comparable to slice casting before & idxing in to that.
                //      `mem.slice_data_cast()` or `slice.reinterpret()`
                // On average is slightly faster but more variable in optimized builds
                pix = (^[4]byte)(&cel.raw[(idx) * 4])^
            } 

            if pix.a != 0 {
                ipix := (^[4]byte)(&buf[((y + _cel.y) * md.width + x + _cel.x) * 4])
                
                if ipix.a != 0 {
                    // Blend pixels
                    a := alpha(i32(cel.opacity), i32(layer.opacity))
                    pix = blend(ipix^, pix, a, layer.blend_mode) or_return

                } else {
                    // Merge Alpha & Opacities
                    pix.a = u8(alpha(i32(pix.a), alpha(cel.opacity, layer.opacity)))
                }
                
                ipix^ = pix
            }
        }
    }

    return
}


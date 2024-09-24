package aseprite_file_handler_utility

import "base:runtime"
import "core:image"
import "core:slice"
import "core:mem"
import "core:os"

@(require) import "core:fmt"
@(require) import "core:log"

import ase ".."

// TODO: Should read in External Files when needed

// Only Uses the first frame
get_image_from_doc :: proc(doc: ^ase.Document, frame := 0, alloc := context.allocator)  -> (img: Image, err: Errors) {
    context.allocator = alloc
    md := get_metadata(doc.header)

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

    info := Info{layers=layers, palette=palette, tilesets=ts, allocator=alloc}

    return get_image_bytes(raw_frame, info)
}

get_image_bytes_from_doc_frame :: proc(
    frame: ase.Frame, info: Info,
)  -> (img: []byte, err: Errors) {

    raw_frame := get_frame(frame) or_return
    return get_image_bytes(raw_frame, info)
}

get_image_bytes_from_cel :: proc( cel: Cel, layer: Layer, info: Info,
) -> (img: []byte, err: Errors) {
    if cel.tilemap.tiles != nil {
        ts := info.tilesets[layer.tileset]
        c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
        defer delete(c.raw)
        log.debug("Doning Tileset")

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

    for cel, pos in frame.cels {
        lay := info.layers[cel.layer]
        if !lay.visiable { continue }

        if cel.tilemap.tiles != nil {
            ts := info.tilesets[lay.tileset]
            c := cel_from_tileset(cel, ts, info.md.bpp, info.allocator) or_return
            defer delete(c.raw)
            log.debug("Doning Tileset")

            write_cel(img, c, lay, info.md, info.palette) or_return

        } else {
            write_cel(img, cel, lay, info.md, info.palette) or_return
            if pos == 0 {
                str := transmute([]u8)format_pixels({height=cel.height, width=cel.width, data=cel.raw, bpp=.RGBA}, cel.width, cel.height)
                defer delete(str)
                os.write_entire_file("_cel.txt", str)
            }
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

    info := Info{layers=layers, palette=palette, tilesets=ts, allocator=alloc}

    for frame, p in doc.frames {
        imgs[p] = get_image_bytes(frame, info) or_return
    }

    return
}


get_img_for_atlas :: proc(doc: ^ase.Document, ignored_pal_idxs: []int = nil, alloc := context.allocator) -> (res: []Image, err: Errors) {
    context.allocator = alloc

    info := get_info(doc) or_return
    defer destroy(&info)

    res = make([]Image, len(doc.frames)) or_return

    return
}


// Converts `utils.Image` to a `core:image.Image`
to_core_image :: proc(buf: []byte, md: Metadata, alloc := context.allocator) -> (img: image.Image, err: runtime.Allocator_Error) {
    img.width = md.width
    img.height = md.height
    img.depth = 8
    img.channels = 4
    img.pixels.buf = make([dynamic]byte, len(buf), alloc) or_return

    copy(img.pixels.buf[:], buf)
    return
}

cel_from_tileset :: proc(cel: Cel, ts: Tileset, chans: Pixel_Depth, alloc := context.allocator) -> (c: Cel, err: runtime.Allocator_Error) {
    c = cel
    c.width = cel.tilemap.width * ts.width
    c.height = cel.tilemap.height * ts.height
    ch := int(chans)/8
    
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
    assert(len(c.raw) == (c.width * c.height * ch), "Missmatched sizes")
    
    return
}

// Write a cel to an image's data. Assumes tilemaps & linked cels have already been handled.
write_cel :: proc (
    img: []byte, cel: Cel, layer: Layer, md: Metadata, 
    pal: Palette = nil,
) -> (err: Errors) {
    if len(cel.raw) <= 0 {
        log.debug("No Cel data to write.")
        return
    }

    switch md.bpp {
    case .Indexed:
        if pal == nil {
            log.error("Indexed Color Mode. No Palette")
            return .Indexed_BPP_No_Palette
        }
        fallthrough 
    case .Grayscale, .RGBA:
        if len(cel.raw) % (int(md.bpp) / 8) == 0 { break }
        fallthrough
    case:
        log.error("Invalid Color Mode: ", md.bpp)
        return .Invalid_BPP
    }

    assert(len(img) >= (md.height * md.width * 4), "Image buffer size is smaller than Metadata.")
    _cel := cel

    offset := [2]int {
        abs(cel.x) if cel.x < 0 else 0,
        abs(cel.y) if cel.y < 0 else 0,
    }

    _cel.x = clamp(cel.x, 0, md.width)
    _cel.y = clamp(cel.y, 0, md.height)
    _cel.width = clamp(cel.width, 0, md.width)
    _cel.height = clamp(cel.height, 0, md.height)

    // TODO: Is this assert really needed???
    assert (
        _cel.x <= md.width && _cel.y <= md.height \
        && _cel.width <= md.width && _cel.height <= md.height \
        && offset.x <= md.width && offset.y <= md.height\
        && _cel.x >= 0 && _cel.y >= 0 \
        && _cel.width >= 0 && _cel.height >= 0 \
        && offset.x >= 0 && offset.y >= 0, 
        "Cel out of bounds of Image bounds."
    )

    for y in 0..<_cel.height {
        for x in 0..<_cel.width {
            pix: [4]byte
            idx := (y + offset.y) * cel.width + x + offset.x

            // Convert to RGBA
            switch md.bpp {
            case .Indexed:
                if int(cel.raw[idx]) == md.trans_idx {
                    continue
                }
                pix = pal[cel.raw[idx]].color

            case .Grayscale:
                pix.rgb = cel.raw[(idx) * 2]
                pix.a = cel.raw[(idx) * 2 + 1]

            case .RGBA:
                pix = (^[4]byte)(&cel.raw[(idx) * 4])^
            } 

            if pix.a != 0 {
                ipix := (^[4]byte)(&img[((y + _cel.y) * md.width + x + _cel.x) * 4])
                
                if ipix.a != 0 {
                    // Blend pixels
                    a := alpha(cel.opacity, layer.opacity)
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


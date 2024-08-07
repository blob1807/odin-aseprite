package aseprite_file_handler_utility

import "base:runtime"
import "core:image"
import "core:slice"
import "core:mem"

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

    raw_frame := get_frame(doc.frames[frame]) or_return
    defer destroy(raw_frame)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    ts := get_tileset(doc) or_return
    defer delete(ts)

    info := Info { 
        layers=layers, palette=palette, tilesets=ts, md=md,
        allocator=alloc
    }
    
    return get_image_from_frame(raw_frame, info)
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
        write_cel(img.data[:], c, layer, info.md, info.palette) or_return

    } else {
        img.data = make([]byte, cel.width * cel.height * 4, info.allocator) or_return
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
get_image_bytes_from_doc :: proc(doc: ^ase.Document, alloc := context.allocator)  -> (img: []byte, err: Errors) {
    context.allocator = alloc
    md := get_metadata(doc.header)

    raw_frame := get_frame(doc.frames[0]) or_return
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

        img = make([]byte, c.width * c.height * 4, info.allocator) or_return
        write_cel(img, c, layer, info.md, info.palette) or_return

    } else {
        img = make([]byte, cel.width * cel.height * 4, info.allocator) or_return
        write_cel(img, cel, layer, info.md, info.palette) or_return
    }

    return
}

get_image_bytes_from_frame :: proc(
    frame: Frame, info: Info,
) -> (img: []byte, err: Errors) {
    context.allocator = info.allocator

    img = make([]byte, info.md.width * info.md.height * 4) or_return

    if !slice.is_sorted_by(frame.cels[:], cel_less) {
        slice.sort_by(frame.cels[:], cel_less)
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

    md := get_metadata(doc.header)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    ts := get_tileset(doc) or_return
    defer delete(ts)

    info := Info{layers=layers, palette=palette, tilesets=ts, allocator=alloc}

    for frame, p in doc.frames {
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

    info := get_all(doc) or_return
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
    
    c.raw = make([]byte, ts.height*ts.width*len(c.tilemap.tiles)*ch, alloc) or_return

    for h in 0..<c.tilemap.height {
        for w in 0..<c.tilemap.width {
            s := (h * c.tilemap.width * ts.height + w) * ts.width * ch
            s1 := ts.width * ts.height * c.tilemap.tiles[h * c.tilemap.width + w] * ch

            for y in 0..<ts.height {
                copy(c.raw[s+(y*ts.width*c.tilemap.width*ch):], ts.tiles[s1+(y*ts.width*ch):][:ch*ts.width])
            }
        }
    }
    
    return
}

// Write a cel to an image's data. Assumes tilemaps & linked cels have already been handled.
write_cel :: proc (
    img: []byte, cel: Cel, layer: Layer, md: Metadata, 
    pal: Palette = nil, ignored_pal_idxs: []int = nil,
) -> (err: Errors) {
    for y in 0..<cel.height {
        for x in 0..<cel.width {
            //xi := ((y + cel.y) * md.width + x + cel.x) * 4
            //xc := (y * cel.width + x) * 4

            pix: [4]byte
            // Convert to RGBA
            switch md.bpp {
            case .Indexed:
                if pal == nil {
                    log.error("Indexed Color Mode. No Palette")
                    return .Indexed_BPP_No_Palette
                }
                if slice.contains(ignored_pal_idxs, int(cel.raw[x])) {
                    continue
                }
                pix = pal[cel.raw[x]].color
            case .Grayscale:
                pix.rgb = cel.raw[x]
                pix.a = cel.raw[x+1]
            case .RGBA:
                pix = (^[4]byte)(&cel.raw[(y * cel.width + x) * 4:][0])^
            case:
                log.error("Invalid Color Mode: ", md.bpp)
                return .Invalid_BPP
            }

            if pix.a != 0 {
                ipix := (^[4]byte)(&img[((y + cel.y) * md.width + x + cel.x) * 4:][0])
                cpix := B_Pixel{u16(ipix.r), u16(ipix.g), u16(ipix.b), u16(ipix.a)}

                if cpix.a != 0 {
                    if layer.blend_mode == .Normal {
                        // TODO: Does this work for all cases?
                        // Or should I just do blend() regaurdless?
                        // a := u16(int(pix.a) * cel.opacity * layer.opacity / (255*255))

                        a := alpha(u16(pix.a), alpha(cel.opacity, layer.opacity))
                        pa := a + cpix.a - alpha(a, cpix.a)

                        pix.r = byte(cpix.r + (u16(pix.r) - cpix.r) * a / pa)
                        pix.g = byte(cpix.g + (u16(pix.g) - cpix.g) * a / pa)
                        pix.b = byte(cpix.b + (u16(pix.b) - cpix.b) * a / pa)
                        pix.a = byte(pa)

                    } else {
                        a := alpha(cel.opacity, layer.opacity)
                        pix = blend(ipix^, pix, a, layer.blend_mode) or_return
                    }
                }
                ipix^ = pix
            }
        }
    }

    return
}


package aseprite_file_handler_utility

import "base:runtime"
import "core:fmt"
import "core:image"
import "core:slice"
import "core:log"
_::fmt
import ase ".."

// TODO: Should read in External Files when needed

// Only Uses the first frame
get_image_from_doc :: proc(doc: ^ase.Document, alloc := context.allocator)  -> (img: Image, err: Image_Errors) {
    context.allocator = alloc
    md := get_metadata(doc.header)

    raw_frame := get_frame(doc.frames[0]) or_return
    defer delete(raw_frame.cels)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    return get_image(raw_frame, layers, md, palette, alloc)
}

get_image_from_doc_frame :: proc(frame: ase.Frame, layers: []Layer, md: Metadata,  pal: Palette = nil, alloc := context.allocator)  -> (img: Image, err: Image_Errors) {
    raw_frame := get_frame(frame, alloc) or_return
    defer delete(raw_frame.cels, alloc)
    return get_image(raw_frame, layers, md, pal)
}

get_image_from_cel :: proc(cel: Cel, layer: Layer, md: Metadata, pal: Palette = nil, alloc := context.allocator) -> (img: Image, err: Image_Errors) {
    img.width = cel.width
    img.height = cel.height
    img.bpp = .RGBA
    img.data = make([]byte, cel.width * cel.height * 4, alloc) or_return
    write_cel(img.data[:], cel, layer, md, pal) or_return
    return
}

get_image_from_frame :: proc(frame: Frame, layers: []Layer, md: Metadata, pal: Palette = nil, alloc := context.allocator) -> (img: Image, err: Image_Errors) {
    img.width = md.width
    img.height = md.height
    img.data = get_image_bytes(frame, layers, md, pal, alloc) or_return
    return
}

get_image :: proc {
    get_image_from_doc, 
    get_image_from_doc_frame, 
    get_image_from_frame, 
    get_image_from_cel, 
}


// Only Uses the First Frame
get_image_bytes_from_doc :: proc(doc: ^ase.Document, alloc := context.allocator)  -> (img: []byte, err: Image_Errors) {
    context.allocator = alloc
    md := get_metadata(doc.header)

    raw_frame := get_frame(doc.frames[0]) or_return
    defer delete(raw_frame.cels)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    return get_image_bytes(raw_frame, layers, md, palette)
}

get_image_bytes_from_doc_frame :: proc(frame: ase.Frame, layers: []Layer, md: Metadata,  pal: Palette = nil, alloc := context.allocator)  -> (img: []byte, err: Image_Errors) {
    raw_frame := get_frame(frame) or_return
    return get_image_bytes(raw_frame, layers, md, pal)
}

get_image_bytes_from_cel :: proc(cel: Cel, layer: Layer, md: Metadata,  pal: Palette = nil, alloc := context.allocator) -> (img: []byte, err: Image_Errors) {
    img = make([]byte, cel.width * cel.height * 4, alloc) or_return
    write_cel(img[:], cel, layer, md, pal) or_return
    return
}

get_image_bytes_from_frame :: proc(frame: Frame, layers: []Layer, md: Metadata, pal: Palette = nil, alloc := context.allocator) -> (img: []byte, err: Image_Errors) {
    img = make([]byte, md.width * md.height * 4, alloc) or_return

    if !slice.is_sorted_by(frame.cels[:], cel_less) {
        slice.sort_by(frame.cels[:], cel_less)
    }

    for cel in frame.cels {
        lay := layers[cel.layer]
        if !lay.visiable { continue }
        write_cel(img, cel, lay, md, pal) or_return
    }

    return
}

get_image_bytes :: proc {
    get_image_bytes_from_doc,
    get_image_bytes_from_doc_frame,
    get_image_bytes_from_cel,
    get_image_bytes_from_frame,
}


get_all_images :: proc(doc: ^ase.Document, alloc := context.allocator) -> (imgs: []Image, err: Image_Errors) {
    context.allocator = alloc
    images := make([]Image, len(doc.frames)) or_return
    md := get_metadata(doc.header)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    for frame, p in doc.frames {
        images[p] = get_image(frame, layers, md, palette) or_return
    }

    return images, nil
}

get_all_images_bytes :: proc(doc: ^ase.Document, alloc := context.allocator) -> (imgs: [][]byte, err: Image_Errors) {
    context.allocator = alloc
    images := make([][]byte, len(doc.frames)) or_return
    md := get_metadata(doc.header)

    layers := get_layers(doc) or_return
    defer delete(layers)

    palette := get_palette(doc) or_return
    defer delete(palette)

    for frame, p in doc.frames {
        images[p] = get_image_bytes(frame, layers, md, palette) or_return
    }

    return images, nil
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

// Write a cel to an image's data
write_cel :: proc(img: []byte, cel: Cel, layer: Layer, md: Metadata, pal: Palette = nil) -> (err: Image_Errors) {
    for y in 0..<cel.height {
        yi := y + cel.y
        for x in 0..<cel.width {
            xi := (yi * md.width + x + cel.x) * 4
            xc := (y * cel.width + x) * 4

            pix: [4]byte
            // Convert to RGBA
            switch md.bpp {
            case .Indexed:
                if pal == nil {
                    log.error("Indexed Color Mode. No Palette")
                    return .Indexed_BPP_No_Palette
                }
                pix = pal[cel.raw[x]].color
            case .Grayscale:
                pix.rgb = cel.raw[x]
                pix.a = cel.raw[x+1]
            case .RGBA:
                copy(pix[:], cel.raw[xc:xc+4])
            case:
                log.error("Invalid Color Mode: ", md.bpp)
                return .Invalid_BPP
            }

            if pix.a != 0 {
                ipix: [4]byte
                copy(ipix[:], img[xi:xi+4])

                if ipix.a != 0 {
                    if layer.blend_mode == .Normal {
                        // TODO: Does this work for all cases?
                        // Or should I just do blend() regaurdless?
                        a := u16(int(pix.a) * cel.opacity * layer.opacity / (255*255))
                        pa := a + u16(ipix.a) - alpha(a, u16(ipix.a))

                        pix.r = byte(u16(ipix.r) + (u16(pix.r) - u16(ipix.r)) * a / pa)
                        pix.g = byte(u16(ipix.g) + (u16(pix.g) - u16(ipix.g)) * a / pa)
                        pix.b = byte(u16(ipix.b) + (u16(pix.b) - u16(ipix.b)) * a / pa)
                        pix.a = byte(pa)

                    } else {
                        a := alpha(cel.opacity, layer.opacity)
                        pix = blend(ipix, pix, a, layer.blend_mode) or_return
                    }
                }

                copy(img[xi:xi+4], pix[:])
            }
        }
    }

    return
}


package aseprite_file_handler_utility

import "base:runtime"
import "core:fmt"
import "core:image"
import "core:bytes"
import "core:slice"
import "core:log"

import ase ".."

// TODO: Should read in External Files when needed

// Only Uses the first frame
get_image_from_doc :: proc(doc: ^ase.Document)  -> (img: Image) {
    md := get_metadata(doc)

    raw_frame := get_frame(doc.frames[0], md)
    defer delete(raw_frame.cels)

    layers := get_layers(doc)
    defer delete(layers)

    palette := get_palette(doc)
    defer delete(palette)

    return get_image(raw_frame, layers, md, palette)
}

get_image_from_doc_frame :: proc(frame: ase.Frame, layers: []Layer, md: Metadata,  pal: Palette = nil)  -> (img: Image) {
    raw_frame := get_frame(frame, md)
    defer delete(raw_frame.cels)
    return get_image(raw_frame, layers, md, pal)
}

get_image_from_cel :: proc(cel: Cel, layer: Layer, md: Metadata, pal: Palette = nil) -> (img: Image) {
    img.width = cel.width
    img.height = cel.height
    img.bpp = .RGBA
    img.data = make([]byte, cel.width * cel.height * 4)
    write_cel(img.data[:], cel, layer, md, pal)
    return
}

get_image_from_frame :: proc(frame: Frame, layers: []Layer, md: Metadata, pal: Palette = nil) -> (img: Image) {
    img.width = md.width
    img.height = md.height
    img.data = get_image_bytes(frame, layers, md, pal)
    return
}

get_image :: proc {
    get_image_from_doc, 
    get_image_from_doc_frame, 
    get_image_from_frame, 
    get_image_from_cel, 
}


// Only Uses the First Frame
get_image_bytes_from_doc :: proc(doc: ^ase.Document)  -> (img: []byte) {
    md := get_metadata(doc)

    raw_frame := get_frame(doc.frames[0], md)
    defer delete(raw_frame.cels)

    layers := get_layers(doc)
    defer delete(layers)

    palette := get_palette(doc)
    defer delete(palette)

    return get_image_bytes(raw_frame, layers, md, palette)
}

get_image_bytes_from_doc_frame :: proc(frame: ase.Frame, layers: []Layer, md: Metadata,  pal: Palette = nil)  -> (img: []byte) {
    raw_frame := get_frame(frame, md)
    return get_image_bytes(raw_frame, layers, md, pal)
}

get_image_bytes_from_cel :: proc(cel: Cel, layer: Layer, md: Metadata,  pal: Palette = nil) -> (img: []byte) {
    img = make([]byte, cel.width * cel.height * 4)
    write_cel(img[:], cel, layer, md, pal)
    return
}

get_image_bytes_from_frame :: proc(frame: Frame, layers: []Layer, md: Metadata, pal: Palette = nil) -> (img: []byte) {
    img = make([]byte, md.width * md.height * 4)

    if !slice.is_sorted_by(frame.cels[:], cel_less) {
        slice.sort_by(frame.cels[:], cel_less)
    }

    for cel in frame.cels {
        lay := layers[cel.layer]
        if !lay.visiable { continue }
        write_cel(img, cel, lay, md, pal)
    }

    return
}

get_image_bytes :: proc {
    get_image_bytes_from_doc,
    get_image_bytes_from_doc_frame,
    get_image_bytes_from_cel,
    get_image_bytes_from_frame,
}


get_all_images :: proc(doc: ^ase.Document) -> (imgs: []Image) {
    images := make([]Image, len(doc.frames))
    md := get_metadata(doc)

    layers := get_layers(doc)
    defer delete(layers)

    palette := get_palette(doc)
    defer delete(palette)

    for frame, p in doc.frames {
        images[p] = get_image(frame, layers, md, palette)
    }

    return images
}

get_all_images_bytes :: proc(doc: ^ase.Document) -> (imgs: [][]byte) {
    images := make([][]byte, len(doc.frames))
    md := get_metadata(doc)

    layers := get_layers(doc)
    defer delete(layers)

    palette := get_palette(doc)
    defer delete(palette)

    for frame, p in doc.frames {
        images[p] = get_image_bytes(frame, layers, md, palette)
    }

    return images
}

// Converts `utils.Image` to a `core:image.Image`
to_core_image :: proc(buf: []byte, md: Metadata) -> (img: image.Image) {
    img.width = md.width
    img.height = md.height
    img.depth = 8
    img.channels = 4
    bytes.buffer_init(&img.pixels, buf[:])
    return
}

// Write a cel to an image's data
write_cel :: proc(img: []byte, cel: Cel, layer: Layer, md: Metadata, pal: Palette = nil) {
    for y in 0..<cel.height {
        yi := y + cel.y
        for x in 0..<cel.width {
            xi := (yi * md.width + x + cel.x) * 4
            xc := (y * cel.width + x) * 4

            pix: [4]byte
            // Convert to RGBA
            switch md.bpp {
            case .Indexed:
                if pal != nil {
                    pix = pal[cel.raw[x]].color
                }
            case .Grayscale:
                pix.rgb = cel.raw[x]
                pix.a = cel.raw[x+1]
            case .RGBA:
                copy(pix[:], cel.raw[xc:xc+4])
            case:
                log.error("Invalid Color Mode was provided: ", md.bpp)
            }

            if pix.a != 0 {
                //img_pix: [4]byte
                //copy(img_pix[:], img[xi:xi+4])
                //pix = blend(img_pix, pix, alpha(cel.opacity, layer.opacity), layer.blend_mode)
                
                if i := img[xi:xi+4][3]; i != 0 {
                    pix.a = byte(int(i) * int(pix.a) * cel.opacity * layer.opacity / (255*255*255))
                } else {
                    pix.a = byte(int(pix.a) * cel.opacity * layer.opacity / (255*255))
                }
                copy(img[xi:xi+4], pix[:])
            }
        }
    }

    return
}


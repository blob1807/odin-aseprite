package aseprite_file_handler_utility

import "core:slice"
import "core:fmt"

import ase ".."


// TODO: Need destruction & alloctor passing
get_layers :: proc(frame: ase.Frame, layer_valid_opacity := false)  -> (layers: []Layer) {
    lays := make([dynamic]Layer)

    doc_lays := make([dynamic]ase.Layer_Chunk)
    defer delete(doc_lays)
    doc_cels := make([dynamic]ase.Cel_Chunk)
    defer delete(doc_cels)

    for chunk in frame.chunks {
        #partial switch v in chunk {
        case ase.Layer_Chunk:
            append(&doc_lays, v)
        case ase.Cel_Chunk:
            append(&doc_cels, v)
        }
    }

    for layer, p in doc_lays {
        lay := Layer {
            name = layer.name, 
            opacity = int(layer.opacity) if layer_valid_opacity else 0,
            index = p,
            blend_mode = layer.blend_mode
        }

        cels := make([dynamic]Cel)

        for doc_cel in doc_cels {
            if int(doc_cel.layer_index) != p { continue }
            cel := Cel {
                pos = {int(doc_cel.x), int(doc_cel.y)},
                opacity = int(doc_cel.opacity_level), // TODO: Needs rework
                z_index = int(doc_cel.z_index),
            }
    
            switch v in doc_cel.cel {
            case ase.Com_Image_Cel:
                cel.width = int(v.width)
                cel.height = int(v.height)
                //cel.pixels = v.pixel
            case ase.Raw_Cel:
                cel.width = int(v.width)
                cel.height = int(v.height)
                //lay.pixels = v.pixel
            case ase.Com_Tilemap_Cel:
            case ase.Linked_Cel:
                cel.link = int(v)
            }
            append(&cels, cel)      
        }
        lay.cels = cels[:]

        append(&lays, lay)
    }

    /*if !slice.is_sorted_by(lays[:], layers_less) {
        slice.stable_sort_by(lays[:], layers_less)
    }*/

    return lays[:]
}


/*
// Use with slice.sort_by, .sort_by_with_indices, .stable_sort_by, .is_sorted_by & .reverse_sort_by
layers_less :: proc(i, j: Layer) -> bool {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    i_or := i.index + i.z_index
    j_or := j.index + j.z_index
    return i_or < j_or || (i_or == j_or && i.z_index < j.z_index )
}

// Use with slice.sort_by_cmp, .stable_sort_by_cmp, .is_sorted_cmp & .reverse_sort_by_cmp
layers_cmp :: proc(i, j: Layer) -> slice.Ordering {
    // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    i_or := i.index + i.z_index
    j_or := j.index + j.z_index

    if i_or < j_or { return .Less } 
    else if i_or > j_or { return .Greater} 
    else if i.z_index < j.z_index { return .Less}
    else if i.z_index > j.z_index { return .Greater}
    return .Equal
}
*/

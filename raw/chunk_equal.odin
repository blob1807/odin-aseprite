//+private
package raw_aseprite_file_handler

import "core:slice"

_old_palette_256_equal :: proc(x, y: Old_Palette_256_Chunk) -> bool {
    if x.size != y.size || len(x.packets) != len(y.packets) {
        return false
    }
    for i in 0..<len(x.packets) {
        xp, yp := x.packets[i], y.packets[i]

        if xp.num_colors != yp.num_colors \
        || xp.entries_to_skip != yp.entries_to_skip \
        || len(xp.colors) != len(yp.colors) {
            return false
        } 

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return false
            }
        }
    }
    return true
}

_old_plette_64_equal :: proc(x, y: Old_Palette_64_Chunk) -> bool {
    if x.size != y.size || len(x.packets) != len(y.packets) {
        return false
    }
    for i in 0..<len(x.packets) {
        xp, yp := x.packets[i], y.packets[i]

        if xp.num_colors != yp.num_colors \
        || xp.entries_to_skip != yp.entries_to_skip \
        || len(xp.colors) != len(yp.colors) {
            return false
        } 

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return false
            }
        }
    }
    return true
}

_layer_equal :: proc(x, y: Layer_Chunk) -> bool {
    if x.type != y.type \
    || x.flags != y.flags \ 
    || x.opacity != y.opacity \ 
    || x.blend_mode != y.blend_mode \
    || x.child_level != y.child_level \
    || x.default_width != y.default_width \
    || x.tileset_index != y.tileset_index \
    || x.default_height != y.default_height \
    || x.name.length != x.name.length {
        return false
    }

    return slice.equal(x.name.data[:], y.name.data[:])
}

_cel_equal :: proc(x, y: Cel_Chunk) -> bool {
    if x.x != y.x \ 
    || y.y != x.y \ 
    || x.type != y.type \
    || x.z_index != y.z_index \
    || x.layer_index != y.layer_index \
    || x.opacity_level != y.opacity_level {
        return false
    }

    switch xv in x.cel {
    case Raw_Cel:
        yv := y.cel.(Raw_Cel) or_return
        if xv.width != yv.width \
        || xv.height != yv.height \
        || !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return false
        }

    case Linked_Cel:
        yv := y.cel.(Linked_Cel) or_return
        return xv == yv

    case Com_Image_Cel:
        yv := y.cel.(Com_Image_Cel) or_return
        if xv.width != yv.width \
        || xv.height != yv.height \ 
        || xv.did_com != yv.did_com \
        || !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return false
        }

    case Com_Tilemap_Cel:
        yv := y.cel.(Com_Tilemap_Cel) or_return
        if xv.width != yv.width \
        || xv.height != yv.height \
        || xv.did_com != yv.did_com \
        || xv.bitmask_x != yv.bitmask_y \
        || xv.bitmask_id != yv.bitmask_id \
        || xv.bits_per_tile != yv.bits_per_tile \
        || xv.bitmask_diagonal != yv.bitmask_diagonal \
        || !slice.equal(xv.tiles[:], yv.tiles[:]) {
            return false
        }

    case nil:
        return y.cel == nil

    case:
        return false
    }
    return true
}

_cel_extra_equal :: proc(x, y: Cel_Extra_Chunk) -> bool {
    return x == y
}

_color_profile_equal :: proc(x, y: Color_Profile_Chunk) -> bool {
    if x.type != y.type \
    || x.flags != y.flags \
    || x.fixed_gamma != y.fixed_gamma \
    || x.icc.length != y.icc.length {
        return false
    }
    return slice.equal(x.icc.data[:], y.icc.data[:])
}

_external_files_equal :: proc(x, y: External_Files_Chunk) -> bool {
    if x.length != y.length \
    || len(x.entries) != len(y.entries) {
        return false
    }

    for i in 0..<len(x.entries) {
        xe, ye := x.entries[i], y.entries[i]
        if xe.id != ye.id \
        || xe.type != ye.type \
        || xe.file_name_or_id.length != ye.file_name_or_id.length \ 
        || !slice.equal(xe.file_name_or_id.data[:], ye.file_name_or_id.data[:]) {
            return false
        }
    }
    return true
}

_mask_equal :: proc(x, y: Mask_Chunk) -> bool {
    if x.x != y.x \ 
    || x.y != y.y \
    || x.width != y.width \
    || x.height != y.height \
    || x.name.length != y.name.length \
    || !slice.equal(x.name.data[:], y.name.data[:]) {
        return false
    }
    return slice.equal(x.bit_map_data[:], y.bit_map_data[:])
}

_path_equal :: proc(x, y: Path_Chunk) -> bool {
    return x == y
}

_tags_equal :: proc(x, y: Tags_Chunk) -> bool {
    if x.number != y.number \
    || len(x.tags) != len(y.tags) {
        return false
    }

    for i in 0..<len(x.tags) {
        xt, yt: Tag = x.tags[i], y.tags[i]
        if xt.repeat != yt.repeat \ 
        || xt.to_frame != yt.to_frame \ 
        || xt.tag_color != yt.tag_color \
        || xt.from_frame != yt.from_frame \
        || xt.loop_direction != yt.loop_direction \
        || xt.name.length != xt.name.length \
        || !slice.equal(xt.name.data[:], yt.name.data[:]) {
            return false
        }
        
    }
    return true
}

_palette_equal :: proc(x, y: Palette_Chunk) -> bool {
    if x.size != y.size \ 
    || x.last_index != y.last_index \
    || x.first_index != y.first_index \
    || len(x.entries) != len(y.entries) {
        return false
    }

    for i in 0..<len(x.entries) {
        xp, yp: Palette_Entry = x.entries[i], y.entries[i]
        if xp.red != yp.red \
        || xp.blue != yp.blue \
        || xp.green != yp.green \
        || xp.alpha != yp.alpha \
        || xp.flags != yp.flags \
        || xp.name.length != xp.name.length \
        || !slice.equal(xp.name.data[:], yp.name.data[:]) {
            return false
        }
    }
    return true
}

_ud_prop_val_eq :: proc(x,y: UD_Property_Value) -> (eq: bool) {
    switch xv in x {
    case BYTE:
        yv := y.(BYTE) or_return
        eq = xv == yv

    case SHORT:
        yv := y.(SHORT) or_return
        eq = xv == yv

    case WORD:
        yv := y.(WORD) or_return
        eq = xv == yv

    case LONG:
        yv := y.(LONG) or_return
        eq = xv == yv

    case DWORD:
        yv := y.(DWORD) or_return
        eq = xv == yv

    case LONG64:
        yv := y.(LONG64) or_return
        eq = xv == yv

    case QWORD:
        yv := y.(QWORD) or_return
        eq = xv == yv

    case FIXED:
        yv := y.(FIXED) or_return
        eq = xv == yv

    case FLOAT:
        yv := y.(FLOAT) or_return
        eq = xv == yv

    case DOUBLE:
        yv := y.(DOUBLE) or_return
        eq = xv == yv

    case STRING:
        yv := y.(STRING) or_return
        if xv.length == yv.length \
        && slice.equal(xv.data[:], yv.data[:]) {
            eq = true
        } 

    case SIZE:
        yv := y.(SIZE) or_return
        eq = xv == yv

    case POINT:
        yv := y.(POINT) or_return
        eq = xv == yv

    case RECT:
        yv := y.(RECT) or_return
        eq = xv == yv

    case UUID:
        yv := y.(UUID) or_return
        eq = xv == yv

    case UD_Properties_Map:
        yv := y.(UD_Properties_Map) or_return
        eq = _ud_prop_map_eq(xv, yv)

    case UD_Vec:
        yv := y.(UD_Vec) or_return
        if xv.num != yv.num \
        || xv.type != yv.type {
            break
        }

        switch xt in xv.data {
        case []UD_Property_Value:
            yt := yv.data.([]UD_Property_Value) or_return
            if len(xt) != len(yt) {
                break
            }

            for i in 0..<len(xt) {
                _ud_prop_val_eq(xt[i], yt[i]) or_return
            }
            eq = true

        case []Vec_Diff:
            yt := yv.data.([]Vec_Diff) or_return
            if len(xt) != len(yt) {
                break
            }

            for i in 0..<len(xt) {
                if xt[i].type != yt[i].type {
                    break
                }
                _ud_prop_val_eq(xt[i].data, yt[i].data) or_return
            }
            eq = true

        case nil:
            eq = yv.data == nil
        case:
        }
    case nil:
        eq = y == nil
    case:
    }
    return
}
_ud_prop_map_eq :: proc(x, y: UD_Properties_Map) -> bool {
    if x.key != y.key \
    || x.num != y.num \
    || len(x.properties) != len(y.properties) {
        return false
    }
    for p in 0..<len(x.properties) {
        xp := x.properties[p]
        yp := y.properties[p]

        if xp.type != yp.type \
        || xp.name.length != yp.name.length \
        || !slice.equal(xp.name.data[:], yp.name.data[:]) \
        || !_ud_prop_val_eq(xp.data, yp.data) {
            return false
        }
    }
    return true
}

_user_data_equal :: proc(x, y: User_Data_Chunk) -> bool {
    if x.flags != y.flags \
    || x.text.length != y.text.length \
    || x.color != y.color \
    || x.properties.num != y.properties.num \
    || x.properties.size != y.properties.size \
    || len(x.properties.properties_map) != len(x.properties.properties_map) \
    || !slice.equal(x.text.data[:], y.text.data[:]) {
        return false
    }

    for i in 0..<len(x.properties.properties_map) {
        xm := x.properties.properties_map[i]
        ym := y.properties.properties_map[i]
        _ud_prop_map_eq(xm, ym) or_return
    }
    return true
}

_slice_equal :: proc(x, y: Slice_Chunk) -> bool {
    if x.num_of_keys != y.num_of_keys \
    || x.flags != y.flags \
    || x.name.length != x.name.length \
    || len(x.data) != len(y.data) \
    || !slice.equal(x.name.data[:], y.name.data[:]) {
        return false
    }

    for i in 0..<len(x.data) {
        xk, yk: Slice_Key = x.data[i], y.data[i]
        if xk != yk {
            return false
        }
    }
    return true
}

_tileset_equal :: proc(x, y: Tileset_Chunk) -> bool {
    if x.id != y.id \
    || x.flags != y.flags \
    || x.num_of_tiles != y.num_of_tiles \
    || x.width != y.width \
    || x.height != y.height \
    || x.base_index != y.base_index \
    || x.name.length != x.name.length \
    || x.external != y.external \
    || x.compressed.did_com != y.compressed.did_com \
    || x.compressed.length != y.compressed.length \
    || !slice.equal(x.name.data[:], y.name.data[:]) {
        return false
    }
    return slice.equal(x.compressed.tiles[:], y.compressed.tiles[:])
}

_chunk_equal :: proc{
    _old_palette_256_equal, _old_plette_64_equal, _layer_equal, _cel_equal,
    _cel_extra_equal, _color_profile_equal, _external_files_equal, _mask_equal,
    _path_equal, _tags_equal, _palette_equal, _user_data_equal, _slice_equal,
    _tileset_equal,
}
#+private
package raw_aseprite_file_handler

import "core:slice"
import "core:reflect"

_old_palette_256_equal :: proc(x, y: Old_Palette_256_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.size != y.size {
        return x.size, y.size, typeid_of(Old_Palette_256_Chunk), false
    }
    if len(x.packets) != len(y.packets) {
        return x.packets, y.packets, typeid_of(Old_Palette_256_Chunk), false
    }
    for i in 0..<len(x.packets) {
        xp, yp := x.packets[i], y.packets[i]

        if xp.num_colors != yp.num_colors {
            return xp.num_colors, yp.num_colors, typeid_of(Old_Palette_Packet), false
        }
        if xp.entries_to_skip != yp.entries_to_skip{
            return xp.entries_to_skip, yp.entries_to_skip, typeid_of(Old_Palette_Packet), false
        }
        if len(xp.colors) != len(yp.colors){
            return len(xp.colors), len(yp.colors), typeid_of(Old_Palette_Packet), false
        }

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return xc, yc, typeid_of(Old_Palette_Packet), false
            }
        }
    }
    eq = true
    return
}

_old_plette_64_equal :: proc(x, y: Old_Palette_64_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.size != y.size {
        return x.size, y.size, typeid_of(Old_Palette_64_Chunk), false
    }
    if len(x.packets) != len(y.packets) {
        return x.packets, y.packets, typeid_of(Old_Palette_64_Chunk), false
    }
    for i in 0..<len(x.packets) {
        xp, yp := x.packets[i], y.packets[i]

        if xp.num_colors != yp.num_colors {
            return xp.num_colors, yp.num_colors, typeid_of(Old_Palette_Packet), false
        }
        if xp.entries_to_skip != yp.entries_to_skip{
            return xp.entries_to_skip, yp.entries_to_skip, typeid_of(Old_Palette_Packet), false
        }
        if len(xp.colors) != len(yp.colors){
            return len(xp.colors), len(yp.colors), typeid_of(Old_Palette_Packet), false
        }

        for c in 0..<len(xp.colors) {
            xc, yc := xp.colors[c], yp.colors[c]
            if xc != yc {
                return xc, yc, typeid_of(Old_Palette_Packet), false
            }
        }
    }
    eq = true
    return
}

_layer_equal :: proc(x, y: Layer_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.type != y.type {
        return x.type, y.type, typeid_of(Layer_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Layer_Chunk), false
    } 
    if x.opacity != y.opacity {
        return x.opacity, y.opacity, typeid_of(Layer_Chunk), false
    } 
    if x.blend_mode != y.blend_mode {
        return x.blend_mode, y.blend_mode, typeid_of(Layer_Chunk), false
    }
    if x.child_level != y.child_level {
        return x.child_level, y.child_level, typeid_of(Layer_Chunk), false
    }
    if x.default_width != y.default_width {
        return x.default_width, y.default_width, typeid_of(Layer_Chunk), false
    }
    if x.tileset_index != y.tileset_index {
        return x.tileset_index, y.tileset_index, typeid_of(Layer_Chunk), false
    }
    if x.default_height != y.default_height {
        return x.default_height, y.default_height, typeid_of(Layer_Chunk), false
    }
    if x.name.length != y.name.length {
        return x.name.length, y.name.length, typeid_of(Layer_Chunk), false
    }
    if !slice.equal(x.name.data[:], y.name.data[:]) {
        return x.name.data[:], y.name.data[:], typeid_of(Layer_Chunk), false
    }

    eq = true
    return 
}

_cel_equal :: proc(x, y: Cel_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.x != y.x {
        return y.x, y.x, typeid_of(Cel_Chunk), false
    } 
    if y.y != x.y {
        return x.y, y.y, typeid_of(Cel_Chunk), false
    } 
    if x.type != y.type {
        return x.type, y.type , typeid_of(Cel_Chunk), false
    }
    if x.z_index != y.z_index {
        return x.z_index, y.z_index, typeid_of(Cel_Chunk), false
    }
    if x.layer_index != y.layer_index {
        return x.layer_index, y.layer_index, typeid_of(Cel_Chunk), false
    }
    if x.opacity_level != y.opacity_level {
        return x.opacity_level, y.opacity_level, typeid_of(Cel_Chunk), false
    }

    switch xv in x.cel {
    case Raw_Cel:
        yv, ok := y.cel.(Raw_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Raw_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Raw_Cel), false
        }
        if !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return xv.pixel[:], yv.pixel[:], typeid_of(Raw_Cel), false
        }

    case Linked_Cel:
        yv, ok := y.cel.(Linked_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv != yv {
            return xv, yv, typeid_of(Linked_Cel), false
        }

    case Com_Image_Cel:
        yv, ok := y.cel.(Com_Image_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Com_Image_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Com_Image_Cel), false
        }
        if xv.did_com != yv.did_com {
            return xv.did_com, yv.did_com, typeid_of(Com_Image_Cel), false
        }
        if !slice.equal(xv.pixel[:], yv.pixel[:]) {
            return xv.pixel[:], yv.pixel[:], typeid_of(Com_Image_Cel), false
        }

    case Com_Tilemap_Cel:
        yv, ok := y.cel.(Com_Tilemap_Cel)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Cel_Type), false
        }
        if xv.width != yv.width {
            return xv.width, yv.width, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.height != yv.height {
            return xv.height, yv.height, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.did_com != yv.did_com {
            return xv.did_com, yv.did_com, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_x != yv.bitmask_x {
            return xv.bitmask_x, yv.bitmask_x, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_y != yv.bitmask_y {
            return xv.bitmask_y, yv.bitmask_y, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_id != yv.bitmask_id {
            return xv.bitmask_id, yv.bitmask_id, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bits_per_tile != yv.bits_per_tile {
            return xv.bits_per_tile, yv.bits_per_tile, typeid_of(Com_Tilemap_Cel), false
        }
        if xv.bitmask_diagonal != yv.bitmask_diagonal {
            return xv.bitmask_diagonal, yv.bitmask_diagonal, typeid_of(Com_Tilemap_Cel), false
        }
        if !slice.equal(xv.tiles[:], yv.tiles[:]) {
            return xv.tiles[:], yv.tiles[:], typeid_of(Com_Tilemap_Cel), false
        }

    case nil:
        if y.cel != nil {
            return x.cel, y.cel, typeid_of(Cel_Type), false
        }

    case:
        return x.cel, y.cel, typeid_of(Cel_Type), false
    }
    eq = true
    return
}

_cel_extra_equal :: proc(x, y: Cel_Extra_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x != y { 
        return x, y, typeid_of(Cel_Extra_Chunk), false 
    }
    eq = true
    return 
}

_color_profile_equal :: proc(x, y: Color_Profile_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.type != y.type {
        return x.type, y.type, typeid_of(Color_Profile_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Color_Profile_Chunk), false
    }
    if x.fixed_gamma != y.fixed_gamma {
        return x.fixed_gamma, y.fixed_gamma, typeid_of(Color_Profile_Chunk), false
    }
    if x.icc.length != y.icc.length {
        return x.icc.length, y.icc.length, typeid_of(Color_Profile_Chunk), false
    }
    if !slice.equal(x.icc.data[:], y.icc.data[:]) {
        return x.icc.data[:], y.icc.data[:], typeid_of(Color_Profile_Chunk), false
    }
    eq = true
    return 
}

_external_files_equal :: proc(x, y: External_Files_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.length != y.length {
        return x.length, y.length, typeid_of(External_Files_Chunk), false
    }
    if len(x.entries) != len(y.entries) {
        return len(x.entries), len(y.entries), typeid_of(External_Files_Chunk), false
    }

    for i in 0..<len(x.entries) {
        xe, ye: External_Files_Entry = x.entries[i], y.entries[i]
        if xe.id != ye.id {
            return xe.id, ye.id, typeid_of(External_Files_Entry), false
        }
        if xe.type != ye.type {
            return xe.type,ye.type, typeid_of(External_Files_Entry), false
        }
        if xe.file_name_or_id.length != ye.file_name_or_id.length {
            return xe.file_name_or_id.length, ye.file_name_or_id.length, typeid_of(External_Files_Entry), false
        } 
        if !slice.equal(xe.file_name_or_id.data[:], ye.file_name_or_id.data[:]) {
            return xe.file_name_or_id.data[:], ye.file_name_or_id.data[:], typeid_of(External_Files_Entry), false
        }
    }
    eq = true
    return
}

_mask_equal :: proc(x, y: Mask_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.x != y.x {
        return x.x, y.x, typeid_of(Mask_Chunk), false
    } 
    if x.y != y.y {
        return x.y, y.y, typeid_of(Mask_Chunk), false
    }
    if x.width != y.width {
        return x.width, y.width, typeid_of(Mask_Chunk), false
    }
    if x.height != y.height {
        return x.height, y.height, typeid_of(Mask_Chunk), false
    }
    if x.name.length != y.name.length {
        return x.name.length, y.name.length, typeid_of(Mask_Chunk), false
    }
    if !slice.equal(x.name.data[:], y.name.data[:]) {
        return x.name.data[:], y.name.data[:], typeid_of(Mask_Chunk), false
    }
    if !slice.equal(x.bit_map_data[:], y.bit_map_data[:]) {
        return x.bit_map_data[:], y.bit_map_data[:], typeid_of(Mask_Chunk), false
    }
    eq = true
    return
}

_path_equal :: proc(x, y: Path_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x != y { 
        return x, y, typeid_of(Path_Chunk), false 
    }
    eq = true
    return 
}

_tags_equal :: proc(x, y: Tags_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.number != y.number {
        return x.number, y.number, typeid_of(Tags_Chunk), false
    }
    if len(x.tags) != len(y.tags) {
        return len(x.tags), len(y.tags), typeid_of(Tags_Chunk), false
    }

    for i in 0..<len(x.tags) {
        xt, yt: Tag = x.tags[i], y.tags[i]
        if xt.repeat != yt.repeat {
            return xt.repeat, yt.repeat, typeid_of(Tag), false
        } 
        if xt.to_frame != yt.to_frame {
            return xt.to_frame, yt.to_frame, typeid_of(Tag), false
        } 
        if xt.tag_color != yt.tag_color {
            return xt.tag_color, yt.tag_color, typeid_of(Tag), false
        }
        if xt.from_frame != yt.from_frame {
            return xt.from_frame, yt.from_frame, typeid_of(Tag), false
        }
        if xt.loop_direction != yt.loop_direction {
            return xt.loop_direction, yt.loop_direction, typeid_of(Tag), false
        }
        if xt.name.length != xt.name.length {
            return xt.name.length, xt.name.length, typeid_of(Tag), false
        }
        if !slice.equal(xt.name.data[:], yt.name.data[:]) {
            return xt.name.data[:], yt.name.data[:], typeid_of(Tag), false
        }
        
    }
    eq = true
    return
}

_palette_equal :: proc(x, y: Palette_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.size != y.size {
        return x.size, y.size, typeid_of(Palette_Chunk), false
    } 
    if x.last_index != y.last_index {
        return x.last_index, y.last_index, typeid_of(Palette_Chunk), false
    }
    if x.first_index != y.first_index {
        return x.first_index, y.first_index, typeid_of(Palette_Chunk), false
    }
    if len(x.entries) != len(y.entries) {
        return len(x.entries), len(y.entries), typeid_of(Palette_Chunk), false
    }

    for i in 0..<len(x.entries) {
        xp, yp: Palette_Entry = x.entries[i], y.entries[i]
        if xp.red != yp.red {
            return xp.red, yp.red, typeid_of(Palette_Entry), false
        }
        if xp.blue != yp.blue {
            return xp.blue, yp.blue, typeid_of(Palette_Entry), false
        }
        if xp.green != yp.green {
            return xp.green, yp.green, typeid_of(Palette_Entry), false
        }
        if xp.alpha != yp.alpha {
            return xp.alpha, yp.alpha, typeid_of(Palette_Entry), false
        }
        if xp.flags != yp.flags {
            return xp.flags, yp.flags, typeid_of(Palette_Entry), false
        }
        if xp.name.length != yp.name.length {
            return xp.name.length, yp.name.length, typeid_of(Palette_Entry), false
        }
        if !slice.equal(xp.name.data[:], yp.name.data[:]) {
            return xp.name.data[:], yp.name.data[:], typeid_of(Palette_Entry), false
        }
    }
    eq = true
    return
}

_ud_prop_val_eq :: proc(x,y: UD_Property_Value) -> (a: any, b: any, c: typeid, eq: bool) {
    switch xv in x {
    case BYTE:
        yv, ok := y.(BYTE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(BYTE), false
        }

    case SHORT:
        yv, ok := y.(SHORT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(SHORT), false
        }

    case WORD:
        yv, ok := y.(WORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(WORD), false
        }

    case LONG:
        yv, ok := y.(LONG)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(LONG), false
        }

    case DWORD:
        yv, ok := y.(DWORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(DWORD), false
        }

    case LONG64:
        yv, ok := y.(LONG64)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(LONG64), false
        }

    case QWORD:
        yv, ok := y.(QWORD)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(QWORD), false
        }

    case FIXED:
        yv, ok := y.(FIXED)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(FIXED), false
        }

    case FLOAT:
        yv, ok := y.(FLOAT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(FLOAT), false
        }

    case DOUBLE:
        yv, ok := y.(DOUBLE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(DOUBLE), false
        }

    case STRING:
        yv, ok := y.(STRING)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv.length == yv.length {
            return xv.length, yv.length, typeid_of(STRING), false
        }
        if !slice.equal(xv.data[:], yv.data[:]) {
            return xv.data[:], yv.data[:], typeid_of(STRING), false
        } 

    case SIZE:
        yv, ok := y.(SIZE)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(SIZE), false
        }

    case POINT:
        yv, ok := y.(POINT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(POINT), false
        }

    case RECT:
        yv, ok := y.(RECT)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(RECT), false
        }

    case UUID:
        yv, ok := y.(UUID)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv != yv {
            return xv, yv, typeid_of(UUID), false
        }

    case UD_Properties_Map:
        yv, ok := y.(UD_Properties_Map)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        return _ud_prop_map_eq(xv, yv)

    case UD_Vec:
        yv, ok := y.(UD_Vec)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(UD_Property_Value), false
        }
        if xv.num != yv.num {
            return xv.num, yv.num, typeid_of(UD_Vec), false 
        }
        if xv.type != yv.type {
            return xv.type, yv.type, typeid_of(UD_Vec), false 
        }

        switch xt in xv.data {
        case []UD_Property_Value:
            yt, okt := yv.data.([]UD_Property_Value)
            if !okt {
                return typeid_of(type_of(xt)), reflect.union_variant_typeid(yv), typeid_of(UD_Vec), false
            }
            if len(xt) != len(yt) {
                return len(xt), len(yt), typeid_of(UD_Property_Value), false
            }

            for i in 0..<len(xt) {
                a, b, c, eq = _ud_prop_val_eq(xt[i], yt[i])
                if !eq { return }
            }

        case []Vec_Diff:
            yt, okt := yv.data.([]Vec_Diff)
            if !okt {
                return typeid_of(type_of(xt)), reflect.union_variant_typeid(yv), typeid_of(UD_Vec), false
            }
            if len(xt) != len(yt) {
                return len(xt), len(yt), typeid_of(Vec_Diff), false
            }

            for i in 0..<len(xt) {
                if xt[i].type != yt[i].type {
                    return xt[i].type, yt[i].type, typeid_of(Vec_Diff), false
                }
                a, b, c, eq = _ud_prop_val_eq(xt[i].data, yt[i].data)
                if !eq { return }
            }

        case nil:
            if yv.data != nil {
                return xt, yv.data, typeid_of(Vec_Type), false
            }
        case:
            return x, y, typeid_of(Vec_Type), false
        }
    case nil:
        if y != nil {
            return x, y, typeid_of(UD_Property_Value), false
        }
    case:
        return x, y, typeid_of(UD_Property_Value), false
    }
    eq = true
    return
}
_ud_prop_map_eq :: proc(x, y: UD_Properties_Map) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.key != y.key {
        return x.key, y.key, typeid_of(UD_Properties_Map), false
    }
    if x.num != y.num {
        return x.num, y.num, typeid_of(UD_Properties_Map), false
    }
    if len(x.properties) != len(y.properties) {
        return len(x.properties), len(y.properties), typeid_of(UD_Properties_Map), false
    }

    for p in 0..<len(x.properties) {
        xp := x.properties[p]
        yp := y.properties[p]

        if xp.type != yp.type {
            return xp.type, yp.type, typeid_of(UD_Property), false
        }
        if xp.name.length != yp.name.length {
            return xp.name.length, yp.name.length, typeid_of(UD_Property), false
        }
        if !slice.equal(xp.name.data[:], yp.name.data[:]) {
            return xp.name.data[:], yp.name.data[:], typeid_of(UD_Property), false
        }
        a, b, c, eq = _ud_prop_val_eq(xp.data, yp.data)
        if !eq { return }
    }
    eq = true
    return
}

_user_data_equal :: proc(x, y: User_Data_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(User_Data_Chunk), false
    }
    if x.text.length != y.text.length {
        return x.text.length, y.text.length, typeid_of(User_Data_Chunk), false
    }
    if x.color != y.color {
        return x.color, y.color, typeid_of(User_Data_Chunk), false
    }
    if x.properties.num != y.properties.num {
        return x.properties.num, y.properties.num, typeid_of(User_Data_Chunk), false
    }
    if x.properties.size != y.properties.size {
        return x.properties.size, y.properties.size, typeid_of(User_Data_Chunk), false
    }
    if len(x.properties.properties_map) != len(x.properties.properties_map) {
        return len(x.properties.properties_map), len(x.properties.properties_map), typeid_of(User_Data_Chunk), false
    }
    if !slice.equal(x.text.data[:], y.text.data[:]) {
        return x.text.data[:], y.text.data[:], typeid_of(User_Data_Chunk), false
    }

    for i in 0..<len(x.properties.properties_map) {
        xm := x.properties.properties_map[i]
        ym := y.properties.properties_map[i]
        a, b, c, eq = _ud_prop_map_eq(xm, ym)
        if !eq {
            return xm, ym, typeid_of(UD_Properties_Map), false
        }
    }
    eq = true
    return
}

_slice_equal :: proc(x, y: Slice_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.num_of_keys != y.num_of_keys {
        return x.num_of_keys, y.num_of_keys, typeid_of(Slice_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Slice_Chunk), false
    }
    if x.name.length != x.name.length {
        return x.name.length, x.name.length, typeid_of(Slice_Chunk), false
    }
    if len(x.data) != len(y.data) {
        return len(x.data), len(y.data), typeid_of(Slice_Chunk), false
    }
    if !slice.equal(x.name.data[:], y.name.data[:]) {
        return x.name.data[:], y.name.data[:], typeid_of(Slice_Chunk), false
    }

    for i in 0..<len(x.data) {
        xk, yk: Slice_Key = x.data[i], y.data[i]
        if xk != yk {
            return xk, yk, typeid_of(Slice_Key), false
        }
    }
    eq = true
    return
}

_tileset_equal :: proc(x, y: Tileset_Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.id != y.id {
        return x.id, y.id, typeid_of(Tileset_Chunk), false
    }
    if x.flags != y.flags {
        return x.flags, y.flags, typeid_of(Tileset_Chunk), false
    }
    if x.num_of_tiles != y.num_of_tiles {
        return x.num_of_tiles, y.num_of_tiles, typeid_of(Tileset_Chunk), false
    }
    if x.width != y.width {
        return x.width, y.width, typeid_of(Tileset_Chunk), false
    }
    if x.height != y.height {
        return x.height, y.height, typeid_of(Tileset_Chunk), false
    }
    if x.base_index != y.base_index {
        return x.base_index, y.base_index, typeid_of(Tileset_Chunk), false
    }
    if x.name.length != x.name.length {
        return x.name.length, x.name.length, typeid_of(Tileset_Chunk), false
    }
    if x.external != y.external {
        return x.external, y.external, typeid_of(Tileset_Chunk), false
    }
    if x.compressed.did_com != y.compressed.did_com {
        return x.compressed.did_com, y.compressed.did_com, typeid_of(Tileset_Chunk), false
    }
    if x.compressed.length != y.compressed.length {
        return x.compressed.length, y.compressed.length, typeid_of(Tileset_Chunk), false
    }
    if !slice.equal(x.name.data[:], y.name.data[:]) {
        return x.name.data[:], y.name.data[:], typeid_of(Tileset_Chunk), false
    }
    if !slice.equal(x.compressed.tiles[:], y.compressed.tiles[:]) {
        return x.compressed.tiles[:], y.compressed.tiles[:], typeid_of(Tileset_Chunk), false
    }
    eq = true
    return
}

_chunk_equal :: proc{
    _old_palette_256_equal, _old_plette_64_equal, _layer_equal, _cel_equal,
    _cel_extra_equal, _color_profile_equal, _external_files_equal, _mask_equal,
    _path_equal, _tags_equal, _palette_equal, _user_data_equal, _slice_equal,
    _tileset_equal,
}
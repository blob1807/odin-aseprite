package raw_aseprite_file_handler

import "core:reflect"

chunk_equal :: proc(x, y: Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.type != y.type {
        return x.type, y.type, typeid_of(Chunk), false
    }
    if x.size != y.size {
        return x.size, y.size, typeid_of(Chunk), false
    }

    switch xv in x.data {
    case Old_Palette_256_Chunk:
        yv, ok := y.data.(Old_Palette_256_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Old_Palette_64_Chunk:
        yv, ok := y.data.(Old_Palette_64_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Layer_Chunk:
        yv, ok := y.data.(Layer_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Chunk:
        yv, ok := y.data.(Cel_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Extra_Chunk:
        yv, ok := y.data.(Cel_Extra_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case External_Files_Chunk:
        yv, ok := y.data.(External_Files_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Mask_Chunk:
        yv, ok := y.data.(Mask_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Path_Chunk:
        yv, ok := y.data.(Path_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Tags_Chunk:
        yv, ok := y.data.(Tags_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Palette_Chunk:
        yv, ok := y.data.(Palette_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Color_Profile_Chunk:
        yv, ok := y.data.(Color_Profile_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case User_Data_Chunk:
        yv, ok := y.data.(User_Data_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Slice_Chunk:
        yv, ok := y.data.(Slice_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case Tileset_Chunk:
        yv, ok := y.data.(Tileset_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk_Data), false 
        }
        return _chunk_equal(xv, yv)

    case nil:
        if y.data != nil {
            return x.data, y.data, typeid_of(Chunk_Data), false
        }
    case:
        return
    }

    eq = true
    return
}

frame_equal :: proc(x, y: Frame) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header { 
        return x.header, y.header, typeid_of(ASE_Document), false
    }
    if len(x.chunks) != len(y.chunks) {
        return len(x.chunks), len(y.chunks), typeid_of(ASE_Document), false
    }
    for i in 0..<len(x.chunks) {
        xc, yc := x.chunks[i], y.chunks[i]
        a, b, c, eq = chunk_equal(xc, yc)
        if !eq { return }
    }
    eq = true
    return
}

ase_document_equal :: proc(x, y: ASE_Document) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header { 
        return x.header, y.header, typeid_of(ASE_Document), false
    }
    if len(x.frames) != len(y.frames) {
        return len(x.frames), len(y.frames), typeid_of(ASE_Document), false
    }
    for i in 0..<len(x.frames) {
        xf, yf := x.frames[i], y.frames[i]
        a, b, c, eq = frame_equal(xf, yf)
        if !eq { return }
    }
    eq = true
    return
}

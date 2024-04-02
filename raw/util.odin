package raw_aseprite_file_handler

chunk_equal :: proc(x, y: Chunk) -> bool {
    if x.type != y.type || x.size != y.size {
        return false
    }

    switch xv in x.data {
    case Old_Palette_256_Chunk:
        yv := y.data.(Old_Palette_256_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Old_Palette_64_Chunk:
        yv := y.data.(Old_Palette_64_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Layer_Chunk:
        yv := y.data.(Layer_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Cel_Chunk:
        yv := y.data.(Cel_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Cel_Extra_Chunk:
        yv := y.data.(Cel_Extra_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case External_Files_Chunk:
        yv := y.data.(External_Files_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Mask_Chunk:
        yv := y.data.(Mask_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Path_Chunk:
        yv := y.data.(Path_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Tags_Chunk:
        yv := y.data.(Tags_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Palette_Chunk:
        yv := y.data.(Palette_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Color_Profile_Chunk:
        yv := y.data.(Color_Profile_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case User_Data_Chunk:
        yv := y.data.(User_Data_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Slice_Chunk:
        yv := y.data.(Slice_Chunk) or_return
        _chunk_equal(xv, yv) or_return

    case Tileset_Chunk:
        yv := y.data.(Tileset_Chunk) or_return
        _chunk_equal(xv, yv) or_return
    case nil:
        return y.data == nil
    case:
        return false
    }

    return true
}

frame_equal :: proc(x, y: Frame) -> bool {
    if x.header != y.header || len(x.chunks) != len(y.chunks) { 
        return false 
    }
    for _, i in x.chunks {
        xc, yc := x.chunks[i], y.chunks[i]
        chunk_equal(xc, yc) or_return
    }
    return true
}

ase_document_equal :: proc(x, y: ASE_Document) -> bool {
    if x.header != y.header || len(x.frames) != len(y.frames) { 
        return false 
    }
    for _, i in x.frames {
        xf, yf := x.frames[i], y.frames[i]
        frame_equal(xf, yf) or_return
    }
    return true
}

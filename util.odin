package aseprite_file_handler

import "core:encoding/endian"

get_chunk_type :: proc(c: Chunk) -> (type: WORD, err: Marshal_Error) {
    switch _ in c {
    case Old_Palette_256_Chunk:
        type = WORD(Chunk_Types.old_palette_256)
    case Old_Palette_64_Chunk:
        type = WORD(Chunk_Types.old_palette_64)
    case Layer_Chunk:
        type = WORD(Chunk_Types.layer)
    case Cel_Chunk:
        type = WORD(Chunk_Types.cel)
    case Cel_Extra_Chunk:
        type = WORD(Chunk_Types.cel_extra)
    case Color_Profile_Chunk:
        type = WORD(Chunk_Types.color_profile)
    case External_Files_Chunk:
        type = WORD(Chunk_Types.external_files)
    case Mask_Chunk:
        type = WORD(Chunk_Types.mask)
    case Path_Chunk:
        type = WORD(Chunk_Types.path)
    case Tags_Chunk:
        type = WORD(Chunk_Types.tags)
    case Palette_Chunk:
        type = WORD(Chunk_Types.palette)
    case User_Data_Chunk:
        type = WORD(Chunk_Types.user_data)
    case Slice_Chunk:
        type = WORD(Chunk_Types.slice)
    case Tileset_Chunk:
        type = WORD(Chunk_Types.tileset)
    case:
        err = .Invalid_Chunk_Type
    }
    return
}

get_cel_type :: proc(c: Cel_Type) -> (type: WORD, err: Marshal_Error) {
    switch _ in c {
        case Raw_Cel:
            type = WORD(Cel_Types.Raw)
        case Linked_Cel:
            type = WORD(Cel_Types.Linked_Cel)
        case Com_Image_Cel:
            type = WORD(Cel_Types.Compressed_Image)
        case Com_Tilemap_Cel:
            type = WORD(Cel_Types.Compressed_Tilemap)
        case:
            err = .Invalid_Cel_Type
    }
    return
}

get_property_type :: proc(v: UD_Property_Value) -> (type: WORD, err: Marshal_Error) {
    return
}

tiles_to_u8 :: proc(tiles: []TILE, b: []u8) -> (pos: int, err: Write_Error) {
    next: int
    for t in tiles {
        switch v in t {
        case BYTE:
            pos = next
            next += size_of(BYTE)
            b[pos] = v
        case WORD:
            pos = next
            next += size_of(WORD)
            if !endian.put_u16(b[pos:next], .Little, v) {
                return 0, .Unable_To_Encode_Data
            }
        case DWORD:
            pos = next
            next += size_of(DWORD)
            if !endian.put_u32(b[pos:next], .Little, v) {
                return 0, .Unable_To_Encode_Data
            }
        }
    }
    pos = next
    return
}
package raw_aseprite_file_handler

import "core:math/fixed"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

BYTE   :: u8
WORD   :: u16le
SHORT  :: i16le
DWORD  :: u32le
LONG   :: i32le
FIXED  :: i32le // 16.16
//FIXED  :: struct{h,l: i16le}
FLOAT  :: f32le
DOUBLE :: f64le
QWORD  :: u64le
LONG64 :: i64le

BYTE_N :: [dynamic]BYTE

// TODO: See if adding #packed is better
// https://odin-lang.org/docs/overview/#packed 
STRING :: struct {length: WORD, data: []u8}
POINT :: struct {
    x,y: LONG
}
SIZE :: struct {
    w,h: LONG
}
RECT :: struct {
    origin: POINT,
    size: SIZE,
}

PIXEL_RGBA      :: [4]BYTE
PIXEL_GRAYSCALE :: [2]BYTE
PIXEL_INDEXED   :: BYTE

PIXEL :: union {PIXEL_RGBA, PIXEL_GRAYSCALE, PIXEL_INDEXED}
TILE  :: union {BYTE, WORD, DWORD}

UUID :: [16]BYTE

Color_RGB :: struct{r,g,b: BYTE} // == [3]BYTE
Color_RGBA :: struct{r,g,b,a: BYTE} // == [4]BYTE


FILE_HEADER_SIZE :: 128
File_Header :: struct {
    size: DWORD,
    magic: WORD, // always \xA5E0
    frames: WORD,
    width: WORD,
    height: WORD,
    color_depth: WORD, // 32=RGBA, 16=Grayscale, 8=Indexed
    flags: DWORD, // 1=Layer opacity has valid value
    speed: WORD, // Not longer in use
    transparent_index: BYTE, // for Indexed sprites only
    num_of_colors: WORD, // 0 == 256 for old sprites
    ratio_width: BYTE, // "pixel width/pixel height" if 0 ratio == 1:1
    ratio_height: BYTE, // "pixel width/pixel height" if 0 ratio == 1:1
    x: SHORT,
    y: SHORT,
    grid_width: WORD, // 0 if no grid
    grid_height: WORD, // 0 if no grid
}

FRAME_HEADER_SIZE :: 16
Frame_Header :: struct {
    size: DWORD,
    magic: WORD, // always \xF1FA
    old_num_of_chunks: WORD, // if \xFFFF use new
    duration: WORD, // in milliseconds
    num_of_chunks: WORD, // if 0 use old
}

Frame :: struct {
    size: DWORD,
    type: Chunk_Types,
    data: []Chunk,
}

Chunk :: union{
    Old_Palette_256_Chunk, Old_Palette_64_Chunk, Layer_Chunk, Cel_Chunk, 
    Cel_Extra_Chunk, Color_Profile_Chunk, External_Files_Chunk, Mask_Chunk, 
    Path_Chunk, Tags_Chunk, Palette_Chunk, User_Data_Chunk, Slice_Chunk, 
    Tileset_Chunk,
}

Chunk_Types :: enum(WORD) {
    none,
    old_palette_256 = 0x0004,
    old_palette_64 = 0x0011,
    laayer = 0x2004,
    cel = 0x2005,
    cel_extra = 0x2006,
    color_profile = 0x2007,
    external_files = 0x2008,
    mask = 0x2016, // no longer in use
    path = 0x2017, // not in use
    tags = 0x2018,
    palette = 0x2019,
    user_data = 0x2020,
    slice = 0x2022,
    tileset = 0x2023,
}

Old_Palette_256_Chunk :: struct {
    size: WORD,
    packets: []struct {
        entries_to_skip: BYTE, // start from 0
        num_colors: BYTE, // 0 == 256
        colors: []Color_RGB
    }
}

Old_Palette_64_Chunk :: struct {
    size: WORD,
    packets: []struct {
        entries_to_skip: BYTE, // start from 0
        num_colors: BYTE, // 0 == 256
        colors: []Color_RGB
    }
}

Layer_Chunk_Flags :: enum(WORD) {
    Visiable,
    Editable,
    Lock_Movement,
    Background,
    Prefer_Linked_Cels,
    Group_Collapsed,
    Ref_Layer,
}

Layer_Chunk :: struct {
    //flags: WORD,
    flags: bit_set [Layer_Chunk_Flags; WORD], // to WORD -> transmute(WORD)layer_chunk.flags
    type: enum(WORD) {
        Normal, // image
        Group,
        Tilemap,
    },
    child_level: WORD,
    default_width: WORD, // Ignored
    default_height: WORD, // Ignored
    blend_mode: enum(WORD) {
        Normal,
        Multiply,
        Screen,
        Overlay,
        Darken,
        Lighten,
        Color_Dodge,
        Color_Burn,
        Hard_Light,
        Soft_Light,
        Difference,
        Exclusion,
        Hue,
        Saturation,
        Color,
        Luminosity,
        Addition,
        Subtract,
        Divide,
    },
    opacity: BYTE, // set when header flag is 1
    name: string,
    tileset_index: DWORD, // set if type == Tilemap
}

Raw_Cel :: struct{width, height: WORD, pixel: []PIXEL}
Linked_Cel :: distinct WORD
Com_Image_Cel :: struct{width, height: WORD, pixel: []PIXEL} // raw cel ZLIB compressed
Com_Tilemap_Cel :: struct{
    width, height: WORD,
    bits_per_tile: WORD, // always 32
    bitmask_id: DWORD,
    bitmask_x: DWORD,
    bitmask_y: DWORD,
    bitmask_diagonal: DWORD,
    tiles: []TILE, // ZLIB compressed
}

Cel_Types :: enum(WORD){
    Raw,
    Linked_Cel,
    Compressed_Image,
    Compressed_Tilemap,
}

Cel_Chunk :: struct {
    layer_index: WORD,
    x,y: SHORT,
    opacity_level: BYTE,
    type: Cel_Types,
    z_index: SHORT, //0=default, pos=show n layers later, neg=back
    cel: union{ Raw_Cel, Linked_Cel, Com_Image_Cel, Com_Tilemap_Cel}
}

Cel_Extra_Chunk :: struct {
    flags: bit_set[enum(WORD){Precise}; WORD],
    x,y: FIXED,
    width, height: FIXED,
}

Color_Profile_Chunk :: struct {
    type: enum(WORD) {
        None,
        sRGB,
        ICC,
    },
    flags: bit_set[enum(WORD){Fixed_Gamma}; WORD],
    fixed_gamma: FIXED,
    icc: struct {
        length: DWORD,
        data: []BYTE,
    },
}

External_Files_Chunk :: struct {
    length: DWORD,
    entries: []struct{
        id: DWORD,
        type: enum(BYTE){
            Palette,
            Tileset,
            Properties_Name,
            Tile_Manegment_Name,
        },
        file_name_or_id: string,
    }
}

Mask_Chunk :: struct {
    x,y: SHORT,
    width, height: WORD,
    name: string,
    bit_map_data: []BYTE, //size = height*((width+7)/8)
}

Path_Chunk :: struct{} // never used

Tags_Chunk :: struct {
    nuber: WORD,
    tags: []struct{
        from_frame: WORD,
        to_frame: WORD,
        loop_direction: enum(BYTE){
            Forward,
            Reverse,
            Ping_Pong,
            Ping_Pong_Reverse,
        },
        repeat: WORD,
        tag_color: Color_RGB,
        name: string,
    }
}

Palette_Chunk :: struct {
    size: DWORD,
    first_index: DWORD,
    last_index: DWORD,
    entries: []struct {
        // flags: bit_set[enum(WORD){Has_Name}; WORD],
        flags: enum(WORD){None, Has_Name},
        red, green, blue, alpha: BYTE,
        name: string,
    }
}

user_data_vec :: struct {
    name: DWORD,
    type: WORD,
    data: union {
        []struct{type: WORD, data: []BYTE},
        []BYTE,
    }
}

// TODO: properties_map needs to be reworked into a map
user_data_bit_4 :: struct {
    size: DWORD,
    num: DWORD,
    properties_map: []struct {
        key: DWORD,
        num: DWORD,
        property:[]struct {
            name: string,
            type: WORD,
            data: union {
                BYTE, SHORT, WORD, LONG, DWORD, LONG64, QWORD, FIXED, FLOAT,
                DOUBLE, string, SIZE, RECT, user_data_vec, 
                struct{type: WORD, data: []BYTE}, UUID
            }
        }
    }
}

user_data_chunk_flags :: enum(DWORD) {
    Test,
    Color,
    Properties,
}

User_Data_Chunk :: struct {
    flags: bit_set[user_data_chunk_flags; DWORD],
    data: union{string, Color_RGBA, user_data_bit_4}
}

slice_chunk_flags :: enum(DWORD) {
    Patched_slice, 
    Pivot_Information,
}

Slice_Chunk :: struct {
    num_of_keys: DWORD,
    flags: bit_set[slice_chunk_flags; DWORD],
    name: string,
    data: []struct{
        frams_num: DWORD,
        x,y: LONG,
        width, heigth: DWORD,
        data: union{
            struct{center_x,center_y: LONG, center_width, center_height: DWORD}, 
            struct{pivot_x,pivot_y: LONG}
        }
    }
}

tileset_chunk_flags :: enum(DWORD) {
    include_link_to_external_file,
    Include_tiles_inside_this_file,
    tile_id_is_0,
    auto_mode_x_flip_match,
    ditto_y,
    ditto_diagonal,
}

Tileset_Chunk :: struct {
    id: DWORD,
    flags: bit_set[tileset_chunk_flags; DWORD],
    num_of_tiles: DWORD,
    witdh, height: WORD,
    base_index: SHORT,
    name: string,
    data: union{
        struct{file_id, tileset_id: DWORD},
        struct{length: DWORD, data:[]PIXEL},
    }
}
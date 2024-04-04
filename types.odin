package aseprite_file_handler

import "core:math/fixed"
import "base:runtime"
import "core:io"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

// TODO: Whole File rework.
// Anything set by a flag should be a Maybe(). 
// Only Size/Lengths that can't be gotten by len() are set.

Unmarshal_Errors :: enum {
    Bad_File_Magic_Number,
    Bad_Frame_Magic_Number,
    Bad_User_Data_Type,
}
Unmarshal_Error :: union #shared_nil {Unmarshal_Errors, runtime.Allocator_Error}

Marshal_Errors :: enum {
    Buffer_Not_Big_Enough,
    Invalid_Chunk_Type,
}
Marshal_Error :: union #shared_nil {Marshal_Errors, runtime.Allocator_Error}

Read_Errors :: enum {
    Unable_To_Decode_Data,
    Wrong_Read_Size,
    Array_To_Small,
}
Read_Error :: union #shared_nil {Read_Errors, io.Error, runtime.Allocator_Error}

Write_Errors :: enum {
    Unable_To_Encode_Data,
    Wrong_Write_Size,
    Array_To_Small,
}
Write_Error :: union #shared_nil {Write_Errors, io.Error, runtime.Allocator_Error}

// all writen in le
BYTE   :: u8
WORD   :: u16
SHORT  :: i16
DWORD  :: u32
LONG   :: i32
FIXED  :: fixed.Fixed16_16
FLOAT  :: f32
DOUBLE :: f64
QWORD  :: u64
LONG64 :: i64

BYTE_N :: [dynamic]BYTE

// https://odin-lang.org/docs/overview/#packed
STRING :: string
POINT :: struct {
    x: LONG,
    y: LONG
}
SIZE :: struct {
    w: LONG,
    h: LONG
}
RECT :: struct {
    origin: POINT,
    size: SIZE,
}

PIXEL_RGBA      :: [4]BYTE
PIXEL_GRAYSCALE :: [2]BYTE
PIXEL_INDEXED   :: BYTE

// PIXEL :: union {PIXEL_RGBA, PIXEL_GRAYSCALE, PIXEL_INDEXED}
PIXEL :: u8
TILE  :: union {BYTE, WORD, DWORD}

UUID :: [16]BYTE

Color_RGB :: struct{r,g,b: BYTE} // == [3]BYTE
Color_RGBA :: struct{r,g,b,a: BYTE} // == [4]BYTE

Document :: struct {
    header: File_Header,
    frames: []Frame,
}

Frame :: struct {
    header: Frame_Header,
    chunks: []Chunk,
}

Chunk :: union{
    Old_Palette_256_Chunk, Old_Palette_64_Chunk, Layer_Chunk, Cel_Chunk, 
    Cel_Extra_Chunk, Color_Profile_Chunk, External_Files_Chunk, Mask_Chunk, 
    Path_Chunk, Tags_Chunk, Palette_Chunk, User_Data_Chunk, Slice_Chunk, 
    Tileset_Chunk,
}

FILE_HEADER_SIZE :: 128
File_Header :: struct {
    width: WORD,
    height: WORD,
    color_depth: enum(WORD){
        Indexed=8,
        Grayscale=16,
        RGBA=32
    },
    flags: bit_set[enum(DWORD){Layer_Opacity}; DWORD], // 1=Layer opacity has valid value
    //valid_opacity: bool,
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
    old_num_of_chunks: WORD, // if \xFFFF use new
    duration: WORD, // in milliseconds
    num_of_chunks: WORD, // if 0 use old
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
    packets: []struct {
        entries_to_skip: BYTE, // start from 0
        num_colors: BYTE, // 0 == 256
        colors: []Color_RGB
    }
}

Old_Palette_64_Chunk :: struct {
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

Layer_Blend_Mode :: enum(WORD) {
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
}

Layer_Chunk :: struct {
    flags: bit_set [Layer_Chunk_Flags; WORD], // to WORD -> transmute(WORD)layer_chunk.flags
    type: enum(WORD) {
        Normal, // image
        Group,
        Tilemap,
    },
    child_level: WORD,
    default_width: WORD, // Ignored
    default_height: WORD, // Ignored
    blend_mode: Layer_Blend_Mode,
    opacity: BYTE, // set when header flag is 1
    name: string,
    tileset_index: DWORD, // set if type == Tilemap
}

Raw_Cel :: struct{width, height: WORD, pixel: []PIXEL}
Linked_Cel :: distinct WORD
Com_Image_Cel :: struct{width, height: WORD, pixel: []PIXEL} // raw cel ZLIB compressed

Tile_ID :: enum { byte=0xfffffff1, word=0xffff1fff, dword=0x1fffffff }
Com_Tilemap_Cel :: struct{
    width, height: WORD,
    bits_per_tile: WORD, // always 32
    bitmask_id: Tile_ID,
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
    //flags: bit_set[enum(WORD){Precise}; WORD],
    precise_bounds: bool,
    x: FIXED,
    y: FIXED,
    width: FIXED, 
    height: FIXED,
}

ICC_Profile :: []byte

Color_Profile_Chunk :: struct {
    type: enum(WORD) {
        None,
        sRGB,
        ICC,
    },
    //flags: bit_set[enum(WORD){Fixed_Gamma}; WORD],
    use_fixed_gamma: bool,
    fixed_gamma: FIXED,
    /*icc: struct { // TODO: Yay more libs to make, https://www.color.org/icc1v42.pdf
        length: DWORD,
        data: []BYTE,
    },*/
    icc: Maybe(ICC_Profile),
}

External_Files_Chunk :: struct {
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
    number: WORD,
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
    first_index: DWORD,
    last_index: DWORD,
    entries: []struct {
        //flags: bit_set[enum(WORD){Has_Name}; WORD],
        //has_name: bool,
        color: Color_RGBA,
        name: Maybe(string),
    }
}

UD_Vec_Diff :: struct{
    type: WORD, 
    data: []BYTE
}

UD_Vec_Same :: []BYTE

UD_Vec :: struct {
    name: DWORD,
    type: WORD,
    data: []union {UD_Vec_Diff, UD_Vec_Same}
}

UD_Property_Type :: enum(WORD) {
    Bool, Int8, Uint8, Int16, Uint16, Int64, Uint64,
    Qword, Fixed, Float, Double, String, Point, Size,
    Rect, Vector, Nested_Map, UUID 
}

UD_Property :: struct {
    name: string,
    type: UD_Property_Type,
    data: union {
        BYTE, SHORT, WORD, LONG, DWORD, LONG64, QWORD, FIXED, FLOAT,
        DOUBLE, string, SIZE, RECT, UD_Vec, 
        UD_Properties_Map, UUID
    }
}

UD_Properties_Map :: map[DWORD][]UD_Property

User_Data_Flags :: enum(DWORD) {
    Test,
    Color,
    Properties,
}

User_Data :: struct {
    text: string, 
    color: Color_RGBA, 
    maps: []UD_Properties_Map
}

User_Data_Chunk :: struct {
    flags: bit_set[User_Data_Flags; DWORD],
    data: User_Data
}

Slice_Flags :: enum(DWORD) {
    Patched_slice, 
    Pivot_Information,
}

Slice_Center :: struct{
    x: LONG,
    y: LONG, 
    width: DWORD, 
    height: DWORD
}

Slice_Pivot :: struct{
    x: LONG, 
    y: LONG,
}

Slice_Chunk :: struct {
    flags: bit_set[Slice_Flags; DWORD],
    name: string,
    data: []struct{
        frame_num: DWORD,
        x: LONG,
        y: LONG, 
        width: DWORD, 
        height: DWORD,
        center: Maybe(Slice_Center),
        pivot: Maybe(Slice_Pivot),
    }
}

Tileset_Flags :: enum(DWORD) {
    Include_Link_To_External_File,
    Include_Tiles_Inside_This_File,
    Tile_ID_Is_0,
    Auto_Mode_X_Flip_Match,
    Auto_Mode_Y_Flip_Match,
    Auto_Mode_Diagonal_Flip_Match,
}

Tileset_External :: struct{
    file_id, tileset_id: DWORD
}

Tileset_Compressed :: struct{
    length: DWORD, 
    data: []PIXEL
}

Tileset_Chunk :: struct {
    id: DWORD,
    flags: bit_set[Tileset_Flags; DWORD],
    num_of_tiles: DWORD,
    witdh, height: WORD,
    base_index: SHORT,
    name: string,
    external: Maybe(Tileset_External), 
    compressed: Maybe(Tileset_Compressed),

}
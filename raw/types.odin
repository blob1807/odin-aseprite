package raw_aseprite_file_handler

import "base:runtime"

ASE_Unmarshal_Errors :: enum {
    Bad_File_Magic_Number,
    Bad_Frame_Magic_Number,
    Bad_User_Data_Type,
}
ASE_Unmarshal_Error :: union #shared_nil {ASE_Unmarshal_Errors, runtime.Allocator_Error}

ASE_Marshal_Errors :: enum {
    Buffer_Not_Big_Enough,
    Invalid_Chunk_Type,
}
ASE_Marshal_Error :: union #shared_nil {ASE_Marshal_Errors, runtime.Allocator_Error}

Doc_Upgrade_Errors :: enum {
    Palette_Color_To_Big,
}
Doc_Upgrade_Error :: union #shared_nil {Doc_Upgrade_Errors, runtime.Allocator_Error}

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

// all write in le
BYTE   :: u8
WORD   :: u16
SHORT  :: i16
DWORD  :: u32
LONG   :: i32
FIXED  :: distinct i32 // 16.16
FLOAT  :: f32
DOUBLE :: f64
QWORD  :: u64
LONG64 :: i64

BYTE_N :: [dynamic]BYTE

// https://odin-lang.org/docs/overview/#packed 
STRING :: struct {
    length: WORD, 
    data: []u8
}
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
PIXEL :: BYTE
TILE  :: union {BYTE, WORD, DWORD}

UUID :: [16]BYTE

ASE_Document :: struct {
    header: File_Header,
    frames: []Frame
}

Frame :: struct {
    header: Frame_Header,
    chunks: []Chunk,
}

Chunk :: struct {
    size: DWORD,
    type: Chunk_Types,
    data: Chunk_Data,
}

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
    num_of_chunks: DWORD, // if 0 use old
}

Chunk_Data :: union{
    Old_Palette_256_Chunk, Old_Palette_64_Chunk, Layer_Chunk, Cel_Chunk, 
    Cel_Extra_Chunk, Color_Profile_Chunk, External_Files_Chunk, Mask_Chunk, 
    Path_Chunk, Tags_Chunk, Palette_Chunk, User_Data_Chunk, Slice_Chunk, 
    Tileset_Chunk,
}

Chunk_Types :: enum(WORD) {
    none,
    old_palette_256 = 0x0004,
    old_palette_64 = 0x0011,
    layer = 0x2004,
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

Old_Palette_Packet :: struct {
    entries_to_skip: BYTE, // start from 0
    num_colors: BYTE, // 0 == 256
    colors: [][3]BYTE
}

Old_Palette_256_Chunk :: struct {
    size: WORD,
    packets: []Old_Palette_Packet
}

Old_Palette_64_Chunk :: struct {
    size: WORD,
    packets: []Old_Palette_Packet
}

Layer_Chunk :: struct {
    flags: WORD, // to WORD -> transmute(WORD)layer_chunk.flags
    type: WORD,
    child_level: WORD,
    default_width: WORD, // Ignored
    default_height: WORD, // Ignored
    blend_mode: WORD,
    opacity: BYTE, // set when header flag is 1
    name: STRING,
    tileset_index: DWORD, // set if type == Tilemap
}

Raw_Cel :: struct{
    width: WORD, 
    height: WORD, 
    pixel: []PIXEL
}
Linked_Cel :: distinct WORD
Com_Image_Cel :: struct{
    width: WORD, 
    height: WORD, 
    pixel: []PIXEL,
    did_com: bool,
} // raw cel ZLIB compressed

Com_Tilemap_Cel :: struct{
    width: WORD, 
    height: WORD,
    bits_per_tile: WORD, // always 32
    bitmask_id: DWORD,
    bitmask_x: DWORD,
    bitmask_y: DWORD,
    bitmask_diagonal: DWORD,
    //tiles: []TILE, // ZLIB compressed
    tiles: []BYTE,
    did_com: bool,
}
Cel_Type :: union{ Raw_Cel, Linked_Cel, Com_Image_Cel, Com_Tilemap_Cel }
Cel_Chunk :: struct {
    layer_index: WORD,
    x: SHORT,
    y: SHORT,
    opacity_level: BYTE,
    type: WORD,
    z_index: SHORT, //0=default, pos=show n layers later, neg=back
    cel: Cel_Type
}

Cel_Extra_Chunk :: struct {
    flags: WORD,
    x: FIXED,
    y: FIXED,
    width: FIXED,
    height: FIXED,
}

Color_Profile_Chunk :: struct {
    type: WORD,
    flags: WORD,
    fixed_gamma: FIXED,
    icc: struct { // TODO: Yay more libs to make, https://www.color.org/icc1v42.pdf
        length: DWORD,
        data: []BYTE,
    },
}

External_Files_Entry :: struct{
    id: DWORD,
    type: BYTE,
    file_name_or_id: STRING,
}

External_Files_Chunk :: struct {
    length: DWORD,
    entries: []External_Files_Entry
}

Mask_Chunk :: struct {
    x: SHORT,
    y: SHORT,
    width: WORD, 
    height: WORD,
    name: STRING,
    bit_map_data: []BYTE, //size = height*((width+7)/8)
}

Path_Chunk :: struct{} // never used

Tag :: struct{
    from_frame: WORD,
    to_frame: WORD,
    loop_direction: BYTE,
    repeat: WORD,
    tag_color: [3]BYTE,
    name: STRING,
}

Tags_Chunk :: struct {
    number: WORD,
    tags: []Tag,
}

Palette_Entry :: struct {
    flags: WORD,
    red: BYTE, 
    green: BYTE, 
    blue: BYTE, 
    alpha: BYTE,
    name: STRING,
}

Palette_Chunk :: struct {
    size: DWORD,
    first_index: DWORD,
    last_index: DWORD,
    entries: []Palette_Entry,
}

Vec_Diff :: struct{type: WORD, data: UD_Property_Value}
Vec_Type :: union {[]UD_Property_Value, []Vec_Diff}


UD_Vec :: struct {
    num: DWORD,
    type: WORD,
    data: Vec_Type
}

UD_Property_Value :: union {
    BYTE, SHORT, WORD, LONG, DWORD, LONG64, QWORD, FIXED, FLOAT,
    DOUBLE, STRING, SIZE, POINT, RECT, UUID, 
    UD_Vec, UD_Properties_Map,
}

UD_Property :: struct {
    name: STRING,
    type: WORD,
    data: UD_Property_Value,
}

UD_Properties_Map :: struct {
    key: DWORD,
    num: DWORD,
    properties: []UD_Property
}

UD_Bit_4 :: struct {
    size: DWORD,
    num: DWORD,
    properties_map: []UD_Properties_Map
}

UB_Bit_2 :: [4]BYTE

User_Data_Chunk :: struct {
    flags: DWORD,
    text: STRING,
    color: UB_Bit_2,
    properties: UD_Bit_4,
}

Slice_Center :: struct{
    x: LONG,
    y: LONG, 
    width: DWORD, 
    height: DWORD,
}

Slice_Pivot :: struct{
    x: LONG, 
    y: LONG
}

Slice_Key :: struct{
    frame_num: DWORD,
    x: LONG,
    y: LONG,
    width: DWORD, 
    height: DWORD,
    center: Slice_Center,
    pivot: Slice_Pivot,
}

Slice_Chunk :: struct {
    num_of_keys: DWORD,
    flags: DWORD,
    name: STRING,
    data: []Slice_Key,
}

Tileset_External :: struct{
    file_id: DWORD, 
    tileset_id: DWORD
}

Tileset_Compressed :: struct{
    length: DWORD, 
    tiles: []PIXEL,
    did_com: bool,
}

Tileset_Chunk :: struct {
    id: DWORD,
    flags: DWORD,
    num_of_tiles: DWORD,
    width: WORD, 
    height: WORD,
    base_index: SHORT,
    name: STRING,
    external: Tileset_External, 
    compressed: Tileset_Compressed,
}
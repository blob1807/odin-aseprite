package aseprite_file_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:c"
import "core:math/fixed"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

BYTE   :: u8
WORD   :: u16le
SHORT  :: i16le
DWORD  :: u32le
LONG   :: i32le
//FIXED  :: u32le // 16.16
//FIXED  :: struct{h,l: u16le}
//FIXED  :: fixed.Fixed16_16
FIXED  :: distinct fixed.Fixed(i32le, 16)
FLOAT  :: f32le
DOUBLE :: f64le
QWORD  :: u64le
LONG64 :: i64le

BYTE_N :: [dynamic]BYTE

// TODO: See if adding #packed is better
// https://odin-lang.org/docs/overview/#packed 
// STRING :: struct {length: WORD, data: []u8}
STRING :: string
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
file_header :: struct {
    size: DWORD,
    magic: WORD, // always \xA5E0
    frames: WORD,
    width: WORD,
    height: WORD,
    //color_depth: WORD, // 32=RGBA, 16=Grayscale, 8=Indexed
    color_depth: enum(WORD){ // TODO: is bitset????
        Indexed=8,
        Grayscale=16,
        RGBA=32
    }, 
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
frame_header :: struct {
    size: DWORD,
    magic: WORD, // always \xF1FA
    old_num_of_chunks: WORD, // if \xFFFF use new
    duration: WORD, // in milliseconds
    num_of_chunks: WORD, // if 0 use old
}

chunk :: struct {
    size: DWORD,
    type: Chunk_Types,
    date: []BYTE,
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

old_palette_256_chunk :: struct {
    size: WORD,
    packets: []struct {
        entries_to_skip: BYTE, // start from 0
        num_colors: BYTE, // 0 == 256
        colors: []Color_RGB
    }
}

old_palette_64_chunk :: struct {
    size: WORD,
    packets: []struct {
        entries_to_skip: BYTE, // start from 0
        num_colors: BYTE, // 0 == 256
        colors: []Color_RGB
    }
}

layer_chunk :: struct {
    flags: enum(WORD) { // TODO: is bitset????
        Visiable = 1,
        Editable = 2,
        Lock_Movement = 4,
        Background = 8,
        Prefer_Linked_Cels = 16,
        Group_Collapsed = 32,
        Ref_Layer = 64,
    },
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
    opacity: BYTE, // set header flag is 1
    name: STRING,
    tileset_index: DWORD, // set if type == Tilemap
}

raw_cel :: struct{width, height: WORD, pixel: []PIXEL}
linked_cel :: distinct WORD
com_image_cel :: struct{width, height: WORD, pixel: []PIXEL} // raw cel ZLIB compressed
com_tilemap_cel :: struct{
    width, height: WORD,
    bits_per_tile: WORD, // always 32
    bitmask_id: DWORD,
    bitmask_x: DWORD,
    bitmask_y: DWORD,
    bitmask_diagonal: DWORD,
    tiles: []TILE, // ZLIB compressed
}

cel_chunk :: struct {
    layer_index: WORD,
    x,y: SHORT,
    opacity_level: BYTE,
    type: enum(WORD){
        Raw,
        Linked_Cel,
        Compressed_Image,
        Compressed_Tilemap,
    },
    z_index: SHORT, //0=default, pos=show n layers later, neg=back
    cel: union{ raw_cel, linked_cel, com_image_cel, com_tilemap_cel}
}

cel_extra_chunk :: struct {
    flags: enum(WORD){None,Precise},
    x,y: FIXED,
    width, height: FIXED,
}

color_profile_chunk :: struct {
    type: enum(WORD) {
        none,
        srgb,
        icc,
    },
    flags: WORD,
    fixed_gamma: FIXED,
    icc: struct {
        length: DWORD,
        data: []BYTE,
    },
}

external_files_chunk :: struct {
    length: DWORD,
    entries: []struct{
        id: DWORD,
        type: enum(BYTE){ // TODO: is bitset????
            Palette,
            Tileset,
            Properties_Name,
            Tile_Manegment_Name,
        },
        file_name_or_id: STRING,
    }
}

mask_chunk :: struct {
    x,y: SHORT,
    width, height: WORD,
    name: STRING,
    bit_map_data: []BYTE, //size = height*((width+7)/8)
}

path_chunk :: struct{} // never used

tags_chunk :: struct {
    nuber: WORD,
    tags: []struct{
        from_frame: WORD,
        to_frame: WORD,
        loop_direction: enum(BYTE){ // TODO: is bitset????
            Forward,
            Reverse,
            Ping_Pong,
            Ping_Pong_Reverse,
        },
        repeat: WORD,
        tag_color: Color_RGB,
        name: STRING,
    }
}

palette_chunk :: struct {
    size: DWORD,
    first_index: DWORD,
    last_index: DWORD,
    entries: []struct {
        flags: WORD, // 1=has name
        red, green, blue, alpha: BYTE,
        name: STRING,
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
            name: STRING,
            type: WORD,
            data: union {
                BYTE, SHORT, WORD, LONG, DWORD, LONG64, QWORD, FIXED, FLOAT,
                DOUBLE, STRING, SIZE, RECT, user_data_vec, 
                struct{type: WORD, data: []BYTE}, UUID
            }
        }
    }
}

user_data_chunk :: struct {
    flags: enum(DWORD){ // TODO: is bitset????
        test=1,
        color=2,
        properties=4
    },
    data: union{STRING, Color_RGBA, user_data_bit_4}
}

slice_chunk :: struct {
    num_of_keys: DWORD,
    flags: DWORD, // 1=9-patched slice, 2=pivot information
    name: STRING,
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

tileset_chunk :: struct {
    id: DWORD,
    flags: enum(DWORD){ // TODO: is bitset????
        include_link_to_external_file=1,
        Include_tiles_inside_this_file=2,
        tile_id_is_0=4,
        auto_mode_x_flip_match=8,
        ditto_y=16,
        ditto_diagonal=32,
    },
    num_of_tiles: DWORD,
    witdh, height: WORD,
    base_index: SHORT,
    name: STRING,
    data: union{
        struct{file_id, tileset_id: DWORD},
        struct{length: DWORD, data:[]PIXEL},
    }
}
package aseprite_file_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:c"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

BYTE   :: u8
WORD   :: u16le
SHORT  :: i16le
DWORD  :: u32le
LONG   :: i32le
//FIXED  :: u32le // 16.16
FIXED :: struct {high, low:u16le}
FLOAT  :: f32le
DOUBLE :: f64le
QWORD  :: u64le
LONG64 :: i64le

BYTE_N :: [dynamic]BYTE

// TODO: See if adding #packed is better
// https://odin-lang.org/docs/overview/#packed 
STRING :: struct {
    length: WORD,
    data: []u8
}
POINT :: struct {
    x,y: LONG
}
SIZE :: struct {
    w,h: LONG
}
PECT :: struct {
    origin: POINT,
    size: SIZE,
}

PIXEL_RGBA      :: [4]BYTE
PIXEL_GRAYSCALE :: [2]BYTE
PIXEL_INDEXED   :: BYTE

PIXEL :: union {PIXEL_RGBA, PIXEL_GRAYSCALE, PIXEL_INDEXED}
TILE  :: union {BYTE, WORD, DWORD}

UUID :: [16]BYTE

FILE_HEADER_SIZE :: 128
file_header :: struct {
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
    packets: [dynamic]struct {

    }

}
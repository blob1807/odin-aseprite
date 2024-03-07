package ase_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:c"

BYTE   :: u8
WORD   :: u16le
SHORT  :: i16le
DWORD  :: u32le
LONG   :: i32le
FIXED  :: u32le // 16.16
FLOAT  :: f32le
DOUBLE :: f64le
QWORD  :: u64le
LONG64 :: i64le

BYTE_N :: [dynamic]BYTE

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
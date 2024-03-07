package ase_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "core:c"

BYTE: u8
WORD: u16le
SHORT: i16le
DWORD: u32le
LONG: i32le
FIXED: u32le // 16.16
FLOAT: f32le
DOUBLE: f64le
QWORD: u64le
LONG64: i64le

BYTE_N: [dynamic]BYTE

STRING :: struct {
    length: WORD
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

PIXEL :: union {RGBA: [4]BYTE, GRAYSCALE: [2]BYTE, INDEXED: BYTE}

TILE :: union {BYTE, WORD, DWORD}

UUID: [16]BYTE
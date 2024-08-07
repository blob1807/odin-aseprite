package aseprite_file_handler_utility

import "base:runtime"
import "core:time"

import ase ".."


// Errors
Palette_Error :: enum { 
    None,
    Color_Index_Out_of_Bounds, 
}
Blend_Error :: enum {
    None,
    Invalid_Mode,
    Unequal_Image_Sizes, 
}
Image_Error :: enum {
    None,
    Frame_Index_Out_Of_Bounds, 
    Indexed_BPP_No_Palette,
    Invalid_BPP,
}
Animation_Error :: enum {
    None,
    Tag_Not_Found, 
    Tag_Index_Out_Of_Bounds,
}
User_Data_Error :: enum {
    None,
    No_Parent, 
}
Tileset_Error :: enum {
    None,
}

Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Image_Error, 
    Animation_Error, 
    Tileset_Error, 
    Blend_Error, 
    Palette_Error, 
    User_Data_Error, 
}

// Raw Types
B_Pixel :: [4]u16
Pixel   :: [4]byte
Pixels  :: []byte

Vec2 :: [2]int

Precise_Bounds :: struct {
    // Truely fixpoint but I anit dealing with that shit
    x, y, width, height: f64
}

Cel :: struct {
    using pos: Vec2, 
    width, height: int,
    opacity: int,
    link: int,
    layer: int, 
    z_index: int, // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    raw: Pixels, 
    tilemap: Tilemap,
    extra: Maybe(Precise_Bounds),
}

Tilemap :: struct {
    width: int, 
    height: int, 
    x_flip: uint,
    y_flip: uint,
    diag_flip: uint,
    tiles: []int,
}

Layer :: struct {
    name: string,
    opacity: int,
    visiable: bool,
    index: int, 
    blend_mode: Blend_Mode,
    tileset: int,
}

Frame :: struct {
    duration: i64, // in milliseconds
    cels: []Cel,
}

Tag :: struct {
    from: int,
    to: int,
    direction: ase.Tag_Loop_Dir,
    name: string,
}

Palette :: []Color

Color :: struct {
    using color: Pixel, 
    name: string,
}

// Bits per pixel
Pixel_Depth :: enum {
    Indexed=8,
    Grayscale=16, 
    RGBA=32,
}

// Not needed RN. We'll only ever handle sRGB.
Color_Space :: enum {
    None, sRGB, ICC,
}

Metadata :: struct {
    width: int, 
    height: int, 
    bpp: Pixel_Depth, 
    // spase: Color_Space, 
    // channels: int, Will always be RGBA i.e. 4
}

Slice_Key :: struct {
    frame, x, y, width, height: int,
}

Slice :: struct {
    name: string,
    keys: []Slice_Key
}

Tileset :: struct {
    id: int,
    width: int, 
    height: int, 
    num: int,
    base: int,
    name: string,
    tiles: Pixels, 
}


Info :: struct {
    frames:    []Frame,
    layers:    []Layer,
    tags:      []Tag,
    tilesets:  []Tileset,
    slieces:   []Slice,
    palette:   Palette,
    
    md:        Metadata,
    allocator: runtime.Allocator,
}


// Precomputed Types. They own all their data.
Image :: struct {
    using md: Metadata, 
    data: Pixels, 
}

Animation :: struct {
    fps: int,
    using md: Metadata,
    length: time.Duration, 
    frames: []Pixels, 
}


@(private)
User_Data :: struct {
    chunk: ase.User_Data_Chunk,
    parent: User_Data_Parent, 
    index: int,
}

@(private)
User_Data_Parent :: enum {
    None, Sprite, Tag, Tileset
}

Blend_Mode :: enum {
    Unspecified = -1,
    Src         = -2,
    Merge       = -3,
    Neg_BW      = -4,
    Red_Tint    = -5,
    Blue_Tint   = -6,
    Dst_Over    = -7,

    Normal      = 00,
    Multiply    = 01,
    Screen      = 02,
    Overlay     = 03,
    Darken      = 04,
    Lighten     = 05,
    Color_Dodge = 06,
    Color_Burn  = 07,
    Hard_Light  = 08,
    Soft_Light  = 09,
    Difference  = 10,
    Exclusion   = 11,
    Hue         = 12,
    Saturation  = 13,
    Color       = 14,
    Luminosity  = 15,
    Addition    = 16,
    Subtract    = 17,
    Divide      = 18,
}

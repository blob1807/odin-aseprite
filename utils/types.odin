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
    Cel_Out_Of_Bounds, 
    Cel_Size_Not_Of_BPP,
    Buffer_To_Small,
    Buffer_Size_Not_Match_Metadata,
    Buffer_Not_RGBA,
}
Animation_Error :: enum {
    None,
    Tag_Not_Found, 
    Tag_Index_Out_Of_Bounds,
}

Tileset_Error :: enum {
    None,
    Tileset_Cel_Sizes_Mismatch,
}

Sprite_Sheet_Error :: enum {
    None,
    Frame_To_Big,
    Invalid_Alignment,
    Invalid_Offset,
}

Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Image_Error, 
    Animation_Error, 
    Tileset_Error, 
    Blend_Error, 
    Palette_Error, 
    Sprite_Sheet_Error,
}

// Raw Types
B_Pixel :: [4]i32
Pixel   :: [4]byte
Pixels  :: []byte

Vec2 :: [2]int

Precise_Bounds :: struct {
    // Truely fixpoint but I anit dealing with that shit
    x, y, width, height: f64
}

Bounds :: struct {
    using pos:     Vec2,
    width, height: int,
}

Cel :: struct {
    using bounds: Bounds,
    opacity:      int,
    link:         int,
    layer:        int, 
    z_index:      int, // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    raw:          Pixels `fmt:"-"`, 
    tilemap:      Tilemap,
    extra:        Maybe(Precise_Bounds),
}

Tilemap :: struct {
    width:     int, 
    height:    int, 
    x_flip:    uint,
    y_flip:    uint,
    diag_flip: uint,
    tiles:     []int,
}

Layer :: struct {
    name:          string,
    opacity:       int,
    visiable:      bool,
    is_background: bool,
    index:         int, 
    blend_mode:    Blend_Mode,
    tileset:       int,
}

Frame :: struct {
    duration: i64, // in milliseconds
    cels:     []Cel,
}

Tag :: struct {
    from:      int,
    to:        int,
    direction: ase.Tag_Loop_Dir,
    name:      string,
}

Palette :: []Color

Color :: struct {
    using color: Pixel, 
    name:        string,
}

// Bits per pixel
Pixel_Depth :: enum {
    Indexed   = 8,
    Grayscale = 16, 
    RGBA      = 32,
}

// Not needed RN. We'll only ever handle sRGB.
Color_Space :: enum {
    None, 
    sRGB, 
    ICC,
}

Metadata :: struct {
    width:     int, 
    height:    int, 
    bpp:       Pixel_Depth, 
    trans_idx: u8,
}

Slice_Key :: struct {
    frame:  int, 
    x, y:   int, 
    w, h:   int,
    center: [4]int,
    pivot:  [2]int,
}

Slice :: struct {
    flags: ase.Slice_Flags,
    name:  string,
    keys:  []Slice_Key
}

Tileset :: struct {
    id:     int,
    width:  int, 
    height: int, 
    num:    int,
    name:   string,
    tiles:  Pixels, 
}


Info :: struct {
    frames:   []Frame,
    layers:   []Layer,
    tags:     []Tag,
    tilesets: []Tileset,
    slices:   []Slice,
    palette:  Palette,
    
    md:        Metadata,
    allocator: runtime.Allocator,
}


// Precomputed Types. They own all their data.
Image :: struct {
    using md: Metadata, 
    data:     Pixels `fmt:"-"`, 
}

Animation :: struct {
    using md: Metadata,
    fps:      int,
    length:   time.Duration, 
    frames:   []Pixels, 
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

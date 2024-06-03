package aseprite_file_handler_utility

import "base:runtime"
import "core:image"
import "core:time"

import ase ".."


// Errors
Layer_Error :: enum{}
Layer_Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Layer_Error,
}

Frame_Error :: enum{}
Frame_Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Frame_Error,
}

Image_Error :: enum{}
Image_Errors :: union #shared_nil {
    Image_Error,
    image.General_Image_Error,
    runtime.Allocator_Error, 
}

Animation_Error :: enum{}
Animation_Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Animation_Error,
}

Tileset_Error :: enum{}
Tileset_Errors :: union #shared_nil {
    runtime.Allocator_Error, 
    Tileset_Error,
}

Erros :: union #shared_nil {
    runtime.Allocator_Error, 
    Layer_Error, 
    Frame_Error, 
    Image_Error, 
    Animation_Error, 
    Tileset_Error, 
}

// Raw Types
Pixel :: [4]byte
Pixels :: []byte

Vec2 :: [2]int

Cel :: struct {
    using pos: Vec2, 
    width, height: int,
    opacity: int,
    link: int,
    layer: int, 
    z_index: int, // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
    raw: Pixels, 
}

Layer :: struct {
    name: string,
    opacity: int,
    visiable: bool,
    index: int, 
    blend_mode: Blend_Mode // TODO: Replace with int backed one??
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


// Precomputed Types. They own all their data.
Image :: struct {
    using md: Metadata, 
    data: []byte, 
}

Animation :: struct {
    fps: int,
    using md: Metadata,
    length: time.Duration, 
    frames: [][]byte, 
}

// TODO: A single image or array of tiles? 
// Is it even something i should do?
Tileset :: struct {
    tile_width: int, 
    tile_height: int, 
    tiles: []Pixels, 
}


@(private)
User_Data :: struct {
    chunk: ase.User_Data_Chunk,
    parent: User_Data_Parent, 
    index: int,
}

@(private)
User_Data_Parent :: enum {
    Tag, Tileset, Sprite
}

Blend_Mode :: enum {
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
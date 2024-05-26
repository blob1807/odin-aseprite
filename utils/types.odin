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
Pixel :: image.RGBA_Pixel
Pixels :: []byte

Vec2 :: [2]int

// TODO: Might not be needed. IDK yet
Cel :: struct {
    using md: Metadata, 
    pos: Vec2, 
    opacity: int,
    pixel: Pixels, 
    link: int,
    z_index: int, // https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md#note5
}

Layer :: struct {
    using md: Metadata, 
    name: string,
    opacity: int,
    cels: []Cel,
    visiable: bool,
    index: int, 
    
    blend_mode: ase.Layer_Blend_Mode // TODO: Replace with int backed one?? Is it even needed??
}

Frame :: struct {
    using md: Metadata, 
    duration: i64, // in milliseconds
    layers: []Layer,
    visiable: bool, 
    // tags
}

// Bits per pixel
Color_Depth :: enum {
    None,
    Indexed=8,
    Grayscale=16,
    RGBA=32,
}

Metadata :: struct {
    width: int, 
    height: int, 
    depth: Color_Depth, 
    // channels: int, Will always be RGBA i.e. 4
}


// Precomputed Types
Image :: image.Image

Animation :: struct {
    using md: Metadata,
    fps: int, 
    lenght: time.Duration, 
    frames: []Pixels, 
}

// TODO: A single image or array of tiles?
Tileset :: struct {
    tile_width: int, 
    tile_height: int, 
    tiles: []Pixels, 
}


DEFAULT_ANIMATION :: Animation {}
DEFAULT_FRAME :: Frame {}


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
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
    runtime.Allocator_Error, 
    Image_Error,
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

Layer :: struct {
    using md: Metadata, 
    pos: Vec2,
    name: string,
    opacity: int,
    pixels: Pixels,
    visiable: bool,
    // blend_mode
}

Frame :: struct {
    using md: Metadata, 
    duration: i64, // in milliseconds
    layers: []Layer,
    visiable: bool, 
    // tags
}

Metadata :: struct {
    width: int, 
    height: int, 
    depth: int, 
    // channels: int, Will always be RGBA
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
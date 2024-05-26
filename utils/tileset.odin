package aseprite_file_handler_utility

import "base:runtime"
import "core:image"

import ase ".."

// TODO: Should read in External Files when needed

// Extracts Tileset from Frames with Document Context
tileset_from_doc :: proc(doc: ^ase.Document, tile_width, tile_height: int) {

}
tilesset_from_doc_frames :: proc(frames: []ase.Frame, tile_width, tile_height: int, metadata: Metadata,) {
    
}

tileset_from_layers :: proc(layers: []Layer, tile_width, tile_height: int, metadata: Metadata,) {

}
tilesset_from_frames :: proc(frames: []Frame, tile_width, tile_height: int) {

}

get_tileset :: proc {
    tileset_from_doc, 
    tilesset_from_doc_frames, 
    tileset_from_layers, 
    tilesset_from_frames, 
}
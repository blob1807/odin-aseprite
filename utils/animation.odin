package aseprite_file_handler_utility

import "base:runtime"
import "core:image"

import ase ".."

// TODO: ALL Animation procs should respect Tags
// TODO: Should read in External Files when needed

animation_from_doc :: proc(doc: ^ase.Document, anim: ^Animation) {}
animation_from_doc_frames :: proc(frames: []ase.Frame, anim: ^Animation) {}


// Assumes the Defaults found in Aseprite
animation_from_frames :: proc(frames: []Frame, metadata: Metadata, anim: ^Animation) {}
animation_from_images :: proc(imgs: []Image, metadata: Metadata, anim: ^Animation) {}
animation_from_tileset :: proc(ts: Tileset, metadata: Metadata, anim: ^Animation) {}


get_animation :: proc {
    animation_from_doc, 
    animation_from_doc_frames, 
    animation_from_frames, 
    animation_from_images, 
    animation_from_tileset, 
}

Jarvis make automating things easier please.

### Not Supporting:
- Exteranl Files
- Non-standard versions of Ase


## Bug Fixes:
- [X] Cel writing / blending adding 1
- [X] Blending, again
- [X] Indexed Colour Depth
- [X] Tilemaps
- [X] Errors


### Automation things:
- [X] Frames
- [X] Layers
    - [X] Groups
- [X] Cels
    - [X] Use Precise Bounds from Cel Extra when set
    - [X] Linked Cels
- [X] Palettes new & old
- [X] Metadata
- [X] Tags
- [X] Upscaling
    - [X] Repects pixel depth in assertion
- [X] Tilesets
- [X] Precomputed Images 
- [X] Precomputed Animations 
- [~] Precomputed Tileset 


### Images:
- [X] Basic Image creation
- [X] Covert colour spaces to sRGB
- [X] Colour Palette Indexing
- [X] Change Alpha based on Cel & Layer Opacity
- [X] Nearest Neighbor Upscaling
- [X] See if it's worth using a Fast Alpha algo. Used it.
- [X] Use Tilesets to make images.
    - [X] Support Index & Greyscale Pixel Depths
- [X] Ingore select palette indices
- [X] Blend Modes
    - [X] Use u16s. Ints may still be needed.
    - [X] Find out how Aseprite does them
    - [X] Add Aseprite's license
    - [X] Refactor to use fix arrays in helpers
    - [X] See if refactoring EVERYTHING to use fix arrays
- [ ] Test Blends
    - [X] Normal
    - [X] Multiply
    - [X] Screen
    - [X] Overlay
        - [X] Bug
    - [X] Darken
    - [X] Lighten
    - [X] Color_Dodge
    - [X] Color_Burn
    - [X] Hard_Light
        - [X] Bug
    - [X] Soft_Light
    - [X] Difference
    - [X] Exclusion
    - [X] Hue
        - [X] Bug
    - [X] Saturation
        - [X] Bug
    - [X] Color
    - [X] Luminosity
    - [X] Addition
    - [X] Subtract
        - [X] Bug
    - [X] Divide
    - [ ] Src
    - [X] Merge
    - [ ] Negitive Black White
    - [ ] Red Tint
    - [ ] Blue Tint
    - [ ] Destination Over


### Animations:
- [X] Basic Animation Creation
- [X] Onion Skinning
- [X] Tags
    - [X] Only selected Tag
    - [X] Use Tag durection


### Tilemap:
- [X] Decide if I'm even gonna support this
- [X] Extract Tilesets
- [X] Rename to Tilemap?
- [X] Fix writeing them to cel.raw
    - [X] Check if idxing in ts is right
    - [X] Check if reading ts is right
- [X] Fix when tileset it larger the image size
    size=2x2
    1, 2, 3,
    3, 4, 3,
    2, 2, 3,


### Other things:
- [X] Palettes, to & from GPL 
    - [X] Doc
    - [X] Image
- [X] Images to `core:image`
- [ ] Custom formatter (fmt.set_user_formatters)??? What did I mean by this???
- [X] Add Error returns for deallocation errors
- [X] Use a fucking context which holds everything

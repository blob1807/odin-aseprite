Jarvis make automating things easier please.

### Not Supporting:
- Exteranl Files
- Non-standard versions of Ase

https://github.com/aseprite/aseprite/blob/main/src/doc/blend_funcs.cpp#L400
https://github.com/aseprite/pixman/blob/285b9a907caffeb979322e629d4e57aa42061b5a/pixman/pixman-combine32.h

## Bug Fixes:
- [x] Cel writing / blending adding 1
- [ ] Blending, again
- [x] Indexed Colour Depth
- [ ] Tilemaps
- [ ] Errors
    <!-- 
    tb1 := mem.slice_data_cast([][4]u8, img.data)
    tb2 := mem.slice_data_cast([][4]u8, raw_file_data)
    pix, p, ok := rgba_is_equal(tb1, tb2)
    log.warn("RGBA Images don't match", file, pos, raw, pix, p*channels)
    -->

    - [ ] RGBA Images don't match ..\asefile\blend_hue.aseprite 0 asefile\blend_hue-frame0.raw [[118, 213, 144, 98], [108, 221, 122, 98]] 4
    - [ ] RGBA Images don't match ..\asefile\blend_saturation.aseprite 0 asefile\blend_saturation-frame0.raw [[41, 51, 222, 211], [58, 44, 213, 211]] 0
    - [ ] RGBA Images don't match ..\asefile\blend_saturation_bug.aseprite 0 asefile\blend_saturation_bug-frame0.raw [[102, 102, 217, 255], [175, 71, 186, 255]] 548


### Automation things:
- [x] Frames
- [ ] Layers
    - [ ] Groups
- [x] Cels
    - [x] Use Precise Bounds from Cel Extra when set
    - [x] Linked Cels
- [x] Palettes new & old
- [x] Metadata
- [x] Tags
- [x] Upscaling
    - [x] Repects pixel depth in assertion
- [ ] Tilesets
- [ ] Use User Data
- [ ] Precomputed Images 
- [ ] Precomputed Animations 
- [ ] Precomputed Tileset 


### Images:
- [x] Basic Image creation
- [x] Covert colour spaces to sRGB
- [x] Colour Palette Indexing
- [x] Change Alpha based on Cel & Layer Opacity
- [x] Nearest Neighbor Upscaling
- [x] See if it's worth using a Fast Alpha algo. Used it.
- [x] Use Tilesets to make images.
    - [x] Support Index & Greyscale Pixel Depths
- [x] Ingore select palette indices
- [ ] Blend Modes
    - [x] Use u16s. Ints may still be needed.
    - [x] Find out how Aseprite does them
    - [x] Add Aseprite's license
    - [x] Refactor to use fix arrays in helpers
    - [ ] See if refactoring EVERYTHING to use fix arrays
    - [ ] See if using simd Vecs is better.
- [ ] Test Blends
    - [x] Normal
    - [x] Multiply
    - [x] Screen
    - [ ] Overlay
        - [ ] Bug
    - [x] Darken
    - [x] Lighten
    - [x] Color_Dodge
    - [x] Color_Burn
    - [ ] Hard_Light
        - [ ] Bug
    - [x] Soft_Light
    - [x] Difference
    - [x] Exclusion
    - [ ] Hue
        - [ ] Bug
    - [ ] Saturation
        - [ ] Bug
    - [x] Color
    - [x] Luminosity
    - [x] Addition
    - [ ] Subtract
        - [ ] Bug
    - [x] Divide
    - [ ] Src
    - [x] Merge
    - [ ] Negitive Black White
    - [ ] Red Tint
    - [ ] Blue Tint
    - [ ] Destination Over


### Animations:
- [x] Basic Animation Creation
- [x] Onion Skinning
- [x] Tags
    - [x] Only selected Tag
    - [x] Use Tag durection
- [ ] Tilesets


### Tilemap:
- [x] Decide if I'm even gonna support this
- [x] Extract Tilesets
- [x] Rename to Tilemap?
- [x] Fix writeing them to cel.raw
    - [x] Check if idxing in ts is right
    - [x] Check if reading ts is right
- [ ] Fix when tileset it larger the image size
    size=2x2
    1, 2, 3,
    3, 4, 3,
    2, 2, 3,


### Sprite sheet / Atlas
- [ ] Decide if I'm even gonna support this


### Other things:
- [x] Palettes, to & from GPL 
    - [x] Doc
    - [x] Image
- [x] Images to `core:image`
- [ ] Custom formatter (fmt.set_user_formatters)
- [x] Add Error returns for deallocation errors
- [ ] Use a fucking context which holds everything

A use case very cool.
https://gist.github.com/karl-zylinski/ddc98344cb45468649df8e52d9247dff

\aseprite\laf\os\common\generic_surface.h
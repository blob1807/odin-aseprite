Jarvis make automating things easier please.

### Not Supporting:
- Exteranl Files
- Non-standard versions of Ase


### Automation things:
- [x] Frames
- [x] Layers
- [x] Cels
    - [x] Use Precise Bounds from Cel Extra when set
    - [x] Linked Cels
- [x] Palettes new & old
- [x] Metadata
- [x] Tags
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
- [ ] Use Tilesets to make images.
    - [ ] Support Index & Greyscale Pixel Depths
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
    - [ ] Multiply
    - [ ] Screen
    - [ ] Overlay
    - [ ] Darken
    - [ ] Lighten
    - [ ] Color_Dodge
    - [ ] Color_Burn
    - [ ] Hard_Light
    - [ ] Soft_Light
    - [ ] Difference
    - [ ] Exclusion
    - [ ] Hue
    - [ ] Saturation
    - [ ] Color
    - [ ] Luminosity
    - [ ] Addition
    - [ ] Subtract
    - [ ] Divide
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


### Tilesets:
- [x] Decide if I'm even gonna support this
- [x] Extract Tilesets
- [ ] Rename to Tilemap?


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


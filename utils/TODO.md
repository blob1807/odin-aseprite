Jarvis make automating things easier please.

### Not doing:
- Respecting Exteranl Files


### Automation things:
- [x] Frames
- [x] Layers
- [x] Cels
    - [x] Use Precise Bounds from Cel Extra when set
    - [x] Linked Cels
- [x] Palettes new & old
- [x] Metadata
- [x] Tags
- [ ] Use User Data
- [ ] Precomputed Images 
- [ ] Precomputed Animations 
- [ ] Precomputed Tileset 


### Images:
- [x] Basic Image creation
- [x] Covert colour spaces to sRGB
- [x] Colour Palette Indexing
- [x] Change Alpha based on Cel & Layer Opacity
- [ ] Linear Image scaling
- [X] See if it's worth using a Fast Alpha algo. Used it.
- [ ] Blend Modes
    - [x] Use u16s. Ints may still be needed.
    - [x] Find out how Aseprite does them
    - [ ] Add Aseprite's license
    - [ ] Maybe refactor to use Vecs in helpers
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


### Tilesets:
- [ ] Decide if I'm even gonna support this


### Other things:
- [ ] Palettes, to & from GPL 
    - [ ] Doc
    - [x] Image
- [x] Images to `core:image`
- [ ] Custom formatter (fmt.set_user_formatters)

A use case very cool.
https://gist.github.com/karl-zylinski/ddc98344cb45468649df8e52d9247dff


package aseprite_extentions 

import "base:runtime"
import "core:os"
import "core:io"
import "core:fmt"
import "core:slice"
import "core:strconv"
import "core:strings"
import "core:encoding/xml"
import "core:compress/zlib"
import "core:encoding/json"

import ase ".."

ext_type :: enum {
    None,
    Key,
    Themes,
    Palettes,
    Languages,
    Dithering_Matrices,
    Plugins_with_Scripts,
}

// https://www.aseprite.org/docs/extensions/
main :: proc() { 
    fmt.println("Hellope")
}

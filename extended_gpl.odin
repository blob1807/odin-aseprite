package ase_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "base:runtime"
import "core:strconv"

// https://github.com/aseprite/aseprite/blob/main/docs/gpl-palette-extension.md
// https://developer.gimp.org/core/standards/gpl/

gpl_palette :: struct {
    name: string,
    colums: int,
    rgba: bool,
    colors: [dynamic]gpl_color
}

gpl_color :: struct {
    r,g,b,a: int,
    name: string
}

gpl_parse :: proc(data: string, allocator := context.allocator) -> (parsed: gpl_palette, ok: bool, err: runtime.Allocator_Error) {
    split := strings.split_lines(data, allocator) or_return
    defer delete(split)
    if len(split) < 1 || split[0] != "GIMP Palette" {
        return
    }
    for line in split[1:] {
        line := strings.trim_null(strings.trim_space(line))
        line = strings.to_lower(line, allocator) or_return
        defer delete(line)

        if len(line) < 1 || line[0] == '#' {
        }
        else if strings.has_prefix(line, "channels") {
            if strings.has_suffix(line, "rgba") {
                parsed.rgba = true
            }
        } else if strings.has_prefix(line, "name") {
            parsed.name = strings.trim_prefix(line, "name: ")

        } else if strings.has_prefix(line, "colums") {
            line = strings.trim_prefix(line, "colums: ")
            n, n_ok := strconv.parse_int(line)
            if !n_ok {
                return
            }
            parsed.colums = n
        } else  {

        }
        fmt.println(line)
    }
    return parsed, true, .None
}
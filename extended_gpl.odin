package ase_handler

import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"
import "base:runtime"
import "core:strconv"
import "core:math/linalg"

// https://github.com/aseprite/aseprite/blob/main/docs/gpl-palette-extension.md
// https://developer.gimp.org/core/standards/gpl/

gpl_palette :: struct {
    raw: string,
    name: string,
    colums: int,
    rgba: bool,
    colors: [dynamic]gpl_color
}

gpl_color :: struct {
    using color: struct{r,g,b,a: int},
    name: string
}

gpl_parse_split:: proc(data: string, allocator := context.allocator) -> (parsed: gpl_palette, ok: bool, err: runtime.Allocator_Error) {
    split := strings.split_lines(data, allocator) or_return
    defer delete(split)

    if len(split) <= 1 || split[0] != "GIMP Palette" {
        return
    }
    for line in split[1:] {
        line := strings.trim_null(strings.trim_space(line))

        if len(line) < 1 || line[0] == '#' {
        }
        else if strings.has_prefix(line, "Channels") || strings.has_prefix(line, "channels") {
            if strings.has_suffix(line, "rgba") || strings.has_suffix(line, "RGBA") {
                parsed.rgba = true
            }
        } else if strings.has_prefix(line, "Name") || strings.has_prefix(line, "Name") {
            line = strings.trim_prefix(line, "name: ")
            parsed.name = strings.clone(strings.trim_prefix(line, "Name: "), allocator)

        } else if strings.has_prefix(line, "Colums") || strings.has_prefix(line, "colums") {
            line = strings.trim_prefix(line, "colums: ")
            n, n_ok := strconv.parse_int(strings.trim_prefix(line, "Colums: "))
            if !n_ok {
                return
            }
            parsed.colums = n
        } else {
            color: gpl_color
            line := line
            i := strings.index(line, " ")
            n, n_ok := strconv.parse_int(line[:i])
            if !n_ok {return}
            color.r = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok {return}
            color.g = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            if i == -1 {i = len(line)-1}
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok {return}
            color.b = n

            if parsed.rgba {
                line = strings.trim_left_space(line[i:])
                i = strings.index(line, " ")
                if i == -1 {i = len(line)-1}
                n, n_ok = strconv.parse_int(line[:i])
                if !n_ok {return}
                color.a = n
            }
            color.name = line[i+1:]

            append(&parsed.colors, color)
        }
    }
    return parsed, true, .None
}


gpl_parse :: proc(data: string, allocator := context.allocator) -> (parsed: gpl_palette, ok: bool, err: runtime.Allocator_Error) {
    parsed.raw := data
    s := parsed.raw
    index := strings.index(s, "\n")
    if index == -1 || s[:index] != "GIMP Palette" { return }

    s = s[index+1:]
    index = strings.index(s, "\n")

    for s[0] == '#' { s = s[index+1:];index = strings.index(s, "\n") }
    if index == -1 { return }

    for {
        if i := strings.index(s, "Name: "); i > 0 {
            index = strings.index(s, "\n")
            if index == -1 { index = len(data)-1 }
            parsed.name = s[i:index]
        }
    }
    
    
    for {
        line := strings.trim_null(strings.trim_space(s))

        if len(line) < 1 || line[0] == '#' {
        }
        else if strings.has_prefix(line, "Channels") || strings.has_prefix(line, "channels") {
            if strings.has_suffix(line, "rgba") || strings.has_suffix(line, "RGBA") {
                parsed.rgba = true
            }
        } else if strings.has_prefix(line, "Name") || strings.has_prefix(line, "name") {
            line = strings.trim_prefix(line, "name: ")
            parsed.name = strings.clone(strings.trim_prefix(line, "Name: "), allocator)

        } else if strings.has_prefix(line, "Colums") || strings.has_prefix(line, "colums") {
            line = strings.trim_prefix(line, "colums: ")
            n, n_ok := strconv.parse_int(strings.trim_prefix(line, "Colums: "))
            if !n_ok {
                return
            }
            parsed.colums = n
        } else {
            color: gpl_color
            color.a = 255
            line := line

            i := strings.index(line, " ")
            n, n_ok := strconv.parse_int(line[:i])
            if !n_ok {return}
            color.r = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok {return}
            color.g = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            if i == -1 {i = len(line)-1}
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok {return}
            color.b = n

            if parsed.rgba {
                line = strings.trim_left_space(line[i:])
                i = strings.index(line, " ")
                if i == -1 {i = len(line)-1}
                n, n_ok = strconv.parse_int(line[:i])
                if !n_ok {return}
                color.a = n
            }
            color.name = line[i+1:]

            append(&parsed.colors, color)
        }
        fmt.println(line)
    }
    return parsed, true, .None
}
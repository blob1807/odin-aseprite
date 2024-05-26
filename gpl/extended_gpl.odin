package extended_gpl_handler

import "base:runtime"
import "core:io"
import "core:os"
import "core:fmt"
import "core:strings"
import "core:strconv"

// https://github.com/aseprite/aseprite/blob/main/docs/gpl-palette-extension.md
// https://developer.gimp.org/core/standards/gpl/

GPL_Palette :: struct {
    raw: string,
    name: string,
    colums: int,
    rgba: bool,
    colors: [dynamic]Color
}

Color :: struct {
    //using color: struct{r,g,b,a: int},
    using color: [4]int,
    name: string
}

GPL_Error :: enum {
    None,
    Invalid_Palette,
    Bad_Magic_Number,
    Cant_Parse_Columns,
    Cant_Parse_Color,
}

Errors :: union #shared_nil {GPL_Error, runtime.Allocator_Error}

from_string :: proc(data: string, alloc := context.allocator) -> (parsed: GPL_Palette, err: Errors) {
    parsed.colors = make([dynamic]Color, alloc) or_return

    parsed.raw = data
    s := parsed.raw
    index := strings.index(s, "\n")
    if index == -1 || s[:index] != "GIMP Palette" { 
        return {}, .Bad_Magic_Number 
    }

    s = s[index+1:]
    index = strings.index(s, "\n")

    for s[0] == '#' { 
        s = s[index+1:]
        index = strings.index(s, "\n")
        if index == -1 { 
            return {}, .Invalid_Palette
        }
    }

    for {
        index = strings.index(s, "\n")
        if index == -1 { index = len(s)-1 } 
        if s[0] == '#' {}
        else if strings.has_prefix(s, "Name: ") {
            i := strings.index(s, " ")
            parsed.name = strings.trim_space(s[i:index])

        } else if strings.has_prefix(s, "Channels: ") {
            if strings.has_suffix(s[:index], "RGBA") {
                parsed.rgba = true
            }
            
        } else if strings.has_prefix(s, "Colums: ") {
            i := strings.index(s, " ")
            n, n_ok := strconv.parse_int(strings.trim_space(s[i:index]))
            if !n_ok { return {}, .Cant_Parse_Columns }
            parsed.colums = n
            
        } else {
            break
        }
        s = s[index+1:]
    }    
    
    for len(s) != 0 && index != len(s) {
        index = strings.index(s, "\n")
        if index == -1 { index = len(s) }
        if s[0] != '#' { 
            color: Color
            color.a = 255
            line := strings.trim_left_space(s[:index])

            i := strings.index(line, " ")
            n, n_ok := strconv.parse_int(line[:i])
            if !n_ok { return {}, .Cant_Parse_Color }
            color.r = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok { return {}, .Cant_Parse_Color }
            color.g = n

            line = strings.trim_left_space(line[i:])
            i = strings.index(line, " ")
            if i == -1 {i = len(line)-1}
            n, n_ok = strconv.parse_int(line[:i])
            if !n_ok { return {}, .Cant_Parse_Color }
            color.b = n

            if parsed.rgba {
                line = strings.trim_left_space(line[i:])
                i = strings.index(line, " ")
                if i == -1 {i = len(line)}
                n, n_ok = strconv.parse_int(line[:i])
                if !n_ok { return {}, .Cant_Parse_Color }
                color.a = n
            } else {
                color.a = 255
            }
            color.name = strings.trim_space(line[i:])
            append(&parsed.colors, color) or_return
        }
        if index == len(s) {
            break
        }
        s = s[index+1:]
    }
    return
}

from_bytes :: proc(data: []byte) -> (parsed: GPL_Palette, err: Errors) {
    return from_string(string(data))
}

parse :: proc {from_string, from_bytes}


to_bytes :: proc(pal: GPL_Palette, allocator := context.allocator) -> (data: []byte, err: runtime.Allocator_Error) {
    sb: strings.Builder
    // len("GIMP Palette\nName: \nChannels: RGBA\nColums: 255\n") == 47
    strings.builder_init_len_cap(&sb, 0, 47 + len(pal.colors) + len(pal.name), allocator) or_return
    strings.write_string(&sb, "GIMP Palette\n")

    if len(pal.name) != 0 {
        strings.write_string(&sb, "Name: ")
        strings.write_string(&sb, pal.name)
        strings.write_string(&sb, "\n")
    }
    if pal.colums != 0 {
        strings.write_string(&sb, "Colums: ")
        strings.write_int(&sb, pal.colums)
        strings.write_string(&sb, "\n")
    }

    strings.write_string(&sb, "Channels: RGBA\n#\n")

    for color in pal.colors {
        strings.write_int(&sb, color.r)
        strings.write_byte(&sb, ' ')
        strings.write_int(&sb, color.g)
        strings.write_byte(&sb, ' ')
        strings.write_int(&sb, color.b)
        strings.write_byte(&sb, ' ')
        strings.write_int(&sb, color.a)
        strings.write_byte(&sb, ' ')
        strings.write_string(&sb, color.name)
        strings.write_byte(&sb, '\n')

    }
    data = sb.buf[:]
    return
}

to_string  :: proc(pal: GPL_Palette, allocator := context.allocator) -> (data: string, err: runtime.Allocator_Error) {
    return string(to_bytes(pal, allocator) or_return), .None
}

destroy_gpl :: proc(pal: ^GPL_Palette) {
    delete(pal.colors)
    pal.colors = nil
}
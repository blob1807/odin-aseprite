package aseprite_file_handler_utility

import ir "base:intrinsics"
import "base:runtime"
import "core:reflect"
import "core:strconv"
import "core:slice"

@(require) import "core:fmt"
@(require) import "core:log"

_ :: reflect


@(private)
fast_log_str :: proc(lvl: log.Level, str: string, loc := #caller_location) {
    logger := context.logger
    if logger.procedure == nil { return }
    if lvl < logger.lowest_level { return }
    logger.procedure(logger.data, lvl, str, logger.options, loc)
}

@(private)
fast_log_str_enum :: proc(lvl: log.Level, str: string, val: $T, sep := " ", loc := #caller_location) where ir.type_is_enum(T) {
    logger := context.logger
    if logger.procedure == nil { return }
    if lvl < logger.lowest_level { return }

    s := reflect.enum_string(val)
    buf := make([]u8, len(str) + len(sep) + len(s))
    defer delete(buf)

    n := copy(buf[:], str)
    n += copy(buf[n:], sep)
    copy(buf[n:], s)

    logger.procedure(logger.data, lvl, string(buf), logger.options, loc)
}

@(private)
fast_log_str_num :: proc(lvl: log.Level, str: string, val: $T, sep := " ", loc := #caller_location) where ir.type_is_integer(T) {
    logger := context.logger
    if logger.procedure == nil { return }
    if lvl < logger.lowest_level { return }

    nb: [32]u8
    s := strconv.append_int(nb[:], i64(val), 10)
    buf := make([]u8, len(str) + len(sep) + len(s))
    defer delete(buf)

    n := copy(buf[:], str)
    n += copy(buf[n:], sep)
    copy(buf[n:], s)

    logger.procedure(logger.data, lvl, string(buf), logger.options, loc)
}

@(private)
fast_log :: proc {fast_log_str, fast_log_str_enum, fast_log_str_num}


// Internal Debugging Tool.
format_pixels :: proc(img: Image, x := 4, y := 4, alloc := context.allocator) -> (str: string, err: runtime.Allocator_Error) #optional_allocator_error  {
    ch := int(img.bpp) >> 3

    size := len(img.data) * 3  /*pixel in bytes*/ \ 
    + (len(img.data)/ch - 1)   /*comas*/ \
    + (len(img.data)*2/ch)     /*<space>|*/ \
    + (img.width*img.height*4) /*tile gap*/

    sb := make([dynamic]byte, 0, size) or_return
    buf: [3]byte 

    for n in 0..<len(img.data)/ch { 
        if n %% (img.width) == 0 {
            append(&sb, '|') or_return
        }

        s := strconv.itoa(buf[:], int(img.data[n*ch]))
        for _ in 0..<3-len(s) {
            append(&sb, ' ') or_return
        }
       append(&sb, s) or_return

        for i in 1..<ch {
            append(&sb, ',')
            s = strconv.itoa(buf[:], int(img.data[n*ch+i]))
            for _ in 0..<3-len(s) {
                append(&sb, ' ') or_return
            }
            append(&sb, s) or_return
        }
        append(&sb, '|') or_return

        if (n+1) %% img.width == 0 { 
            append(&sb, '\n') or_return
        }else if (n+1) %% x == 0 { 
            append(&sb, "   |") or_return
        }
        if (n+1) %% (img.width * y) == 0 { 
            append(&sb, '\n') or_return
        }
    }

    return string(sb[:]), nil
}

fill_colour :: proc(data: []u8, colour: [4]u8) {
    slice.fill(slice.reinterpret([][4]u8, data), colour)
}

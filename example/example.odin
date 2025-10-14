package example

import "core:log"
import "core:mem"
import "core:fmt"

import ase ".."

main :: proc() {
    track: mem.Tracking_Allocator
    mem.tracking_allocator_init(&track, context.allocator)
    context.allocator = mem.tracking_allocator(&track)
    context.logger = log.create_console_logger()

    defer {
        log.destroy_console_logger(context.logger)
        for _, leak in track.allocation_map {
            fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
        }

        for bad_free in track.bad_free_array {
            fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
        }
    }

    ase_example()
    read_only()

    single_image()
    all_images()
    nth_image()

    animation()
    animation_tag()
    animation_images()

    sprite_sheet()
    sprite_sheet_custom_rules()
    sprite_sheet_dynamic_count_and_size()
    sprite_sheet_draw_spacing_and_boarder()
    
}

package ase_tests

import "core:os"
import "core:fmt"
import "core:mem"
import "core:slice"
import "core:testing"
import "core:strings"
import fp "core:path/filepath"
import "../raw"


//@(test)
raw_unmarshal :: proc(t: ^testing.T) {
    track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
		}

		for bad_free in track.bad_free_array {
			fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
		}
	}

    data := #load("/asefile/basic-16x16.aseprite")
    doc: raw.ASE_Document
    defer raw.destroy_doc(&doc)

    uerr := raw.unmarshal(data[:], &doc)

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "Unable to unmarshal")
    }
}

//@(test)
raw_marshal :: proc(t: ^testing.T) {
    track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
		}

		for bad_free in track.bad_free_array {
			fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
		}
	}

    data := #load("/asefile/basic-16x16.aseprite")
    doc: raw.ASE_Document
    defer raw.destroy_doc(&doc)

    uerr := raw.unmarshal(data[:], &doc)

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "Unable to unmarshal")
    }

    buf := make_slice([]byte, int(doc.header.size), context.temp_allocator)
    defer delete(buf)
    n, merr := raw.marshal(buf[:], &doc)

    ok = expect(t, merr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, merr))
    if !ok {
        testing.fail_now(t, "Unable to marshal")
    }

    ok = expect(t, slice.equal(buf, data), fmt.tprintf("%s File: /asefile/basic-16x16.aseprite", #procedure))
    if !ok {
        testing.fail_now(t, "Marshaled doesn't match input")
    }

}


//@(test)
raw_full_test :: proc(t: ^testing.T) {
    track: mem.Tracking_Allocator
	mem.tracking_allocator_init(&track, context.allocator)
	context.allocator = mem.tracking_allocator(&track)

	defer {
		for _, leak in track.allocation_map {
			fmt.printf("%v leaked %v bytes\n", leak.location, leak.size)
		}

		for bad_free in track.bad_free_array {
			fmt.printf("%v allocation %p was freed badly\n", bad_free.location, bad_free.memory)
		}
	}
    
    fd, f_err := os.open("./tests", {.Read})
    base_f, FF_err := os.read_dir(fd, 0, context.allocator)
    defer delete(base_f)
    os.close(fd)

    for f in base_f {
        if f.type == .Directory {
            folder_h, f_err := os.open(f.fullpath, {.Read})
            defer os.close(folder_h)
            sprites, ff_err := os.read_dir(folder_h, 0, context.allocator)
            defer delete(sprites)

            for s in sprites {
                if strings.has_suffix(s.name, ".aseprite") || strings.has_suffix(s.name, ".ase") {
                    file_h, f_err := os.open(s.fullpath, {.Read})
                    if f_err != nil do testing.fail_now(t, fmt.tprintf("Failed to open file. %v", f_err))
                    defer os.close(file_h)
                    data, err := os.read_entire_file(file_h, context.allocator)
                    defer delete(data)

                    if err != nil {
                        testing.fail_now(t, fmt.tprintf("Failed to load file. OS error: %v", err))
                    }
                    doc: raw.ASE_Document
                    defer raw.destroy_doc(&doc)

                    unmarshal_err := raw.unmarshal(data[:], &doc)

                    expect(t, err == nil, fmt.tprintf("%s Error: %v, File: %v", #procedure, unmarshal_err, s.fullpath))

                }
            }
        }
    }
}
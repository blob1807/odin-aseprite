package tests

import "core:os"
import fp "core:path/filepath"
import "core:testing"
import "core:fmt"
import "core:strings"
import ase ".."
import "core:mem"
import "core:slice"


@(test)
ase_unmarshal :: proc(t: ^testing.T) {
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
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    uerr := ase.unmarshal(data[:], &doc)

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "Unable to unmarshal")
    }
}

@(test)
ase_marshal :: proc(t: ^testing.T) {
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
    doc: ase.ASE_Document
    defer ase.destroy_doc(&doc)

    uerr := ase.unmarshal(data[:], &doc)

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "Unable to unmarshal")
    }

    buf := make_slice([dynamic]byte, context.temp_allocator)
    defer delete(buf)
    n, merr := ase.marshal(&buf, &doc)

    ok = expect(t, merr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, merr))
    if !ok {
        testing.fail_now(t, "Unable to marshal")
    }

    ok = expect(t, slice.equal(buf, data), fmt.tprintf("%s File: /asefile/basic-16x16.aseprite", #procedure))
    if !ok {
        testing.fail_now(t, "Marshaled doesn't match input")
    }

}


@(test)
ase_full_test :: proc(t: ^testing.T) {
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
    
    fd, f_err := os.open("./tests", os.O_RDONLY, 0)
    base_f, FF_err := os.read_dir(fd, 0)
    defer delete(base_f)
    os.close(fd)

    for f in base_f {
        if f.is_dir {
            folder_h, f_err := os.open(f.fullpath, os.O_RDONLY, 0)
            defer os.close(folder_h)
            sprites, ff_err := os.read_dir(folder_h, 0)
            defer delete(sprites)

            for s in sprites {
                if strings.has_suffix(s.name, ".aseprite") || strings.has_suffix(s.name, ".ase") {
                    file_h, f_err := os.open(s.fullpath, os.O_RDONLY, 0)
                    defer os.close(file_h)
                    data, ok := os.read_entire_file(file_h)
                    defer delete(data)

                    if !ok {
                        testing.fail_now(t, "Failed to load file")
                    }
                    doc: ase.ASE_Document
                    defer ase.destroy_doc(&doc)

                    err := ase.unmarshal(data[:], &doc)

                    expect(t, err == nil, fmt.tprintf("%s Error: %v, File: %v", #procedure, err, s.fullpath))

                }
            }
        }
    }
}
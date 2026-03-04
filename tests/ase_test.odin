package ase_tests

import "base:runtime"
import "core:os"
import "core:fmt"
import "core:log"
import "core:mem"
import "core:slice"
import "core:testing"
import "core:strings"
import fp "core:path/filepath"
import ase ".."


@(test)
ase_unmarshal :: proc(t: ^testing.T) {
    data := #load("/asefile/basic-16x16.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    uerr := ase.unmarshal(&doc, data[:])

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
}

@(test)
ase_marshal :: proc(t: ^testing.T) {
    // FIXME: Marshaler isn't working.
    data := #load("/asefile/basic-16x16.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    uerr := ase.unmarshal(&doc, data[:])

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "Unable to unmarshal")
    }

    buf := make([dynamic]byte, context.temp_allocator)
    defer delete(buf)
    _, merr := ase.marshal(&doc, &buf)

    ok = expect(t, merr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, merr))
    if !ok {
        testing.fail_now(t, "Unable to marshal")
    }

    ok = expect(t, slice.equal(buf[:], data[:]), fmt.tprintf("%s File: /asefile/basic-16x16.aseprite", #procedure))
    if !ok {
        testing.fail_now(t, "Marshaled doesn't match input")
    }

}


@(test)
ase_full_test :: proc(t: ^testing.T) {
    fd, f_err := os.open(".", {.Read})
    base_f, FF_err := os.read_dir(fd, 0, context.allocator)
    defer {
        for b in base_f {
            delete(b.fullpath)
        }
        delete(base_f)
    }
    os.close(fd)
    fmt.println(" ")

    for f in base_f {
        if f.type == .Directory {
            folder_h, f_err := os.open(f.fullpath, {.Read})
            defer os.close(folder_h)
            sprites, ff_err := os.read_dir(folder_h, 0, context.allocator)
            defer { 
                for s in sprites {
                    delete(s.fullpath)
                }
                delete(sprites) 
            }
            fmt.println("Found Dir:", f.name)

            for s in sprites {
                if strings.has_suffix(s.name, ".aseprite") || strings.has_suffix(s.name, ".ase") {
                    file_h, f_err := os.open(s.fullpath, {.Read})
                    defer os.close(file_h)
                    data, err := os.read_entire_file(file_h, context.allocator)
                    defer delete(data)

                    if err != nil {
                        testing.fail_now(t, fmt.tprintf("%s: Failed to load file %v. OS err: %v", #procedure, s.name, err))
                    }
                    fmt.println("   Testing:", s.name)

                    doc: ase.Document
                    defer ase.destroy_doc(&doc)
                    unerr := ase.unmarshal(&doc, data[:])

                    if unerr != nil {
                        log.errorf("%s: Unmarshal Error: %v, File: %v", #procedure, unerr, s.name)
                        continue
                    }

                    buf, bur_err := make([dynamic]byte)
                    defer delete(buf)
                    if bur_err != nil {
                        testing.fail_now(t, fmt.tprintf("%s: Failed to make buffer.", #procedure))
                    }

                    _, merr := ase.marshal(&doc, &buf)
                    if merr != nil {
                        log.errorf("%s: Marshal Error: %v, File: %v", #procedure, merr, s.name)
                        continue
                    }

                    doc2: ase.Document
                    defer ase.destroy_doc(&doc2)
                    unerr2 := ase.unmarshal(&doc2, data[:])

                    if unerr2 != nil {
                        log.errorf("Full Test: Unmarshal Error 2: %v, File: %v", unerr2, s.name)
                        continue
                    }

                    for frame in doc2.frames {
                        for chunk in frame.chunks {
                            #partial switch chunk in chunk {
                                case ase.Cel_Chunk: {
                                    #partial switch cel in chunk.cel {
                                        case ase.Com_Image_Cel: {
                                            if cel.width > 0 && cel.height > 0 && len(cel.pixels) == 0 {
                                                testing.fail_now(t, fmt.tprintf("No pixel generated for cel.", #procedure))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    /*a, b, ty, o := ase.document_equal(doc, doc2)
                    if !o {
                        errorf (
                            t, 
                            "Full Test: Unmarshaled Doc don't equal OG Doc. %s \nx: %v\ny: %v\nType: %v", 
                            s.name, a, b, ty \
                        )
                    }*/
                }
            }
            fmt.println(" ")
        }
    }
}
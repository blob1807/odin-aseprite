package tests

import "core:os"
import fp "core:path/filepath"
import "core:testing"
import "core:fmt"
import "core:strings"
import "../raw"

main :: proc() {
    t := testing.T{}
    raw_unmarshal(&t)
    raw_marshal(&t)
}


@(test)
raw_unmarshal :: proc(t: ^testing.T) {
    fd, f_err := os.open("./tests", os.O_RDONLY, 0)
    base_f, FF_err := os.read_dir(fd, 0)
    defer delete(base_f)
    os.close(fd)

    for f in base_f {
        if f.is_dir {
            fd, f_err = os.open(f.fullpath, os.O_RDONLY, 0)
            sprites, ff_err := os.read_dir(fd, 0)
            os.close(fd)

            for s in sprites {
                if strings.has_suffix(s.name, ".aseprite") || strings.has_suffix(s.name, ".ase") {
                    fd, f_err = os.open(s.fullpath, os.O_RDONLY, 0)
                    data, ok := os.read_entire_file(fd)
                    os.close(fd)

                    if !ok {
                        testing.fail_now(t, "Failed to load file")
                    }
                    doc: raw.ASE_Document
                    //defer raw.destroy_doc(&doc)

                    err := raw.ase_unmarshal(data[:], &doc)

                    expect(t, err == nil, fmt.tprintf("%s Error: %v, File: %v", #procedure, err, s.fullpath))

                }
            }
        }
    }

    
}

@(test)
raw_marshal :: proc(t: ^testing.T) {
    data := #load("/asefile/basic-16x16.aseprite")
    doc: raw.ASE_Document
    //defer raw.destroy_doc(&doc)

    uerr := raw.ase_unmarshal(data[:], &doc)

    ok := expect(t, uerr == nil, fmt.tprintf("%s Error: %v, File: /asefile/basic-16x16.aseprite", #procedure, uerr))
    if !ok {
        testing.fail_now(t, "/asefile/basic-16x16.aseprite")
    }
}

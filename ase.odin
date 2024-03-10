package aseprite_file_handler

import "base:runtime"
import "core:fmt"
import "core:io"
import "core:os"
import "core:strings"
import "core:unicode/utf8"

//https://github.com/aseprite/aseprite/blob/main/docs/ase-file-specs.md

ASE_Unmarshal_Errors :: enum{}
ASE_Unmarshal_Error :: union #shared_nil {ASE_Unmarshal_Errors, runtime.Allocator_Error}

ase_unmarshal :: proc(data: []byte, doc: ^ASE_Document, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    header := data[:FILE_HEADER_SIZE]
    return
}
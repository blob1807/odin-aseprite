package aseprite_extentions 

import "core:c/libc"
import "core:strings"
import "core:fmt"
import "core:reflect"


read_file :: proc(path: string, ext: ext_type) {
    dst := fmt.aprintf(".\\extention_temp\\%v", reflect.enum_name_from_value(ext))
    cmd := fmt.aprintf("powershell -command \"Expand-Archive %v %v\"", path, dst)
    libc.system(strings.clone_to_cstring(cmd))
}
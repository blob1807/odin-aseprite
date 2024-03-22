package aseprite_extentions 

import "core:c/libc"
import "core:strings"
import "core:fmt"
import "core:reflect"
import "core:os"


read_file :: proc(path: string, ext: ext_type) {
    // From: https://superuser.com/a/1473255
    when ODIN_OS == .Windows || ODIN_OS == .Linux || ODIN_OS == .FreeBSD {
        cmd := fmt.aprintf("tar -xf \"%v\"", path)
    } else when ODIN_OS == .Darwin {
        cmd := fmt.aprintf("unzip \"%v\"", path)
    }
    
    dir := fmt.aprintf("./temp_%v", reflect.enum_name_from_value(ext))
    err := os.make_directory(dir)
    if err != 0 {
        fmt.println(err)
        return
    }

    cur_dir := os.get_current_directory()
    err = os.set_current_directory(dir)
    if err != 0 {
        fmt.println(err)
        return
    }
    libc.system(strings.clone_to_cstring(cmd))
}
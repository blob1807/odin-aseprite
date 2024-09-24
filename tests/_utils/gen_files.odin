package odin_aseprite_utils_test

import "core:os"
import "core:os/os2"
import "core:mem"
import "core:fmt"
import "core:image/png"
import fp "core:path/filepath"

import ase "../.."
import "../../utils"

// Set to your Aseprite exe path, needed to make pngs via CLI interface https://www.aseprite.org/docs/cli/
ASE_PATH :: "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Aseprite\\Aseprite.exe"

UTIL_PATH := fp.dir(os.args[0])
TEST_PATH := fp.dir(UTIL_PATH)
PATHS := [?]string{"asefile", "aseprite", "blob", "community"}

SAVE_CMD := []string{ASE_PATH, "-b", "", "--save-as", "{title}-frame{frame}.png"}

main :: proc() {
    fmt.println("Making PNG files")
    os.change_directory(UTIL_PATH)

    for path in PATHS {
        fmt.println("  DIR", path)
        os.make_directory(path)
        os.change_directory(path)

        m, _ := fp.glob(fmt.aprint(TEST_PATH, "/*", sep=""))
        for file in m {
            switch fp.long_ext(file) {
            case ".aseprite", ".ase":
            case: continue
            }
            os2.copy_file(file, ".")
            SAVE_CMD[2] = file

            p, _ := os2.process_start({command=SAVE_CMD})
            _, _ = os2.process_wait(p)
            os.remove(file)
        }
        os.change_directory("..")
    }

    fmt.println("Making RAW files")
    os.change_directory(UTIL_PATH)

    for path in PATHS {
        fmt.println("  DIR", path)
        os.change_directory(path)
        m, _ := fp.glob("./*")
        for file in m {
            if fp.long_ext(file) != ".png" {
                continue
            }
            ib: []byte
            im, _ := png.load(file)
            if im.channels == 3 { 
                ib = make([]u8, im.height * im.width * 4)

                temp1 := mem.slice_data_cast([][4]u8, ib)
                temp2 := mem.slice_data_cast([][3]u8, im.pixels.buf[im.pixels.off:])

                for &pix, p in temp1 {
                    pix.rgb = temp2[p]
                    pix.a = 255
                }
            } else {
                ib = im.pixels.buf[im.pixels.off:]
            }
            os.write_entire_file(fmt.aprint(file, ".raw", sep=""), ib)
        }
        os.change_directory("..")
    }
}
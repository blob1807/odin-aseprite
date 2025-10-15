package odin_aseprite_utils_test

import "core:os"
import "core:os/os2"
import "core:mem"
import "core:fmt"
import "core:image/png"
import "core:strings"
import fp "core:path/filepath"

import ase "../.."
import "../../utils"

// Set to your Aseprite exe path, needed to make pngs via CLI interface https://www.aseprite.org/docs/cli/
ASE_PATH :: "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Aseprite\\Aseprite.exe"
PATHS := [?]string{"asefile", "aseprite", "blob", "community"}
SAVE_CMD := []string{ASE_PATH, "-b", "", "--save-as", "{title}-frame{frame}.png"}


main :: proc() {
    UTIL_PATH := fp.dir(os.args[0])
    TEST_PATH := fp.dir(UTIL_PATH)

    fmt.println(TEST_PATH,)
    fmt.println("Basic Files")
    fmt.println("  Making PNG files")
    os.change_directory(UTIL_PATH)

    for path in PATHS {
        fmt.println("    DIR", path)
        os.make_directory(path)
        os.change_directory(path)

        m, _ := fp.glob(fmt.aprint(TEST_PATH, path, "*", sep="/"))
        for file in m {
            switch fp.long_ext(file) {
            case ".aseprite", ".ase":
            case: continue
            }
            SAVE_CMD[2] = file

            p, _ := os2.process_start({command=SAVE_CMD})
            _, _ = os2.process_wait(p)
        }
        os.change_directory("..")
    }

    fmt.println("  Making RAW files")
    os.change_directory(UTIL_PATH)

    for path in PATHS {
        fmt.println("    DIR", path)
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
            os.write_entire_file(fmt.aprint(strings.trim_suffix(file, ".png"), ".raw", sep=""), ib)
        }
        os.change_directory("..")
    }

    // Sprite Sheets. done file by file.
    {
        fmt.println("Sprite Sheets")
        src := fp.join({TEST_PATH, "blob/marshmallow.aseprite"})

        commands := [][]string {
            { // 16x1
                ASE_PATH, 
                "-b", src,
                "--color-mode", "rgb",
                "--sheet", "marshmallow-sheet-16x1.png"
            },
            { // 16x1 + Trim
                ASE_PATH, 
                "-b", src, "--trim-sprite",  
                "--color-mode", "rgb",
                "--sheet", "marshmallow-sheet-16x1-Trim.png"
            },
            { // 4x4
                ASE_PATH, 
                "-b", src,
                "--sheet-columns", "4",  
                "--color-mode", "rgb",
                "--sheet", "marshmallow-sheet-4x4.png"
            },
            { // 4x4 + Trim
                ASE_PATH, 
                "-b", src, "--trim-sprite",
                "--color-mode", "rgb", 
                "--sheet-columns", "4", 
                "--sheet", "marshmallow-sheet-4x4-Trim.png"
            },
            { // 5x4
                ASE_PATH, 
                "-b", src,
                "--color-mode", "rgb", 
                "--sheet-columns", "5", 
                "--sheet", "marshmallow-sheet-5x4.png"
            },
            { // 5x4 + Trim
                ASE_PATH, 
                "-b", src, "--trim-sprite",
                "--color-mode", "rgb", 
                "--sheet-columns", "5", 
                "--sheet", "marshmallow-sheet-5x4-Trim.png"
            },
            { // 3x6
                ASE_PATH, 
                "-b", src,
                "--color-mode", "rgb", 
                "--sheet-columns", "3", 
                "--sheet", "marshmallow-sheet-3x6.png"
            },
            { // 3x6 + Trim
                ASE_PATH, 
                "-b", src, "--trim-sprite",
                "--color-mode", "rgb", 
                "--sheet-columns", "3", 
                "--sheet", "marshmallow-sheet-3x6-Trim.png"
            },
        }

        fmt.println("  Making PNG & RAW files")
        fmt.println("    DIR blob")

        for cmd in commands {
            cmd[len(cmd)-1] = fp.join({UTIL_PATH, "blob", cmd[len(cmd)-1]})
            p, _ := os2.process_start({command=cmd})
            _, _ = os2.process_wait(p)

            ib: []byte
            im, _ := png.load(cmd[len(cmd)-1])
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
            os.write_entire_file(fmt.aprint(strings.trim_right(cmd[len(cmd)-1], ".png"), ".raw", sep=""), ib)
        }
    }

    fmt.println("DONE")
}


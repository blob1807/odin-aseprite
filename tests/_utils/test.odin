package odin_aseprite_utils_test

import "core:os"
import "core:mem"
import "core:fmt"
import "core:log"
import "core:slice"
import "core:image"
import "core:strconv"
import "core:testing"
import "core:strings"
import "core:unicode/utf8"
import fp "core:path/filepath"

import ase "../.."
import "../../utils"

import stbi "vendor:stb/image"


rgba_is_equal :: proc(a, b: [][4]u8) -> ([2][4]byte, int, bool) {
    if len(a) != len(b) {
        p := min(len(a), len(b))
        return {a[p-1], b[p-1]}, p, false
    }

    for p in 0..<len(a) {
        if a[p] != b[p] {
            if a[p].a == 0 && b[p].a == 0 {
                continue
            }
            return {a[p], b[p]}, p, false
        }
    }

    return {}, -1, true
}

rgb_is_equal :: proc(a, b: [][3]u8) -> ([2][3]byte, int, bool) {
    if len(a) != len(b) {
        p := min(len(a), len(b))
        return {a[p-1], b[p-1]}, p, false
    }

    for p in 0..<len(a) {
        if a[p] != b[p] {
            return {a[p], b[p]}, p, false
        }
    }

    return {}, -1, true
}


test_runner :: proc(t: ^testing.T, PATH: string, SKIP_FILES: []string) {
    files, f_err := fp.glob(fmt.tprint("../", PATH, "/*", sep=""), context.temp_allocator)
    if f_err != nil {
        testing.fail_now(t, fmt.tprint("Failed to glob ase", PATH, f_err))
    }
    if len(files) == 0 {
        testing.fail_now(t, fmt.tprint("Failed to find ase files", PATH))
    }

    raw_files, rf_err := fp.glob(fmt.tprint(PATH, "/*", sep=""), context.temp_allocator)
    if rf_err != nil {
        testing.fail_now(t, fmt.tprint("Failed to glob ./raw", rf_err))
    }
    if len(files) == 0 {
        testing.fail_now(t, fmt.tprint("Failed to find raw files", PATH))
    }

    raws, rm_err := make([dynamic]string)
    if rm_err != nil {
        testing.fail_now(t, fmt.tprint("Failed to make raw", rm_err))
    }
    defer delete(raws)

    file_loop: for file in files {
        if fp.long_ext(file) != ".aseprite" \
        && fp.long_ext(file) != ".ase" {
            continue
        }

        for skip in SKIP_FILES {
            if strings.contains(file, skip) {
                continue file_loop
            }
        }
        
        //log.info("Checking", file)

        defer clear(&raws)
        for rf in raw_files {
            if fp.long_ext(rf) != ".raw" {
                continue
            }

            tf := fp.stem(rf)
            i := strings.index(tf, "-frame")
            if i == -1 {
                if strings.contains(tf, "-sheet") {
                    continue
                }
                testing.fail_now(t, fmt.tprint("Failed to find \"-frame\" in file", file, rf))
            }

            if tf[:i] == fp.stem(file) {
                _, err := append(&raws, rf)
                if err != nil {
                    testing.fail_now(t, fmt.tprint("Failed to append", rf, err))
                }
            }
        }

        if len(raws) == 0 {
            testing.fail_now(t, fmt.tprint("Failed to find raws", file, fp.stem(file)))
        }

        doc: ase.Document
        s := fp.join({"..", PATH, file}, context.temp_allocator)
        unm_err := ase.unmarshal(&doc, s)
        if unm_err != nil {
            testing.fail_now(t, fmt.tprint("Failed to unmarshal", s, unm_err))
        }
        defer ase.destroy_doc(&doc)

        for ch in doc.frames[0].chunks {
            if c, ok := ch.(ase.Color_Profile_Chunk); ok {
                if _, ok = c.icc.?; ok {
                    log.info(file, "has ICC profile")
                    continue file_loop
                }
            } 
        }

        imgs, img_err := utils.get_all_images(&doc)
        if img_err != nil {
            testing.fail_now(t, fmt.tprint("Failed to get all images", file, img_err))
        }
        defer utils.destroy(imgs)

        if len(imgs) != len(raws) {
            testing.fail_now(t, fmt.tprint("Missmatched num imgs got", len(imgs), len(raws), file))
        }

        for img, pos in imgs {
            raw: string
            ts := fmt.tprint("-frame", pos, ".raw", sep="")

            for r in raws {
                if strings.has_suffix(r, ts) {
                    raw = r
                    break
                }
            }

            buf, buf_err := os.read_entire_file_from_filename(raw)
            if buf_err != true {
                testing.fail_now(t, fmt.tprint("Failed read file", raw, buf_err))
            }
            defer delete(buf)

            if len(buf) == len(img.data) {
                tb2 := mem.slice_data_cast([][4]u8, buf)
                tb1 := mem.slice_data_cast([][4]u8, img.data)
                pix, p, ok := rgba_is_equal(tb1, tb2)

                if !ok {
                    testing.fail_now(t, fmt.tprint("RGBA Images don't match\n", file, pos, raw, pix, p*4))
                   // log.warn("RGBA Images don't match", file, pos, raw, pix, p*4)
                }

            } else if len(buf) %% 3 == 0 {
                rgb_buf, rgb_err := utils.remove_alpha(img.data)
                if rgb_err != nil {
                    testing.fail_now(t, fmt.tprint("Failed convert to rgb", file, pos, buf_err))
                }
                defer delete(rgb_buf)

                tb1 := mem.slice_data_cast([][3]u8, rgb_buf)
                tb2 := mem.slice_data_cast([][3]u8, buf)
                pix, p, ok := rgb_is_equal(tb1, tb2)
                
                if !ok {
                    testing.fail_now(t, fmt.tprint("RGB Images don't match", file, pos, raw, pix, p*3))
                    //log.warn("RGB Images don't match", file, pos, raw, pix, p*3)
                }

            } else if len(img.data) / 4 == len(buf) {
                pal, pal_err := utils.get_palette(&doc)
                if pal_err != nil {
                    testing.fail_now(t,  fmt.tprint("Unable to get palette\n", file, pos, raw, pal_err))
                }
                defer utils.destroy(pal)

                img_buf, img_buf_err := make([]u8, len(img.data))
                if img_buf_err != nil {
                    testing.fail_now(t,  fmt.tprint("Unable to make img buf\n", file, pos, raw, img_buf_err))
                }
                defer delete(img_buf)

                lay := utils.Layer {
                    opacity = 255, 
                    visiable = true, 
                    blend_mode = .Normal
                }
                cel := utils.Cel {
                    width = img.width, 
                    height = img.height,
                    raw = buf
                }
                md := utils.Metadata {
                    width = img.width, 
                    height = img.height,
                    bpp = .Indexed
                }

                cel_err := utils.write_cel(img_buf, cel, lay, md, pal)
                if cel_err != nil {
                    testing.fail_now(t,  fmt.tprint("Unable to write cel\n", file, pos, raw, cel_err))
                }

                tb1 := mem.slice_data_cast([][4]u8, img.data)
                tb2 := mem.slice_data_cast([][4]u8, img_buf)
                pix, p, ok := rgba_is_equal(tb1, tb2)
                
                if !ok {
                    testing.fail_now(t, fmt.tprint("Indexed Images don't match\n", file, pos, raw, pix, p*3))
                    //log.warn("Indexed Images don't match", file, pos, raw, pix, p*3)
                }

            } else if len(img.data) / 2 == len(buf) {
                img_buf, img_buf_err := make([]u8, len(img.data))
                if img_buf_err != nil {
                    testing.fail_now(t,  fmt.tprint("Unable to make img buf\n", file, pos, raw, img_buf_err))
                }
                defer delete(img_buf)

                lay := utils.Layer {
                    opacity = 255, 
                    visiable = true, 
                    blend_mode = .Normal
                }
                cel := utils.Cel {
                    width = img.width, 
                    height = img.height,
                    raw = buf
                }
                md := utils.Metadata {
                    width = img.width, 
                    height = img.height,
                    bpp = .Grayscale
                }

                cel_err := utils.write_cel(img_buf, cel, lay, md)
                if cel_err != nil {
                    testing.fail_now(t, fmt.tprint("Unable to write cel\n", file, pos, raw, cel_err))
                }

                tb1 := mem.slice_data_cast([][4]u8, img.data)
                tb2 := mem.slice_data_cast([][4]u8, img_buf)
                pix, p, ok := rgba_is_equal(tb1, tb2)
                
                if !ok {
                    testing.fail_now(t, fmt.tprint("Grayscale Images don't match\n", file, pos, raw, pix, p*3))
                    //log.warn("Grayscale Images don't match", file, pos, raw, pix, p*3)
                }

            } else {
                testing.fail_now(t, fmt.tprint("BPP of Raw Image unknown\n", file, pos, raw, len(buf), len(img.data)))
            }
        }
    }
}

@(test)
blob_test :: proc(t: ^testing.T) {
    PATH :: "blob"
    // Hue & Saturation Bland tests due to being bugged in Aseprite
    SKIP_FILES := [?]string{"hue", "saturation"}
    test_runner(t, PATH, SKIP_FILES[:])
    free_all(context.temp_allocator)
}


@(test)
asefile_test :: proc(t: ^testing.T) {
    PATH :: "asefile"
    // Hue & Saturation Bland tests due to being bugged in Aseprite
    // ICCC colour profile unsupported
    SKIP_FILES := [?]string{"hue", "saturation", "color-curve"}
    test_runner(t, PATH, SKIP_FILES[:])
    free_all(context.temp_allocator)
}

@(test)
aseprite_test :: proc(t: ^testing.T) {
    PATH :: "aseprite"
    // Slices to be implematated, when asked
    // Exteral files unsupported
    SKIP_FILES := [?]string{"file-tests-props", "slices"}
    test_runner(t, PATH, SKIP_FILES[:])
    free_all(context.temp_allocator)
}


@(test)
community_test :: proc(t: ^testing.T) {
    PATH :: "community"
    SKIP_FILES := [?]string{}
    test_runner(t, PATH, SKIP_FILES[:])
    free_all(context.temp_allocator)
}



@(test)
sprite_sheet_test :: proc(t: ^testing.T) {
    ASE_FILE :: "../blob/marshmallow.aseprite"
    FILES :: []string {
        "./blob/marshmallow-sheet-16x1.raw",
        "./blob/marshmallow-sheet-4x4.raw",
        "./blob/marshmallow-sheet-5x4.raw",
        "./blob/marshmallow-sheet-3x6.raw",
        "./blob/marshmallow-sheet-16x1-Trim.raw",
        "./blob/marshmallow-sheet-4x4-Trim.raw",
        "./blob/marshmallow-sheet-5x4-Trim.raw",
        "./blob/marshmallow-sheet-3x6-Trim.raw",
    }

    doc: ase.Document
    uerr := ase.unmarshal(&doc, ASE_FILE)
    defer ase.destroy_doc(&doc)

    info: utils.Info
    ierr := utils.get_info(&doc, &info)
    defer utils.destroy(&info)


    sheet_info := utils.Sprite_Info {
        size = {info.md.width, info.md.height},
        count = len(info.frames)
    }
    rules := utils.Sprite_Write_Rules {
        align = .Middle,
        background_colour = 0
    }
    sheet_16x1, err_16x1 := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_16x1 == nil, "failed to create sheet_16x1", err_16x1) {
        return
    }
    defer utils.destroy(&sheet_16x1)

    data, err := os.read_entire_file_or_err(FILES[0])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[0] + "\" %v", err) {
        return
    }

    ok := slice.equal(sheet_16x1.img.data, data)
    if !testing.expect(t, ok, "sheet_16x1 not equal") {
        delete(data)
        return
    }
    delete(data)

    sheet_info.count = 4
    sheet_4x4, err_4x4 := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_4x4 == nil, "failed to create sheet_4x4", err_4x4) {
        return
    }
    defer utils.destroy(&sheet_4x4)
    
    data, err = os.read_entire_file_or_err(FILES[1])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[1] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_4x4.img.data, data)
    if !testing.expect(t, ok, "sheet_4x4 not equal") {
        delete(data)
        return
    }
    delete(data)


    sheet_info.count = 5
    sheet_5x4, err_5x4 := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_5x4 == nil, "failed to create sheet_5x4", err_5x4) {
        return
    }
    defer utils.destroy(&sheet_5x4)
    
    data, err = os.read_entire_file_or_err(FILES[2])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[2] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_5x4.img.data, data)
    if !testing.expect(t, ok, "sheet_5x4 not equal") {
        delete(data)
        return
    }
    delete(data)


    sheet_info.count = 3
    sheet_3x6, err_3x6 := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_3x6 == nil, "failed to create sheet_3x6", err_3x6) {
        return
    }
    defer utils.destroy(&sheet_3x6)
    
    data, err = os.read_entire_file_or_err(FILES[3])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[3] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_3x6.img.data, data)
    if !testing.expect(t, ok, "sheet_3x6 not equal") {
        delete(data)
        return
    }
    delete(data)


    sheet_info = {
        size = utils.find_min_sprite_size(info, false),
        count = 16,
    }
    rules = {
        align = .Bot_Center,
        shrink_to_pixels = true, 
        ingore_sprite_size = true,
        background_colour = 0,
    }
    sheet_16x1_trim, err_16x1_trim := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_16x1_trim == nil, "failed to create sheet_16x1_trim", err_16x1_trim) {
        return
    }
    defer utils.destroy(&sheet_16x1_trim)

    data, err = os.read_entire_file_or_err(FILES[4])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[2] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_16x1_trim.img.data, data)
    if !testing.expect(t, ok, "sheet_16x1_trim not equal") {
        delete(data)
        return
    }
    delete(data)

    sheet_info.count = 4
    sheet_4x4_trim, err_4x4_trim := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_4x4_trim == nil, "failed to create sheet_4x4_trim", err_4x4_trim) {
        return
    }
    defer utils.destroy(&sheet_4x4_trim)

    data, err = os.read_entire_file_or_err(FILES[5])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[3] + "\" %v", err) {
        return
    }
    delete(data)

    ok = slice.equal(sheet_4x4_trim.img.data, data)
    if !testing.expect(t, ok, "sheet_4x4_trim not equal") {
        return
    }


    sheet_info.count = 5
    sheet_5x4_trim, err_5x4_trim := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_5x4_trim == nil, "failed to create sheet_5x4_trim", err_5x4_trim) {
        return
    }
    defer utils.destroy(&sheet_5x4_trim)
    
    data, err = os.read_entire_file_or_err(FILES[6])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[6] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_5x4_trim.img.data, data)
    if !testing.expect(t, ok, "sheet_5x4_trim not equal") {
        delete(data)
        return
    }
    delete(data)


    sheet_info.count = 3
    sheet_3x6_trim, err_3x6_trim := utils.create_sprite_sheet(info, sheet_info, rules)
    if !testing.expectf(t, err_3x6_trim == nil, "failed to create sheet_3x6_trim", err_3x6_trim) {
        return
    }
    defer utils.destroy(&sheet_3x6_trim)
    
    data, err = os.read_entire_file_or_err(FILES[7])
    if !testing.expectf(t, err == nil, "failed to open file\"" + FILES[7] + "\" %v", err) {
        return
    }

    ok = slice.equal(sheet_3x6_trim.img.data, data)
    if !testing.expect(t, ok, "sheet_3x6_trim not equal") {
        delete(data)
        return
    }
    delete(data)

}


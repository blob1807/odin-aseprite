package example

import "core:log"
import "core:fmt"

import ase "../"
import "../utils"


// Convert first frame into an Image.
single_image :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data[:])
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    img, img_err := utils.get_image(&doc)
    if img_err != nil {
        fmt.eprintln("Fail to get image:", img_err)
        return
    }
    defer utils.destroy(img)
}


// Convert all frames into an Image.
all_images :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data[:])
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    imgs, img_err := utils.get_all_images(&doc)
    if img_err != nil {
        fmt.eprintln("Fail to get all imags:", img_err)
        return
    }
    defer utils.destroy(imgs)
    
}


// Convert nth frame into Images.
nth_image :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data[:])
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    img, img_err := utils.get_image(&doc, 7)
    if img_err != nil {
        fmt.eprintln("Fail to get image:", img_err)
        return
    }
    defer utils.destroy(img)
}


// Create animation frames.
animation :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    anim: utils.Animation
    anim_err := utils.get_animation(&doc, &anim)
    if anim_err != nil {
        fmt.eprintln("Fail to make animation:", anim_err)
        return
    }
    defer utils.destroy(&anim)

}


// Create animation frames, only in tag.
animation_tag :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    anim: utils.Animation
    anim_err := utils.get_animation(&doc, &anim, "Squish")
    if anim_err != nil {
        fmt.eprintln("Fail to make animation:", anim_err)
        return
    }
    defer utils.destroy(&anim)
}


// Create animation frames from bytes.
animation_images :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    imgs, img_err := utils.get_all_images_bytes(&doc)
    if img_err != nil {
        fmt.eprintln("Fail to get all imags:", img_err)
        return
    }
    defer utils.destroy(imgs)

    md := utils.get_metadata(doc.header)

    anim: utils.Animation
    anim_err := utils.get_animation(imgs, md, &anim)
    if anim_err != nil {
        fmt.eprintln("Fail to animation:", anim_err)
        return
    }
    defer utils.destroy(&anim)
}


upscale_image :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    img, img_err := utils.get_image(&doc) // default frame idx is 0
    if img_err != nil {
        fmt.eprintln("Fail to get imag:", img_err)
        return
    }
    defer utils.destroy(img)

    big_img, big_err := utils.upscale_image(img, 100) // default is 10
    if big_err != nil {
        fmt.eprintln("Fail to upscale imag:", big_err)
        return
    }
    defer utils.destroy(big_img)
}

upscale_all_images :: proc() {
    data := #load("../tests/blob/geralt.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    imgs, img_err := utils.get_all_images(&doc)
    if img_err != nil {
        fmt.eprintln("Fail to get all imags:", img_err)
        return
    }
    defer utils.destroy(imgs)

    big_imgs, big_err := utils.upscale_all(imgs) // default is 10
    if big_err != nil {
        fmt.eprintln("Fail to upscale all imags:", img_err)
        return
    }
    defer utils.destroy(big_imgs)
}


sprite_sheet :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    sheet_info := utils.Sprite_Info {
        size  = {48, 48},
        count = 16,
    }

    sheet, sheet_err := utils.create_sprite_sheet(&doc, sheet_info)
    if sheet_err != nil {
        fmt.eprintln("Fail to create sheet:", sheet_err)
        return
    }
    defer utils.destroy(sheet)
}


sprite_sheet_custom_rules :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    sheet_info := utils.Sprite_Info {
        size  = {64, 64},
        count = 4,
    }

    rules := utils.Sprite_Write_Rules {
        align = .Top,
        ingore_bg_layers = true,
        background_colour = {20, 20, 248, 255},
    }

    sheet, sheet_err := utils.create_sprite_sheet(&doc, sheet_info, rules)
    if sheet_err != nil {
        fmt.eprintln("Fail to create sheet:", sheet_err)
        return
    }
    defer utils.destroy(sheet)
}


sprite_sheet_dynamic_count_and_size :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    info: utils.Info
    defer utils.destroy_info(&info)

    info_err := utils.get_info(&doc, &info)
    if info_err != nil {
        fmt.eprintln("Fail to get info:", info_err)
        return
    }

    // Using `find_min_sprite_size` along with the rules below.
    // Allows for a very basic form of sprite packing.
    sheet_info := utils.Sprite_Info {
        size  = utils.find_min_sprite_size(info, false),
        count = len(info.frames),
    }

    /*
    `ingore_sprite_size` allow the sprite's size to be less then the OG file's size.
    `shrink_to_pixels` ensures the position correct.
    `ingore_bg_layers` ensures we're not overwritting what was already writen. 
    */
    rules := utils.Sprite_Write_Rules {
        align = .Middle,
        shrink_to_pixels   = true,
        ingore_bg_layers   = true,
        ingore_sprite_size = true,
        background_colour  = {53, 124, 187, 255},
    }

    sheet, sheet_err := utils.create_sprite_sheet(info, sheet_info, rules)
    if sheet_err != nil {
        fmt.eprintln("Fail to create sheet:", sheet_err)
        return
    }
    defer utils.destroy(sheet)
}


sprite_sheet_draw_spacing_and_boarder :: proc() {
    data := #load("../tests/blob/marshmallow.aseprite")
    doc: ase.Document
    defer ase.destroy_doc(&doc)

    doc_err := ase.unmarshal(&doc, data)
    if doc_err != nil {
        fmt.eprintln("Fail to unmarshal:", doc_err)
        return
    }

    sheet_info := utils.Sprite_Info {
        size  = {48, 48},
        count = 6,
        spacing = 2,
        boarder = 5,
    }

    sheet, sheet_err := utils.create_sprite_sheet(&doc, sheet_info)
    if sheet_err != nil {
        fmt.eprintln("Fail to create sheet:", sheet_err)
        return
    }
    defer utils.destroy(sheet)

    utils.draw_sheet_spacing(&sheet, {255, 0, 0, 255}, false)
    utils.draw_sheet_boarder(&sheet, {255, 0, 0, 255})
}

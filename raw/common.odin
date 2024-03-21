package raw_aseprite_file_handler

destroy_doc :: proc(doc: ^ASE_Document) {
    destroy_map :: proc(m: UD_Properties_Map) {
        for p in m.properties {
            destroy_value(p.data)
        }
    }
    
    destroy_value :: proc(p: UD_Property_Value) {
        #partial switch v in p {
        case UD_Properties_Map:
            destroy_map(p.(UD_Properties_Map))
            delete(v.properties)
        case UD_Vec:
            if v.type == 0 {
                for n in v.data.([]Vec_Diff) {
                    destroy_value(n.data)
                }
                delete(v.data.([]Vec_Diff))
            } else {
                for n in v.data.([]UD_Property_Value) {
                    destroy_value(n)
                }
                delete(v.data.([]UD_Property_Value))
            }
        }
    }

    for &frame in doc.frames {
        for &chunk in frame.chunks {
            #partial switch c in chunk.data {
            case Old_Palette_256_Chunk:
                for pal in c.packets {
                    delete(pal.colors)
                }
                delete(c.packets)
            
            case Old_Palette_64_Chunk:
                for pal in c.packets {
                    delete(pal.colors)
                }
                delete(c.packets)

            case Cel_Chunk:
                #partial switch cel in c.cel {
                case Com_Tilemap_Cel:
                    delete(cel.tiles)
                case Com_Image_Cel:
                    delete(cel.pixel)
                case Raw_Cel:
                    delete(cel.pixel)
                }

            case External_Files_Chunk:
                delete(c.entries)

            case Mask_Chunk:
                delete(c.bit_map_data)

            case Tags_Chunk:
                delete(c.tags)

            case Palette_Chunk:
                delete(c.entries)

            case User_Data_Chunk:
                if (c.flags & 4) == 4 {
                    for mp in c.properties.properties_map {
                        destroy_map(mp)
                        delete(mp.properties)
                    }
                    delete(c.properties.properties_map)
                }
                
            case Slice_Chunk:
                delete(c.data)

            case Tileset_Chunk:
                if (c.flags & 2) == 2 && c.compressed.did_com {
                    delete(c.compressed.tiles)
                }
            }
        }
        delete(frame.chunks)
    }

    delete(doc.frames)
}

// FIXME: Needs to be finished before use.
update_doc :: proc(doc: ^ASE_Document, assume_flags := false) {
    if assume_flags { update_flags(doc) }
    update_types(doc)
    update_sizes(doc)
}

update_flags :: proc(doc: ^ASE_Document) {
    for &frame in doc.frames {
        for &chunk in frame.chunks {
            #partial switch &v in chunk.data {
            case Palette_Chunk:
                for &entry in v.entries {
                    if len(entry.name.data) != 0 {
                        entry.flags = 1
                    } else {
                        entry.flags = 0
                    }
                }

            case User_Data_Chunk:
                if len(v.text.data) != 0 {
                    v.flags |= 1
                } else {
                    v.flags &~= 1
                }

                if len(v.properties.properties_map) != 0 {
                    v.flags |= 4
                } else {
                    v.flags &~= 4
                }
                
            case Tileset_Chunk:
                if len(v.compressed.tiles) != 0 {
                    v.flags |= 2
                } else {
                    v.flags &~= 2
                }
            }
        }
    }
}

update_types :: proc(doc: ^ASE_Document) {
    update_value :: proc(value: ^UD_Property_Value) -> (prop_type: WORD) {
        switch &pt in value {
        case BYTE:   prop_type = 0x0003
        case SHORT:  prop_type = 0x0004
        case WORD:   prop_type = 0x0005
        case LONG:   prop_type = 0x0006
        case DWORD:  prop_type = 0x0007
        case LONG64: prop_type = 0x0008
        case QWORD:  prop_type = 0x0009
        case FIXED:  prop_type = 0x000A
        case FLOAT:  prop_type = 0x000B
        case DOUBLE: prop_type = 0x000C
        case STRING: prop_type = 0x000D
        case POINT:  prop_type = 0x000E
        case SIZE:   prop_type = 0x000F
        case RECT:   prop_type = 0x0010
        case UUID:   prop_type = 0x0013
    
        case UD_Vec:
            prop_type = 0x0011
            switch &vt in pt.data {
                case []Vec_Diff:
                    for &dt in vt {
                        dt.type = update_value(&dt.data)
                    }
                case []UD_Property_Value:
                    if len(vt) != 0 {
                        pt.type = update_value(&vt[0])
                    }
            }
    
        case UD_Properties_Map:
            prop_type = 0x0012
            for &prop in pt.properties {
                prop.type = update_value(&prop.data)
            }
        }
        return
    }

    for &frame in doc.frames {
        for &chunk in frame.chunks {
            switch &v in chunk.data {
            case Old_Palette_256_Chunk: chunk.type = .old_palette_256
            case Old_Palette_64_Chunk:  chunk.type = .old_palette_64
            case Layer_Chunk:      chunk.type = .layer
            case Cel_Extra_Chunk:  chunk.type = .cel_extra
            case External_Files_Chunk: chunk.type = .external_files
            case Mask_Chunk:    chunk.type = .mask
            case Path_Chunk:    chunk.type = .path
            case Tags_Chunk:    chunk.type = .tags
            case Palette_Chunk: chunk.type = .palette
            case Slice_Chunk:   chunk.type = .slice
            case Tileset_Chunk: chunk.type = .tileset
                
            case Cel_Chunk:
                chunk.type = .cel
                switch cel in v.cel {
                case Raw_Cel: v.type = 0
                case Linked_Cel: v.type = 1
                case Com_Image_Cel: v.type = 2
                case Com_Tilemap_Cel: v.type = 3
                }

            case Color_Profile_Chunk: 
                chunk.type = .color_profile
                if len(v.icc.data) != 0 {
                    v.type = 2
                } else {
                    v.type = 0
                }            

            case User_Data_Chunk:
                chunk.type = .user_data

                if (v.flags & 4) == 4 {
                    for &pmap in v.properties.properties_map {
                        for &prop in pmap.properties {
                            prop.type = update_value(&prop.data)
                        }
                    }
                }
            }
        }
    }
}
   

// doc: raw.ASE_Document to update
// size: New total size in bytes
update_sizes :: proc(doc: ^ASE_Document) -> (size: int) {
    update_value :: proc(value: ^UD_Property_Value) -> (size: DWORD) {
        switch &pt in value {
        case BYTE: size = 1
        case SHORT, WORD: size = 2
        case LONG, DWORD, FIXED, FLOAT: size = 4
        case LONG64, QWORD, DOUBLE: size = 8
        case STRING: size = 2 + DWORD(len(pt.data))
        case POINT, SIZE: size = 4+4
        case RECT: size = 4*4
        case UUID: size = 16
    
        case UD_Vec:
            size += 4 + 2
            switch &vt in pt.data {
            case []Vec_Diff:
                pt.num = DWORD(len(vt))
                for &dt in vt {
                    size += update_value(&dt.data)
                }
            case []UD_Property_Value:
                pt.num = DWORD(len(vt))
                if len(vt) != 0 {
                    size += update_value(&vt[0]) * pt.num
                }
            }
    
        case UD_Properties_Map:
            size = 4
            pt.num = DWORD(len(pt.properties))
            for &prop in pt.properties {
                size += update_value(&prop.data)
            }
        }
        return
    }
    
    size += FILE_HEADER_SIZE
    doc.header.frames = WORD(len(doc.frames))

    for &frame in doc.frames {
        if frame.header.num_of_chunks == 0 && len(frame.chunks) < 0xFFFF {
            frame.header.old_num_of_chunks = WORD(len(frame.chunks))
            frame.header.num_of_chunks = 0
        } else {
            frame.header.old_num_of_chunks = 0xFFFF
            frame.header.num_of_chunks = DWORD(len(frame.chunks))
        }
        frame.header.size = DWORD(FRAME_HEADER_SIZE)
        
        for &chunk in frame.chunks {
            chunk.size = DWORD(size_of(DWORD))

            switch &v in chunk.data {
            case Old_Palette_256_Chunk:
                chunk.size += DWORD(size_of(WORD))
                v.size = WORD(len(v.packets))
                for &pal in v.packets{
                    if len(pal.colors) == 256 {
                        pal.num_colors = 0
                        chunk.size += 256 * 3 + 2
                    } else {
                        pal.num_colors = BYTE(len(pal.colors))
                        chunk.size += DWORD(pal.num_colors) * 3 + 2
                    }
                }

            case Old_Palette_64_Chunk:
                chunk.size += DWORD(size_of(WORD))
                v.size = WORD(len(v.packets))
                for &pal in v.packets{
                    if len(pal.colors) == 256 {
                        pal.num_colors = 0
                        chunk.size += 256 * 3 + 2
                    } else {
                        pal.num_colors = BYTE(len(pal.colors))
                        chunk.size += DWORD(pal.num_colors) * 3 + 2
                    }
                }

            case Layer_Chunk:
                v.name.length = WORD(len(v.name.data))
                chunk.size += 2*6 + 1*4 + 2 + DWORD(len(v.name.data)) + 4
            
            case Cel_Chunk:
                chunk.size += 2*5 + 1 + 5
                switch cel in v.cel {
                case Raw_Cel:
                    chunk.size += 2*2 + DWORD(len(cel.pixel))
                case Linked_Cel:
                    chunk.size += 2
                case Com_Image_Cel:
                    chunk.size += 2*2 + DWORD(len(cel.pixel))
                case Com_Tilemap_Cel:
                    chunk.size += 2*3 + 4*4 + 10 + DWORD(len(cel.tiles))
                }

            case Cel_Extra_Chunk:
                chunk.size += 2 + 4*4 + 16

            case Color_Profile_Chunk:
                v.icc.length = DWORD(len(v.icc.data))
                chunk.size += 2*2 + 4 + 8 + 4 + v.icc.length

            case External_Files_Chunk:
                v.length = DWORD(len(v.entries))
                chunk.size += 4 + 8 
                for &e in v.entries {
                    e.file_name_or_id.length = WORD(len(e.file_name_or_id.data))
                    chunk.size += 4 + 1 + 7 + 2 + DWORD(e.file_name_or_id.length)
                }

            case Mask_Chunk:
                v.name.length = WORD(len(v.name.data))
                chunk.size += 4*4 + 8 + 2 + + DWORD(v.name.length)
            
            case Path_Chunk:

            case Tags_Chunk:
                v.number = WORD(len(v.tags))
                chunk.size += 2 + 8
                for &tag in v.tags {
                    tag.name.length = WORD(len(tag.name.data))
                    chunk.size += 2*2 + 1 + 2 + 6 + 3 + 1 + 2 + DWORD(tag.name.length)
                }

            case Palette_Chunk:
                v.size = DWORD(len(v.entries))
                chunk.size += 4*3 + 8
                for &e in v.entries {
                    e.name.length = WORD(len(e.name.data))
                    chunk.size += 2 + 1*4
                    if (e.flags * 1) == 1 {
                        chunk.size += 2 + DWORD(len(e.name.data))
                    }
                }

            case User_Data_Chunk: 
                if (v.flags & 1) == 1 {
                    v.text.length = WORD(len(v.text.data))
                    chunk.size += 2 + DWORD(len(v.text.data))
                }
                if (v.flags & 2) == 2 {
                    chunk.size += 1*4
                }
                if (v.flags & 4) == 4 {
                    v.properties.num = DWORD(len(v.properties.properties_map))
                    v.properties.size += 4*2

                    for &pmap in v.properties.properties_map {
                        v.properties.size += 4*2
                        pmap.num += DWORD(len(pmap.properties))
                        for &prop in pmap.properties {
                            prop.name.length = WORD(len(prop.name.data))
                            v.properties.size += 2 + DWORD(len(prop.name.data)) + 2
                            v.properties.size += update_value(&prop.data)
                        }
                    }
                    chunk.size += v.properties.size

                }
            
            case Slice_Chunk:
                v.num_of_keys = DWORD(len(v.data))
                v.name.length = WORD(len(v.name.data))
                chunk.size += 4*3 + 2 + DWORD(len(v.name.data))

                for key in v.data {
                    chunk.size += 4*5
                    if (v.flags & 1) == 1 {
                        chunk.size += 4*4
                    }
                    if (v.flags & 2) == 2 {
                        chunk.size += 4+4
                    }
                }

            case Tileset_Chunk:
                v.name.length = WORD(len(v.name.data))
                chunk.size += 4*3 + 2*3 + 14 + 2 + DWORD(len(v.name.data))
                if (v.flags & 1) == 1 {
                    chunk.size += 4+4
                }
                // Can only update compressed.length when failed to uncompress 
                if (v.flags & 2) == 2 && !v.compressed.did_com {
                    v.compressed.length = DWORD(len(v.compressed.tiles))
                    chunk.size += 4 + v.compressed.length
                }
            }
            frame.header.size += chunk.size
        }
        size += int(frame.header.size)
    }
    doc.header.size = DWORD(size)
    return
}

upgrade_doc :: proc(doc: ^ASE_Document, allocator := context.allocator) -> (err: Doc_Upgrade_Error) {
    for &frame in doc.frames {
        frame.header.num_of_chunks = DWORD(frame.header.old_num_of_chunks)
        frame.header.old_num_of_chunks = 0xFFFF

        for &chunk in frame.chunks {
            #partial switch &v in chunk.data {
            case Old_Palette_256_Chunk:
                chunk.type = .palette
                new_chunk: Palette_Chunk

                entries := make([dynamic]Palette_Entry, allocator=allocator) or_return
                defer delete(entries)

                for pak in v.packets {
                    for c in pak.colors {
                        pal: Palette_Entry
                        pal.red = c[0]
                        pal.green = c[1]
                        pal.blue = c[2]
                        pal.alpha = 255
                        append(&entries)
                    }
                }

                new_chunk.entries = make([]Palette_Entry, len(entries), allocator) or_return
                copy(new_chunk.entries[:], entries[:])

                new_chunk.size = DWORD(len(entries))
                new_chunk.last_index = DWORD(len(entries) - 1)

                chunk.data = new_chunk
                
            case Old_Palette_64_Chunk:
                // https://github.com/alpine-alpaca/asefile/blob/main/src/palette.rs#L134
                scale :: proc(c: BYTE) -> (res: BYTE, err: Doc_Upgrade_Error) {
                    if c > 63 {
                        return c, .Palette_Color_To_Big
                    }
                    return c << 2 | c >> 4, nil
                }

                chunk.type = .palette
                new_chunk: Palette_Chunk

                entries := make([dynamic]Palette_Entry, allocator=allocator) or_return
                defer delete(entries)

                for pak in v.packets {
                    for c in pak.colors {
                        pal: Palette_Entry
                        pal.red = scale(c[0]) or_return
                        pal.green = scale(c[1]) or_return
                        pal.blue = scale(c[2]) or_return
                        pal.alpha = 255
                        append(&entries)
                    }
                }

                new_chunk.entries = make([]Palette_Entry, len(entries), allocator) or_return
                copy(new_chunk.entries[:], entries[:])

                new_chunk.size = DWORD(len(entries))
                new_chunk.last_index = DWORD(len(entries) - 1)

                chunk.data = new_chunk
                
            case Color_Profile_Chunk:
                if v.type == 0 {
                    v.type = 1
                }
            }
        }
    }

    return
}
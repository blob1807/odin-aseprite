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

update_doc :: proc(doc: ^ASE_Document) {
    update_flags(doc)
    update_types(doc)
    update_sizes(doc)
}

update_flags :: proc(doc: ^ASE_Document) {
    for &frame in doc.frames {
        for &chunk in frame.chunks {
            switch &v in chunk.data {
            case Old_Palette_256_Chunk:
            case Old_Palette_64_Chunk:
            case Layer_Chunk:
            case Cel_Chunk:
            case Cel_Extra_Chunk:
            case Color_Profile_Chunk: 
            case External_Files_Chunk:
            case Mask_Chunk:
            case Path_Chunk: 
            case Tags_Chunk: 
            case Palette_Chunk:
            case User_Data_Chunk:
            case Slice_Chunk:
            case Tileset_Chunk:
            case:
            }
        }
    }
}

update_types :: proc(doc: ^ASE_Document) {
    for &frame in doc.frames {
        for &chunk in frame.chunks {
            switch &v in chunk.data {
            case Old_Palette_256_Chunk:
                chunk.type = .old_palette_256
            case Old_Palette_64_Chunk:
                chunk.type = .old_palette_64
            case Layer_Chunk:
                chunk.type = .layer
                
            case Cel_Chunk:
                chunk.type = .cel
            case Cel_Extra_Chunk:
                chunk.type = .cel_extra
            case Color_Profile_Chunk: 
                chunk.type = .color_profile
            case External_Files_Chunk:
                chunk.type = .external_files
            case Mask_Chunk:
                chunk.type = .mask
            case Path_Chunk: 
                chunk.type = .path
            case Tags_Chunk: 
                chunk.type = .tags
            case Palette_Chunk:
                chunk.type = .palette
            case User_Data_Chunk:
                chunk.type = .user_data
            case Slice_Chunk:
                chunk.type = .slice
            case Tileset_Chunk:
                chunk.type = .tileset
            case:
            }
        }
    }
}

update_sizes :: proc(doc: ^ASE_Document) -> (size: int) {
    for &frame in doc.frames {
        if frame.header.num_of_chunks == 0 && len(frame.chunks) < 0xFFFF {
            frame.header.old_num_of_chunks = WORD(len(frame.chunks))
            frame.header.num_of_chunks = 0
        } else {
            frame.header.old_num_of_chunks = 0xFFFF
            frame.header.num_of_chunks = DWORD(len(frame.chunks))
        }
        
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
            
            case Cel_Chunk:
            case Cel_Extra_Chunk:

            case Color_Profile_Chunk:
                v.icc.length = DWORD(len(v.icc.data))

            case External_Files_Chunk:
                v.length = DWORD(len(v.entries))
                for &e in v.entries {
                    e.file_name_or_id.length = WORD(len(e.file_name_or_id.data))
                }

            case Mask_Chunk:
                v.name.length = WORD(len(v.name.data))
            
            case Path_Chunk:
            case Tags_Chunk:
                v.number = WORD(len(v.tags))
                for &tag in v.tags {
                    tag.name.length = WORD(len(tag.name.data))
                }

            case Palette_Chunk:
                v.size = DWORD(len(v.entries))
                for &e in v.entries {
                    e.name.length = WORD(len(e.name.data))
                }

            case User_Data_Chunk: 
                if (v.flags & 1) == 1 {
                    v.text.length = WORD(len(v.text.data))
                }
                if (v.flags & 4) == 4 {
                    v.properties.size += 0 // TODO: ya no
                    v.properties.num = DWORD(len(v.properties.properties_map))

                }
            
            case Slice_Chunk:
                v.num_of_keys = DWORD(len(v.data))
                v.name.length = WORD(len(v.name.data))

            case Tileset_Chunk:
                v.name.length = WORD(len(v.name.data))
                if (v.flags & 2) == 2 && v.compressed.did_com {
                    v.compressed.length = DWORD(len(v.compressed.tiles))
                }
            }
        }
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
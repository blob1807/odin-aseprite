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
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

    for frame in doc.frames {
        for chunk in frame.chunks {
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

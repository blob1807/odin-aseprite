package aseprite_file_handler

destroy_doc :: proc(doc: ^Document) {
    for &frame in doc.frames {
        for &chunk in frame.chunks {
            #partial switch &v in chunk {
                case Old_Palette_256_Chunk:
                case Old_Palette_64_Chunk:
                case Cel_Chunk:
                case Color_Profile_Chunk:
                case External_Files_Chunk:
                case Mask_Chunk:
                case Tags_Chunk:
                case Palette_Chunk:
                case User_Data_Chunk:
                case Slice_Chunk:
                case Tileset_Chunk:
            }
        }
        //delete(frame.chunks)
    }
    //delete(doc.frames)
}
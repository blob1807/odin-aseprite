package raw_aseprite_file_handler

import "core:fmt"
import "core:encoding/endian"
import "core:slice"
import "core:log"
import "core:bytes"
import "core:compress/zlib"
import "base:intrinsics"


get_chunk_from_type :: proc($T: typeid) -> (c: Chunk_Types)
where intrinsics.type_is_variant_of(Chunk_Data, T) {
    switch typeid_of(T) {
    case Old_Palette_256_Chunk: c = .old_palette_256
    case Old_Palette_64_Chunk: c = .old_palette_64
    case Layer_Chunk: c = .layer
    case Cel_Chunk: c = .cel
    case Cel_Extra_Chunk: c = .cel_extra
    case Color_Profile_Chunk: c = .color_profile
    case External_Files_Chunk: c = .external_files
    case Mask_Chunk: c = .mask
    case Path_Chunk: c = .path
    case Tags_Chunk: c = .tags
    case Palette_Chunk: c = .palette
    case User_Data_Chunk: c = .user_data
    case Slice_Chunk: c = .slice
    case Tileset_Chunk: c = .tileset
    case nil:
    case:
        unreachable()
    }
    return
}


unmarshal_chunks :: proc(data: []byte, buf: ^[dynamic]$T, allocator := context.allocator) -> (err: ASE_Unmarshal_Error)
where intrinsics.type_is_variant_of(Chunk_Data, T) {
    chunk := get_chunk_from_type(T)
    pos := size_of(DWORD)
    next := size_of(DWORD) + size_of(WORD)
    magic, _ := endian.get_u16(data[pos:next], .Little)

    if magic != 0xA5E0 {
        return .Bad_File_Magic_Number
    }

    pos = next
    next += size_of(WORD)
    frames, _ := endian.get_u16(data[pos:next], .Little)

    next += size_of(WORD) + size_of(WORD)

    pos = next
    next += size_of(WORD)
    color_depth, _ := endian.get_u16(data[pos:next], .Little)

    pos = next
    next += size_of(DWORD)
    flags, _ := endian.get_u32(data[pos:next], .Little)

    next += 110
    
    for frame in 0..<frames {
        next += size_of(DWORD)

        pos = next
        next += size_of(WORD)
        frame_magic, _ := endian.get_u16(data[pos:next], .Little)

        if frame_magic != 0xF1FA {
            return .Bad_Frame_Magic_Number
        }

        pos = next
        next += size_of(WORD)
        old_num_of_chunks, _ := endian.get_u16(data[pos:next], .Little)

        next += 4
        pos = next
        next += size_of(DWORD)
        num_of_chunks, _ := endian.get_u32(data[pos:next], .Little)

        frame_count: int
        if num_of_chunks == 0 {
            frame_count = int(old_num_of_chunks)
        } else {
            frame_count = int(num_of_chunks)
        }

        for _ in 0..<frame_count {
            c_start := next

            pos = next
            next += size_of(DWORD)
            c_size, _ := endian.get_u32(data[pos:next], .Little)

            pos = next
            next += size_of(WORD)
            t_c_type, _ := endian.get_u16(data[pos:next], .Little)
            c_type := Chunk_Types(t_c_type)

            if c_type != chunk {
                continue
            }
        }
    }
    return
}

read_file_header :: proc(data: []byte) -> (
    frames, color_depth: u16, 
    flags: u32,
    err: ASE_Unmarshal_Error
) 
{
    pos := size_of(DWORD)
    next := size_of(DWORD) + size_of(WORD)
    magic, _ := endian.get_u16(data[pos:next], .Little)

    if magic != 0xA5E0 {
        err = .Bad_File_Magic_Number
        return
    }

    pos = next
    next += size_of(WORD)
    frames, _ = endian.get_u16(data[pos:next], .Little)

    next += size_of(WORD) + size_of(WORD)

    pos = next
    next += size_of(WORD)
    color_depth, _ = endian.get_u16(data[pos:next], .Little)

    pos = next
    next += size_of(DWORD)
    flags, _ = endian.get_u32(data[pos:next], .Little)

    next += 110

    return
}

read_frame_header :: proc(data: []byte) -> (
    frame_count: int, err: ASE_Unmarshal_Error
) {
    pos: int
    next := size_of(DWORD) + size_of(WORD)
    frame_magic, _ := endian.get_u16(data[pos:next], .Little)

    if frame_magic != 0xF1FA {
        err = .Bad_Frame_Magic_Number
        return
    }

    pos = next
    next += size_of(WORD)
    old_num, _ := endian.get_u16(data[pos:next], .Little)

    next += 4
    pos = next
    next += size_of(DWORD)
    new_num, _ := endian.get_u32(data[pos:next], .Little)

    if new_num == 0 {
        frame_count = int(old_num)
    } else {
        frame_count = int(new_num)
    }

    return
}

read_old_palette_256 :: proc(data: []byte, buf: ^[dynamic]Old_Palette_256_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return

    return
}
read_old_palette_64 :: proc(data: []byte, buf: ^[dynamic]Old_Palette_64_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return

    return
}
read_layer :: proc(data: []byte, buf: ^[dynamic]Layer_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_cel :: proc(data: []byte, buf: ^[dynamic]Cel_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_cel_extra :: proc(data: []byte, buf: ^[dynamic]Cel_Extra_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_color_profile :: proc(data: []byte, buf: ^[dynamic]Color_Profile_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_external_files :: proc(data: []byte, buf: ^[dynamic]External_Files_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_mask :: proc(data: []byte, buf: ^[dynamic]Mask_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_path :: proc(data: []byte, buf: ^[dynamic]Path_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_tags :: proc(data: []byte, buf: ^[dynamic]Tags_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_palette :: proc(data: []byte, buf: ^[dynamic]Palette_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_user_data :: proc(data: []byte, buf: ^[dynamic]User_Data_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_slice :: proc(data: []byte, buf: ^[dynamic]Slice_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}
read_tileset :: proc(data: []byte, buf: ^[dynamic]Tileset_Chunk, allocator := context.allocator) -> (err: ASE_Unmarshal_Error) {
    pos, next: int
    frames, _, _ := read_file_header(data[:FILE_HEADER_SIZE]) or_return
    
    return
}

read_chunks :: proc{read_old_palette_256, read_old_palette_64, read_layer, read_cel, read_cel_extra, read_color_profile, read_external_files}
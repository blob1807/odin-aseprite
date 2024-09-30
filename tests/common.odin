package ase_tests

import "core:os"
import "core:fmt"
import "core:strings"
import "core:testing"
import "core:reflect"

import ase ".."

TEST_count := 0
TEST_fail  := 0

when ODIN_TEST {
	expect  :: testing.expect
	log     :: testing.log
	errorf  :: testing.errorf
} else {
	expect  :: proc(t: ^testing.T, condition: bool, message: string, loc := #caller_location) -> bool {
		TEST_count += 1
		if !condition {
			TEST_fail += 1
			fmt.printf("[%v:%s] FAIL %v\n", loc, loc.procedure, message)
		}
        return condition
	}
	errorf  :: proc(t: ^testing.T, message: string, args: ..any, loc := #caller_location) {
		TEST_fail += 1
		fmt.printf("[%v:%s] Error %v\n", loc, loc.procedure, fmt.tprintf(message, ..args))
		return
	}
	log     :: proc(t: ^testing.T, v: any, loc := #caller_location) {
		fmt.printf("[%v] ", loc)
		fmt.printf("log: %v\n", v)
	}
}

report :: proc(t: ^testing.T) {
	if TEST_fail > 0 {
		if TEST_fail > 1 {
			fmt.printf("%v/%v tests successful, %v tests failed.\n", TEST_count - TEST_fail, TEST_count, TEST_fail)
		} else {
			fmt.printf("%v/%v tests successful, 1 test failed.\n", TEST_count - TEST_fail, TEST_count)
		}
		os.exit(1)
	} else {
		fmt.printf("%v/%v tests successful.\n", TEST_count, TEST_count)
	}
}

// Returns absolute path to `sub_path` where `sub_path` is within the "tests/" sub-directory of the Odin project root
// and we're being run from the Odin project root or from a sub-directory of "tests/"
// e.g. get_data_path("assets/blah") will return "/Odin_root/tests/assets/blah" if run within "/Odin_root",
// "/Odin_root/tests" or "/Odin_root/tests/subdir" etc
get_data_path :: proc(t: ^testing.T, sub_path: string) -> (data_path: string) {

	cwd := os.get_current_directory()
	defer delete(cwd)

	when ODIN_OS == .Windows {
		norm, was_allocation := strings.replace_all(cwd, "\\", "/")
		if !was_allocation {
			norm = strings.clone(norm)
		}
		defer delete(norm)
	} else {
		norm := cwd
	}

	last_index := strings.last_index(norm, "/tests/")
	if last_index == -1 {
		len := len(norm)
		if len >= 6 && norm[len-6:] == "/tests" {
			data_path = fmt.tprintf("%s/%s", norm, sub_path)
		} else {
			data_path = fmt.tprintf("%s/tests/%s", norm, sub_path)
		}
	} else {
		data_path = fmt.tprintf("%s/tests/%s", norm[:last_index], sub_path)
	}

	return data_path
}


chunk_equal :: proc(x, y: ase.Chunk) -> (a: any, b: any, c: typeid, eq: bool) {
	using ase

    switch xv in x {
    case Old_Palette_256_Chunk:
        yv, ok := y.(Old_Palette_256_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Old_Palette_64_Chunk:
        yv, ok := y.(Old_Palette_64_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Layer_Chunk:
        yv, ok := y.(Layer_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Chunk:
        yv, ok := y.(Cel_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Cel_Extra_Chunk:
        yv, ok := y.(Cel_Extra_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case External_Files_Chunk:
        yv, ok := y.(External_Files_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Mask_Chunk:
        yv, ok := y.(Mask_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Path_Chunk:
        yv, ok := y.(Path_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Tags_Chunk:
        yv, ok := y.(Tags_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Palette_Chunk:
        yv, ok := y.(Palette_Chunk)
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Color_Profile_Chunk:
        yv, ok := y.(Color_Profile_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case User_Data_Chunk:
        yv, ok := y.(User_Data_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Slice_Chunk:
        yv, ok := y.(Slice_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case Tileset_Chunk:
        yv, ok := y.(Tileset_Chunk) 
        if !ok {
            return typeid_of(type_of(xv)), reflect.union_variant_typeid(y), typeid_of(Chunk), false 
        }
        return _chunk_equal(xv, yv)

    case nil:
        if y != nil {
            return x, y, typeid_of(Chunk), false
        }
    case:
        return
    }

    eq = true
    return
}

frame_equal :: proc(x, y: ase.Frame) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header { 
        return x.header, y.header, typeid_of(ase.Document), false
    }
    if len(x.chunks) != len(y.chunks) {
        return len(x.chunks), len(y.chunks), typeid_of(ase.Document), false
    }
    for i in 0..<len(x.chunks) {
        xc, yc := x.chunks[i], y.chunks[i]
        a, b, c, eq = chunk_equal(xc, yc)
        if !eq { return }
    }
    eq = true
    return
}

document_equal :: proc(x, y: ase.Document) -> (a: any, b: any, c: typeid, eq: bool) {
    if x.header != y.header {
        if x.header.size == y.header.size {
            return x.header, y.header, typeid_of(ase.Document), false
        }
    }

    if len(x.frames) != len(y.frames) {
        return len(x.frames), len(y.frames), typeid_of(ase.Document), false
    }

    for i in 0..<len(x.frames) {
        xf, yf := x.frames[i], y.frames[i]
        a, b, c, eq = frame_equal(xf, yf)
        if !eq { return }
    }

    eq = true
    return
}

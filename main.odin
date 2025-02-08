package main

import "core:odin/parser"
import "core:odin/ast"
import "core:path/filepath"
import "core:os"
import "core:strings"
import "core:fmt"
import "core:sys/posix"

sdk_root : string

// Inputs:
// - args: is a list of strings with at least one element which is the process to execute. It needs to be the full path
exec_and_get_stdout :: proc(cmd: string) -> string {
    fp := posix.popen(strings.clone_to_cstring(cmd), "r")
    if fp == nil {
        fmt.println("Failed to start process")
        os.exit(1)
    }

    sb := strings.builder_make()
    stdout: [dynamic]byte
    output: [1024]byte
    index : int

    for posix.fgets(&output[0], size_of(output), fp) != nil {
        read := bytes.index_byte(output[:], 0)
        defer index += cast(int)read

        if read > 0 {
            assign_at(&stdout, index, ..output[:read])
        }
    }

    status := posix.pclose(fp)
    if status == -1 {
        fmt.println("Error reported by pclose()")
        os.exit(1)
    }

    return strings.trim_right_null(string(stdout[:]))
}

process_file :: proc(file_name: string) {
    pkg := ast.Package {
        kind = .Normal,
    }
    data, success := os.read_entire_file(file_name)
    if !success {
        fmt.println("Failed to read file")
        os.exit(1)
    }
    src := string(data)
    file := ast.File {
        pkg = &pkg,
        src = src,
        fullpath = file_name,
    }
    parser_flags := parser.Flags{ .Optional_Semicolons }
    p := parser.default_parser(parser_flags)
    ok := parser.parse_file(&p, &file)
    if !ok {
        fmt.println("Failed to parse file")
        os.exit(1)
    }
    for d in file.decls {
        #partial switch k in d.derived_stmt {
        case ^ast.Value_Decl:
            function_with_body := strings.trim(src[k.pos.offset - 1:k.end.offset - 1], "\n")
            offset := strings.index_byte(function_with_body, '\n')
            fmt.print(strings.trim_prefix(file_name, sdk_root), ":", k.pos.line, ":", sep="")
            if offset == -1 {
                fmt.println(function_with_body)
            } else {
                fmt.println(function_with_body[:offset])
            }
        }
    }
}

cb :: proc(info: os.File_Info, in_err: os.Errno, user_data: rawptr) -> (err: os.Error, skip_dir: bool) {
    if !info.is_dir && strings.has_suffix(info.name, ".odin") {
        process_file(info.fullpath)
    }
    return nil, false
}

main :: proc() {
    sb := strings.builder_make()
    strings.write_string(&sb, exec_and_get_stdout("odin root"))
    strings.write_string(&sb, "/core")
    sdk_root := strings.to_string(sb)
    filepath.walk(sdk_root, cb, nil)}

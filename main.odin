package main

import "core:odin/parser"
import "core:odin/ast"
import "core:path/filepath"
import "core:os"
import "core:strings"
import "core:fmt"

//dir := "/opt/homebrew/Cellar/odin/2024-07/libexec/core/io"
dir := "/opt/homebrew/Cellar/odin/2024-07/libexec/core/"

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
            fmt.print(strings.trim_prefix(file_name, dir), ":", k.pos.line, ":", sep="")
            if offset == -1 {
                fmt.println(function_with_body)
            } else {
                fmt.println(function_with_body[:offset])
            }
        }
    }
}

cb :: proc(info: os.File_Info, in_err: os.Errno, user_data: rawptr) -> (err: os.Errno, skip_dir: bool) {
    if !info.is_dir && strings.has_suffix(info.name, ".odin") {
        process_file(info.fullpath)
    }
    return 0, false
}

main :: proc() {
    filepath.walk(dir, cb, nil)
}
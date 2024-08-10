# Lists all procedures in the SDK source files

You need to modify `main.odin` to adjust the SDK path to your directory. Then it recursively crawls it for any `.odin` files to parse them and outputs definitions.

# Example output

```
unicode/utf8/utf8.odin:383:full_rune_in_bytes :: proc "contextless" (b: []byte) -> bool {
unicode/utf8/utf8.odin:403:full_rune_in_string :: proc "contextless" (s: string) -> bool {
unicode/utf8/utf8string/string.odin:7:String :: struct {
```

std = "max"
exclude_files = { ".luarocks/**", "json.lua" }

read_globals = {
	"awesome",
	"screen",
	"mouse",
	"client",
	"root",
	"mousegrabber",
	"keygrabber",
}

self = false
max_line_length = 120
max_string_line_length = false
max_comment_line_length = false

files["spec/"] = {
	globals = { "describe", "it", "assert_eq", "assert_true", "assert_nil", "assert_error", "os" },
}

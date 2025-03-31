return {
	cmd = {
		"clangd",
		"--background-index",
		"--fallback-style=llvm",
	},
	filetypes = { "c", "cpp", "h", "hpp" },
	root_markers = { ".clangd" },
}

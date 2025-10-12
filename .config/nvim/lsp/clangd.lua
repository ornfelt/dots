return {
  cmd = { "clangd", "--background-index", "--fallback-style=llvm" },
  filetypes = { "c", "cpp", "h", "hpp", "objc", "objcpp", "cuda" }, -- maybe omit h/hpp here?
  root_markers = { ".clangd", "compile_commands.json", ".git" },
}


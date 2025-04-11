local myconfig = require("myconfig")

local code_root_dir = myconfig.code_root_dir

-- Helper function for setting key mappings for filetypes
local function create_hellow_mapping(ft, fe)
  code_root_dir = code_root_dir:gsub(" ", '" "')
  local template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. ft
  if fe then
    template_file = code_root_dir .. "Code2/General/utils/hellow/hellow." .. fe
  end

  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local map_opts = { noremap = true, silent = true }
      vim.api.nvim_buf_set_keymap(0, 'i', 'hellow<Tab>', '<Esc>:r ' .. template_file .. '<Enter>', map_opts)
    end
  })
end

-- Set mappings for various filetypes
create_hellow_mapping("asm")
create_hellow_mapping("c")
create_hellow_mapping("clojure", "clj")
create_hellow_mapping("cobol", "cob")
create_hellow_mapping("cpp")
create_hellow_mapping("cs")
create_hellow_mapping("dart")
create_hellow_mapping("erlang", "erl")
create_hellow_mapping("elixir", "ex")
create_hellow_mapping("fortran", "f90")
create_hellow_mapping("fsharp", "fs")
create_hellow_mapping("go")
create_hellow_mapping("groovy")
create_hellow_mapping("haskell", "hs")
create_hellow_mapping("java")
create_hellow_mapping("julia", "jl")
create_hellow_mapping("javascript", "js")
create_hellow_mapping("kotlin", "kt")
create_hellow_mapping("lua")
create_hellow_mapping("ocaml", "ml")
create_hellow_mapping("nim")
create_hellow_mapping("pascal", "pas")
create_hellow_mapping("perl", "pl")
create_hellow_mapping("php")
create_hellow_mapping("py,python", "py")
create_hellow_mapping("r")
create_hellow_mapping("ruby", "rb")
create_hellow_mapping("rust", "rs")
create_hellow_mapping("scala")
create_hellow_mapping("scheme", "scm")
create_hellow_mapping("st")
create_hellow_mapping("swift")
create_hellow_mapping("typescript", "ts")
create_hellow_mapping("vb")
create_hellow_mapping("zig")


require('dbg_log').log_file(debug.getinfo(1, 'S').source)

-- Helper function to create key mappings for given filetypes
local function create_mappings(ft, mappings)
  vim.api.nvim_create_autocmd("FileType", {
    pattern = ft,
    callback = function()
      local bufnr = vim.api.nvim_get_current_buf()
      for lhs, rhs in pairs(mappings) do
        vim.api.nvim_buf_set_keymap(bufnr, 'i', lhs, rhs, { noremap = true, silent = true })
      end
    end
  })
end

-- autocmd vtxt,vimwiki,wiki,text,md,markdown: line, oline, date
create_mappings("vtxt,vimwiki,wiki,text,md,markdown", {
  ["line<Tab>"] = '----------------------------------------------------------------------------------<Enter>',
  ["oline<Tab>"] = '******************************************<Enter>',
  ["date<Tab>"] = '<-- <C-R>=strftime("%Y-%m-%d %a")<CR><Esc>A -->'
})

-- autocmd html: <i<Tab>, <b<Tab>, <h1<Tab>, <h2<Tab>, <im<Tab>
create_mappings("html", {
  ["<i<Tab>"] = '<em></em> <Space><++><Esc>/<<Enter>GNi',
  ["<b<Tab>"] = '<b></b><Space><++><Esc>/<<Enter>GNi',
  ["<h1<Tab>"] = '<h1></h1><Space><++><Esc>/<<Enter>GNi',
  ["<h2<Tab>"] = '<h2></h2><Space><++><Esc>/<<Enter>GNi',
  ["<im<Tab>"] = '<img></img><Space><++><Esc>/<<Enter>GNi'
})

-- autocmd c: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("c", {
  ["sout<Tab>"] = 'printf("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'printf("x: %d\\n", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'printf("x: %s\\n", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'printf("x: %s\\n", x ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'printf("x: %.2f\\n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'printf("x: %.6f\\n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'printf("x: %c\\n", x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'printf("x: %p\\n", (void*)&x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (int i = 0; i < length; i++) {<Enter>printf("El: %d\\n", arr[i]);<Enter>}<Esc>?arr<Enter>ciw'
})

-- autocmd cpp,c++: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("cpp,c++", {
  ["sout<Tab>"] = 'std::cout << "" << std::endl;<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["souts<Tab>"] = 'std::cout << "x: " << x << std::endl;<Esc>Fxciw',
  ["soutb<Tab>"] = 'std::cout << "x: " << (x ? "true" : "false") << std::endl;<Esc>Fxciw',
  ["soutf<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(2) << x << std::endl;<Esc>Fxciw',
  ["soutd<Tab>"] = 'std::cout << "x: " << std::fixed << std::setprecision(6) << x << std::endl;<Esc>Fxciw',
  ["soutc<Tab>"] = 'std::cout << "x: " << static_cast<char>(x) << std::endl;<Esc>Fxciw',
  ["soutp<Tab>"] = 'std::cout << "x: " << &x << std::endl;<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for (auto& el : arr) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- autocmd cs: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, fore, for
create_mappings("cs", {
  ["sout<Tab>"] = 'Console.WriteLine("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["souts<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutb<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw',
  ["soutf<Tab>"] = 'Console.WriteLine($"x: {x:F2}");<Esc>Fxciw',
  ["soutd<Tab>"] = 'Console.WriteLine($"x: {x:F6}");<Esc>Fxciw',
  ["soutc<Tab>"] = 'Console.WriteLine($"x: {(char)x}");<Esc>Fxciw',
  ["soutp<Tab>"] = 'Console.WriteLine($"x: {x}");<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'foreach (var x in obj)<Enter>{<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw'
})

-- autocmd go: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("go", {
  ["sout<Tab>"] = 'fmt.Println("");<Esc>2F"li',
  ["souti<Tab>"] = 'fmt.Printf("x: %d\\n", x)<Esc>Fxciw',
  ["souts<Tab>"] = 'fmt.Printf("x: %s\\n", x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'fmt.Printf("x: %t\\n", x)<Esc>Fxciw',
  ["soutf<Tab>"] = 'fmt.Printf("x: %.2f\\n", x)<Esc>Fxciw',
  ["soutd<Tab>"] = 'fmt.Printf("x: %.6f\\n", x)<Esc>Fxciw',
  ["soutc<Tab>"] = 'fmt.Printf("x: %c\\n", x)<Esc>Fxciw',
  ["soutp<Tab>"] = 'fmt.Printf("x: %p\\n", &x)<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i := 0; i < val; i++ {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for idx, el := range arr {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- autocmd java: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, fore, for, psvm
create_mappings("java", {
  ["sout<Tab>"] = 'System.out.println("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["souts<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'System.out.println("x: " + (x ? "true" : "false"));<Esc>Fxciw',
  ["soutf<Tab>"] = 'System.out.printf("x: %.2f%n", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'System.out.printf("x: %.6f%n", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'System.out.println("x: " + (char)x);<Esc>Fxciw',
  ["soutp<Tab>"] = 'System.out.println("x: " + x);<Esc>Fxciw', -- Pointer value
  ["fore<Tab>"] = 'for (String s : obj){<Enter><Enter>}<Esc>?obj<Enter>ciw',
  ["for<Tab>"] = 'for(int i = 0; i < val; i++){<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["psvm<Tab>"] = 'public static void main(String[] args){<Enter><Enter>}<Esc>?{<Enter>o'
})

-- autocmd js,ts,jsx,tsx,javascript,typescript,typescriptreact: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("js,ts,jsx,tsx,javascript,typescript,typescriptreact", {
  ["sout<Tab>"] = 'console.log("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["souts<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw',
  ["soutb<Tab>"] = 'console.log(`x: ${x}` ? "true" : "false");<Esc>Fxciw',
  ["soutf<Tab>"] = 'console.log(`x: ${x.toFixed(2)}`);<Esc>Fxciw',
  ["soutd<Tab>"] = 'console.log(`x: ${x.toFixed(6)}`);<Esc>Fxciw',
  ["soutc<Tab>"] = 'console.log(`x: ${String.fromCharCode(x)}`);<Esc>Fxciw',
  ["soutp<Tab>"] = 'console.log(`x: ${x}`);<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for (let i = 0; i < val; i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'arr.forEach(el => {<Enter><Enter>});<Esc>?arr<Enter>ciw'
})

-- autocmd lua: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("lua", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["souts<Tab>"] = 'print("x: " .. x)<Esc>Fxciw',
  ["soutb<Tab>"] = 'print("x: " .. (x and "true" or "false"))<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(string.format("x: %.2f", x))<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(string.format("x: %.6f", x))<Esc>Fxciw',
  ["soutc<Tab>"] = 'print("x: " .. string.char(x))<Esc>Fxciw',
  ["soutp<Tab>"] = 'print("x: " .. tostring(x))<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i = 1, val, 1 do<Enter><Enter>end<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for i, el in ipairs(arr) do<Enter><Enter>end<Esc>?arr<Enter>ciw'
})

-- autocmd php: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("php", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["souts<Tab>"] = 'echo "x: $x\\n";<Esc>Fxciw',
  ["soutb<Tab>"] = 'echo "x: " . ($x ? "true" : "false") . "\\n";<Esc>Fxciw',
  ["soutf<Tab>"] = 'echo "x: " . number_format($x, 2) . "\\n";<Esc>Fxciw',
  ["soutd<Tab>"] = 'echo "x: " . number_format($x, 6) . "\\n";<Esc>Fxciw',
  ["soutc<Tab>"] = 'echo "x: " . chr($x) . "\\n";<Esc>Fxciw',
  ["soutp<Tab>"] = 'echo "x: " . $x . "\\n";<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for ($i = 0; $i < $val; $i++) {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'foreach ($arr as $el) {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- autocmd py,python: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("py,python", {
  ["sout<Tab>"] = 'print("")<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["souts<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw',
  ["soutb<Tab>"] = 'print(f"x: {\'true\' if x else \'false\'}")<Esc>Fxciw',
  ["soutf<Tab>"] = 'print(f"x: {x:.2f}")<Esc>Fxciw',
  ["soutd<Tab>"] = 'print(f"x: {x:.6f}")<Esc>Fxciw',
  ["soutc<Tab>"] = 'print(f"x: {chr(x)}")<Esc>Fxciw',
  ["soutp<Tab>"] = 'print(f"x: {x}")<Esc>Fxciw', -- Pointer value
  ["for<Tab>"] = 'for i in range():<Esc>hi',
  ["fore<Tab>"] = 'for i in :<Esc>i'
})

-- autocmd rs,rust: sout, souti, souts, soutb, soutf, soutd, soutc, soutp, for, fore
create_mappings("rs,rust", {
  ["sout<Tab>"] = 'println!("");<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["souts<Tab>"] = 'println!("x: {}", x);<Esc>Fxciw',
  ["soutb<Tab>"] = 'println!("x: {}", if x { "true" } else { "false" });<Esc>Fxciw',
  ["soutf<Tab>"] = 'println!("x: {:.2}", x);<Esc>Fxciw',
  ["soutd<Tab>"] = 'println!("x: {:.6}", x);<Esc>Fxciw',
  ["soutc<Tab>"] = 'println!("x: {}", x as char);<Esc>Fxciw',
  ["soutp<Tab>"] = 'println!("x: {:?}", &x);<Esc>Fxciw', -- Pointer address
  ["for<Tab>"] = 'for i in 0..val {<Enter><Enter>}<Esc>?val<Enter>ciw',
  ["fore<Tab>"] = 'for el in arr.iter() {<Enter><Enter>}<Esc>?arr<Enter>ciw'
})

-- autocmd sh,bash: sout, souti, souts, soutb, soutf, for, fore
create_mappings("sh,bash", {
  ["sout<Tab>"] = 'echo "";<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["souts<Tab>"] = 'echo "x: $x";<Esc>0f$ciw',
  ["soutb<Tab>"] = 'if [ "$x" = "true" ]; then echo "x: true"; else echo "x: false"; fi;<Esc>0f$ciw',
  ["soutf<Tab>"] = 'printf "x: %.2f\\n" "$x";<Esc>0f$ciw',
  ["for<Tab>"] = 'for i in {1..10}; do<Enter>echo "Element: $i"<Enter>done<Esc>kA<Enter>',
  ["fore<Tab>"] = 'for item in "${array[@]}"; do<Enter>echo "Item: $item"<Enter>done<Esc>kA<Enter>'
})

-- autocmd ps1,powershell: sout, souti, souts, soutb, soutf, for, fore
create_mappings("ps1,powershell", {
  ["sout<Tab>"] = 'Write-Host "" -ForegroundColor Cyan<Esc>?""<Enter>li',
  ["souti<Tab>"] = 'Write-Host "x: $x" -ForegroundColor Blue<Esc>0f$lciw',
  ["souts<Tab>"] = 'Write-Host "x: $x" -ForegroundColor Green<Esc>0f$lciw',
  ["soutb<Tab>"] = 'Write-Host ("x: " + ($x.ToString().ToLower())) -ForegroundColor Magenta<Esc>0f$lciw',
  ["soutf<Tab>"] = 'Write-Host ("x: " + "{0:N2}" -f $x) -ForegroundColor DarkBlue<Esc>0f$lciw',
  ["for<Tab>"] = 'for ($i = 0; $i -lt 10; $i++) {<Enter>Write-Host "Element: $i" -ForegroundColor Yellow<Enter>}<Esc>kA<Enter>',
  ["fore<Tab>"] = 'foreach ($item in $array) {<Enter>Write-Host "Item: $item" -ForegroundColor DarkYellow<Enter>}<Esc>kA<Enter>'
})


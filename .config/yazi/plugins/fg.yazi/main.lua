local toggle_ui = ya.sync(function(self)
	if self.children then
		Modal:children_remove(self.children)
		self.children = nil
	else
		self.children = Modal:children_add(self, 10)
	end
	ya.render()
end)

local init_ui_data = ya.sync(function(self,file_url)
	self.opt = {"nvim", "helix", "jump"}
	self.title = "fg"
	self.title_color = "#82ab3a"
	self.cursor = 0
	self.file_url = file_url and file_url or ""
	ya.render()
end)

local set_option = ya.sync(function(self,enable)
	if enable then
		self.active_opt = self.opt[self.cursor+1]
	else
		self.active_opt = nil
	end
end)

local get_option = ya.sync(function(self)
	return self.active_opt
end)

local get_default_action = ya.sync(function(self)
	return self.default_action
end)

local update_cursor = ya.sync(function(self, cursor)
	-- if add opt, need to add change 3th arg.
	-- forexample, 2 mean 3 opt. circle 0 to 2.
	self.cursor = ya.clamp(0, self.cursor + cursor,  2)
	ya.render()
end)

local M = {
	keys = {
		{ on = "q", run = "quit" },
		{ on = "<Esc>", run = "quit" },
		{ on = "<Enter>", run = "select" },


		{ on = "k", run = "up" },
		{ on = "j", run = "down" },


		{ on = "<Up>", run = "up" },
		{ on = "<Down>", run = "down" },

	},
}

function M:new(area)
	self:layout(area)
	return self
end

function M:layout(area)
	local chunks = ui.Layout()
		:constraints({
			ui.Constraint.Percentage(10),
			ui.Constraint.Percentage(80),
			ui.Constraint.Percentage(10),
		})
		:split(area)

	local chunks = ui.Layout()
		:direction(ui.Layout.HORIZONTAL)
		:constraints({
			ui.Constraint.Percentage(10),
			ui.Constraint.Percentage(80),
			ui.Constraint.Percentage(10),
		})
		:split(chunks[2])

	self._area = chunks[2]
end

local function splitAndGetNth(inputstr, sep, index)
    if sep == nil then
        sep = "%s"
    end
    local count = 0
    local start = 1
    while true do
        local sepStart, sepEnd = string.find(inputstr, sep, start)
        if not sepStart then
            break
        end
        count = count + 1
        if count == index then
            return string.sub(inputstr, start, sepStart - 1)
        end
        start = sepEnd + 1
    end
    if index == 1 then
        return inputstr
    end
    return nil -- 如果没有足够的分割部分，返回nil
end

local state = ya.sync(function() return tostring(cx.active.current.cwd) end)

local function fail(s, ...) ya.notify { title = "Fzf", content = string.format(s, ...), timeout = 5, level = "error" } end

function M:entry(job)
	local args = job.args
	local _permit = ya.hide()
	local cwd = state()
	local shell_value = ya.target_family() == "windows" and "nu" or os.getenv("SHELL"):match(".*/(.*)")
	local cmd_args = ""

	local preview_cmd = [===[line={2} && begin=$( if [[ $line -lt 7 ]]; then echo $((line-1)); else echo 6; fi ) && bat --highlight-line={2} --color=always --line-range $((line-begin)):$((line+10)) {1}]===]
	if ya.target_family() == "windows" then
		preview_cmd = [[bat --highlight-line={2} --color=always --line-range {2}: {1}]]
	elseif shell_value == "fish" then
		preview_cmd = [[set line {2} && set begin ( test $line -lt 7  &&  echo (math "$line-1") || echo  6 ) && bat --highlight-line={2} --color=always --line-range (math "$line-$begin"):(math "$line+10") {1}]]
	elseif shell_value == "nu" then
		preview_cmd = [[let line = ({2} | into int); let begin = if $line < 7 { $line - 1 } else { 6 }; bat --highlight-line={2} --color=always --line-range $'($line - $begin):($line + 10)' {1}]]
	end
  	if ya.target_family() == "windows" and args[1] == "fzf" then
		cmd_args = [[fzf --preview="bat --color=always {}"]]
	elseif ya.target_family() == "windows" and args[1] == "rg" then
		local rg_prefix = [[rg --colors "path:fg:blue" --colors "line:fg:red" --colors "column:fg:yellow" --column --line-number --no-heading --color=always --smart-case ]]
		cmd_args = [[fzf --ansi --disabled --bind "start:reload:]]
			.. rg_prefix
			.. [[{q}" --bind "change:reload:]]
			.. rg_prefix
			.. [[{q}" --delimiter ":" --preview "]]
			.. preview_cmd
			.. [[" --preview-window "up,60%" --nth "3.."]]
  	elseif ya.target_family() == "windows" then
		cmd_args = [[rg --color=always --line-number --no-heading --smart-case "" | fzf --ansi --preview="]] .. preview_cmd .. [[" --delimiter=":" --preview-window="up:60%" --nth="3.."]]
	elseif args[1] == "fzf" then
		cmd_args = [[fzf --preview="bat --color=always {}"]]
	elseif args[1] == "rg" and shell_value == "fish" then
		cmd_args = [[
			RG_PREFIX="rg --colors 'path:fg:blue' --colors 'line:fg:red' --colors 'column:fg:yellow' --column --line-number --no-heading --color=always --smart-case " \
			fzf --ansi --disabled \
				--bind "start:reload:$RG_PREFIX {q}" \
				--bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
				--delimiter : \
				--preview ']] .. preview_cmd .. [[' \
				--preview-window 'up,60%' \
				--nth '3..'
		]]
	elseif args[1] == "rg" and (shell_value == "bash" or shell_value == "zsh")  then
		cmd_args = [[
			RG_PREFIX="rg --colors 'path:fg:blue' --colors 'line:fg:red' --colors 'column:fg:yellow' --column --line-number --no-heading --color=always --smart-case "
			fzf --ansi --disabled \
				--bind "start:reload:$RG_PREFIX {q}" \
				--bind "change:reload:sleep 0.1; $RG_PREFIX {q} || true" \
				--delimiter : \
				--preview ']] .. preview_cmd .. [[' \
				--preview-window 'up,60%' \
				--nth '3..'
		]]
	elseif args[1] == "rg" and shell_value == "nu" then
		local rg_prefix = "rg --colors 'path:fg:blue' --colors 'line:fg:red' --colors 'column:fg:yellow' --column --line-number --no-heading --color=always --smart-case "
		cmd_args = [[fzf --ansi --disabled --bind "start:reload:]]
			.. rg_prefix
			.. [[{q}" --bind "change:reload:sleep 100ms; try { ]]
			.. rg_prefix
			.. [[{q} }" --delimiter : --preview ']]
			.. preview_cmd
			.. [[' --preview-window 'up,60%' --nth '3..']]
	else
		cmd_args = [[rg --color=always --line-number --no-heading --smart-case '' | fzf --ansi --preview=']] .. preview_cmd .. [[' --delimiter=':' --preview-window='up:60%' --nth='3..']]
	end

	local child, err =
		Command(shell_value):args({"-c", cmd_args}):cwd(cwd):stdin(Command.INHERIT):stdout(Command.PIPED):stderr(Command.INHERIT):spawn()

	if not child then
		return fail("Spawn `rfzf` failed with error code %s. Do you have it installed?", err)
	end

	local output, err = child:wait_with_output()
	if not output then
		return fail("Cannot read `fzf` output, error code %s", err)
	elseif not output.status.success and output.status.code ~= 130 then
		return fail("`fzf` exited with error code %s", output.status.code)
	end

	if output.stdout == "" then
		return
	end

	local target = output.stdout:gsub("\n$", "")

    local file_url = splitAndGetNth(target,":",1)
	local line_number = splitAndGetNth(target,":",2)
	line_number = line_number and line_number or 1
	init_ui_data(cwd.."/"..file_url)
	local default_action = get_default_action()

	if (default_action == "menu" or default_action == nil) and args[1] ~= "fzf" then
		_permit:drop()
		toggle_ui()
		while true do
			local cand = self.keys[ya.which { cands = self.keys, silent = true }]
			if cand then
				if cand.run == "quit" then
					set_option(false)
					toggle_ui()
					break
				elseif cand.run == "select" then
					set_option(true)
					toggle_ui()
					break
				elseif cand.run == "down" then
					update_cursor(1)
				elseif cand.run == "up" then
					update_cursor(-1)
				end
			end
		end
		_permit = ya.hide()
	end

	if (default_action == "nvim" or get_option() == "nvim" ) and args[1] ~= "fzf" then
		os.execute("nvim +"..line_number.." -n "..file_url)
	elseif (default_action == "helix" or get_option() == "helix" ) and args[1] ~= "fzf" then
		os.execute("hx +"..line_number.." "..file_url)
	elseif (default_action == "jump" or get_option() == "jump" or args[1] == "fzf") and file_url ~= ""  then
		ya.mgr_emit(file_url:match("[/\\]$") and "cd" or "reveal", { file_url })
	else
		return
	end

end

function M:reflow() return { self } end

function M:redraw()
	local rows = {}

	rows[1] = ui.Row { "open with nvim" }
	rows[2] = ui.Row { "open with helix" }
	rows[3] = ui.Row { "reach at yazi" }
	return {
		ui.Clear(self._area),
		ui.Border(ui.Border.ALL)
			:area(self._area)
			:type(ui.Border.ROUNDED)
			:style(ui.Style():fg("#82ab3a"))
			:title(ui.Line(self.title):align(ui.Line.CENTER):fg(self.title_color)),
		ui.Table(rows)
			:area(self._area:pad(ui.Pad(1, 2, 1, 2)))
			:header(ui.Row({ "Action for:"..self.file_url }):style(ui.Style():bold():fg("#e73c80")))
			:row(self.cursor)
			:row_style(ui.Style():fg("#82ab3a"):underline()),
	}
end


function M.fail(s, ...)
	ya.mgr_emit("plugin", {"mount", "refresh" })
	ya.notify { title = "fg", content = string.format(s, ...), timeout = 10, level = "error" }
end

function M:click() end

function M:scroll() end

function M:touch() end

function M:setup(config)
	self.default_action = (config and config.default_action) and config.default_action or "menu"
end

return M

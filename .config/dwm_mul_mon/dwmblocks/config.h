//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
	/* {"^c1^",	"~/.local/bin/my_scripts/spotify_dwmblocks.sh",	5,	12}, */
	{"",	"~/.local/bin/my_scripts/spotify_dwmblocks.sh",	5,	12},
	/* {"",	"~/.local/bin/statusbar/sb-internet",	5,	6}, */
	/* {"",	"~/.local/bin/statusbar/sb-forecast",	18000,	20}, */
	/* {"",	"~/.local/bin/statusbar/sb-volumetwo.sh",	0,	11}, */

	{"^2^   ",  "~/.local/bin/dwmblocks/weather", 	 1800, 				 5},
	/* {"   ",  "~/.local/bin/dwmblocks/weather", 	 1800, 				 5}, */
	{"^3^  ",  "~/.local/bin/dwmblocks/cputemp", 	5, 					4},
	/* {"  ",  "~/.local/bin/dwmblocks/cputemp", 	5, 					4}, */
	/* {"^4^ ",	"~/.local/bin/statusbar/sb-volume",	0,	10}, */
	{"^4^ ",	"~/.local/bin/statusbar/sb-volume",	0,	10},
	/* {" ",	"~/.local/bin/statusbar/sb-volume",	0,	10}, */
	{"^5^ ",	"~/.local/bin/statusbar/sb-internet",	5,	3},
	/* {"^5^ ",	"~/.local/bin/statusbar/sb-battery_col",	5,	3}, */
	/* {" ",	"~/.local/bin/statusbar/sb-battery",	5,	3}, */
	{"^6^  ",	"~/.local/bin/statusbar/sb-clock",	60,	1},
	/* {"  ",	"~/.local/bin/statusbar/sb-clock",	60,	1}, */
};

/*Icons:       婢墳  */


//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
/* static char *delim = " | "; */
static char *delim = " ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }

//Modify this file to change what commands output to your statusbar, and recompile using the make command.

/* static const Block blocks[] = { 
	 Icon	Command		Update Interval	Update Signal 
	{"⌨", "sb-kbselect", 0, 30},
	{"", "cat /tmp/recordingicon 2>/dev/null",	0,	9},
	{"",	"~/.local/bin/statusbar/sb-tasks",	10,	26},
	{"",	"~/.local/bin/statusbar/sb-music",	0,	11},
	{"",	"~/.local/bin/statusbar/sb-pacpackages",	0,	8},
	{"",	"~/.local/bin/statusbar/sb-news",		0,	6},
	{"",	"sb-price lbc \"LBRY Token\" 📚",			9000,	22},
	{"",	"sb-price bat \"Basic Attention Token\" 🦁",	9000,	20},
	{"",	"sb-price link \"Chainlink\" 🔗",			300,	25},
	{"",	"sb-price xmr \"Monero\" 🔒",			9000,	24},
	{"",	"sb-price eth Ethereum 🍸",	9000,	23},
	{"",	"sb-price btc Bitcoin 💰",				9000,	21},
	{"",	"~/.local/bin/statusbar/sb-torrent",	20,	7},
	{"",	"sb-memory",	10,	14},
	{"",	"sb-cpu",		10,	18},
	{"",	"sb-moonphase",	18000,	17},
	{"",	"~/.local/bin/statusbar/sb-forecast",	18000,	5},
	{"",	"~/.local/bin/statusbar/sb-mailbox",	180,	12},
	{"",	"~/.local/bin/statusbar/sb-nettraf",	1,	16},
	{"",	"~/.local/bin/statusbar/sb-volume",	0,	10},
	{"",	"~/.local/bin/statusbar/sb-battery",	5,	3},
	{"",	"~/.local/bin/statusbar/sb-clock",	60,	1},
	{"",	"~/.local/bin/statusbar/sb-internet",	5,	4},
	{"",	"~/.local/bin/statusbar/sb-help-icon",	0,	15},
};*/

static const Block blocks[] = {
	/*Icon*/	/*Command*/		/*Update Interval*/	/*Update Signal*/
	{"",	"~/.local/bin/my_scripts/spotify_dwmblocks.sh",	5,	12},
	/* {"",	"~/.local/bin/statusbar/sb-internet",	5,	6}, */
	/* {"",	"~/.local/bin/statusbar/sb-forecast",	18000,	20}, */
	/* {"",	"~/.local/bin/statusbar/sb-volumetwo.sh",	0,	11}, */
	{"   ",  "~/.local/bin/dwmblocks/weather", 	 1800, 				 5},
	{"  ",  "~/.local/bin/dwmblocks/cputemp", 	5, 					4},
	{" ",	"~/.local/bin/statusbar/sb-volume",	0,	10},
	{" ",	"~/.local/bin/statusbar/sb-battery",	5,	3},
	{"  ",	"~/.local/bin/statusbar/sb-clock",	60,	1},
};

/*Icons:       婢墳  */


//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
/* static char *delim = " | "; */
static char *delim = " ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:

// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }

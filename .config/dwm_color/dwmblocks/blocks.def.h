//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/	 	/*Update Interval*/	/*Update Signal*/
	/* {"<\x02  ", "~/.local/bin/dwmblocks_test/updates", 	120, 				0}, */

	{"\x03﬙  ",  "~/.local/bin/dwmblocks_test/upt", 		10, 				0},
 
	{"\x04﨎  ",  "~/.local/bin/dwmblocks_test/weather", 	 1800, 				 0},

	{"\x05  ",  "~/.local/bin/dwmblocks_test/cputemp", 	1, 					0},

	{"\x06  ",  "~/.local/bin/dwmblocks_test/mem", 		5, 					0},

	/* {"\x07  ",  "~/.local/bin/dwmblocks_test/xkb-switch", 	1, 					10}, */

	/* {"\x08  ",  "~/.local/bin/dwmblocks_test/pamixer --get-volume-human", 1, 	0}, */

	{"\x09  ",  "~/.local/bin/dwmblocks_test/clock", 		5, 					0},
};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = "<";
static unsigned int delimLen = 5;

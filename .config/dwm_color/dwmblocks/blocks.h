//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
	/*Icon*/	/*Command*/	 	/*Update Interval*/	/*Update Signal*/

	/* {"\x02  ",  "~/.local/bin/dwmblocks/updates", 		120, 				0}, */
	/* {"\x04﬙  ",  "~/.local/bin/dwmblocks/upt", 		10, 				0}, */
	/* {"\x07  ",  "~/.local/bin/dwmblocks/mem", 		5, 					0}, */
	/* {"\x07 﨎 ",  "~/.local/bin/dwmblocks/xkb-switch", 	1, 					10}, */

	{"<\x03 ", "~/.local/bin/my_scripts/spotify.sh", 	10, 				0},
	{"\x04   ",  "~/.local/bin/dwmblocks/weather", 	 1800, 				 0},
	{"\x01  ",  "~/.local/bin/dwmblocks/cputemp", 	1, 					0},
	{"\x08 ",  "~/.local/bin/statusbar/sb-internet", 	10, 					0},
	{"\x05 ",  "~/.local/bin/statusbar/sb-battery", 	10, 					0},
	/* {"\x06  ",  "pamixer --get-volume-human", 1, 	0}, */
	{"\x06"  ,  "~/.local/bin/statusbar/sb-volume2",		1,						0},
	{"\x09 ",  "~/.local/bin/dwmblocks/clock", 		60, 					0},
	/* {"\x09 ",  "~/.local/bin/statusbar/sb-clock", 		60, 					0}, */

	// 1: Orange (D)
	// x: yellow
	// 3: blue, (D)
	// 4: green
	// 5: yellow (D)
	// 6: purple
	// x: light blue (D)
	// 8: green
	// 9: blue (D)

};

//sets delimeter between status commands. NULL character ('\0') means no delimeter.
static char delim[] = "<";
static unsigned int delimLen = 5;

//Modify this file to change what commands output to your statusbar, and recompile using the make command.

static const Block blocks[] = {
    /*Icon*/        /*Command*/                                     /*Update Interval*/     /*Update Signal*/
    /* {"^c1^",        "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12}, */
    {"",            "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12},
    {"^2^  ",      "~/.local/bin/statusbar/weather",               1800,                   5},
    {"^3^  ",      "~/.local/bin/statusbar/cputemp",               5,                      4},
    {"^4^ ",        "~/.local/bin/statusbar/sb-volume",             0,                      10},
    /* {"^5^ ",        "~/.local/bin/statusbar/sb-internet",           5,                      3}, */
    {"^5^ ",        "~/.local/bin/statusbar/sb-battery",            5,                      3},
    {"^6^  ",      "~/.local/bin/statusbar/sb-clock",              60,                     1},
};

/*Icons:            婢 墳  */

//Sets delimiter between status commands. NULL character ('\0') means no delimiter.
/* static char *delim = " | "; */
static char *delim = " ";

// Have dwmblocks automatically recompile and run when you edit this file in
// vim with the following line in your vimrc/init.vim:
// autocmd BufWritePost ~/.local/src/dwmblocks/config.h !cd ~/.local/src/dwmblocks/; sudo make install && { killall -q dwmblocks;setsid dwmblocks & }

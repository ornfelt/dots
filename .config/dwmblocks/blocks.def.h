//Modify this file to change what commands output to your statusbar, and recompile using the make command.
static const Block blocks[] = {
    /*Icon*/        /*Command*/                                     /*Update Interval*/     /*Update Signal*/
    /* {"^c1^",        "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12}, */
    {"",            "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12},
    {"",            "~/.local/bin/statusbar/sb-claude",             30,                     6},
    /* net down/up, memory and cpu, shown/hidden with mod-ctrl-p (sb-sysinfo toggle), a click shows details */
    {"",            "~/.local/bin/statusbar/sb-sysinfo net",        2,                      13},
    {"",            "~/.local/bin/statusbar/sb-sysinfo mem",        2,                      14},
    {"",            "~/.local/bin/statusbar/sb-sysinfo cpu",        2,                      15},
    {"^2^  ",      "~/.local/bin/statusbar/weather",               1800,                   5},
    {"^3^  ",      "~/.local/bin/statusbar/cputemp",               5,                      4},
    {"^4^ ",        "~/.local/bin/statusbar/sb-volume",             0,                      10},
    /* {"^5^ ",        "~/.local/bin/statusbar/sb-internet",           5,                      3}, */
    {"^5^ ",        "~/.local/bin/statusbar/sb-battery",            5,                      3},
    {"^6^  ",      "~/.local/bin/statusbar/sb-clock",              5,                      1},
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = " ";
static unsigned int delimLen = 5;

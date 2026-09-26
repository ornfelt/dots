/* See LICENSE file for copyright and license details. */
/* Mirrors dwmblocksr/config/config.toml */
//dwmblocksc configuration: ~/.config/dwmblocksc/blocks.h, compiled in.
//Modify this file to change what commands output to your statusbar, then rebuild
//(make && sudo make install) and restart dwmblocksc.
//Each command runs with `/bin/sh -c`, so ~ and shell syntax work; only the
//first line of its output is used. A block is updated every interval
//seconds (0 means only on its signal) and on the signal SIGRTMIN+signal
//(0 means none), e.g. `pkill -RTMIN+10 dwmblocksc`. A click on a block with a
//signal runs its command with BLOCK_BUTTON=<button> set.
//Icons and output may contain status2d codes like ^2^ or ^c#rrggbb^, which
//dwm draws.
//HasBattery keeps a block only when there is a battery
//(/sys/class/power_supply/BAT*), NoBattery only when there is none;
//without it the block is always shown. Here sb-battery is only shown on a
//machine with a battery.
static const Block blocks[] = {
    /*Icon*/        /*Command*/                                     /*Update Interval*/     /*Update Signal*/   /*Battery*/
    /* {"^c1^",        "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12}, */
    {"",            "~/.local/bin/my_scripts/spotify_dwmblocks.sh", 5,                      12},
    {"",            "~/.local/bin/statusbar/sb-claude",             30,                     6},
    /* net down/up, memory and cpu, shown/hidden with mod-ctrl-p (sb-sysinfo toggle), a click shows details */
    {"",            "~/.local/bin/statusbar/sb-sysinfo net",        2,                      13},
    {"",            "~/.local/bin/statusbar/sb-sysinfo mem",        2,                      14},
    {"",            "~/.local/bin/statusbar/sb-sysinfo cpu",        2,                      15},
    /* network: wifi/ethernet, cyan online, red offline, orange while restarting NetworkManager; clicks: details, restart, wifi menu */
    {"",            "~/.local/bin/statusbar/sb-network",            3,                      16},
    {"^2^  ",      "~/.local/bin/statusbar/weather",               1800,                   5},
    {"^3^  ",      "~/.local/bin/statusbar/cputemp",               5,                      4},
    {"^4^ ",        "~/.local/bin/statusbar/sb-volume",             0,                      10},
    {"^5^ ",        "~/.local/bin/statusbar/sb-battery",            5,                      3,                  HasBattery},
    {"^6^  ",      "~/.local/bin/statusbar/sb-clock",              5,                      1},
};

//sets delimiter between status commands. NULL character ('\0') means no delimiter.
static char delim[] = " ";
//at most this many bytes of the delimiter are used
static unsigned int delimLen = 5;

//1 runs the block commands in parallel, so a slow command (e.g. one waiting on
//the network) can't hold up the other blocks, signals and clicks. 0 runs them
//one at a time like upstream dwmblocks.
#ifndef ASYNC
#define ASYNC 1
#endif

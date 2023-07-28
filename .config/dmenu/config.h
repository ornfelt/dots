/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom */
static int centered = 1;                    /* -c option; centers dmenu on screen */
static int min_width = 500;                 /* minimum width when centered */
static int max_width = 900;                 /* minimum width when centered */

/* -fn option overrides fonts[0]; default X11 font or font set */
/* static const char *fonts[] = { "JetBrainsMono Nerd Font:size=11:style=bold:antialias=true:autohint=true", "JoyPixels:pixelsize=13:antialias=true:autohint=true" }; */
static const char *fonts[] = { "JetBrainsMono Nerd Font:size=11:style=bold" };
// Original:
/* static const char *fonts[] = {"monospace:size=10"}; */

static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *colors[SchemeLast][2] = {
    /*              fg          bg       */
    [SchemeNorm] = { "#ebdbb2", "#282828" },
    /* [SchemeSel] = { "#ebdbb2", "#98971a" }, */
    [SchemeSel] = { "#ebdbb2", "#458588" },
    [SchemeOut] = { "#ebdbb2", "#8ec07c" },
};

/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";

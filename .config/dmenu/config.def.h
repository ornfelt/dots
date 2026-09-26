/* See LICENSE file for copyright and license details. */
/* Default settings; can be overriden by command line. */

static int topbar = 1;                      /* -b  option; if 0, dmenu appears at bottom     */
static int centered = 0;                    /* -c option; centers dmenu on screen */
static int min_width = 500;                    /* minimum width when centered */
static int max_width = 1200;                   /* maximum width when centered */
static const float centered_width = 0;        /* width when centered: this part of the monitor, 0 fits the items between min_width and max_width; -W sets it in pixels */
static const float menu_height_ratio = 4.0f;  /* This is the ratio used in the original calculation */
/* -fn option overrides fonts[0]; default X11 font or font set */
static const char *fonts[] = {
	"monospace:size=10"
};
static const char *prompt      = NULL;      /* -p  option; prompt to the left of input field */
static const char *prompt_suffix = "";      /* drawn after the prompt */
static const int highlight_italic = 0;      /* draw the matches in italic */
static const char *colors[SchemeLast][2] = {
	/*     fg         bg       */
	/* the bg of the *Highlight schemes is taken from their base scheme */
	[SchemeNorm] = { "#ebdbb2", "#282828" },
	[SchemeSel] = { "#ebdbb2", "#98971a" },
	[SchemeSelHighlight] = { "#ffc978", "#98971a" },
	[SchemeNormHighlight] = { "#ffc978", "#282828" },
	[SchemeOut] = { "#282828", "#8ec07c" },
	[SchemeOutHighlight] = { "#9d0006", "#8ec07c" },
	[SchemePrompt] = { "#ebdbb2", "#98971a" },
	[SchemeNormAlt] = { "#ebdbb2", "#282828" },     /* every other list item */
	[SchemeBorder] = { "#98971a", "#98971a" },      /* fg: window border and the line under the input */
};
/* -l option; if nonzero, dmenu uses vertical list with given number of lines */
static unsigned int lines      = 0;
/* -O option; 1: list the matches in the order of stdin, like rofi; 0: exact
 * matches first, then prefix matches, then the rest */
static int input_order = 0;
/* 1: the vertical list keeps its -l lines when there are fewer items, like
 * rofi; 0: it shrinks to them */
static const int fixed_lines = 0;
/* -g option; columns of the vertical list, a grid filled column by column */
static unsigned int columns    = 1;
/* -eh option; lines of text per item (an item's own lines, read with -sep) */
static unsigned int item_lines = 1;

/*
 * Characters not considered part of a word while deleting words
 * for example: " /?\"&[]"
 */
static const char worddelimiters[] = " ";

/* Size of the window border */
static unsigned int border_width = 0;
/* space around and between the input and the items, and the thickness of the line between them */
static int padding = 0;

/* super + this key cancels like Escape: my WMs open the layout menu with
 * mod-r, so it closes it again (rofi's -kb-cancel in layout_menu.sh) */
static const KeySym supercancelkey = XK_r;

/* two clicks on an item within this many milliseconds accept it */
static const unsigned int doubleclick_ms = 300;

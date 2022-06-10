/* appearance */
static const unsigned int borderpx       = 3;   /* border pixel of windows */
static const unsigned int snap           = 32;  /* snap pixel */
static const unsigned int gappih         = 10;  /* horiz inner gap between windows */
static const unsigned int gappiv         = 10;  /* vert inner gap between windows */
static const unsigned int gappoh         = 10;  /* horiz outer gap between windows and screen edge */
static const unsigned int gappov         = 10;  /* vert outer gap between windows and screen edge */
static const int smartgaps_fact          = 1;   /* gap factor when there is only one client; 0 = no gaps, 3 = 3x outer gaps */
static const char autostartblocksh[]     = "autostart_blocking.sh";
static const char autostartsh[]          = "autostart.sh";
static const char dwmdir[]               = "dwm";
static const char localshare[]           = ".local/share";
static const int showbar                 = 1;   /* 0 means no bar */
static const int topbar                  = 1;   /* 0 means bottom bar */
static const int bar_height              = 24;   /* 0 means derive from font, >= 1 explicit height */
static const int vertpad                 = 10;  /* vertical padding of bar */
static const int sidepad                 = 10;  /* horizontal padding of bar */
/* Status is to be shown on: -1 (all monitors), 0 (a specific monitor by index), 'A' (active monitor) */
static const int statusmon               = -1;
static const unsigned int systrayspacing = 2;   /* systray spacing */
static const int showsystray             = 0;   /* 0 means no systray */
/* Indicators: see patch/bar_indicators.h for options */
static int tagindicatortype              = INDICATOR_BOTTOM_BAR_SLIM;
static int tiledindicatortype            = INDICATOR_NONE;
static int floatindicatortype            = INDICATOR_TOP_LEFT_SQUARE;
/* static const char *fonts[]               = { "JetBrainsMono Nerd Font:size=11:style=bold:antialias=true:autohint=true, Inconsolata Nerd Font:size=15", "Nerd Font Complete Mono:size=13","FontAwesome:size=15","FontAwesome5Brands:size=12:antialias:true", "FontAwesome5Free:size=12:antialias:true", "FontAwesome5Free:style=Solid:size=12:antialias:true" }; */
static const char *fonts[]               = { "JetBrainsMono Nerd Font:size=11:style=bold:antialias=true:autohint=true", "JoyPixels:pixelsize=13:antialias=true:autohint=true" };
/* static char *fonts[]          = { "Linux Libertine Mono:size=12", "Mono:pixelsize=12:antialias=true:autohint=true", "FontAwesome:size=15","FontAwesome5Brands:size=13:antialias:true", "FontAwesome5Free:size=13:antialias:true", "FontAwesome5Free:style=Solid:size=13:antialias:true", "Inconsolata Nerd Font:size=16" }; */

// theme
#include "themes/gruvbox.h"
#include <X11/XF86keysym.h>

static char *colors[][ColCount] = {
	/*                       fg                bg                border                float */
	[SchemeNorm]         = { normfgcolor,      normbgcolor,      normbordercolor,      normfloatcolor },
	[SchemeSel]          = { selfgcolor,       selbgcolor,       selbordercolor,       selfloatcolor },
	[SchemeTitleNorm]    = { titlenormfgcolor, titlenormbgcolor, titlenormbordercolor, titlenormfloatcolor },
	[SchemeTitleSel]     = { titleselfgcolor,  titleselbgcolor,  titleselbordercolor,  titleselfloatcolor },
	[SchemeTagsNorm]     = { tagsnormfgcolor,  tagsnormbgcolor,  tagsnormbordercolor,  tagsnormfloatcolor },
	[SchemeTagsSel]      = { tagsselfgcolor,   tagsselbgcolor,   tagsselbordercolor,   tagsselfloatcolor },
	[SchemeHidNorm]      = { hidnormfgcolor,   hidnormbgcolor,   c000000,              c000000 },
	[SchemeHidSel]       = { hidselfgcolor,    hidselbgcolor,    c000000,              c000000 },
	[SchemeUrg]          = { urgfgcolor,       urgbgcolor,       urgbordercolor,       urgfloatcolor },
};

/* Tags
 * In a traditional dwm the number of tags in use can be changed simply by changing the number
 * of strings in the tags array. This build does things a bit different which has some added
 * benefits. If you need to change the number of tags here then change the NUMTAGS macro in dwm.c.
 *
 * Examples:
 *
 *  1) static char *tagicons[][NUMTAGS*2] = {
 *         [DEFAULT_TAGS] = { "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F", "G", "H", "I" },
 *     }
 *
 *  2) static char *tagicons[][1] = {
 *         [DEFAULT_TAGS] = { "•" },
 *     }
 *
 * The first example would result in the tags on the first monitor to be 1 through 9, while the
 * tags for the second monitor would be named A through I. A third monitor would start again at
 * 1 through 9 while the tags on a fourth monitor would also be named A through I. Note the tags
 * count of NUMTAGS*2 in the array initialiser which defines how many tag text / icon exists in
 * the array. This can be changed to *3 to add separate icons for a third monitor.
 *
 * For the second example each tag would be represented as a bullet point. Both cases work the
 * same from a technical standpoint - the icon index is derived from the tag index and the monitor
 * index. If the icon index is is greater than the number of tag icons then it will wrap around
 * until it an icon matches. Similarly if there are two tag icons then it would alternate between
 * them. This works seamlessly with alternative tags and alttagsdecoration patches.
 */
static char *tagicons[][NUMTAGS] = {
	/* [DEFAULT_TAGS] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" }, */
	[DEFAULT_TAGS] = { "", "", "", "", "", "", "", "", "" },
	/* [DEFAULT_TAGS]        = { "一", "二", "三", "四", "五", "六", "七", "八", "九" }, */
	[ALTERNATIVE_TAGS]    = { "A", "B", "C", "D", "E", "F", "G", "H", "I" },
	[ALT_TAGS_DECORATION] = { "<1>", "<2>", "<3>", "<4>", "<5>", "<6>", "<7>", "<8>", "<9>" },
};


/* There are two options when it comes to per-client rules:
 *  - a typical struct table or
 *  - using the RULE macro
 *
 * A traditional struct table looks like this:
 *    // class      instance  title  wintype  tags mask  isfloating  monitor
 *    { "Gimp",     NULL,     NULL,  NULL,    1 << 4,    0,          -1 },
 *    { "Firefox",  NULL,     NULL,  NULL,    1 << 7,    0,          -1 },
 *
 * The RULE macro has the default values set for each field allowing you to only
 * specify the values that are relevant for your rule, e.g.
 *
 *    RULE(.class = "Gimp", .tags = 1 << 4)
 *    RULE(.class = "Firefox", .tags = 1 << 7)
 *
 * Refer to the Rule struct definition for the list of available fields depending on
 * the patches you enable.
 */
static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	 *	WM_WINDOW_ROLE(STRING) = role
	 *	_NET_WM_WINDOW_TYPE(ATOM) = wintype
	 */
	RULE(.wintype  = WTYPE "DIALOG", .isfloating = 1)
	RULE(.wintype  = WTYPE "UTILITY", .isfloating = 1)
	RULE(.wintype  = WTYPE "TOOLBAR", .isfloating = 1)
	RULE(.wintype  = WTYPE "SPLASH", .isfloating = 1)
	RULE(.class    = "Gimp", .isfloating=1, .tags = 1 << 3)
	RULE(.class    = "Lxappearance", .isfloating = 1)
	RULE(.class    = "File-roller", .isfloating = 1)
	RULE(.class    = "obs", .monitor = 1)
	RULE(.instance = "discord", .isfloating = 1)
	RULE(.class    = "mpv", .isfloating = 1)
	RULE(.class    = "Galculator", .isfloating = 1)
	RULE(.class    = "Yad", .isfloating = 1)
	RULE(.class    = "Steam", .tags = 1 << 6)
	RULE(.class    = "Lutris", .tags = 1 << 6, .isfloating = 1)
	RULE(.class    = "Microsoft-edge", .tags = 1 << 1)
	RULE(.class    = "TelegramDesktop", .tags = 1 << 4)
};



/* Bar rules allow you to configure what is shown where on the bar, as well as
 * introducing your own bar modules.
 *
 *    monitor:
 *      -1  show on all monitors
 *       0  show on monitor 0
 *      'A' show on active monitor (i.e. focused / selected) (or just -1 for active?)
 *    bar - bar index, 0 is default, 1 is extrabar
 *    alignment - how the module is aligned compared to other modules
 *    widthfunc, drawfunc, clickfunc - providing bar module width, draw and click functions
 *    name - does nothing, intended for visual clue and for logging / debugging
 */
static const BarRule barrules[] = {
	/* monitor   bar    alignment         widthfunc                drawfunc                clickfunc                name */
	{ -1,        0,     BAR_ALIGN_LEFT,   width_tags,              draw_tags,              click_tags,              "tags" },
	{  0,        0,     BAR_ALIGN_RIGHT,  width_systray,           draw_systray,           click_systray,           "systray" },
	{ -1,        0,     BAR_ALIGN_LEFT,   width_ltsymbol,          draw_ltsymbol,          click_ltsymbol,          "layout" },
	{ statusmon, 0,     BAR_ALIGN_RIGHT,  width_pwrl_status,       draw_pwrl_status,       click_pwrl_status,       "powerline_status" },
	{ -1,        0,     BAR_ALIGN_NONE,   width_wintitle,          draw_wintitle,          click_wintitle,          "wintitle" },
};

/* layout(s) */
static const float mfact     = 0.50; /* factor of master area size [0.05..0.95] */
static const int nmaster     = 1;    /* number of clients in master area */
static const int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int decorhints  = 0;    /* 1 means respect decoration hints */


static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[\\]=",      dwindle },    /* first entry is default */
	{ "><>",      NULL },    /* no layout function means floating behavior */
	{ "[M]",      monocle },
	{ "TTT",      bstack },
	{ "|M|",      centeredmaster },
	{ "[]",     tile },
	{ "HHH",      grid },
	{ NULL,       NULL },
};


/* key definitions */
#define MODKEY Mod4Mask
#define PrintScr 0x0000ff61
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },



/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
/* static const char *termcmd[] = { "st", NULL }; */
static const char *termcmd[] = { "urxvt", NULL };
/* static const char *termcmd[] = { "kitty", NULL }; */
static const char *inhibitor_on[] = { "inhibit_activate", NULL };
static const char *inhibitor_off[] = { "inhibit_deactivate", NULL };

static Key keys[] = {

	/* modifier                     key            function                argument */

	{ MODKEY,                       XK_Return,     spawn,                  {.v = termcmd } },
	{ MODKEY,                       XK_b,          togglebar,              {0} },
	{ MODKEY,                       XK_j,          focusstack,             {.i = +1 } },
	{ MODKEY,                       XK_h,          focusstack,             {.i = +1 } },
	{ MODKEY,                       XK_k,          focusstack,             {.i = -1 } },
	{ MODKEY,                       XK_l,          focusstack,             {.i = -1 } },
	{ MODKEY,                       XK_s,          swapfocus,              {.i = -1 } },
	{ MODKEY|ShiftMask,                       XK_a,          incnmaster,             {.i = +1 } },
	{ MODKEY|ShiftMask,                       XK_d,          incnmaster,             {.i = -1 } },
	{ MODKEY,                       XK_Left,       setmfact,               {.f = -0.01} },
	{ MODKEY,                       XK_Right,      setmfact,               {.f = +0.01} },
	{ MODKEY|ShiftMask,             XK_Up,         setcfact,               {.f = +0.1} },
	{ MODKEY|ShiftMask,             XK_Down,       setcfact,               {.f = -0.15} },
	{ MODKEY,						XK_y,			setmfact,				{.f = -0.05} },
	{ MODKEY,						XK_o,			setmfact,				{.f = +0.05} },
	{ MODKEY|ShiftMask,             XK_o,          setcfact,               {0} },
	{ MODKEY|ShiftMask,             XK_j,          movestack,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_k,          movestack,              {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_h,          movestack,              {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_l,          movestack,              {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_Return,     zoom,                   {0} },

	{ MODKEY|Mod1Mask,              XK_0,          incrihgaps,             {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_0,          incrihgaps,             {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_9,          incrivgaps,             {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_9,          incrivgaps,             {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_8,          incrohgaps,             {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_8,          incrohgaps,             {.i = -1 } },
	{ MODKEY|Mod1Mask,              XK_7,          incrovgaps,             {.i = +1 } },
	{ MODKEY|Mod1Mask|ShiftMask,    XK_7,          incrovgaps,             {.i = -1 } },
	{ MODKEY,						XK_plus,       incrgaps,               {.i = +3 } },
	{ MODKEY,						XK_minus,      incrgaps,               {.i = -3 } },
	{ MODKEY|ShiftMask,				XK_plus,	   incrigaps,			   {.i = +1 } },
	{ MODKEY|ShiftMask,				XK_minus,	   incrigaps,			   {.i = -1 } },
	{ MODKEY|ControlMask,           XK_plus,	   incrogaps,              {.i = +1 } },
	{ MODKEY|ControlMask,			XK_minus,      incrogaps,              {.i = -1 } },
	{ MODKEY,						XK_z,          togglegaps,             {0} },
	{ MODKEY,						XK_x,          togglegaps,             {0} },
	/* { MODKEY,					    XK_x,          defaultgaps,            {0} }, */
	{ MODKEY,                       XK_Tab,        view,                   {0} },
	{ MODKEY,		                XK_q,          killclient,             {0} },
	{ MODKEY|ControlMask|ShiftMask, XK_q,          quit,                   {1} },
	//TODO: change below to less
	{ MODKEY,                       XK_t,          setlayout,              {.v = &layouts[0]} },
	{ MODKEY|ShiftMask,             XK_f,          setlayout,              {.v = &layouts[1]} },
	{ MODKEY|ShiftMask,             XK_m,          setlayout,              {.v = &layouts[2]} },
	{ MODKEY,						XK_space,      togglefloating,         {0} },
	{ MODKEY|ShiftMask,             XK_space,      togglefloating,         {0} },
	{ MODKEY,			            XK_f,          fullscreen,             {0} },
	/* { MODKEY,                       XK_0,          view,                   {.ui = ~0 } }, */
	/* { MODKEY|ShiftMask,             XK_0,          tag,                    {.ui = ~0 } }, */
	{ MODKEY,                       XK_comma,      focusmon,               {.i = -1 } },
	{ MODKEY|ControlMask,           XK_comma,      tagmon,                 {.i = -1 } },
	{ MODKEY|ControlMask,           XK_period,     tagmon,                 {.i = +1 } },
	/* { MODKEY|ShiftMask,             XK_comma,      cyclelayout,            {.i = -1 } }, */
	TAGKEYS(                        XK_1,                                  0)
	TAGKEYS(                        XK_2,                                  1)
	TAGKEYS(                        XK_3,                                  2)
	TAGKEYS(                        XK_4,                                  3)
	TAGKEYS(                        XK_5,                                  4)
	TAGKEYS(                        XK_6,                                  5)
	TAGKEYS(                        XK_7,                                  6)
	TAGKEYS(                        XK_8,                                  7)
	TAGKEYS(                        XK_9,                                  8)

	/* XF86 keys */
	{ 0, XF86XK_AudioMute,		spawn,		SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle ; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioRaiseVolume,	spawn,		SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioLowerVolume,	spawn,		SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_MonBrightnessUp,	spawn,		SHCMD("~/.local/bin/my_scripts/brightness.sh +10") },
	{ 0, XF86XK_MonBrightnessDown,	spawn,		SHCMD("~/.local/bin/my_scripts/brightness.sh -10") },

	/* Custom commands */

	{ MODKEY|ControlMask,             XK_a,          spawn,                  SHCMD("~/.config/rofi/launchers/greenclip/launcher.sh")}, /* rofi clipboard */
	{ 0, 							XK_ISO_Next_Group, 		spawn, 		   SHCMD("pkill -RTMIN+10 dwmblocks")}, /* keyboard indicator */


	{ MODKEY,						XK_a,			spawn,				SHCMD("kitty -e bash -c 'tmux attach | tmux'") },
	{ MODKEY,						XK_section,			spawn,				SHCMD("~/.local/bin/my_scripts/loadEww.sh") },
	{ MODKEY,						XK_c,			spawn,				SHCMD("gnome-calculator") },
	{ MODKEY,                       XK_period,     spawn,				SHCMD("~/.local/bin/my_scripts/emojipick/emojipick")},
	{ MODKEY|ShiftMask,             XK_period,     spawn,               SHCMD("i3lock-fancy && ~/.local/bin/my_scripts/alert_exit.sh && systemctl suspend")},
	{ MODKEY|ShiftMask,             XK_comma,     spawn,               SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.local/bin/my_scripts/suspend.sh")},
	{ MODKEY,						XK_n,		   spawn,		    		SHCMD("~/.local/bin/my_scripts/nautilus_wd.sh") },
	{ MODKEY|ShiftMask,				XK_n,		   spawn,					SHCMD("nautilus -w --no-desktop") },
	{ MODKEY,                       XK_g,          spawn,                  SHCMD("urxvt -e bash -c 'nvim -c 'FZF ~''")}, /* rofi launcher */
	{ MODKEY|ShiftMask,             XK_b,          spawn,                  SHCMD("urxvt -e sudo htop")}, /* rofi powermenu */
	{ MODKEY|ControlMask,           XK_b,          spawn,                  SHCMD("urxvt -e sudo bashtop")}, /* rofi powermenu */
	{ MODKEY,                       XK_v,          spawn,                  SHCMD("~/.local/bin/my_scripts/clip_history.sh")}, /* rofi launcher */
	{ MODKEY|ShiftMask,             XK_v,          spawn,                  SHCMD("~/.local/bin/my_scripts/qr_clip.sh")}, /* rofi clipboard */
	{ MODKEY,						XK_w,			spawn,					SHCMD("kitty -e ranger ~/") },
	{ MODKEY,						XK_e,			spawn,					SHCMD("~/.local/bin/my_scripts/ranger_wd.sh") },
	{ MODKEY|ShiftMask,				XK_e,			spawn,							SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.config/polybar/forest/scripts/powermenu_dwm.sh") },
	{ MODKEY,						XK_r,			spawn,					SHCMD("dmenu_run -fn 'Linux Libertine Mono'") },
	{ MODKEY,						XK_d,			spawn,					SHCMD("rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi") },


	{ MODKEY,                       XK_x,          spawn,                  {.v = inhibitor_on } }, /* activate inhibitor */
	{ MODKEY|ShiftMask,             XK_x,          spawn,                  SHCMD("i3lock-fancy")}, /* rofi powermenu */
	{ MODKEY|ControlMask,           XK_x,          spawn,                  SHCMD("i3lock -i ~/Downloads/lock-wallpaper.png")}, /* rofi powermenu */
	{ MODKEY|ShiftMask,             XK_s,		   spawn,				   SHCMD("import png:- | xclip -selection clipboard -t image/png")},
	{ 0,             		        PrintScr,      spawn,                  SHCMD("~/.local/bin/my_scripts/screenshot_select.sh")}, /* maim screen copy */
	{ MODKEY,             			PrintScr,      spawn,                  SHCMD("~/.local/bin/my_scripts/screenshot.sh")}, /* maim screen */
	{ MODKEY|ShiftMask,          	PrintScr,      spawn,                  SHCMD("")}, /* maim screen */
	{ MODKEY|ControlMask,          	PrintScr,      spawn,                  SHCMD("")}, /* Open recently taken image in ranger*/
};


/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask           button          function        argument */
	{ ClkLtSymbol,          0,                   Button1,        setlayout,      {0} },
	{ ClkLtSymbol,          0,                   Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,                   Button2,        zoom,           {0} },
	{ ClkStatusText,        0,                   Button2,        spawn,          {.v = termcmd } },
	/* placemouse options, choose which feels more natural:
	 *    0 - tiled position is relative to mouse cursor
	 *    1 - tiled postiion is relative to window center
	 *    2 - mouse pointer warps to window center
	 *
	 * The moveorplace uses movemouse or placemouse depending on the floating state
	 * of the selected client. Set up individual keybindings for the two if you want
	 * to control these separately (i.e. to retain the feature to move a tiled window
	 * into a floating position).
	 */
	{ ClkClientWin,         MODKEY,              Button1,        moveorplace,    {.i = 1} },
	{ ClkClientWin,         MODKEY,              Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,              Button3,        resizemouse,    {0} },
	{ ClkClientWin,         MODKEY|ShiftMask,    Button3,        dragcfact,      {0} },
	{ ClkClientWin,         MODKEY|ShiftMask,    Button1,        dragmfact,      {0} },
	{ ClkTagBar,            0,                   Button1,        view,           {0} },
	{ ClkTagBar,            0,                   Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,              Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,              Button3,        toggletag,      {0} },
};

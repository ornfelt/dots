/* See LICENSE file for copyright and license details. */

/* Constants */
/* #define TERMINAL "st" */
#define TERMINAL "urxvt"
/* #define TERMINAL "kitty" */

/* #define TERMCLASS "St" */
#define TERMCLASS "Urxvt"
/* #define TERMCLASS "kitty" */

/* appearance */
static unsigned int borderpx  = 3;        /* border pixel of windows */
static const unsigned int gappx     = 10;       /* default gap between windows in pixels */
static unsigned int snap      = 32;       /* snap pixel */
static unsigned int gappih    = 20;       /* horiz inner gap between windows */
static unsigned int gappiv    = 10;       /* vert inner gap between windows */
static unsigned int gappoh    = 10;       /* horiz outer gap between windows and screen edge */
static unsigned int gappov    = 30;       /* vert outer gap between windows and screen edge */
static int swallowfloating    = 0;        /* 1 means swallow floating windows by default */
static int smartgaps          = 0;        /* 1 means no outer gap when there is only one window */
static int showbar            = 1;        /* 0 means no bar */
static int topbar             = 1;        /* 0 means bottom bar */
/* static const Bool viewontag         = True;     /1* Switch view on tag switch *1/ */
static int viewontag         = 1;     /* Switch view on tag switch */
/* static char *fonts[]          = { "Linux Libertine Mono:size=12", "Mono:pixelsize=12:antialias=true:autohint=true", "FontAwesome:size=15","FontAwesome5Brands:size=13:antialias:true", "FontAwesome5Free:size=13:antialias:true", "FontAwesome5Free:style=Solid:size=13:antialias:true","JetBrainsMono Nerd Font:size=12:style=bold:antialias=true:autohint=true", "Nerd Font Complete Mono:size=13", "JoyPixels:pixelsize=10:antialias=true:autohint=true", "Inconsolata Nerd Font:size=15", "Nerd Font Complete Mono:size=13" }; */
static const char *fonts[]               = { "JetBrainsMono Nerd Font:size=11:style=bold:antialias=true:autohint=true", "JoyPixels:pixelsize=13:antialias=true:autohint=true" };
/* static char *fonts[]          = { "Iosevka, Iosevka Nerd Font:size=12", "Mono:pixelsize=12:antialias=true:autohint=true", "Nerd Font:size=16", "Nerd Font Mono:size=16", "Nerd Font Mono:size=16", "Inconsolata Nerd Font:size=16" }; */
static char normbgcolor[]           = "#222222";
static char normbordercolor[]       = "#444444";
static char normfgcolor[]           = "#bbbbbb";
static char selfgcolor[]            = "#eeeeee";
static char selbordercolor[]        = "#770000";
static char selbgcolor[]            = "#005577";
static char *colors[][3] = {
       /*               fg           bg           border   */
       [SchemeNorm] = { normfgcolor, normbgcolor, normbordercolor },
       [SchemeSel]  = { selfgcolor,  selbgcolor,  selbordercolor  },
};

typedef struct {
	const char *name;
	const void *cmd;
} Sp;
const char *spcmd1[] = {"st", "-n", "spterm", "-g", "120x34", "-e", "python3", NULL };
const char *spcmd2[] = {"st", "-n", "spcalc", "-g", "220x14", NULL };
/* const char *spcmd2[] = {"st", "-n", "spcalc", "-f", "monospace:size=16", "-g", "50x20", "-e", "bc", "-lq", NULL }; */
static Sp scratchpads[] = {
	/* name          cmd  */
	{"spterm",      spcmd1},
	{"spcalc",      spcmd2},
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };
/* static const char *tags[] = { "", "", "", "", "", "", "", "", "" } */

static const Rule rules[] = {
	/* xprop(1):
	 *	WM_CLASS(STRING) = instance, class
	 *	WM_NAME(STRING) = title
	*/
	/* class    instance      title       	 tags mask    isfloating   isterminal  noswallow  monitor */
	{ "Gimp",     NULL,       NULL,       	    1 << 8,       0,           0,         0,        -1 },
	{ TERMCLASS,  NULL,       NULL,       	    0,            0,           1,         0,        -1 },
	{ NULL,       NULL,       "Event Tester",   0,            0,           0,         1,        -1 },
	{ NULL,      "spterm",    NULL,       	    SPTAG(0),     1,           1,         1,        -1 },
	{ NULL,      "spcalc",    NULL,       	    SPTAG(1),     1,           1,         0,        -1 },
	{ NULL,      "gnome-calculator",    NULL,       0,     1,           0,         0,        -1 },
	{ NULL,      "gnome-calendar",    NULL,       0,     1,           0,         0,        -1 },
};

/* layout(s) */
static float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static int nmaster     = 1;    /* number of clients in master area */
static int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"
static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[@]",	spiral },		/* Default: Fibonacci spiral */
	{ "[]=",	tile },			/* Master on left, slaves on right */
	{ "TTT",	bstack },		/* Master on top, slaves on bottom */
	{ "[\\]",	dwindle },		/* Decreasing in size right and leftward */
	{ "[D]",	deck },			/* Master on left, slaves in monocle-like mode on right */
	{ "[M]",	monocle },		/* All windows on top of eachother */
	{ "|M|",	centeredmaster },		/* Master in middle, slaves on sides */
	{ ">M>",	centeredfloatingmaster },	/* Same but master floats */
	{ "><>",	NULL },			/* no layout function means floating behavior */
	{ NULL,		NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define MODKEY1 Mod1Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },
#define STACKKEYS(MOD,ACTION) \
	{ MOD,	XK_j,	ACTION##stack,	{.i = INC(+2) } }, \
	{ MOD,	XK_k,	ACTION##stack,	{.i = INC(-2) } }, \
	{ MOD,	XK_h,	ACTION##stack,	{.i = INC(+1) } }, \
	{ MOD,	XK_l,	ACTION##stack,	{.i = INC(-1) } }, \

	/* { MOD,  XK_v,   ACTION##stack,  {.i = 0 } }, \ */
	/* { MOD, XK_grave, ACTION##stack, {.i = PREVSEL } }, \ */
	/* { MOD, XK_a,     ACTION##stack, {.i = 1 } }, \ */
	/* { MOD, XK_z,     ACTION##stack, {.i = 2 } }, \ */
	/* { MOD, XK_x,     ACTION##stack, {.i = -1 } }, */

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static const char *termcmd[]  = { TERMINAL, NULL };

/*
 * Xresources preferences to load at startup
 */
ResourcePref resources[] = {
		{ "color0",		STRING,	&normbordercolor },
		{ "color8",		STRING,	&selbordercolor },
		{ "color0",		STRING,	&normbgcolor },
		{ "foreground",		STRING,	&normfgcolor },
		{ "color0",		STRING,	&selfgcolor },
		{ "foreground",		STRING,	&selbgcolor },
		{ "borderpx",		INTEGER, &borderpx },
		{ "snap",		INTEGER, &snap },
		{ "showbar",		INTEGER, &showbar },
		{ "topbar",		INTEGER, &topbar },
		{ "nmaster",		INTEGER, &nmaster },
		{ "resizehints",	INTEGER, &resizehints },
		{ "mfact",		FLOAT,	&mfact },
		{ "gappih",		INTEGER, &gappih },
		{ "gappiv",		INTEGER, &gappiv },
		{ "gappoh",		INTEGER, &gappoh },
		{ "gappov",		INTEGER, &gappov },
		{ "swallowfloating",	INTEGER, &swallowfloating },
		{ "smartgaps",		INTEGER, &smartgaps },
};

#include <X11/XF86keysym.h>
#include "shiftview.c"

static Key keys[] = {
	/* modifier                     key        function        argument */
	STACKKEYS(MODKEY,                          focus)
	STACKKEYS(MODKEY|ShiftMask,                push)
	{ MODKEY,			XK_grave,	spawn,	SHCMD("dmenu_run -fn 'Linux Libertine Mono'") },
	TAGKEYS(			XK_1,		0)
	TAGKEYS(			XK_2,		1)
	TAGKEYS(			XK_3,		2)
	TAGKEYS(			XK_4,		3)
	TAGKEYS(			XK_5,		4)
	TAGKEYS(			XK_6,		5)
	TAGKEYS(			XK_7,		6)
	TAGKEYS(			XK_8,		7)
	TAGKEYS(			XK_9,		8)
	{ MODKEY,			XK_0,		view,		{.ui = ~0 } },
	{ MODKEY|ShiftMask,		XK_0,		tag,		{.ui = ~0 } },

	{ MODKEY,			XK_plus,		incrgaps,	{.i = +3 } },
	{ MODKEY,			XK_minus,		incrgaps,	{.i = -3 } },
	{ MODKEY|ShiftMask,		XK_plus,	spawn,		SHCMD("") },
	{ MODKEY|ShiftMask,		XK_minus,	spawn,		SHCMD("") },

	{ MODKEY1,			XK_Tab,	shiftview,	{ .i = +1 } },
	{ MODKEY1|ShiftMask,			XK_Tab,	shiftview,	{ .i = -1 } },
	{ MODKEY,			XK_Tab,		view,		{0} },
	{ MODKEY,			XK_Tab,		view,		{0} },
	{ MODKEY,			XK_q,		killclient,	{0} },
	/* { MODKEY|ShiftMask,             XK_q,      	quit,           {0} }, */
	{ MODKEY|ShiftMask,			XK_x,		spawn,		SHCMD("i3lock-fancy") },
	{ MODKEY|ControlMask,       XK_x,       spawn,      SHCMD("i3lock -i ~/Downloads/lock-wallpaper.png")},
	
	{ MODKEY,			XK_w,		spawn,		SHCMD("urxvt -e ranger ~/") },
	{ MODKEY,			XK_e,		spawn,		SHCMD("~/.local/bin/my_scripts/ranger_wd.sh") },
	{ MODKEY|ShiftMask,			XK_e,		spawn,		SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.config/polybar/forest/scripts/powermenu.sh") },
	
	{ MODKEY,			XK_y,		setmfact,	{.f = -0.05} },
	{ MODKEY,			XK_o,		setmfact,	{.f = +0.05} },
	{ MODKEY|ShiftMask,		XK_u,		incnmaster,     {.i = +1 } },
	{ MODKEY|ShiftMask,		XK_i,		incnmaster,     {.i = -1 } },

	{ MODKEY,			XK_bracketleft,		spawn,		SHCMD("mpc seek -10") },
	{ MODKEY|ShiftMask,		XK_bracketleft,		spawn,		SHCMD("mpc seek -60") },
	{ MODKEY,			XK_bracketright,	spawn,		SHCMD("mpc seek +10") },
	{ MODKEY|ShiftMask,		XK_bracketright,	spawn,		SHCMD("mpc seek +60") },
	{ MODKEY,			XK_backslash,		view,		{0} },

	{ MODKEY,			XK_x,		defaultgaps,	{0} },
	{ MODKEY,			XK_z,		togglegaps,	{0} },

	{ MODKEY|ShiftMask,		XK_s,		spawn,		SHCMD("import png:- | xclip -selection clipboard -t image/png") },
	{ MODKEY|ControlMask,		XK_s,		spawn,		SHCMD("~/.local/bin/my_scripts/tesseract_ocr.sh") },
	{ MODKEY,				XK_d,		spawn,		SHCMD("rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi") },
	{ MODKEY,				XK_r,		spawn,		SHCMD("dmenu_run -fn 'Linux Libertine Mono'") },
	{ MODKEY|ShiftMask,		XK_d,		spawn,		SHCMD("rofi -show run -theme ~/.config/polybar/forest/scripts/rofi/launcher.rasi") },
	{ MODKEY|ShiftMask,		XK_r,		spawn,		SHCMD("rofi -show run -theme ~/.config/polybar/forest/scripts/rofi/launcher.rasi") },
	{ MODKEY,				XK_t,		spawn,		SHCMD("~/.local/bin/my_scripts/script_copy.sh") },
	{ MODKEY|ShiftMask,		XK_t,		spawn,		SHCMD("~/.local/bin/my_scripts/script_helper.sh") },

	/* Layouts */
	{ MODKEY|ShiftMask,			XK_less,		togglesticky,	{0} },
	{ MODKEY,			XK_less,		setlayout,	{.v = &layouts[0]} }, /* Fibonacci spiral */
	{ MODKEY|ControlMask,			XK_t,		setlayout,	{.v = &layouts[1]} }, /* tile */
	{ MODKEY,		XK_s,		setlayout,	{.v = &layouts[2]} }, /* centeredmaster */
	{ MODKEY|ShiftMask,		XK_y,		setlayout,	{.v = &layouts[3]} }, /* dwindle */
	{ MODKEY|ControlMask,	XK_y,		setlayout,	{.v = &layouts[4]} }, /* bstack */
	{ MODKEY|ShiftMask,		XK_u,		setlayout,	{.v = &layouts[5]} }, /* deck*/
	{ MODKEY|ShiftMask,		XK_i,		setlayout,	{.v = &layouts[6]} }, /* monocle */
	{ MODKEY|ShiftMask,		XK_z,		setlayout,	{.v = &layouts[7]} }, /* centeredfloatingmaster */
	{ MODKEY|ShiftMask,		XK_f,		setlayout,	{.v = &layouts[8]} },
	{ MODKEY,			XK_f,		togglefullscr,	{0} },
	/* { MODKEY,			XK_g,		spawn,	{ .i = -1 } }, */
	/* { MODKEY,			XK_g,		shiftview,	{ .i = -1 } }, */
	{ MODKEY,			XK_g,		spawn,		SHCMD("~/.local/bin/my_scripts/fzf_open.sh")},

	{ MODKEY,			XK_semicolon,	shiftview,	{ .i = 1 } },
	{ MODKEY|ShiftMask,		XK_semicolon,	shifttag,	{ .i = 1 } },
	{ MODKEY,			XK_apostrophe,	togglescratch,	{.ui = 0} },
	{ MODKEY|ShiftMask,		XK_apostrophe,	togglescratch,	{.ui = 1} },
	{ MODKEY,			XK_BackSpace,	spawn,		SHCMD("sysact") },
	{ MODKEY|ShiftMask,		XK_BackSpace,	spawn,		SHCMD("sysact") },
	{ MODKEY,			XK_Return,	spawn,		SHCMD("~/.local/bin/my_scripts/term_wd.sh") },
	{ MODKEY|ShiftMask,			XK_Return,	spawn,		{.v = termcmd } },

	{ MODKEY,			XK_c,		spawn,		SHCMD("GTK_THEME=Adwaita:dark gnome-calculator") },
	{ MODKEY|ControlMask,		XK_c,		spawn,		SHCMD("GTK_THEME=Adwaita:dark gnome-calendar") },
	{ MODKEY,			XK_b,		spawn,		SHCMD("urxvt -e htop") },
	{ MODKEY|ShiftMask,			XK_b,		spawn,		 SHCMD("urxvt -e bashtop") },
	{ MODKEY|ControlMask,			XK_b,		spawn,		 SHCMD("urxvt -e ytop") },
	
	/* V is automatically bound above in STACKKEYS */
	/* { MODKEY,		XK_p,		spawn,		SHCMD("") }, */
	{ MODKEY|ShiftMask,		XK_p,			spawn,		SHCMD("mpc pause ; pauseallmpv") },
	{ MODKEY|ShiftMask,			XK_p,		togglebar,	{0} },
	{ MODKEY,			XK_n,		spawn,		SHCMD("~/.local/bin/my_scripts/nautilus_wd.sh") },
	{ MODKEY|ShiftMask,		XK_n,		spawn,		SHCMD("nautilus -w --no-desktop") },
	{ MODKEY,			XK_m,		spawn,		SHCMD("spotify") },
	/* { MODKEY|ShiftMask,		XK_m,		spawn,		SHCMD("pamixer -t; kill -44 $(pidof dwmblocks)") }, */
	{ MODKEY|ShiftMask,			XK_m,		spawn,		 SHCMD("flatpak run org.jamovi.jamovi") },
	{ MODKEY|ControlMask,			XK_m,		spawn,		 SHCMD("~/.local/bin/my_scripts/tstock.sh") },
	{ MODKEY,			XK_comma,	spawn,		SHCMD("mpc prev") },
	{ MODKEY|ShiftMask,             XK_period,     spawn,               SHCMD("i3lock-fancy && ~/.local/bin/my_scripts/alert_exit.sh && systemctl suspend")},
	{ MODKEY|ShiftMask,             XK_comma,     spawn,               SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.local/bin/my_scripts/suspend.sh")},
	{ MODKEY,			XK_v,	spawn,		SHCMD("~/.local/bin/my_scripts/clip_history.sh") },
	{ MODKEY|ShiftMask,		XK_v,	spawn,		SHCMD("~/.local/bin/my_scripts/qr_clip.sh") },
	{ MODKEY,			XK_period,	spawn,		SHCMD("~/.local/bin/my_scripts/emojipick/emojipick") },
	{ MODKEY,						XK_a,			spawn,				SHCMD("urxvt -e bash -c 'tmux attach || tmux'") },
	{ MODKEY,						XK_section,			spawn,				SHCMD("~/.local/bin/my_scripts/loadEww.sh") },
	{ MODKEY|ShiftMask,			XK_section,		toggleviewontag,	{0} },
	
	{ MODKEY,			XK_Left,	focusmon,	{.i = -1 } },
	{ MODKEY|ShiftMask,		XK_Left,	tagmon,		{.i = -1 } },
	{ MODKEY,			XK_Right,	focusmon,	{.i = +1 } },
	{ MODKEY|ShiftMask,		XK_Right,	tagmon,		{.i = +1 } },
	{ MODKEY,			XK_Page_Up,	shiftview,	{ .i = -1 } },
	{ MODKEY|ShiftMask,		XK_Page_Up,	shifttag,	{ .i = -1 } },
	{ MODKEY,			XK_Page_Down,	shiftview,	{ .i = +1 } },
	{ MODKEY|ShiftMask,		XK_Page_Down,	shifttag,	{ .i = +1 } },
	{ MODKEY,			XK_Insert,	spawn,		SHCMD("xdotool type $(grep -v '^#' ~/.local/share/larbs/snippets | dmenu -i -l 50 | cut -d' ' -f1)") },

	{ MODKEY,			XK_F1,		spawn,		SHCMD("groff -mom /usr/local/share/dwm/larbs.mom -Tpdf | zathura -") },
	{ MODKEY,			XK_F2,		spawn,		SHCMD("tutorialvids") },
	{ MODKEY,			XK_F3,		spawn,		SHCMD("displayselect") },
	{ MODKEY,			XK_F4,		spawn,		SHCMD(TERMINAL " -e pulsemixer; kill -44 $(pidof dwmblocks)") },
	/* { MODKEY,			XK_F5,		xrdb,		{.v = NULL } }, */
	{ MODKEY,			XK_F6,		spawn,		SHCMD("torwrap") },
	{ MODKEY,			XK_F7,		spawn,		SHCMD("td-toggle") },
	{ MODKEY,			XK_F8,		spawn,		SHCMD("mw -Y") },
	{ MODKEY,			XK_F9,		spawn,		SHCMD("dmenumount") },
	{ MODKEY,			XK_F10,		spawn,		SHCMD("dmenuumount") },
	{ MODKEY,			XK_F11,		spawn,		SHCMD("mpv --no-cache --no-osc --no-input-default-bindings --profile=low-latency --input-conf=/dev/null --title=webcam $(ls /dev/video[0,2,4,6,8] | tail -n 1)") },
	{ MODKEY,			XK_F12,		spawn,		SHCMD("remaps & notify-send \\\"⌨️ Keyboard remapping...\\\" \\\"Re-running keyboard defaults for any newly plugged-in keyboards.\\\"") },
	{ MODKEY,			XK_space,	zoom,		{0} },
	{ MODKEY|ShiftMask,		XK_space,	togglefloating,	{0} },
	{ 0,				XK_Print,	spawn,		SHCMD("~/.local/bin/my_scripts/screenshot_select.sh") },
	{ ShiftMask,			XK_Print,	spawn,		SHCMD("~/.local/bin/my_scripts/screenshot.sh") },
	{ MODKEY,			XK_Print,	spawn,		SHCMD("~/.local/bin/my_scripts/screenshot_ocr.sh") },

	{ 0, XF86XK_AudioMute,		spawn,		SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle ; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioRaiseVolume,	spawn,		SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%; kill -44 $(pidof dwmblocks)") },
	{ 0, XF86XK_AudioLowerVolume,	spawn,		SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%; kill -44 $(pidof dwmblocks)") },
	/* { 0, XF86XK_AudioPrev,		spawn,		SHCMD("mpc prev") }, */
	/* { 0, XF86XK_AudioNext,		spawn,		SHCMD("mpc next") }, */
	/* { 0, XF86XK_AudioPause,		spawn,		SHCMD("mpc pause") }, */
	/* { 0, XF86XK_AudioPlay,		spawn,		SHCMD("mpc play") }, */
	/* { 0, XF86XK_AudioStop,		spawn,		SHCMD("mpc stop") }, */
	/* { 0, XF86XK_AudioRewind,	spawn,		SHCMD("mpc seek -10") }, */
	/* { 0, XF86XK_AudioForward,	spawn,		SHCMD("mpc seek +10") }, */
	/* { 0, XF86XK_AudioMedia,		spawn,		SHCMD(TERMINAL " -e ncmpcpp") }, */
	/* { 0, XF86XK_AudioMicMute,	spawn,		SHCMD("pactl set-source-mute @DEFAULT_SOURCE@ toggle") }, */
	/* { 0, XF86XK_PowerOff,		spawn,		SHCMD("sysact") }, */
	/* { 0, XF86XK_Calculator,		spawn,		SHCMD(TERMINAL " -e bc -l") }, */
	/* { 0, XF86XK_Sleep,		spawn,		SHCMD("sudo -A zzz") }, */
	/* { 0, XF86XK_WWW,		spawn,		SHCMD("$BROWSER") }, */
	/* { 0, XF86XK_DOS,		spawn,		SHCMD(TERMINAL) }, */
	/* { 0, XF86XK_ScreenSaver,	spawn,		SHCMD("slock & xset dpms force off; mpc pause; pauseallmpv") }, */
	/* { 0, XF86XK_TaskPane,		spawn,		SHCMD(TERMINAL " -e htop") }, */
	/* { 0, XF86XK_Mail,		spawn,		SHCMD(TERMINAL " -e neomutt ; pkill -RTMIN+12 dwmblocks") }, */
	/* { 0, XF86XK_MyComputer,		spawn,		SHCMD(TERMINAL " -e lf /") }, */
	/* /1* { 0, XF86XK_Battery,		spawn,		SHCMD("") }, *1/ */
	/* { 0, XF86XK_Launch1,		spawn,		SHCMD("xset dpms force off") }, */
	/* { 0, XF86XK_TouchpadToggle,	spawn,		SHCMD("(synclient | grep 'TouchpadOff.*1' && synclient TouchpadOff=0) || synclient TouchpadOff=1") }, */
	/* { 0, XF86XK_TouchpadOff,	spawn,		SHCMD("synclient TouchpadOff=1") }, */
	/* { 0, XF86XK_TouchpadOn,		spawn,		SHCMD("synclient TouchpadOff=0") }, */
	{ 0, XF86XK_MonBrightnessUp,	spawn,		SHCMD("~/.local/bin/my_scripts/brightness.sh +10") },
	{ 0, XF86XK_MonBrightnessDown,	spawn,		SHCMD("~/.local/bin/my_scripts/brightness.sh -10") },

};

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkWinTitle, ClkClientWin, or ClkRootWin */
static Button buttons[] = {
	/* click                event mask      button          function        argument */
#ifndef __OpenBSD__
	{ ClkStatusText,        0,              Button1,        sigdwmblocks,   {.i = 1} },
	{ ClkStatusText,        0,              Button2,        sigdwmblocks,   {.i = 2} },
	{ ClkStatusText,        0,              Button3,        sigdwmblocks,   {.i = 3} },
	{ ClkStatusText,        0,              Button4,        sigdwmblocks,   {.i = 4} },
	{ ClkStatusText,        0,              Button5,        sigdwmblocks,   {.i = 5} },
	{ ClkStatusText,        ShiftMask,      Button1,        sigdwmblocks,   {.i = 6} },
#endif
	{ ClkStatusText,        ShiftMask,      Button3,        spawn,          SHCMD(TERMINAL " -e nvim ~/dwm/dwm/dwmblocks/config.h") },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        defaultgaps,	{0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkClientWin,		MODKEY,		Button4,	incrgaps,	{.i = +1} },
	{ ClkClientWin,		MODKEY,		Button5,	incrgaps,	{.i = -1} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
	{ ClkTagBar,		0,		Button4,	shiftview,	{.i = -1} },
	{ ClkTagBar,		0,		Button5,	shiftview,	{.i = 1} },
	{ ClkRootWin,		0,		Button2,	togglebar,	{0} },
};


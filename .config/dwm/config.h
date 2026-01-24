/* See LICENSE file for copyright and license details. */

/* Constants */
/* #define TERMINAL "st" */
/* #define TERMCLASS "St" */
/* #define TERMINAL "urxvt" */
/* #define TERMCLASS "Urxvt" */
/* #define TERMINAL "alacritty" */
/* #define TERMCLASS "alacritty" */
#define TERMINAL "wezterm"
#define TERMCLASS "wezterm"
#define SECTERMINAL "st"

#define FILES "thunar"
//#define FILEX "ranger"
//#define FILEX "lf"
#define FILEX "yazi"

/* appearance */
static unsigned int borderpx    = 3;        /* border pixel of windows */
static const unsigned int gappx = 10;       /* default gap between windows in pixels */
static unsigned int snap        = 32;       /* snap pixel */
static unsigned int gappih      = 20;       /* horiz inner gap between windows */
static unsigned int gappiv      = 20;       /* vert inner gap between windows */
static unsigned int gappoh      = 20;       /* horiz outer gap between windows and screen edge */
static unsigned int gappov      = 20;       /* vert outer gap between windows and screen edge */
static int swallowfloating      = 0;        /* 1 means swallow floating windows by default */
static int smartgaps            = 0;        /* 1 means no outer gap when there is only one window */
static int browsergaps          = 0;        /* 0 means no outer gap when there is only one window and it is firefox */
static int showbar              = 1;        /* 0 means no bar */
static int topbar               = 1;        /* 0 means bottom bar */
static const int focusonwheel       = 0;
/* static char *fonts[]            = { "Linux Libertine Mono:size=12", "Mono:pixelsize=12:antialias=true:autohint=true", "FontAwesome:size=15","FontAwesome5Brands:size=13:antialias:true", "FontAwesome5Free:size=13:antialias:true", "FontAwesome5Free:style=Solid:size=13:antialias:true","JetBrainsMono Nerd Font:size=12:style=bold:antialias=true:autohint=true", "Nerd Font Complete Mono:size=13", "JoyPixels:pixelsize=10:antialias=true:autohint=true", "Inconsolata Nerd Font:size=15", "Nerd Font Complete Mono:size=13" }; */
/* static const char *fonts[]      = { "JetBrainsMono Nerd Font:size=11:style=bold:antialias=true:autohint=true", "JoyPixels:pixelsize=13:antialias=true:autohint=true" }; */
static const char *fonts[]      = { "JetBrainsMono Nerd Font:size=11:style=bold" };
static char normbgcolor[]       = "#282828";
static char normbordercolor[]   = "#282828";
static char normfgcolor[]       = "#ebdbb2";
static char selfgcolor[]        = "#ebdbb2";
static char selbordercolor[]    = "#ebdbb2";
static char selbgcolor[]        = "#282828";
static const char col1[]        = "#98971a";
static const char col21[]       = "#fb4934";
static const char col22[]       = "#ebdbb2";
static const char col23[]       = "#458588";
static const char col24[]       = "#ebdbb2";
static const char col3[]        = "#fabd2f";
static const char col4[]        = "#83a598";
static const char col5[]        = "#d3869b";
static const char col6[]        = "#8ec07c";
static char *colors[][3]        = {
    /*               fg              bg              border   */
    [SchemeNorm] = { normfgcolor,   normbgcolor,    normbordercolor },
    [SchemeSel]  = { selfgcolor,    selbgcolor,     selbordercolor },
};

typedef struct {
    const char *name;
    const void *cmd;
} Sp;
//const char *spcmd1[] = {"st", "-n", "spterm", "-g", "30x30", "-e", "python3", NULL };
//const char *spcmd2[] = {"st", "-n", "spcalc", "-g", "30x30", NULL };
const char *spcmd1[] = {"st", "-n", "spterm", "-e", "python3", NULL };
const char *spcmd2[] = {"st", "-n", "spcalc", NULL };
/* const char *spcmd2[] = {"st", "-n", "spcalc", "-f", "monospace:size=16", "-g", "50x20", "-e", "bc", "-lq", NULL }; */
static Sp scratchpads[] = {
    /* name          cmd  */
    {"spterm",      spcmd1},
    {"spcalc",      spcmd2},
};

/* tagging */
static const char *tags[] = { "1", "2", "3", "4", "5", "6", "7", "8", "9" };
/* static const char *tags[] = { "", "", "", "", "", "", "", "", "" }; */

static const Rule rules[] = {
    /* xprop(1):
     *    WM_CLASS(STRING) = instance, class
     *    WM_NAME(STRING) = title
     */
    /* class        instance                title               tags mask       isfloating   isterminal noswallow   monitor */
    /* { "Gimp",       NULL,                   NULL,               1 << 8,         0,           0,         0,          -1 }, */
    { TERMCLASS,    NULL,                   NULL,               0,              0,           1,         0,          -1 },
    { NULL,         NULL,                   "Event Tester",     0,              0,           0,         1,          -1 },
    { NULL,         "spterm",               NULL,               SPTAG(0),       1,           1,         1,          -1 },
    { NULL,         "spcalc",               NULL,               SPTAG(1),       1,           1,         0,          -1 },
    { NULL,         "gnome-calculator",     NULL,               0,              1,           0,         0,          -1 },
    { NULL,         "gnome-calendar",       NULL,               0,              1,           0,         0,          -1 },
    { NULL,         "yad",                  NULL,               0,              1,           0,         0,          -1 },
    { NULL,         "nm-connection-editor", NULL,               0,              1,           0,         0,          -1 },
};

/* layout(s) */
static float mfact     = 0.55; /* factor of master area size [0.05..0.95] */
static int nmaster     = 1;    /* number of clients in master area */
static int resizehints = 0;    /* 1 means respect size hints in tiled resizals */
static const int refreshrate = 120;  /* refresh rate (per second) for client move/resize */

#define FORCE_VSPLIT 1  /* nrowgrid layout: force two clients to always split vertically */
#include "vanitygaps.c"
static const Layout layouts[] = {
    /* symbol       arrange function */
    { "[@]",        spiral },                   /* Default: Fibonacci spiral */
    { "[]=",        tile },                     /* Master on left, slaves on right */
    { "TTT",        bstack },                   /* Master on top, slaves on bottom */
    { "[\\]",       dwindle },                  /* Decreasing in size right and leftward */
    { "[D]",        deck },                     /* Master on left, slaves in monocle-like mode on right */
    { "[M]",        monocle },                  /* All windows on top of eachother */
    { "|M|",        centeredmaster },           /* Master in middle, slaves on sides */
    { ">M>",        centeredfloatingmaster },   /* Same but master floats */
    { "><>",        NULL },                     /* no layout function means floating behavior */
    { NULL,         NULL },
};

/* key definitions */
#define MODKEY Mod4Mask
#define MODKEY1 Mod1Mask
#define TAGKEYS(KEY,TAG) \
{ MODKEY,                       KEY,      view,         {.ui = 1 << TAG} }, \
{ MODKEY|ControlMask,           KEY,      tag,          {.ui = 1 << TAG} }, \
{ MODKEY|ShiftMask,             KEY,      tagview,      {.ui = 1 << TAG} }, \
{ MODKEY|ControlMask|ShiftMask, KEY,      toggleview,   {.ui = 1 << TAG} },
/* { MODKEY|ControlMask|ShiftMask, KEY,      toggletag,    {.ui = 1 << TAG} }, */
#define STACKKEYS(MOD,ACTION) \
{ MOD,                  XK_j,    ACTION##stack,    {.i = INC(+1) } }, \
{ MOD,                  XK_k,    ACTION##stack,    {.i = INC(-1) } }, \
{ MOD|ControlMask,      XK_j,    ACTION##stack,    {.i = -1 } }, \
{ MOD|ControlMask,      XK_k,    ACTION##stack,    {.i = 0 } }, \
/* { MOD,                  XK_h,    ACTION##stack,    {.i = INC(+1) } }, \ */
/* { MOD,                  XK_l,    ACTION##stack,    {.i = INC(-1) } }, \ */

/* helper for spawning shell commands in the pre dwm-5.0 fashion */
#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

#define STATUSBAR "dwmblocks"

/* commands */
static char dmenumon[2] = "0"; /* component of dmenucmd, manipulated in spawn() */
static const char *termcmd[]  = { TERMINAL, NULL };
//static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn", dmenufont, "-nb", col_gray1, "-nf", col_gray3, "-sb", col_cyan, "-sf", col_gray4, NULL };
static const char *dmenucmd[] = { "dmenu_run", "-m", dmenumon, "-fn JetBrainsMono Nerd Font:size=11:style=bold", NULL };

/*
 * Xresources preferences to load at startup
 */
ResourcePref resources[] = {
    { "color0",             STRING,     &normbordercolor },
    { "foreground",         STRING,     &selbordercolor },
    /* { "color8",             STRING,     &selbordercolor }, */
    { "color0",             STRING,     &normbgcolor },
    { "foreground",         STRING,     &normfgcolor },
    { "color0",             STRING,     &selfgcolor },
    { "foreground",         STRING,     &selbgcolor },
    { "borderpx",           INTEGER,    &borderpx },
    { "snap",               INTEGER,    &snap },
    { "showbar",            INTEGER,    &showbar },
    { "topbar",             INTEGER,    &topbar },
    { "nmaster",            INTEGER,    &nmaster },
    { "resizehints",        INTEGER,    &resizehints },
    { "mfact",              FLOAT,      &mfact },
    { "gappih",             INTEGER,    &gappih },
    { "gappiv",             INTEGER,    &gappiv },
    { "gappoh",             INTEGER,    &gappoh },
    { "gappov",             INTEGER,    &gappov },
    { "swallowfloating",    INTEGER,    &swallowfloating },
    { "smartgaps",          INTEGER,    &smartgaps },
};

#include <X11/XF86keysym.h>

static const Key keys[] = {
    /*  modifier                    key                 function            argument */
        /* bind mod-j: focusstack +1 (focus next window) */
        /* bind mod-k: focusstack -1 (focus previous window) */
        /* bind mod-ctrl-j: focusstack -1 (focus bottom of stack) */
        /* bind mod-ctrl-k: focusstack 0 (focus top of stack) */
        STACKKEYS(MODKEY,                               focus)
        /* bind mod-shift-j: pushstack +1 (move window down stack) */
        /* bind mod-shift-k: pushstack -1 (move window up stack) */
        /* bind mod-shift-ctrl-j: pushstack -1 (move window to bottom) */
        /* bind mod-shift-ctrl-k: pushstack 0 (move window to top) */
        STACKKEYS(MODKEY|ShiftMask,                     push)
        /* bind mod-grave: spawn dmenu_run */
        { MODKEY,                   XK_grave,           spawn,              SHCMD("dmenu_run -fn 'Linux Libertine Mono'") },
        /* bind mod-[1-9]: view tag [0-8] */
        /* bind mod-ctrl-[1-9]: tag window to [0-8] */
        /* bind mod-shift-[1-9]: tagview [0-8] */
        /* bind mod-ctrl-shift-[1-9]: toggleview [0-8] */
        TAGKEYS(                    XK_1,               0)
        TAGKEYS(                    XK_2,               1)
        TAGKEYS(                    XK_3,               2)
        TAGKEYS(                    XK_4,               3)
        TAGKEYS(                    XK_5,               4)
        TAGKEYS(                    XK_6,               5)
        TAGKEYS(                    XK_7,               6)
        TAGKEYS(                    XK_8,               7)
        TAGKEYS(                    XK_9,               8)
        /* bind mod-0: view all tags */
        { MODKEY,                   XK_0,               view,               {.ui = ~0 } },
        /* bind mod-shift-0: tag window to all tags */
        { MODKEY|ShiftMask,         XK_0,               tag,                {.ui = ~0 } },

        /* Layouts */
        /* bind mod-shift-less: togglesticky */
        { MODKEY|ShiftMask,         XK_less,            togglesticky,       {0} },
        /* bind mod-less: setlayout spiral */
        { MODKEY,                   XK_less,            setlayout,          {.v = &layouts[0]} }, /* Fibonacci spiral */
        /* bind mod-s: setlayout bstack */
        { MODKEY,                   XK_s,               setlayout,          {.v = &layouts[2]} }, /* centeredmaster */
        /* bind mod-ctrl-t: setlayout tile */
        { MODKEY|ControlMask,       XK_t,               setlayout,          {.v = &layouts[1]} }, /* tile */
        /* bind mod-ctrl-y: setlayout dwindle */
        { MODKEY|ControlMask,       XK_y,               setlayout,          {.v = &layouts[3]} }, /* dwindle */
        /* bind mod-ctrl-u: setlayout deck */
        { MODKEY|ControlMask,       XK_u,               setlayout,          {.v = &layouts[4]} }, /* bstack */
        /* bind mod-ctrl-i: setlayout monocle */
        { MODKEY|ControlMask,       XK_i,               setlayout,          {.v = &layouts[5]} }, /* deck*/
        /* bind mod-ctrl-o: setlayout centeredmaster */
        { MODKEY|ControlMask,       XK_o,               setlayout,          {.v = &layouts[6]} }, /* monocle */
        /* bind mod-ctrl-p: setlayout centeredfloatingmaster */
        { MODKEY|ControlMask,       XK_p,               setlayout,          {.v = &layouts[7]} }, /* centeredfloatingmaster */
        /* bind mod-ctrl-aring: setlayout floating */
        { MODKEY|ControlMask,       XK_aring,           setlayout,          {.v = &layouts[8]} },
        /* bind mod-f: togglefullscr */
        { MODKEY,                   XK_f,               togglefullscr,      {0} },
        /* bind mod-space: togglefloating */
        { MODKEY,                   XK_space,           togglefloating,     {0} },
        /* bind mod-shift-space: zoom (swap with master) */
        { MODKEY|ShiftMask,         XK_space,           zoom,               {0} },
        /* bind mod-y: setmfact -0.05 (shrink master) */
        { MODKEY,                   XK_y,               setmfact,           {.f = -0.05} },
        /* bind mod-o: setmfact +0.05 (grow master) */
        { MODKEY,                   XK_o,               setmfact,           {.f = +0.05} },
        /* bind mod-shift-u: incnmaster +1 */
        { MODKEY|ShiftMask,         XK_u,               incnmaster,         {.i = +1 } },
        /* bind mod-shift-i: incnmaster -1 */
        { MODKEY|ShiftMask,         XK_i,               incnmaster,         {.i = -1 } },
        /* bind mod-shift-y: shifttag +1 (move window to next tag) */
        { MODKEY|ShiftMask,         XK_y,               shifttag,           { .i = +1 } },
        /* bind mod-shift-o: shifttag -1 (move window to prev tag) */
        { MODKEY|ShiftMask,         XK_o,               shifttag,           { .i = -1 } },
        /* bind mod-x: defaultgaps */
        { MODKEY,                   XK_x,               defaultgaps,        {0} },
        /* bind mod-z: togglegaps */
        { MODKEY,                   XK_z,               togglegaps,         {0} },
        /* bind mod-ctrl-z: togglebgaps */
        { MODKEY|ControlMask,       XK_z,               togglebgaps,        {0} },
        /* bind mod-plus: incrgaps +3 */
        { MODKEY,                   XK_plus,            incrgaps,           {.i = +3 } },
        /* bind mod-minus: incrgaps -3 */
        { MODKEY,                   XK_minus,           incrgaps,           {.i = -3 } },
        /* bind mod-shift-plus: incrgaps +1 */
        { MODKEY|ShiftMask,         XK_plus,            incrgaps,           {.i = +1 } },
        /* bind mod-shift-minus: incrgaps -1 */
        { MODKEY|ShiftMask,         XK_minus,           incrgaps,           {.i = -1 } },
        /* bind alt-tab: shiftviewclients +1 (next occupied tag) */
        { MODKEY1,                  XK_Tab,             shiftviewclients,          { .i = +1 } },
        /* bind alt-shift-tab: shiftviewclients -1 (prev occupied tag) */
        { MODKEY1|ShiftMask,        XK_Tab,             shiftviewclients,          { .i = -1 } },
        /* { MODKEY,                   XK_Tab,             view,               {0} }, */
        /* { MODKEY,                   XK_Tab,             view,               {0} }, */
        /* bind mod-q: killclient */
        { MODKEY,                   XK_q,               killclient,         {0} },
        /* bind mod-shift-p: togglebars */
        { MODKEY|ShiftMask,         XK_p,               togglebars,          {0} },
        /* bind mod-ctrl-shift-p: togglebar */
        { MODKEY|ControlMask|ShiftMask,     XK_p,       togglebar,          {0} },
        /* bind mod-h: focusmon -1 (focus left monitor) */
        { MODKEY,                   XK_h,               focusmon,           { .i = -1 } },
        /* bind mod-shift-h: tagmonview -1 (move window and view left monitor) */
        { MODKEY|ShiftMask,         XK_h,               tagmonview,         { .i = -1 } },
        /* bind mod-ctrl-h: tagmon -1 (move window to left monitor) */
        { MODKEY|ControlMask,       XK_h,               tagmon,             { .i = -1 } },
        /* bind mod-l: focusmon +1 (focus right monitor) */
        { MODKEY,                   XK_l,               focusmon,           { .i = +1 } },
        /* bind mod-shift-l: tagmonview +1 (move window and view right monitor) */
        { MODKEY|ShiftMask,         XK_l,               tagmonview,         { .i = +1 } },
        /* bind mod-ctrl-l: tagmon +1 (move window to right monitor) */
        { MODKEY|ControlMask,       XK_l,               tagmon,             { .i = +1 } },
        /* bind mod-left: focusmon -1 */
        { MODKEY,                   XK_Left,            focusmon,           { .i = -1 } },
        /* bind mod-shift-left: tagmon -1 */
        { MODKEY|ShiftMask,         XK_Left,            tagmon,             { .i = -1 } },
        /* bind mod-right: focusmon +1 */
        { MODKEY,                   XK_Right,           focusmon,           { .i = +1 } },
        /* bind mod-shift-right: tagmon +1 */
        { MODKEY|ShiftMask,         XK_Right,           tagmon,             { .i = +1 } },
        /* bind mod-apostrophe: togglescratch spterm */
        { MODKEY,                   XK_apostrophe,      togglescratch,      { .ui = 0 } },
        /* bind mod-shift-apostrophe: togglescratch spcalc */
        { MODKEY|ShiftMask,         XK_apostrophe,      togglescratch,      { .ui = 1 } },
        /* { MODKEY,                   XK_semicolon,       shiftview,          { .i = 1 } }, */
        /* { MODKEY|ShiftMask,         XK_semicolon,       shifttag,           { .i = 1 } }, */

        /* bind mod-shift-x: spawn i3lock */
        { MODKEY|ShiftMask,         XK_x,               spawn,              SHCMD("i3lock") },
        /* bind mod-ctrl-x: spawn i3lock with wallpaper */
        { MODKEY|ControlMask,       XK_x,               spawn,              SHCMD("i3lock -i ~/Downloads/lock-wallpaper.png")},
        /* bind mod-w: spawn yazi ~/ */
        { MODKEY,                   XK_w,               spawn,              SHCMD(TERMINAL " -e " FILEX " " "~/") },
        /* bind mod-e: spawn file_explorer_wd.sh */
        { MODKEY,                   XK_e,               spawn,              SHCMD("~/.local/bin/my_scripts/file_explorer_wd.sh " TERMINAL " " FILEX) },
        /* bind mod-shift-e: spawn powermenu.sh */
        { MODKEY|ShiftMask,         XK_e,               spawn,              SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.config/polybar/forest/scripts/powermenu.sh") },
        /* bind mod-shift-s: spawn screenshot to clipboard */
        { MODKEY|ShiftMask,         XK_s,               spawn,              SHCMD("import png:- | xclip -selection clipboard -t image/png") },
        /* bind mod-ctrl-s: spawn tesseract_ocr.sh */
        { MODKEY|ControlMask,       XK_s,               spawn,              SHCMD("~/.local/bin/my_scripts/tesseract_ocr.sh") },
        /* bind mod-d: spawn rofi */
        { MODKEY,                   XK_d,               spawn,              SHCMD("rofi -show run -theme ~/.config/rofi/themes/gruvbox/gruvbox-dark.rasi") },
        /* bind mod-r: spawn dmenu_run */
        { MODKEY,                   XK_r,               spawn,              SHCMD("dmenu_run -i -l 20") },
        /* bind mod-shift-r: spawn rofi launcher */
        { MODKEY|ShiftMask,         XK_r,               spawn,              SHCMD("rofi -show run -theme ~/.config/polybar/forest/scripts/rofi/launcher.rasi") },
        /* bind mod-t: spawn script_copy.sh */
        { MODKEY,                   XK_t,               spawn,              SHCMD("~/.local/bin/my_scripts/script_copy.sh") },
        /* bind mod-shift-t: spawn script_helper.sh */
        { MODKEY|ShiftMask,         XK_t,               spawn,              SHCMD("~/.local/bin/my_scripts/script_helper.sh " TERMINAL) },
        /* bind mod-shift-c: spawn code_helper.sh new */
        { MODKEY|ShiftMask,         XK_c,               spawn,              SHCMD("~/.local/bin/my_scripts/code_helper.sh new " TERMINAL) },
        /* bind mod-shift-d: spawn code_helper.sh old */
        { MODKEY|ShiftMask,         XK_d,               spawn,              SHCMD("~/.local/bin/my_scripts/code_helper.sh old " TERMINAL) },
        /* bind mod-g: spawn fzf_open.sh */
        { MODKEY,                   XK_g,               spawn,              SHCMD("~/.local/bin/my_scripts/fzf_open.sh " TERMINAL)},
        /* bind mod-c: spawn term_calc.sh */
        { MODKEY,                   XK_c,               spawn,              SHCMD("~/.local/bin/my_scripts/term_calc.sh " TERMINAL) },
        /* bind mod-ctrl-c: spawn yad calendar */
        { MODKEY|ControlMask,       XK_c,               spawn,              SHCMD("yad --calendar --no-buttons") },
        /* bind mod-b: spawn htop */
        { MODKEY,                   XK_b,               spawn,              SHCMD(TERMINAL " -e htop") },
        /* bind mod-shift-b: spawn bashtop */
        { MODKEY|ShiftMask,         XK_b,               spawn,              SHCMD(TERMINAL " -e bashtop") },
        /* bind mod-ctrl-b: spawn ytop */
        { MODKEY|ControlMask,       XK_b,               spawn,              SHCMD(TERMINAL " -e ytop") },
        /* bind mod-p: spawn xrandr_helper.sh */
        { MODKEY,                   XK_p,               spawn,              SHCMD("~/.local/bin/my_scripts/xrandr_helper.sh") },
        /* bind mod-n: spawn files_wd.sh */
        { MODKEY,                   XK_n,               spawn,              SHCMD("~/.local/bin/my_scripts/files_wd.sh") },
        /* bind mod-shift-n: spawn thunar */
        { MODKEY|ShiftMask,         XK_n,               spawn,              SHCMD(FILES) },
        /* bind mod-ctrl-n: spawn open_notes.sh 1 */
        { MODKEY|ControlMask,       XK_n,               spawn,              SHCMD("~/.local/bin/my_scripts/open_notes.sh 1 " TERMINAL) },
        /* bind mod-m: spawn nm-connection-editor */
        { MODKEY,                   XK_m,               spawn,              SHCMD("nm-connection-editor") },
        /* bind mod-shift-m: spawn spotify */
        { MODKEY|ShiftMask,         XK_m,               spawn,              SHCMD("spotify") },
        /* bind mod-ctrl-m: spawn open_notes.sh 2 */
        { MODKEY|ControlMask,       XK_m,               spawn,              SHCMD("~/.local/bin/my_scripts/open_notes.sh 2 " TERMINAL) },
        /* bind mod-shift-comma: spawn suspend.sh */
        { MODKEY|ShiftMask,         XK_comma,           spawn,              SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.local/bin/my_scripts/suspend.sh")},
        /* bind mod-ctrl-comma: spawn suspend_mute.sh */
        { MODKEY|ControlMask,       XK_comma,           spawn,              SHCMD("~/.local/bin/my_scripts/alert_exit.sh && ~/.local/bin/my_scripts/suspend_mute.sh")},
        /* bind mod-shift-period: spawn i3lock + suspend */
        { MODKEY|ShiftMask,         XK_period,          spawn,              SHCMD("i3lock && ~/.local/bin/my_scripts/alert_exit.sh && systemctl suspend")},
        /* bind mod-v: spawn clip_history.sh greenclip */
        { MODKEY,                   XK_v,               spawn,              SHCMD("~/.local/bin/my_scripts/clip_history.sh greenclip") },
        /* bind mod-shift-v: spawn qr_clip.sh */
        { MODKEY|ShiftMask,         XK_v,               spawn,              SHCMD("~/.local/bin/my_scripts/qr_clip.sh") },
        /* bind mod-comma: spawn progrm_helper.sh */
        { MODKEY,                   XK_comma,           spawn,              SHCMD("~/.local/bin/my_scripts/progrm_helper.sh " TERMINAL) },
        /* bind mod-period: spawn emojipick */
        { MODKEY,                   XK_period,          spawn,              SHCMD("~/.local/bin/my_scripts/emojipick/emojipick") },
        /* bind mod-a: spawn tmux_attach.sh */
        { MODKEY,                   XK_a,               spawn,              SHCMD("~/.local/bin/my_scripts/tmux_attach.sh " TERMINAL) },
        /* bind mod-shift-a: spawn picom-trans -5 */
        { MODKEY|ShiftMask,         XK_a,               spawn,              SHCMD("picom-trans -c -5")},
        /* bind mod-ctrl-a: spawn picom-trans +5 */
        { MODKEY|ControlMask,       XK_a,               spawn,              SHCMD("picom-trans -c +5")},
        /* bind mod-section: spawn loadEww.sh */
        { MODKEY,                   XK_section,         spawn,              SHCMD("~/.local/bin/my_scripts/loadEww.sh") },
        /* { MODKEY,                   XK_BackSpace,       spawn,              SHCMD("sysact") }, */
        /* { MODKEY|ShiftMask,         XK_BackSpace,       spawn,              SHCMD("sysact") }, */
        /* bind mod-return: spawn term_wd.sh */
        { MODKEY,                   XK_Return,          spawn,              SHCMD("~/.local/bin/my_scripts/term_wd.sh " TERMINAL) },
        /* bind mod-shift-return: spawn terminal */
        { MODKEY|ShiftMask,         XK_Return,          spawn,              {.v = termcmd } },
        /* bind mod-ctrl-return: spawn term_wd.sh st */
        { MODKEY|ControlMask,       XK_Return,          spawn,              SHCMD("~/.local/bin/my_scripts/term_wd.sh " SECTERMINAL) },

        /* { MODKEY,                   XK_bracketleft,     spawn,              SHCMD("mpc seek -10") }, */
        /* { MODKEY|ShiftMask,         XK_bracketleft,     spawn,              SHCMD("mpc seek -60") }, */
        /* { MODKEY,                   XK_bracketright,    spawn,              SHCMD("mpc seek +10") }, */
        /* { MODKEY|ShiftMask,         XK_bracketright,    spawn,              SHCMD("mpc seek +60") }, */
        /* { MODKEY,                   XK_Page_Up,         shiftview,          { .i = -1 } }, */
        /* { MODKEY|ShiftMask,         XK_Page_Up,         shifttag,           { .i = -1 } }, */
        /* { MODKEY,                   XK_Page_Down,       shiftview,          { .i = +1 } }, */
        /* { MODKEY|ShiftMask,         XK_Page_Down,       shifttag,           { .i = +1 } }, */
        /* { MODKEY,                   XK_backslash,       view,               {0} }, */
        /* { MODKEY,                   XK_F1,              spawn,              SHCMD("groff -mom /usr/local/share/dwm/larbs.mom -Tpdf | zathura -") }, */

        /* bind F1: spawn show_keys.sh dwm */
        { 0,                        XK_F1,              spawn,              SHCMD("~/.local/bin/my_scripts/show_keys.sh dwm " TERMINAL) },
        /* bind shift-F1: spawn show_keys.sh vim */
        { ShiftMask,                XK_F1,              spawn,              SHCMD("~/.local/bin/my_scripts/show_keys.sh vim " TERMINAL) },
        /* { MODKEY,                   XK_F2,              spawn,              SHCMD("tutorialvids") }, */
        /* { MODKEY,                   XK_F3,              spawn,              SHCMD("displayselect") }, */
        /* { MODKEY,                   XK_F4,              spawn,              SHCMD(TERMINAL " -e pulsemixer; kill -44 $(pidof dwmblocks)") }, */
        /* { MODKEY,                   XK_F5,              xrdb,               {.v = NULL } }, */
        /* { MODKEY,                   XK_F6,              spawn,              SHCMD("torwrap") }, */
        /* { MODKEY,                   XK_F7,              spawn,              SHCMD("td-toggle") }, */
        /* { MODKEY,                   XK_F8,              spawn,              SHCMD("mw -Y") }, */
        /* { MODKEY,                   XK_F9,              spawn,              SHCMD("dmenumount") }, */
        /* bind F10: spawn pactl toggle mute */
        { 0,                        XK_F10,             spawn,              SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle ; kill -44 $(pidof dwmblocks)") },
        /* bind F11: spawn pactl volume -5% */
        { 0,                        XK_F11,             spawn,              SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%; kill -44 $(pidof dwmblocks)") },
        /* bind F12: spawn pactl volume +5% */
        { 0,                        XK_F12,             spawn,              SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%; kill -44 $(pidof dwmblocks)") },
        /* bind Print: spawn screenshot_select.sh */
        { 0,                        XK_Print,           spawn,              SHCMD("~/.local/bin/my_scripts/screenshot_select.sh") },
        /* bind shift-Print: spawn screenshot.sh */
        { ShiftMask,                XK_Print,           spawn,              SHCMD("~/.local/bin/my_scripts/screenshot.sh") },
        /* bind ctrl-Print: spawn screenshot_ocr.sh */
        { ControlMask,              XK_Print,           spawn,              SHCMD("~/.local/bin/my_scripts/screenshot_ocr.sh") },

        /* { MODKEY, XK_Insert,                            spawn,              SHCMD("xdotool type $(grep -v '^#' ~/.local/share/larbs/snippets | dmenu -i -l 50 | cut -d' ' -f1)") }, */
        /* bind XF86AudioMute: spawn pactl toggle mute */
        { 0, XF86XK_AudioMute,                          spawn,              SHCMD("pactl set-sink-mute @DEFAULT_SINK@ toggle ; kill -44 $(pidof dwmblocks)") },
        /* bind XF86AudioRaiseVolume: spawn pactl volume +5% */
        { 0, XF86XK_AudioRaiseVolume,                   spawn,              SHCMD("pactl set-sink-volume @DEFAULT_SINK@ +5%; kill -44 $(pidof dwmblocks)") },
        /* bind XF86AudioLowerVolume: spawn pactl volume -5% */
        { 0, XF86XK_AudioLowerVolume,                   spawn,              SHCMD("pactl set-sink-volume @DEFAULT_SINK@ -5%; kill -44 $(pidof dwmblocks)") },
        /* bind XF86MonBrightnessUp: spawn brightness.sh +10 */
        { 0, XF86XK_MonBrightnessUp,                    spawn,              SHCMD("~/.local/bin/my_scripts/brightness.sh +10") },
        /* bind XF86MonBrightnessDown: spawn brightness.sh -10 */
        { 0, XF86XK_MonBrightnessDown,                  spawn,              SHCMD("~/.local/bin/my_scripts/brightness.sh -10") },
        /* { 0, XF86XK_AudioPrev,                          spawn,              SHCMD("mpc prev") }, */
        /* { 0, XF86XK_AudioNext,                          spawn,              SHCMD("mpc next") }, */
        /* { 0, XF86XK_AudioPause,                         spawn,              SHCMD("mpc pause") }, */
        /* { 0, XF86XK_AudioPlay,                          spawn,              SHCMD("mpc play") }, */
        /* { 0, XF86XK_AudioStop,                          spawn,              SHCMD("mpc stop") }, */
        /* { 0, XF86XK_AudioRewind,                        spawn,              SHCMD("mpc seek -10") }, */
        /* { 0, XF86XK_AudioForward,                       spawn,              SHCMD("mpc seek +10") }, */
        /* { 0, XF86XK_AudioMedia,                         spawn,              SHCMD(TERMINAL " -e ncmpcpp") }, */
        /* { 0, XF86XK_AudioMicMute,                       spawn,              SHCMD("pactl set-source-mute @DEFAULT_SOURCE@ toggle") }, */
        /* { 0, XF86XK_PowerOff,                           spawn,              SHCMD("sysact") }, */
        /* { 0, XF86XK_Calculator,                         spawn,              SHCMD(TERMINAL " -e bc -l") }, */
        /* { 0, XF86XK_Sleep,                              spawn,              SHCMD("sudo -A zzz") }, */
        /* { 0, XF86XK_WWW,                                spawn,              SHCMD("$BROWSER") }, */
        /* { 0, XF86XK_DOS,                                spawn,              SHCMD(TERMINAL) }, */
        /* { 0, XF86XK_ScreenSaver,                        spawn,              SHCMD("slock & xset dpms force off; mpc pause; pauseallmpv") }, */
        /* { 0, XF86XK_TaskPane,                           spawn,              SHCMD(TERMINAL " -e htop") }, */
        /* { 0, XF86XK_Mail,                               spawn,              SHCMD(TERMINAL " -e neomutt ; pkill -RTMIN+12 dwmblocks") }, */
        /* { 0, XF86XK_MyComputer,                         spawn,              SHCMD(TERMINAL " -e lf /") }, */
        /* { 0, XF86XK_Battery,                            spawn,              SHCMD("") }, */
        /* { 0, XF86XK_Launch1,                            spawn,              SHCMD("xset dpms force off") }, */
        /* { 0, XF86XK_TouchpadToggle,                     spawn,              SHCMD("(synclient | grep 'TouchpadOff.*1' && synclient TouchpadOff=0) || synclient TouchpadOff=1") }, */
        /* { 0, XF86XK_TouchpadOff,                        spawn,              SHCMD("synclient TouchpadOff=1") }, */
        /* { 0, XF86XK_TouchpadOn,                         spawn,              SHCMD("synclient TouchpadOff=0") }, */
};

#define STATUSBAR "dwmblocks"

/* button definitions */
/* click can be ClkTagBar, ClkLtSymbol, ClkStatusText, ClkClientWin, or ClkRootWin */
static const Button buttons[] = {
    /* click                event mask      button          function        argument */
#ifndef __OpenBSD__
    /* bind statustext-button1: sigstatusbar 1 */
    { ClkStatusText,        0,              Button1,        sigstatusbar,   {.i = 1} },
    /* bind statustext-button2: sigstatusbar 2 */
    { ClkStatusText,        0,              Button2,        sigstatusbar,   {.i = 2} },
    /* bind statustext-button3: sigstatusbar 3 */
    { ClkStatusText,        0,              Button3,        sigstatusbar,   {.i = 3} },
    /* bind statustext-button4: sigstatusbar 4 (scroll up) */
    { ClkStatusText,        0,              Button4,        sigstatusbar,   {.i = 4} },
    /* bind statustext-button5: sigstatusbar 5 (scroll down) */
    { ClkStatusText,        0,              Button5,        sigstatusbar,   {.i = 5} },
    /* bind statustext-shift-button1: sigstatusbar 6 */
    { ClkStatusText,        ShiftMask,      Button1,        sigstatusbar,   {.i = 6} },
#endif
    /* bind statustext-shift-button3: spawn nvim dwmblocks config */
    { ClkStatusText,        ShiftMask,      Button3,        spawn,          SHCMD(TERMINAL " -e nvim ~/.config/dwmblocks/config.h") },
    /* bind clientwin-mod-button1: movemouse */
    { ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
    /* bind clientwin-mod-button2: defaultgaps */
    { ClkClientWin,         MODKEY,         Button2,        defaultgaps,    {0} },
    /* bind clientwin-mod-button3: resizemouse */
    { ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
    /* bind clientwin-mod-button4: incrgaps +1 (scroll up) */
    { ClkClientWin,         MODKEY,         Button4,        incrgaps,       {.i = +1} },
    /* bind clientwin-mod-button5: incrgaps -1 (scroll down) */
    { ClkClientWin,         MODKEY,         Button5,        incrgaps,       {.i = -1} },
    /* bind tagbar-button1: view */
    { ClkTagBar,            0,              Button1,        view,           {0} },
    /* bind tagbar-button3: toggleview */
    { ClkTagBar,            0,              Button3,        toggleview,     {0} },
    /* bind tagbar-mod-button1: tag */
    { ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
    /* bind tagbar-mod-button3: toggletag */
    { ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
    /* bind tagbar-button4: shiftview -1 (scroll up) */
    { ClkTagBar,            0,              Button4,        shiftview,      {.i = -1} },
    /* bind tagbar-button5: shiftview +1 (scroll down) */
    { ClkTagBar,            0,              Button5,        shiftview,      {.i = 1} },
    /* bind rootwin-button2: togglebar */
    { ClkRootWin,           0,              Button2,        togglebar,      {0} },
};

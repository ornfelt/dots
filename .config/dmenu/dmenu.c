/* See LICENSE file for copyright and license details. */
#include <ctype.h>
#include <locale.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <strings.h>
#include <time.h>
#include <unistd.h>

#include <X11/Xlib.h>
#include <X11/Xatom.h>
#include <X11/Xutil.h>
#ifdef XINERAMA
#include <X11/extensions/Xinerama.h>
#endif
#include <X11/Xft/Xft.h>

#include "drw.h"
#include "util.h"

/* macros */
#define INTERSECT(x,y,w,h,r)  (MAX(0, MIN((x)+(w),(r).x_org+(r).width)  - MAX((x),(r).x_org)) \
                             * MAX(0, MIN((y)+(h),(r).y_org+(r).height) - MAX((y),(r).y_org)))
#define TEXTW(X)              (drw_fontset_getwidth(drw, (X)) + lrpad)

/* enums */
enum { SchemeNorm, SchemeSel, SchemeOut, SchemeNormHighlight, SchemeSelHighlight, SchemeOutHighlight,
       SchemePrompt, SchemeNormAlt, SchemeNormAltHighlight, SchemeBorder, SchemeLast }; /* color schemes */

struct item {
	char *text;
	struct item *left, *right;
	int out;
};

static char text[BUFSIZ] = "";
static char *embed;
static int bh, mw, mh;
static int inputh, itemh; /* heights of the input and of a list item, with padding */
static int inputw = 0, promptw;
static int lrpad; /* sum of left and right padding */
static size_t cursor;
static struct item *items = NULL;
static struct item *matches, *matchend;
static struct item *prev, *curr, *next, *sel;
static int mon = -1, screen;
static int sep = '\n';       /* -sep: separates the items on stdin */
static int fixedw;           /* -W: window width in pixels when centered */
static int printindex;       /* -ix: print the index of the selected item */
static int preselect;        /* -n: the item selected at start */
static Fnt *hlfonts;         /* the italic font set of the highlights */
static char promptbuf[256];  /* the prompt with prompt_suffix */

static Atom clip, utf8;
static Display *dpy;
static Window root, parentwin, win;
static XIC xic;

static Drw *drw;
static Clr *scheme[SchemeLast];

#include "config.h"

static int (*fstrncmp)(const char *, const char *, size_t) = strncmp;
static char *(*fstrstr)(const char *, const char *) = strstr;

static unsigned int
textw_clamp(const char *str, unsigned int n)
{
	unsigned int w = drw_fontset_getwidth_clamp(drw, str, n) + lrpad;
	return MIN(w, n);
}

static void
appenditem(struct item *item, struct item **list, struct item **last)
{
	if (*last)
		(*last)->right = item;
	else
		*list = item;

	item->left = *last;
	item->right = NULL;
	*last = item;
}

static void
calcoffsets(void)
{
	int i, n;

	if (lines > 0)
		n = lines * columns; /* items on a page */
	else
		n = mw - 2 * padding - (promptw + inputw + TEXTW("<") + TEXTW(">"));
	/* calculate which items will begin the next page and previous page */
	for (i = 0, next = curr; next; next = next->right)
		if ((i += (lines > 0) ? 1 : textw_clamp(next->text, n)) > n)
			break;
	for (i = 0, prev = curr; prev && prev->left; prev = prev->left)
		if ((i += (lines > 0) ? 1 : textw_clamp(prev->left->text, n)) > n)
			break;
}

static int
max_textw(void)
{
	int len = 0;
	for (struct item *item = items; item && item->text && len < max_width; item++)
		len = MAX(TEXTW(item->text), len);
	return MIN(len, max_width);
}

static void
cleanup(void)
{
	size_t i;

	XUngrabKeyboard(dpy, CurrentTime);
	XUngrabPointer(dpy, CurrentTime);
	for (i = 0; i < SchemeLast; i++)
		drw_scm_free(drw, scheme[i], 2);
	drw_fontset_free(hlfonts);
	for (i = 0; items && items[i].text; ++i)
		free(items[i].text);
	free(items);
	drw_free(drw);
	XSync(dpy, False);
	XCloseDisplay(dpy);
}

static char *
cistrstr(const char *h, const char *n)
{
	size_t i;

	if (!n[0])
		return (char *)h;

	for (; *h; ++h) {
		for (i = 0; n[i] && tolower((unsigned char)n[i]) ==
		            tolower((unsigned char)h[i]); ++i)
			;
		if (n[i] == '\0')
			return (char *)h;
	}
	return NULL;
}

/* The font set of font in italic, keeping its weight (NULL when it can't
 * be loaded): highlight_italic draws the matches in it, like rofi */
static Fnt *
italicfontset(const char *font)
{
	FcPattern *p;
	FcChar8 *style, *name;
	Fnt *set, *cur = drw->fonts;
	const char *names[1];
	int bold;

	if (!(p = FcNameParse((const FcChar8 *)font)))
		return NULL;
	bold = FcPatternGetString(p, FC_STYLE, 0, &style) == FcResultMatch &&
	       cistrstr((const char *)style, "bold");
	/* a style (e.g. "bold") names a face and would win over the slant */
	FcPatternDel(p, FC_STYLE);
	FcPatternDel(p, FC_SLANT);
	FcPatternAddInteger(p, FC_SLANT, FC_SLANT_ITALIC);
	if (bold) {
		FcPatternDel(p, FC_WEIGHT);
		FcPatternAddInteger(p, FC_WEIGHT, FC_WEIGHT_BOLD);
	}
	name = FcNameUnparse(p);
	FcPatternDestroy(p);
	if (!name)
		return NULL;
	names[0] = (const char *)name;
	set = drw_fontset_create(drw, names, 1);
	free(name);
	drw_setfontset(drw, cur); /* drw_fontset_create() made the new set current */
	return set;
}

/* drw_text() in the highlight font set */
static void
drawhighlighttext(int x, int y, unsigned int w, unsigned int h, const char *s)
{
	Fnt *cur = drw->fonts;

	if (hlfonts)
		drw_setfontset(drw, hlfonts);
	drw_text(drw, x, y, w, h, 0, s, 0);
	drw_setfontset(drw, cur);
}

/* the highlights of the matches in s, a line of item */
static void
drawhighlights(struct item *item, char *s, int x, int y, int maxw, int h, int alt)
{
	char restorechar, tokens[sizeof text], *highlight,  *token;
	int indentx, highlightlen, highlightw, textw, ellipsisw, truncated;

	/* width for the item text, and whether drw_text() cuts it with an ellipsis */
	textw = maxw - lrpad / 2;
	ellipsisw = TEXTW("...") - lrpad;
	truncated = (int)TEXTW(s) - lrpad > textw;

	drw_setscheme(drw, scheme[item == sel ? SchemeSelHighlight : item->out ? SchemeOutHighlight
	                          : alt ? SchemeNormAltHighlight : SchemeNormHighlight]);
	strcpy(tokens, text);
	for (token = strtok(tokens, " "); token; token = strtok(NULL, " ")) {
		highlight = fstrstr(s, token);
		while (highlight) {
			// Move item str end, calc width for highlight indent, & restore
			highlightlen = highlight - s;
			restorechar = *highlight;
			s[highlightlen] = '\0';
			indentx = TEXTW(s) - lrpad;
			s[highlightlen] = restorechar;

			// Hidden under the ellipsis, and so is every later match
			if (truncated && indentx + ellipsisw > textw) break;

			// Move highlight str end, calc width & restore
			restorechar = highlight[strlen(token)];
			highlight[strlen(token)] = '\0';
			highlightw = TEXTW(highlight) - lrpad;
			highlight[strlen(token)] = restorechar;

			if (truncated && indentx + highlightw > textw - ellipsisw) {
				// Runs into the ellipsis: draw the rest of the item text with the
				// same right edge, so it gets cut exactly like in drawitem()
				drawhighlighttext(x + lrpad / 2 + indentx, y, textw - indentx, h, highlight);
			} else {
				// Move highlight str end, draw highlight, & restore
				highlight[strlen(token)] = '\0';
				drawhighlighttext(x + lrpad / 2 + indentx, y, highlightw, h, highlight);
				highlight[strlen(token)] = restorechar;
			}

			if (strlen(highlight) - strlen(token) < strlen(token)) break;
			highlight = fstrstr(highlight + strlen(token), token);
		}
	}
}

/* item in the w x h box at x, y; alt: every other item (rofi's alternate
 * rows). Its lines (-sep) are drawn one under the other, at most
 * item_lines of them */
static int
drawitem(struct item *item, int x, int y, int w, int h, int alt)
{
	char *s, *nl;
	int i, lh;

	if (item == sel)
		drw_setscheme(drw, scheme[SchemeSel]);
	else if (item->out)
		drw_setscheme(drw, scheme[SchemeOut]);
	else
		drw_setscheme(drw, scheme[alt ? SchemeNormAlt : SchemeNorm]);
	drw_rect(drw, x, y, w, h, 1, 1);

	lh = item_lines > 1 ? (int)drw->fonts->h : h;
	y += (h - lh * (item_lines > 1 ? (int)item_lines : 1)) / 2;
	for (s = item->text, i = 0; s && i < (int)item_lines; s = nl ? nl + 1 : NULL, i++, y += lh) {
		if ((nl = strchr(s, '\n')))
			*nl = '\0';
		drw_setscheme(drw, scheme[item == sel ? SchemeSel : item->out ? SchemeOut
		                          : alt ? SchemeNormAlt : SchemeNorm]);
		drw_text(drw, x, y, w, lh, lrpad / 2, s, 0);
		drawhighlights(item, s, x, y, w, lh, alt);
		if (nl)
			*nl = '\n';
	}
	return x + w;
}

/* the box of the ith item shown in the vertical list: columns of lines
 * items under the input and the line below it */
static void
itembox(int i, int *x, int *y, int *w)
{
	*w = (mw - 2 * padding - (columns - 1) * padding) / columns;
	*x = padding + i / lines * (*w + padding);
	*y = 3 * padding + inputh + i % lines * (itemh + padding);
}

static void
drawmenu(void)
{
	unsigned int curpos;
	struct item *item;
	int x = padding, y = padding, w, i, n;

	drw_setscheme(drw, scheme[SchemeNorm]);
	drw_rect(drw, 0, 0, mw, mh, 1, 1);

	if (prompt && *prompt) {
		drw_setscheme(drw, scheme[SchemePrompt]);
		x = drw_text(drw, x, y, promptw, inputh, lrpad / 2, prompt, 0);
	}
	/* draw input field */
	w = (lines > 0 || !matches) ? mw - padding - x : inputw;
	drw_setscheme(drw, scheme[SchemeNorm]);
	drw_text(drw, x, y, w, inputh, lrpad / 2, text, 0);

	curpos = TEXTW(text) - TEXTW(&text[cursor]);
	if ((curpos += lrpad / 2 - 1) < w) {
		drw_setscheme(drw, scheme[SchemeNorm]);
		drw_rect(drw, x + curpos, y + (inputh - bh) / 2 + 2, 2, bh - 4, 1, 0);
	}

	if (lines > 0) {
		/* the line between the input and the list, like rofi's */
		y += inputh;
		drw_setscheme(drw, scheme[SchemeBorder]);
		drw_rect(drw, padding, y, mw - 2 * padding, padding, 1, 0);
		/* draw vertical list: columns of lines items (a grid with -g),
		 * filled column by column */
		for (n = 0, item = matches; item && item != curr; item = item->right)
			n++;
		for (i = 0, item = curr; item != next; item = item->right, i++) {
			itembox(i, &x, &y, &w);
			drawitem(item, x, y, w, itemh, (n + i) % 2);
		}
	} else if (matches && curr) {
		/* draw horizontal list */
		x += inputw;
		w = TEXTW("<");
		if (curr->left) {
			drw_setscheme(drw, scheme[SchemeNorm]);
			drw_text(drw, x, y, w, inputh, lrpad / 2, "<", 0);
		}
		x += w;
		for (item = curr; item != next; item = item->right)
			x = drawitem(item, x, y, textw_clamp(item->text, mw - padding - x - TEXTW(">")), inputh, 0);
		if (next) {
			w = TEXTW(">");
			drw_setscheme(drw, scheme[SchemeNorm]);
			drw_text(drw, mw - padding - w, y, w, inputh, lrpad / 2, ">", 0);
		}
	}
	drw_map(drw, win, 0, 0, mw, mh);
}

static void
grabfocus(void)
{
	struct timespec ts = { .tv_sec = 0, .tv_nsec = 10000000  };
	Window focuswin;
	int i, revertwin;

	for (i = 0; i < 100; ++i) {
		XGetInputFocus(dpy, &focuswin, &revertwin);
		if (focuswin == win)
			return;
		XSetInputFocus(dpy, win, RevertToParent, CurrentTime);
		nanosleep(&ts, NULL);
	}
	die("cannot grab focus");
}

static void
grabkeyboard(void)
{
	struct timespec ts = { .tv_sec = 0, .tv_nsec = 1000000  };
	int i;

	if (embed)
		return;
	/* try to grab keyboard, we may have to wait for another process to ungrab */
	for (i = 0; i < 1000; i++) {
		if (XGrabKeyboard(dpy, DefaultRootWindow(dpy), True, GrabModeAsync,
		                  GrabModeAsync, CurrentTime) == GrabSuccess)
			return;
		nanosleep(&ts, NULL);
	}
	die("cannot grab keyboard");
}

/* grab the pointer so a click outside the window reaches it too (rofi's
 * click-to-exit); without the grab dmenu only misses that */
static void
grabpointer(void)
{
	struct timespec ts = { .tv_sec = 0, .tv_nsec = 1000000  };
	int i;

	if (embed)
		return;
	/* e.g. the WM still holds the click that started dmenu */
	for (i = 0; i < 1000; i++) {
		if (XGrabPointer(dpy, win, True, ButtonPressMask, GrabModeAsync,
		                 GrabModeAsync, None, None, CurrentTime) == GrabSuccess)
			return;
		nanosleep(&ts, NULL);
	}
}

static void
match(void)
{
	static char **tokv = NULL;
	static int tokn = 0;

	char buf[sizeof text], *s;
	int i, tokc = 0;
	size_t len, textsize;
	struct item *item, *lprefix, *lsubstr, *prefixend, *substrend;

	strcpy(buf, text);
	/* separate input text into tokens to be matched individually */
	for (s = strtok(buf, " "); s; tokv[tokc - 1] = s, s = strtok(NULL, " "))
		if (++tokc > tokn && !(tokv = realloc(tokv, ++tokn * sizeof *tokv)))
			die("cannot realloc %zu bytes:", tokn * sizeof *tokv);
	len = tokc ? strlen(tokv[0]) : 0;

	matches = lprefix = lsubstr = matchend = prefixend = substrend = NULL;
	textsize = strlen(text) + 1;
	for (item = items; item && item->text; item++) {
		for (i = 0; i < tokc; i++)
			if (!fstrstr(item->text, tokv[i]))
				break;
		if (i != tokc) /* not all tokens match */
			continue;
		/* exact matches go first, then prefixes, then substrings; with
		 * input_order all in the order of stdin, like rofi */
		if (input_order || !tokc || !fstrncmp(text, item->text, textsize))
			appenditem(item, &matches, &matchend);
		else if (!fstrncmp(tokv[0], item->text, len))
			appenditem(item, &lprefix, &prefixend);
		else
			appenditem(item, &lsubstr, &substrend);
	}
	if (lprefix) {
		if (matches) {
			matchend->right = lprefix;
			lprefix->left = matchend;
		} else
			matches = lprefix;
		matchend = prefixend;
	}
	if (lsubstr) {
		if (matches) {
			matchend->right = lsubstr;
			lsubstr->left = matchend;
		} else
			matches = lsubstr;
		matchend = substrend;
	}
	curr = sel = matches;
	calcoffsets();
}

static void
insert(const char *str, ssize_t n)
{
	if (strlen(text) + n > sizeof text - 1)
		return;
	/* move existing text out of the way, insert new text, and update cursor */
	memmove(&text[cursor + n], &text[cursor], sizeof text - cursor - MAX(n, 0));
	if (n > 0)
		memcpy(&text[cursor], str, n);
	cursor += n;
	match();
}

static size_t
nextrune(int inc)
{
	ssize_t n;

	/* return location of next utf8 rune in the given direction (+1 or -1) */
	for (n = cursor + inc; n + inc >= 0 && (text[n] & 0xc0) == 0x80; n += inc)
		;
	return n;
}

static void
movewordedge(int dir)
{
	if (dir < 0) { /* move cursor to the start of the word*/
		while (cursor > 0 && strchr(worddelimiters, text[nextrune(-1)]))
			cursor = nextrune(-1);
		while (cursor > 0 && !strchr(worddelimiters, text[nextrune(-1)]))
			cursor = nextrune(-1);
	} else { /* move cursor to the end of the word */
		while (text[cursor] && strchr(worddelimiters, text[cursor]))
			cursor = nextrune(+1);
		while (text[cursor] && !strchr(worddelimiters, text[cursor]))
			cursor = nextrune(+1);
	}
}

/* item, or the input text when item is NULL: its index with -ix (-1 for
 * the text) */
static void
printitem(struct item *item)
{
	if (printindex)
		printf("%d\n", item ? (int)(item - items) : -1);
	else
		puts(item ? item->text : text);
}

static void
keypress(XKeyEvent *ev)
{
	char buf[64];
	int len, i;
	struct item *it;
	KeySym ksym = NoSymbol;
	Status status;

	len = XmbLookupString(xic, ev, buf, sizeof buf, &ksym, &status);
	switch (status) {
	default: /* XLookupNone, XBufferOverflow */
		return;
	case XLookupChars: /* composed string from input method */
		goto insert;
	case XLookupKeySym:
	case XLookupBoth: /* a KeySym and a string are returned: use keysym */
		break;
	}

	if (ev->state & Mod4Mask) {
		/* super-1..9: accept the nth item shown, like rofi's kb-select-n */
		if (ksym >= XK_1 && ksym <= XK_9) {
			for (i = ksym - XK_1, it = curr; it && it != next && i > 0; i--)
				it = it->right;
			if (!it || it == next)
				return;
			printitem(it);
			cleanup();
			exit(0);
		}
		if (ksym == supercancelkey) {
			cleanup();
			exit(1);
		}
		return; /* other super keys don't type */
	}

	if (ev->state & ControlMask) {
		switch(ksym) {
		case XK_a: ksym = XK_Home;      break;
		case XK_b: ksym = XK_Left;      break;
		case XK_c: ksym = XK_Escape;    break;
		case XK_d: ksym = XK_Delete;    break;
		case XK_e: ksym = XK_End;       break;
		case XK_f: ksym = XK_Right;     break;
		case XK_g: ksym = XK_Escape;    break;
		case XK_h: ksym = XK_BackSpace; break;
		case XK_i: ksym = XK_Tab;       break;
		case XK_j: /* fallthrough */
		case XK_J: /* fallthrough */
		case XK_m: /* fallthrough */
		case XK_M: ksym = XK_Return; ev->state &= ~ControlMask; break;
		case XK_n: ksym = XK_Down;      break;
		case XK_p: ksym = XK_Up;        break;

		case XK_k: /* delete right */
			text[cursor] = '\0';
			match();
			break;
		case XK_u: /* delete left */
			insert(NULL, 0 - cursor);
			break;
		case XK_w: /* delete word */
			while (cursor > 0 && strchr(worddelimiters, text[nextrune(-1)]))
				insert(NULL, nextrune(-1) - cursor);
			while (cursor > 0 && !strchr(worddelimiters, text[nextrune(-1)]))
				insert(NULL, nextrune(-1) - cursor);
			break;
		case XK_y: /* paste selection */
		case XK_Y:
			XConvertSelection(dpy, (ev->state & ShiftMask) ? clip : XA_PRIMARY,
			                  utf8, utf8, win, CurrentTime);
			return;
		case XK_Left:
		case XK_KP_Left:
			movewordedge(-1);
			goto draw;
		case XK_Right:
		case XK_KP_Right:
			movewordedge(+1);
			goto draw;
		case XK_Return:
		case XK_KP_Enter:
			break;
		case XK_bracketleft:
			cleanup();
			exit(1);
		default:
			return;
		}
	} else if (ev->state & Mod1Mask) {
		switch(ksym) {
		case XK_b:
			movewordedge(-1);
			goto draw;
		case XK_f:
			movewordedge(+1);
			goto draw;
		case XK_g: ksym = XK_Home;  break;
		case XK_G: ksym = XK_End;   break;
		case XK_h: ksym = XK_Up;    break;
		case XK_j: ksym = XK_Next;  break;
		case XK_k: ksym = XK_Prior; break;
		case XK_l: ksym = XK_Down;  break;
		default:
			return;
		}
	}

	switch(ksym) {
	default:
insert:
		if (len > 0 && !iscntrl((unsigned char)*buf))
			insert(buf, len);
		break;
	case XK_Delete:
	case XK_KP_Delete:
		if (text[cursor] == '\0')
			return;
		cursor = nextrune(+1);
		/* fallthrough */
	case XK_BackSpace:
		if (cursor == 0)
			return;
		insert(NULL, nextrune(-1) - cursor);
		break;
	case XK_End:
	case XK_KP_End:
		if (text[cursor] != '\0') {
			cursor = strlen(text);
			break;
		}
		if (next) {
			/* jump to end of list and position items in reverse */
			curr = matchend;
			calcoffsets();
			curr = prev;
			calcoffsets();
			while (next && (curr = curr->right))
				calcoffsets();
		}
		sel = matchend;
		break;
	case XK_Escape:
		cleanup();
		exit(1);
	case XK_Home:
	case XK_KP_Home:
		if (sel == matches) {
			cursor = 0;
			break;
		}
		sel = curr = matches;
		calcoffsets();
		break;
	case XK_Left:
	case XK_KP_Left:
		if (lines > 0 && columns > 1) {
			/* grid: the item one column to the left */
			for (i = 0, it = sel; it && i < (int)lines; i++)
				it = it->left;
			if (!it)
				return;
			for (i = 0; i < (int)lines; i++)
				if ((sel = sel->left)->right == curr) {
					curr = prev;
					calcoffsets();
				}
			break;
		}
		if (cursor > 0 && (!sel || !sel->left || lines > 0)) {
			cursor = nextrune(-1);
			break;
		}
		if (lines > 0)
			return;
		/* fallthrough */
	case XK_Up:
	case XK_KP_Up:
		if (sel && sel->left && (sel = sel->left)->right == curr) {
			curr = prev;
			calcoffsets();
		}
		break;
	case XK_Next:
	case XK_KP_Next:
		if (!next)
			return;
		sel = curr = next;
		calcoffsets();
		break;
	case XK_Prior:
	case XK_KP_Prior:
		if (!prev)
			return;
		sel = curr = prev;
		calcoffsets();
		break;
	case XK_Return:
	case XK_KP_Enter:
		printitem((sel && !(ev->state & ShiftMask)) ? sel : NULL);
		if (!(ev->state & ControlMask)) {
			cleanup();
			exit(0);
		}
		if (sel)
			sel->out = 1;
		break;
	case XK_Right:
	case XK_KP_Right:
		if (lines > 0 && columns > 1) {
			/* grid: the item one column to the right */
			for (i = 0, it = sel; it && i < (int)lines; i++)
				it = it->right;
			if (!it)
				return;
			for (i = 0; i < (int)lines; i++)
				if ((sel = sel->right) == next) {
					curr = next;
					calcoffsets();
				}
			break;
		}
		if (text[cursor] != '\0') {
			cursor = nextrune(+1);
			break;
		}
		if (lines > 0)
			return;
		/* fallthrough */
	case XK_Down:
	case XK_KP_Down:
		if (sel && sel->right && (sel = sel->right) == next) {
			curr = next;
			calcoffsets();
		}
		break;
	case XK_Tab: /* select next item, wrapping to the first */
		if (!sel)
			return;
		if (sel->right) {
			if ((sel = sel->right) == next) {
				curr = next;
				calcoffsets();
			}
			break;
		}
		sel = curr = matches;
		calcoffsets();
		break;
	case XK_ISO_Left_Tab: /* shift-tab: select previous item, wrapping to the last */
		if (!sel)
			return;
		if (sel->left) {
			if ((sel = sel->left)->right == curr) {
				curr = prev;
				calcoffsets();
			}
			break;
		}
		if (next) {
			/* jump to end of list and position items in reverse */
			curr = matchend;
			calcoffsets();
			curr = prev;
			calcoffsets();
			while (next && (curr = curr->right))
				calcoffsets();
		}
		sel = matchend;
		break;
	}

draw:
	drawmenu();
}

/* the mouse, like rofi: a click selects an item and a double click
 * accepts it, the wheel moves the selection and a click outside the window
 * exits */
static void
buttonpress(XButtonEvent *ev)
{
	static Time lasttime;
	struct item *item;
	int x, y, w, i, bw = border_width;

	if (ev->x < -bw || ev->y < -bw || ev->x >= mw + bw || ev->y >= mh + bw) {
		if (ev->button == Button4 || ev->button == Button5)
			return; /* scrolling elsewhere */
		cleanup();
		exit(1);
	}
	switch (ev->button) {
	case Button4: /* wheel: the previous item */
		if (sel && sel->left && (sel = sel->left)->right == curr) {
			curr = prev;
			calcoffsets();
		}
		break;
	case Button5: /* wheel: the next item */
		if (sel && sel->right && (sel = sel->right) == next) {
			curr = next;
			calcoffsets();
		}
		break;
	case Button1:
		/* the item under the pointer */
		x = padding + promptw + inputw + TEXTW("<");
		for (i = 0, item = curr; item != next; item = item->right, i++) {
			if (lines > 0) {
				itembox(i, &x, &y, &w);
				if (ev->x >= x && ev->x < x + w && ev->y >= y && ev->y < y + itemh)
					break;
			} else {
				w = textw_clamp(item->text, mw - padding - x - TEXTW(">"));
				if (ev->x >= x && ev->x < x + w)
					break;
				x += w;
			}
		}
		if (item == next)
			return;
		if (item == sel && ev->time - lasttime < doubleclick_ms) {
			printitem(item);
			cleanup();
			exit(0);
		}
		sel = item;
		lasttime = ev->time;
		break;
	default:
		return;
	}
	drawmenu();
}

static void
paste(void)
{
	char *p, *q;
	int di;
	unsigned long dl;
	Atom da;

	/* we have been given the current selection, now insert it into input */
	if (XGetWindowProperty(dpy, win, utf8, 0, (sizeof text / 4) + 1, False,
	                   utf8, &da, &di, &dl, &dl, (unsigned char **)&p)
	    == Success && p) {
		insert(p, (q = strchr(p, '\n')) ? q - p : (ssize_t)strlen(p));
		XFree(p);
	}
	drawmenu();
}

static void
readstdin(void)
{
	char *line = NULL;
	size_t i, itemsiz = 0, linesiz = 0;
	ssize_t len;

	/* read each line from stdin and add it to the item list */
	for (i = 0; (len = getdelim(&line, &linesiz, sep, stdin)) != -1; i++) {
		if (i + 1 >= itemsiz) {
			itemsiz += 256;
			if (!(items = realloc(items, itemsiz * sizeof(*items))))
				die("cannot realloc %zu bytes:", itemsiz * sizeof(*items));
		}
		if (line[len - 1] == sep)
			line[--len] = '\0';
		/* an item of several lines (-sep) ends with its last line */
		while (sep != '\n' && len > 0 && line[len - 1] == '\n')
			line[--len] = '\0';
		if (!(items[i].text = strdup(line)))
			die("strdup:");

		items[i].out = 0;
	}
	free(line);
	if (items)
		items[i].text = NULL;
	if (!fixed_lines)
		lines = MIN(lines, i);
}

static void
run(void)
{
	XEvent ev;

	while (!XNextEvent(dpy, &ev)) {
		if (XFilterEvent(&ev, win))
			continue;
		switch(ev.type) {
		case DestroyNotify:
			if (ev.xdestroywindow.window != win)
				break;
			cleanup();
			exit(1);
		case Expose:
			if (ev.xexpose.count == 0)
				drw_map(drw, win, 0, 0, mw, mh);
			break;
		case FocusIn:
			/* regrab focus from parent window */
			if (ev.xfocus.window != win)
				grabfocus();
			break;
		case KeyPress:
			keypress(&ev.xkey);
			break;
		case ButtonPress:
			buttonpress(&ev.xbutton);
			break;
		case SelectionNotify:
			if (ev.xselection.property == utf8)
				paste();
			break;
		case VisibilityNotify:
			if (ev.xvisibility.state != VisibilityUnobscured)
				XRaiseWindow(dpy, win);
			break;
		}
	}
}

static void
setup(void)
{
	int x, y, i, j, bw2;
	unsigned int du;
	XSetWindowAttributes swa;
	XIM xim;
	Window w, dw, *dws;
	XWindowAttributes wa;
	XClassHint ch = {"dmenu", "dmenu"};
#ifdef XINERAMA
	XineramaScreenInfo *info;
	Window pw;
	int a, di, n, area = 0;
#endif
	/* init appearance */
	/* highlight schemes use the background of their base scheme, so -nb/-sb/-ob apply */
	colors[SchemeNormHighlight][ColBg] = colors[SchemeNorm][ColBg];
	colors[SchemeSelHighlight][ColBg] = colors[SchemeSel][ColBg];
	colors[SchemeOutHighlight][ColBg] = colors[SchemeOut][ColBg];
	colors[SchemeNormAltHighlight][ColFg] = colors[SchemeNormHighlight][ColFg];
	colors[SchemeNormAltHighlight][ColBg] = colors[SchemeNormAlt][ColBg];
	for (j = 0; j < SchemeLast; j++)
		scheme[j] = drw_scm_create(drw, colors[j], 2);

	clip = XInternAtom(dpy, "CLIPBOARD",   False);
	utf8 = XInternAtom(dpy, "UTF8_STRING", False);

	/* calculate menu geometry */
	bh = drw->fonts->h + 2;
	lines = MAX(lines, 0);
	columns = MAX(columns, 1);
	item_lines = MAX(item_lines, 1);
	inputh = bh + 2 * padding;
	itemh = (item_lines - 1) * drw->fonts->h + bh + 2 * padding;
	/* padding around everything, the input, then the line under it, the
	 * padding and the list, with padding between the items */
	mh = 2 * padding + inputh;
	if (lines > 0)
		mh += 2 * padding + lines * itemh + (lines - 1) * padding;
	if (prompt && *prompt && prompt_suffix && *prompt_suffix) {
		snprintf(promptbuf, sizeof promptbuf, "%s%s", prompt, prompt_suffix);
		prompt = promptbuf;
	}
	promptw = (prompt && *prompt) ? TEXTW(prompt) - lrpad / 4 : 0;
	bw2 = 2 * border_width; /* the border is drawn outside of mw x mh */
#ifdef XINERAMA
	i = 0;
	if (parentwin == root && (info = XineramaQueryScreens(dpy, &n))) {
		if (n < 1)
			die("Xinerama reported no screens");
		XGetInputFocus(dpy, &w, &di);
		if (mon >= 0 && mon < n)
			i = mon;
		else if (w != root && w != PointerRoot && w != None) {
			/* find top-level window containing current input focus */
			do {
				if (XQueryTree(dpy, (pw = w), &dw, &w, &dws, &du) && dws)
					XFree(dws);
			} while (w != root && w != pw);
			/* find xinerama screen with which the window intersects most */
			if (XGetWindowAttributes(dpy, pw, &wa))
				for (j = 0; j < n; j++)
					if ((a = INTERSECT(wa.x, wa.y, wa.width, wa.height, info[j])) > area) {
						area = a;
						i = j;
					}
		}
		/* no focused window is on screen, so use pointer location instead */
		if (mon < 0 && !area && XQueryPointer(dpy, root, &dw, &dw, &x, &y, &di, &di, &du))
			for (i = 0; i < n; i++)
				if (INTERSECT(x, y, 1, 1, info[i]) != 0)
					break;
		/* fallback to the first screen if there is no intersection */
		if (i >= n)
			i = 0;

		if (centered) {
			if (fixedw > 0)
				mw = MIN(fixedw, info[i].width - bw2);
			else if (centered_width > 0)
				mw = info[i].width * centered_width;
			else
				mw = MIN(MAX(max_textw() + promptw, min_width), info[i].width - bw2);
			x = info[i].x_org + ((info[i].width  - mw - bw2) / 2);
			y = info[i].y_org + ((info[i].height - mh - bw2) / menu_height_ratio);
		} else {
			x = info[i].x_org;
			y = info[i].y_org + (topbar ? 0 : info[i].height - mh - bw2);
			mw = info[i].width - bw2;
		}

		XFree(info);
	} else
#endif
	{
		if (!XGetWindowAttributes(dpy, parentwin, &wa))
			die("could not get embedding window attributes: 0x%lx",
			    parentwin);

		if (centered) {
			if (fixedw > 0)
				mw = MIN(fixedw, wa.width - bw2);
			else if (centered_width > 0)
				mw = wa.width * centered_width;
			else
				mw = MIN(MAX(max_textw() + promptw, min_width), wa.width - bw2);
			x = (wa.width  - mw - bw2) / 2;
			y = (wa.height - mh - bw2) / menu_height_ratio;
		} else {
			x = 0;
			y = topbar ? 0 : wa.height - mh - bw2;
			mw = wa.width - bw2;
		}
	}
	inputw = mw / 3; /* input width: ~33% of monitor width */
	match();
	/* -n: select that item, paging like Down */
	for (i = 0; i < preselect && sel && sel->right; i++)
		if ((sel = sel->right) == next) {
			curr = next;
			calcoffsets();
		}

	/* create menu window */
	swa.override_redirect = True;
	swa.background_pixel = scheme[SchemeNorm][ColBg].pixel;
	swa.event_mask = ExposureMask | KeyPressMask | ButtonPressMask | VisibilityChangeMask;
	win = XCreateWindow(dpy, root, x, y, mw, mh, border_width,
	                    CopyFromParent, CopyFromParent, CopyFromParent,
	                    CWOverrideRedirect | CWBackPixel | CWEventMask, &swa);
	if (border_width)
		XSetWindowBorder(dpy, win, scheme[SchemeBorder][ColFg].pixel);
	XSetClassHint(dpy, win, &ch);

	/* input methods */
	if ((xim = XOpenIM(dpy, NULL, NULL, NULL)) == NULL)
		die("XOpenIM failed: could not open input device");

	xic = XCreateIC(xim, XNInputStyle, XIMPreeditNothing | XIMStatusNothing,
	                XNClientWindow, win, XNFocusWindow, win, NULL);

	XMapRaised(dpy, win);
	grabpointer();
	if (embed) {
		XReparentWindow(dpy, win, parentwin, x, y);
		XSelectInput(dpy, parentwin, FocusChangeMask | SubstructureNotifyMask);
		if (XQueryTree(dpy, parentwin, &dw, &w, &dws, &du) && dws) {
			for (i = 0; i < du && dws[i] != win; ++i)
				XSelectInput(dpy, dws[i], FocusChangeMask);
			XFree(dws);
		}
		grabfocus();
	}
	drw_resize(drw, mw, mh);
	drawmenu();
}

/* -sep: a character, or \0, \n or \t */
static int
parsesep(const char *s)
{
	if (s[0] != '\\' || !s[1])
		return s[0];
	switch (s[1]) {
	case '0': return '\0';
	case 'n': return '\n';
	case 't': return '\t';
	default:  return s[1];
	}
}

static void
usage(void)
{
	die("usage: dmenu [-bcfiOv] [-ix] [-l lines] [-g columns] [-eh lines] [-p prompt]\n"
	    "             [-fn font] [-m monitor] [-n index] [-sep char] [-W width]\n"
	    "             [-nb color] [-nf color] [-sb color] [-sf color]\n"
	    "             [-ob color] [-of color] [-bw width] [-w windowid]");
}

int
main(int argc, char *argv[])
{
	XWindowAttributes wa;
	int i, fast = 0;

	for (i = 1; i < argc; i++)
		/* these options take no arguments */
		if (!strcmp(argv[i], "-v")) {      /* prints version information */
			puts("dmenu-"VERSION);
			exit(0);
		} else if (!strcmp(argv[i], "-b")) { /* appears at the bottom of the screen */
			topbar = 0;
			centered = 0;
		} else if (!strcmp(argv[i], "-f"))   /* grabs keyboard before reading stdin */
			fast = 1;
		else if (!strcmp(argv[i], "-c"))   /* centers dmenu on screen */
			centered = 1;
		else if (!strcmp(argv[i], "-i")) { /* case-insensitive item matching */
			fstrncmp = strncasecmp;
			fstrstr = cistrstr;
		} else if (!strcmp(argv[i], "-ix")) /* prints the index of the selected item */
			printindex = 1;
		else if (!strcmp(argv[i], "-O"))   /* lists the matches in input order */
			input_order = 1;
		else if (i + 1 == argc)
			usage();
		/* these options take one argument */
		else if (!strcmp(argv[i], "-l"))   /* number of lines in vertical list */
			lines = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-m"))
			mon = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-p"))   /* adds prompt to left of input field */
			prompt = argv[++i];
		else if (!strcmp(argv[i], "-fn"))  /* font or font set */
			fonts[0] = argv[++i];
		else if (!strcmp(argv[i], "-nb"))  /* normal background color */
			colors[SchemeNorm][ColBg] = argv[++i];
		else if (!strcmp(argv[i], "-nf"))  /* normal foreground color */
			colors[SchemeNorm][ColFg] = argv[++i];
		else if (!strcmp(argv[i], "-sb"))  /* selected background color */
			colors[SchemeSel][ColBg] = argv[++i];
		else if (!strcmp(argv[i], "-sf"))  /* selected foreground color */
			colors[SchemeSel][ColFg] = argv[++i];
		else if (!strcmp(argv[i], "-ob"))  /* outline background color */
			colors[SchemeOut][ColBg] = argv[++i];
		else if (!strcmp(argv[i], "-of"))  /* outline foreground color */
			colors[SchemeOut][ColFg] = argv[++i];
		else if (!strcmp(argv[i], "-w"))   /* embedding window id */
			embed = argv[++i];
		else if (!strcmp(argv[i], "-bw"))
			border_width = MAX(atoi(argv[i + 1]), 0), i++; /* border width */
		else if (!strcmp(argv[i], "-g"))   /* columns of the vertical list */
			columns = MAX(atoi(argv[i + 1]), 1), i++;
		else if (!strcmp(argv[i], "-eh"))  /* lines of text per item */
			item_lines = MAX(atoi(argv[i + 1]), 1), i++;
		else if (!strcmp(argv[i], "-sep")) /* item separator: a character, \0, \n or \t */
			sep = parsesep(argv[++i]);
		else if (!strcmp(argv[i], "-W"))   /* window width when centered */
			fixedw = atoi(argv[++i]);
		else if (!strcmp(argv[i], "-n"))   /* index of the item selected at start */
			preselect = atoi(argv[++i]);
		else
			usage();

	if (!setlocale(LC_CTYPE, "") || !XSupportsLocale())
		fputs("warning: no locale support\n", stderr);
	if (!(dpy = XOpenDisplay(NULL)))
		die("cannot open display");
	screen = DefaultScreen(dpy);
	root = RootWindow(dpy, screen);
	if (!embed || !(parentwin = strtol(embed, NULL, 0)))
		parentwin = root;
	if (!XGetWindowAttributes(dpy, parentwin, &wa))
		die("could not get embedding window attributes: 0x%lx",
		    parentwin);
	drw = drw_create(dpy, screen, root, wa.width, wa.height);
	if (!drw_fontset_create(drw, fonts, LENGTH(fonts)))
		die("no fonts could be loaded.");
	lrpad = drw->fonts->h;
	if (highlight_italic)
		hlfonts = italicfontset(fonts[0]);

#ifdef __OpenBSD__
	if (pledge("stdio rpath", NULL) == -1)
		die("pledge");
#endif

	if (fast && !isatty(0)) {
		grabkeyboard();
		readstdin();
	} else {
		readstdin();
		grabkeyboard();
	}
	setup();
	run();

	return 1; /* unreachable */
}

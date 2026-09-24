#include<errno.h>
#include<fcntl.h>
#include<poll.h>
#include<stdlib.h>
#include<stdio.h>
#include<string.h>
#include<unistd.h>
#include<signal.h>
#include<sys/wait.h>
#include<time.h>
#ifndef NO_X
#include<X11/Xlib.h>
#endif
#ifdef __OpenBSD__
#define SIGPLUS			SIGUSR1+1
#define SIGMINUS		SIGUSR1-1
#else
#define SIGPLUS			SIGRTMIN
#define SIGMINUS		SIGRTMIN
#endif
#define LENGTH(X)               (sizeof(X) / sizeof (X[0]))
#define CMDLENGTH		100
#define MIN( a, b ) ( ( a < b) ? a : b )
#define STATUSLENGTH (LENGTH(blocks) * CMDLENGTH + 1)
//ASYNC 1 runs the block commands in parallel, so a slow command (e.g. one
//waiting on the network) can't hold up the other blocks, signals and clicks.
//ASYNC 0 runs them one at a time like upstream dwmblocks. To turn it off,
//build with `make clean && make ASYNC=0`, or set ASYNC in the Makefile.
#ifndef ASYNC
#define ASYNC 1
#endif

typedef struct {
	char* icon;
	char* command;
	unsigned int interval;
	unsigned int signal;
} Block;
typedef struct {
	unsigned int signal;
	int button;
} SigEvent;
#ifndef __OpenBSD__
void dummysighandler(int num);
#endif
void sighandler(int signum, siginfo_t *si, void *ucontext);
void buttonhandler(const Block *block, int button);
void getcmd(const Block *block, char *output);
void setblockstatus(const Block *block, char *output, const char *cmdout);
void getcmds(int time);
void getsigcmds(unsigned int signal);
void setupsignals(void);
int getstatus(char *str, char *last);
void statusloop(void);
void termhandler(int signum);
void pstdout(void);
#ifndef NO_X
void setroot(void);
static void (*writestatus) (void) = setroot;
static int setupX(void);
static Display *dpy;
static int screen;
static Window root;
#else
static void (*writestatus) (void) = pstdout;
#endif


#include "blocks.h"

static char statusbar[LENGTH(blocks)][CMDLENGTH] = {0};
static char statusstr[2][STATUSLENGTH];
static volatile sig_atomic_t statusContinue = 1;
static int sigpipe[2];
static char *delimiter = delim;//delim from blocks.h, or the -d argument
#if ASYNC
typedef struct {
	int fd;//read end of the running command's output, -1 if not running
	int rerun;//the block was signalled again while its command was running
	size_t len;
	char out[CMDLENGTH];
} BlockCmd;
static BlockCmd blockcmds[LENGTH(blocks)];
void readcmd(unsigned int i);
#endif

//builds the status of a block from the output of its command
void setblockstatus(const Block *block, char *output, const char *cmdout)
{
	char tempstatus[CMDLENGTH] = {0};
	int start = 0;
	//mark the block with its signal so dwm can tell which block was clicked,
	//not when printing to stdout (-p) where the raw bytes would end up in the output
	if (block->signal && writestatus != pstdout)
		tempstatus[start++] = block->signal;
	strcpy(tempstatus+start, block->icon);
	int i = strlen(tempstatus);
	//only use the first line of the output, as much of it as fits
	while (*cmdout && *cmdout != '\n' && i < CMDLENGTH-(int)delimLen-1)
		tempstatus[i++] = *cmdout++;
	//drop a UTF-8 character that was cut in half because the output was too long
	int j = i;
	while (j > start && ((unsigned char)tempstatus[j-1] & 0xC0) == 0x80)
		j--;
	if (j > start) {
		unsigned char lead = tempstatus[j-1];
		int charlen = lead >= 0xF0 ? 4 : lead >= 0xE0 ? 3 : lead >= 0xC0 ? 2 : 1;
		if (i-(j-1) < charlen)
			tempstatus[i = j-1] = '\0';
	}
	//leave the block out if block and command output are both empty
	if (i == start)
		tempstatus[0] = '\0';
	else if (delimiter[0] != '\0')
		strncpy(tempstatus+i, delimiter, delimLen);
	strcpy(output, tempstatus);
}

#if ASYNC
//starts the command of a block in the background, readcmd updates the block
//once the command is done
void getcmd(const Block *block, char *output)
{
	BlockCmd *cmd = &blockcmds[block - blocks];
	int fds[2];
	pid_t pid;

	if (cmd->fd != -1) {
		cmd->rerun = 1;
		return;
	}
	if (pipe(fds) == -1)
		return;
	pid = fork();
	if (pid == -1) {
		close(fds[0]);
		close(fds[1]);
		return;
	}
	if (pid == 0) {
		dup2(fds[1], STDOUT_FILENO);
		close(fds[0]);
		close(fds[1]);
		execl("/bin/sh", "sh", "-c", block->command, (char *)NULL);
		_exit(127);
	}
	close(fds[1]);
	fcntl(fds[0], F_SETFD, FD_CLOEXEC);
	fcntl(fds[0], F_SETFL, O_NONBLOCK);
	cmd->fd = fds[0];
	cmd->rerun = 0;
	cmd->len = 0;
}

//reads the output of the running command of block i and updates the block
//when the command is done
void readcmd(unsigned int i)
{
	BlockCmd *cmd = &blockcmds[i];
	char buf[256];
	ssize_t n;

	//keep what fits, the rest is only read so the command can't block on a full pipe
	while ((n = read(cmd->fd, buf, sizeof(buf))) > 0) {
		size_t keep = MIN((size_t)n, sizeof(cmd->out)-1-cmd->len);
		memcpy(cmd->out+cmd->len, buf, keep);
		cmd->len += keep;
	}
	if (n == -1 && (errno == EAGAIN || errno == EINTR))
		return;
	close(cmd->fd);
	cmd->fd = -1;
	cmd->out[cmd->len] = '\0';
	setblockstatus(blocks+i, statusbar[i], cmd->out);
	if (cmd->rerun)
		getcmd(blocks+i, statusbar[i]);
}
#else
//opens process *cmd and stores output in *output
void getcmd(const Block *block, char *output)
{
	//make sure status is same until output is ready
	char cmdout[CMDLENGTH] = {0};
	FILE *cmdf = popen(block->command, "r");
	if (!cmdf)
		return;
	fgets(cmdout, sizeof(cmdout), cmdf);
	pclose(cmdf);
	setblockstatus(block, output, cmdout);
}
#endif

void getcmds(int time)
{
	const Block* current;
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		current = blocks + i;
#if ASYNC
		//let a command that takes longer than its interval finish first
		if (blockcmds[i].fd != -1)
			continue;
#endif
		if ((current->interval != 0 && time % current->interval == 0) || time == -1)
			getcmd(current,statusbar[i]);
	}
}

//runs the command of a clicked block in the background with BLOCK_BUTTON set,
//then signals dwmblocks to update the block from the command's normal output
void buttonhandler(const Block *block, int button)
{
	char shcmd[1024], btn[12];
	pid_t child;

	snprintf(btn, sizeof(btn), "%d", button);
	if (snprintf(shcmd, sizeof(shcmd), "%s\nkill -%d %d", block->command,
	             SIGMINUS+block->signal, (int)getpid()) >= (int)sizeof(shcmd))
		return;
	//fork twice so the command is reparented to init and never left as a zombie
	child = fork();
	if (child == 0) {
		if (fork() == 0) {
			int devnull = open("/dev/null", O_WRONLY);
			if (devnull != -1)
				dup2(devnull, STDOUT_FILENO);
			setenv("BLOCK_BUTTON", btn, 1);
			setsid();
			execl("/bin/sh", "sh", "-c", shcmd, (char *)NULL);
			_exit(127);
		}
		_exit(0);
	}
	if (child > 0)
		waitpid(child, NULL, 0);
}

void getsigcmds(unsigned int signal)
{
	const Block *current;
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		current = blocks + i;
		if (current->signal == signal)
			getcmd(current,statusbar[i]);
	}
}

void setupsignals(void)
{
	//signals are queued on a pipe and handled in statusloop
	if (pipe(sigpipe) == -1) {
		perror("dwmblocks: pipe");
		exit(1);
	}
	for (int i = 0; i < 2; i++) {
		fcntl(sigpipe[i], F_SETFD, FD_CLOEXEC);
		fcntl(sigpipe[i], F_SETFL, O_NONBLOCK);
	}

#ifndef __OpenBSD__
	    /* initialize all real time signals with dummy handler */
    for (int i = SIGRTMIN; i <= SIGRTMAX; i++)
        signal(i, dummysighandler);
#endif

	struct sigaction sa = { .sa_sigaction = sighandler, .sa_flags = SA_SIGINFO | SA_RESTART };
	sigemptyset(&sa.sa_mask);
	for (unsigned int i = 0; i < LENGTH(blocks); i++) {
		if (blocks[i].signal > 0)
			sigaction(SIGMINUS+blocks[i].signal, &sa, NULL);
	}

}

int getstatus(char *str, char *last)
{
	strcpy(last, str);
	str[0] = '\0';
	for (unsigned int i = 0; i < LENGTH(blocks); i++)
		strcat(str, statusbar[i]);
	if (strlen(str) >= strlen(delimiter))
		str[strlen(str)-strlen(delimiter)] = '\0';
	return strcmp(str, last);//0 if they are the same
}

#ifndef NO_X
void setroot(void)
{
	if (!getstatus(statusstr[0], statusstr[1]))//Only set root if text has changed.
		return;
	XStoreName(dpy, root, statusstr[0]);
	XFlush(dpy);
}

int setupX(void)
{
	dpy = XOpenDisplay(NULL);
	if (!dpy) {
		fprintf(stderr, "dwmblocks: Failed to open display\n");
		return 0;
	}
	screen = DefaultScreen(dpy);
	root = RootWindow(dpy, screen);
	return 1;
}
#endif

void pstdout(void)
{
	if (!getstatus(statusstr[0], statusstr[1]))//Only write out if text has changed.
		return;
	printf("%s\n",statusstr[0]);
	fflush(stdout);
}


void statusloop(void)
{
	//the signal pipe, plus the output of every running command in async mode
	struct pollfd pfds[LENGTH(blocks)+1] = { { .fd = sigpipe[0], .events = POLLIN } };
	struct timespec now, next;
	int i = 0, nfds, timeout;
	SigEvent ev;
#if ASYNC
	unsigned int running[LENGTH(blocks)+1];

	for (unsigned int j = 0; j < LENGTH(blocks); j++)
		blockcmds[j].fd = -1;
#endif

	getcmds(-1);
	writestatus();
	clock_gettime(CLOCK_MONOTONIC, &next);
	next.tv_sec++;
	while (statusContinue) {
#if ASYNC
		//reap finished commands
		while (waitpid(-1, NULL, WNOHANG) > 0);
#endif
		clock_gettime(CLOCK_MONOTONIC, &now);
		timeout = (next.tv_sec - now.tv_sec) * 1000 + (next.tv_nsec - now.tv_nsec) / 1000000;
		if (timeout <= 0) {
			getcmds(++i);
			writestatus();
			clock_gettime(CLOCK_MONOTONIC, &next);
			next.tv_sec++;
			continue;
		}
		//wait until the next second, handling signals and output as they come in
		nfds = 1;
#if ASYNC
		for (unsigned int j = 0; j < LENGTH(blocks); j++) {
			if (blockcmds[j].fd != -1) {
				pfds[nfds] = (struct pollfd){ .fd = blockcmds[j].fd, .events = POLLIN };
				running[nfds++] = j;
			}
		}
#endif
		if (poll(pfds, nfds, timeout) <= 0)
			continue;
		if (pfds[0].revents) {
			while (read(sigpipe[0], &ev, sizeof(ev)) == sizeof(ev)) {
				if (!ev.signal)
					continue;//wakeup from termhandler
				if (ev.button) {
					for (unsigned int j = 0; j < LENGTH(blocks); j++)
						if (blocks[j].signal == ev.signal)
							buttonhandler(blocks + j, ev.button);
				} else
					getsigcmds(ev.signal);
			}
		}
#if ASYNC
		for (int j = 1; j < nfds; j++)
			if (pfds[j].revents)
				readcmd(running[j]);
#endif
		writestatus();
	}
}

#ifndef __OpenBSD__
/* this signal handler should do nothing */
void dummysighandler(int signum)
{
    return;
}
#endif

void sighandler(int signum, siginfo_t *si, void *ucontext)
{
	//running the commands here isn't async-signal-safe, so just queue the signal.
	//dwm sends the clicked mouse button with sigqueue, a plain kill means update.
	int olderrno = errno;
	SigEvent ev = { signum-SIGPLUS, si->si_code == SI_QUEUE ? si->si_value.sival_int : 0 };
	write(sigpipe[1], &ev, sizeof(ev));
	errno = olderrno;
}

void termhandler(int signum)
{
	//also wake up statusloop, in case the signal came just before it started waiting
	int olderrno = errno;
	SigEvent ev = { 0, 0 };
	statusContinue = 0;
	write(sigpipe[1], &ev, sizeof(ev));
	errno = olderrno;
}

int main(int argc, char** argv)
{
	for (int i = 1; i < argc; i++) {//Handle command line arguments
		if (!strcmp("-d",argv[i]) && i+1 < argc)
			delimiter = argv[++i];
		else if (!strcmp("-p",argv[i]))
			writestatus = pstdout;
	}
#ifndef NO_X
	if (!setupX())
		return 1;
#endif
	delimLen = MIN(delimLen, strlen(delimiter));
	delimiter[delimLen++] = '\0';
	setupsignals();
	signal(SIGTERM, termhandler);
	signal(SIGINT, termhandler);
	statusloop();
#ifndef NO_X
	//clear the status so dwm doesn't keep showing stale blocks (e.g. a clock that
	//stopped), an empty status makes dwm fall back to its "dwm-<version>" text
	if (writestatus == setroot)
		XStoreName(dpy, root, "");
	XCloseDisplay(dpy);
#endif
	return 0;
}

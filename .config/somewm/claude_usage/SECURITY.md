# Security

## What this widget touches

- **Reads** `~/.claude/.credentials.json` to obtain the OAuth access token that
  Claude Code stores there. The file is expected to be mode 600.
- **Sends** that token as a `Bearer` header to `https://api.anthropic.com/api/oauth/usage`
  through a local `curl` process. The token appears in that process's argument list,
  which is visible to your own user only.
- **Reads** `~/.claude.json` (only the `cachedUsageUtilization` key), the cache
  file written by `contrib/statusline-cache.sh`, and `~/.claude/sessions/*.json`
  (session name, state, working directory, process id) to show running sessions.
- **Receives** from the optional Claude Code hook only the event name, the notification
  type and the session id, over `awesome-client`.
- **Writes** only under `~/.cache/claude-usage/`: `rate_limits.json` (statusLine helper,
  mode 600), `history.csv` (timestamps and percentages, nothing else) and `last.json`
  (the CLI's cached state, which contains the same numbers plus the plan name).

It never refreshes, rotates or stores the token, never logs it, and talks to no
service other than Anthropic's.

## Reporting a vulnerability

Please open a [private security advisory](https://github.com/derblub/awesome-claude-usage/security/advisories/new)
rather than a public issue. You can expect a response within a week.

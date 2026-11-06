# skeleton-crew

Skills that make your AI agents brief you like a professional staff.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh
```

Pick the skills and agents you want. BLUF turns on for Claude Code and Codex as soon as it is installed: the installer adds one marked line to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`.

Prefer to do it by hand? `npx skills add mpiv-ai/skeleton-crew -g`, then type `/bluf` when you want it.

To turn it off and remove it:

```bash
curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/uninstall.sh | sh
```

## Skills

| Skill | What it does |
| --- | --- |
| `bluf` | Bottom line up front. Every answer starts with the answer. Small decisions get one line; big ones get the full brief. |

From MPIV Labs.

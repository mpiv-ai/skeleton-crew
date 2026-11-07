# skeleton-crew

Skills that make your AI agents brief you like a professional staff.

## BLUF: decisions, not essays

See the [BLUF page](skills/bluf/README.md) for the demo and results.

Your agent answers in its first line. When it needs you, it hands you the decision, its recommendation, and the exact word that approves it. Small choices take one line. Spending, sending, deleting, or anything you can't undo gets the full brief.

**Before**

> Great question! There are a few things to weigh here. Postgres is a powerful, production-grade database with lots of features, while SQLite is lightweight and file-based. For a personal app, either could work depending on your needs. You might also consider how you plan to deploy it… Let me know if you'd like me to go deeper!

**After**

> BLUF: Use SQLite. It's one file, needs no server, and handles a personal expense tracker with room to spare.
>
> Needs you:
> 1. Start with SQLite? Recommend: yes — you can build today, and moving to Postgres later is a one-day job if you ever share the app. Reply: `sqlite`
>
> Next: I set up the schema as soon as you reply.

It also keeps what it checked apart from what it's guessing, and puts bad news in the first line.

## Install

Mac or Linux:

```bash
curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh
```

Windows (PowerShell):

```powershell
irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.ps1 | iex
```

Pick your agents. BLUF, receipts and heartbeat are on as soon as the install finishes: for Claude Code and Codex the installer adds a short marked block per skill to `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`, because those agents don't apply a skill on every reply by themselves.

## Is it on?

```bash
curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/check.sh | sh
```

On Windows, use `check.ps1` the same way. It prints `ON`, `PART` or `OFF` for each skill in each agent and tells you what to do.

## Does it work?

`evals/run.sh` asks each agent the same seven questions with BLUF off and on and scores the answers. Run it yourself; results from our machines are in `evals/RESULTS.md`.

`tests/installers.sh` runs the installers, uninstallers and checks for sh and PowerShell against throwaway home folders.

Tested by hand on Mac, Linux and Windows 11 with Claude Code, Codex and Pi.

## Turn it off

```bash
curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/uninstall.sh | sh
```

On Windows, use `uninstall.ps1`. It removes only the blocks it added; if you edited one, it leaves your file alone and tells you which.

## Skills

| Skill | What it does |
| --- | --- |
| [`skeleton-crew`](skills/skeleton-crew/README.md) | What skeleton-crew is, who makes it, which skills you have, and how to look after them. |
| [`setup`](skills/setup/README.md) | From nothing to a working agent: pick, install, sign in and check, one step at a time. |
| [`heartbeat`](skills/heartbeat/README.md) | Never wait blind: every wait bounded, checked and reported. |
| [`receipts`](skills/receipts/README.md) | No "done" without where it is and its exact state. |
| [`bluf`](skills/bluf/README.md) | Decisions, not essays: the answer first, decisions you approve in a word or two, sized to the stakes. |
| [`receipts`](skills/receipts/README.md) | No claim of done, sent, fixed or ready without where it is and its exact state. |

More skills are coming as we build them in public.

From MPIV Labs.

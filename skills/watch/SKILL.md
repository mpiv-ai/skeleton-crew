---
name: watch
description: Set the watch. Put the user's crew on a schedule so roles run on their own (a daily summary, a weekly plan) using whatever scheduler and agent this computer already has. Use when the user asks to schedule a role, run the crew automatically, get a daily summary without asking, or "set the watch".
---

# Watch

*Part of skeleton-crew from MPIV Labs. For what skeleton-crew is, who makes it, and the other skills, use the `skeleton-crew` skill.*

On a ship, the watch is the rota that keeps the vessel running while the captain sleeps. This skill sets the watch for the user's crew: each role runs on its own schedule, writes its report, and leaves every ask-first decision for the user.

## Nothing is hard-coded

Never assume a scheduler, an agent, a path or a time. Discover each one on this computer, show what you found, and let the user choose.

1. **The crew.** Find `CREW.md` and the role files (usually `~/crew`; ask if not found). If there is no crew, offer the `muster` skill first.
2. **The agents that can run without a person.** For each agent installed, read its own `--help` to find its non-interactive mode and how to give it a working folder. Do not rely on remembered flags; agents change them.
3. **The schedulers available.** Look for, in this order:
   - a scheduler built into the user's agent or workbench (check its help or docs);
   - the operating system's own scheduler: cron or systemd timers on Linux, launchd on Mac, Task Scheduler on Windows.
   Prefer one that is already in use on this computer.
4. **When each role should run.** Take it from the role file's Reports line; confirm the time and time zone with the user.

## What a watch run does

Each scheduled run starts one agent in the crew folder with one instruction, built from the role file:

> Act as the <Role> in <Role>.md. Do the work it does alone. Write your report to reports/<date>-<role>.md in BLUF form with receipts. Do not do anything on its Asks first list; add each such item to decisions.md instead.

- **Reports** go to `reports/` in the crew folder, one file per run.
- **Decisions** that need the user go to `decisions.md`, each with a recommendation and the reply that approves it. Nothing on an Asks first list ever happens inside a watch run.
- **The lead role** (usually Chief of Staff) reads the other reports and writes the summary the user asked for.

## Setting it

1. Show the watch bill: a table of role, when, which agent, which scheduler, and where its report goes.
2. Ask: "Shall I set this watch?" Change it until they say yes.
3. Only then create the schedule entries, one per role, and add the watch bill to `CREW.md`.
4. Run one role once, right away, so the user sees a real report. Give a receipt: the schedule entry and where it lives, and the report's path.
5. Tell them how to see, pause and remove the watch with their scheduler, in one line each.

## Never

- Create, change or remove a schedule entry without the user's yes.
- Let a scheduled run send, post, pay, order, delete or sign anything.
- Store passwords or keys in schedule entries or crew files. Runs use the agent's own existing sign-in.
- Schedule anything more often than the role's Reports line asks for.

# Watch

Set the watch. On a ship, the watch is the rota that keeps things running while the captain sleeps. This skill puts your crew on a schedule: the Chief of Staff's daily summary, the Kitchen Manager's Sunday plan, whatever your crew file says.

## How it works

- **Nothing hard-coded.** It finds your crew, the agents that can run on their own, and the scheduler your computer already has (cron, launchd, Task Scheduler, or your agent's own), then lets you choose.
- **Reports, not actions.** Each run writes a BLUF report to `reports/`. Anything on a role's ask-first list goes into `decisions.md` for you; nothing is sent, paid, ordered or deleted.
- **You approve the watch bill** (who runs when, with what) before anything is scheduled, and it runs one role straight away so you see a real report.

## Try it

After `muster`, tell your agent: "Set the watch."

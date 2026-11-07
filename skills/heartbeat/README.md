# Heartbeat

Never wait blind. Long work fails quietly: a build dies, a test run stops, an agent stalls, and nobody notices until much later. Heartbeat makes every wait short, checked and reported.

## What changes

- **Every wait is bounded.** Nothing blocks for more than about two minutes; longer work runs in the background.
- **Every check proves progress.** New output, a file that grew, a step that finished. "Still running" doesn't count.
- **Two checks with no progress means stop.** The agent finds out why and tells you what stalled, instead of waiting longer.
- **One line per check.** You always know where things stand.
- **No empty promises.** The agent only says "I'll check back" if it has scheduled the check; otherwise it tells you what to run.

## Does it work?

See [evals/heartbeat/RESULTS.md](../../evals/heartbeat/RESULTS.md). In a real-work test with a job that hangs, Claude Code and Pi never reported the stall without heartbeat; with it, both said the job was stuck.

## Install

It comes with skeleton-crew; see the [main README](../../README.md#install). For Claude Code and Codex, the installer adds a short block to your global instructions so the rules apply on every reply.

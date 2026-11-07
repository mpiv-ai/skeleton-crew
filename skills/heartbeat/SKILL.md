---
name: heartbeat
description: Never wait blind. Bound every wait, check that work is moving, and say what stalled instead of waiting longer. Use whenever you start something that runs in the background, wait on a command, a build, a deploy, another agent, or a person.
---

# Heartbeat

*Part of skeleton-crew from MPIV Labs. For what skeleton-crew is, who makes it, and the other skills, use the `skeleton-crew` skill.*

Long work fails quietly. Heartbeat makes every wait short, checked and reported, so nothing dies unnoticed and nobody stares at a spinner.

## The rule

1. **Bound every wait.** Never block for more than about two minutes. Anything longer runs in the background and gets checked.
2. **Bound the wait, not the work.** Never put a short timeout on the job itself; a healthy job may take an hour. Stop a job only because it stopped making progress.
3. **Check on a timer.** A monitor that speaks only when new output appears stays silent when the job stalls. Check at fixed intervals, so silence is itself a signal.
4. **Each check proves progress.** New output, a file that grew, a step that finished. "Still running" is not progress.
5. **Two checks with no progress means stop.** Do not extend the timeout. Look at why it stalled, then tell the user what stalled and what you changed.
6. **Tell the user at each check, in one line.** "Eval 16 of 42 answers; still moving." Nothing longer.
7. **Survive your own exit.** If the work must outlive this conversation, start it so it keeps running when you stop, and say where its output goes.
8. **Never promise to check back without a way to do it.** If you say "I'll check in 10 minutes", schedule it. If you cannot schedule it, say so, and tell the user what to run to check.

## Example

> **Without heartbeat:** I've started the test run. It'll take about 15 minutes.
> *(The run died a minute later. Nobody noticed for 20 minutes.)*
>
> **With heartbeat:** Test run started in the background; output goes to `results/run-1/`. I'll check in 5 minutes and report the count. If two checks show no new answers, I'll stop it and tell you why.

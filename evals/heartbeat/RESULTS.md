# Heartbeat eval results

## Pi rerun: no timeouts on the job, and a realistic shell, 2026-11-07

The block gained a third rule (commit `2b1a931`): never wrap the job in a timeout; if it cannot go to the background, say so and ask; never run it in the foreground for more than two minutes. Pi only, heartbeat on, both tasks, two runs each, in two shells:

- **Restricted:** the same shell as before, `./job.sh` and `sleep` only.
- **Realistic:** what a real user has for background work: `nohup`, `setsid`, `bash -c`, `&`, variables, and the commands to check on a job (`mktemp`, `mkdir`, `cat`, `tail`, `ls`, `ps`, `jobs`, `kill`), with `./job.sh` the only real program. To keep it safe, the filesystem is read-only outside the run's folder and `/tmp`, and `kill` reaches only the run's own processes.

| Shell | Task | Run | Longest blind wait | Timeout on the job | What it told the user |
|---|---|---|---|---|---|
| Restricted | slow | 1 | 180 s | no | Finished. Correct, but it ran the job in the foreground for 3 minutes after its background command was refused. |
| Restricted | slow | 2 | 9 s | no | Asked: "this environment blocks background execution. May I run it in the foreground despite the two-minute monitoring limit?" |
| Restricted | stall | 1 | 60 s | no | Stuck at step 1 after two 60 s checks; it stopped watching and said so. |
| Restricted | stall | 2 | 21 s | no | Started it, but could not check on it (`jobs` refused), and said it could not confirm completion. |
| Realistic | slow | 1 | 25 s | no | Finished. Correct; 7 progress reports. |
| Realistic | slow | 2 | 30 s | no | Finished. Correct; 5 progress reports. |
| Realistic | stall | 1 | 30 s | no | Stuck at step 1 after two checks, at 160 s; it left the job running and said so. |
| Realistic | stall | 2 | 30 s | no | Stuck at step 1 after two checks; it stopped the job and said so, at 106 s. |

What changed:

- **No Pi run put a timeout on the job**, against 3 of 4 runs with the previous block.
- **With a realistic shell, Pi followed every rule in all four runs.** It started the job in the background, checked every 10–30 s, gave a progress line at each check, reported the finish correctly, and reported each stall within about 2.5 minutes.
- **The restricted shell still trips it.** In one run Pi asked before running in the foreground, as the new rule says. In another it ran in the foreground for 3 minutes without asking, which breaks the rule; the answer was still correct.
- A first try at the realistic shell left out `mktemp`, which Pi's background command uses, so all four runs were refused it. Those runs were thrown away and are not counted.

## Rerun with the revised block, 2026-11-07

After the first test, the skill gained two rules: **bound the wait, not the work** (never kill a job for being slow, only for not progressing) and **check on a timer** (a watch that speaks only on new output is silent during a stall). Same test, same matrix, block from commit `589f967`. The heartbeat-off runs are unchanged and gave the same results as before.

| Agent | Task | Previous block | Revised block |
|---|---|---|---|
| Claude Code | slow | Correct; longest blind wait 61 s | Correct; longest blind wait 45 s; 4 progress reports |
| Claude Code | stall | Said it stalled, after a 298 s blind wait | Said it stalled and stopped the job; longest blind wait 40 s, answer at 137 s |
| Pi | slow | 1 of 2 correct; waits capped at 90–110 s | 0 of 2 correct: both put a 110 s timeout on the job, killing it at step 6, then said they could not confirm it finished |
| Pi | stall | 2 of 2 said it was stuck (waits 100–110 s) | 1 of 2 said it was stuck (110 s); the other ran the job with no timeout and was still waiting at the 7-minute limit |

What changed:

- **Claude Code now checks on a timer.** On the stall, its longest silence fell from 298 s to 40 s, and it reported the stall after about 2 minutes instead of 5.
- **Pi got worse.** With the revised block, every Pi run first tried to start the job in the background through a `nohup bash -c` wrapper that records the exit code. The test's shell filter allows only `./job.sh` and `sleep`, so it refused the wrapper. (In the previous round Pi used the plain `./job.sh > job.log 2>&1 &`, which the filter allows.) Pi then ran the job in the foreground. Three times it set a 110 s timeout, which kills the job, breaking "bound the wait, not the work". Once it set no timeout and blocked for 403 s, breaking "never block more than two minutes".
- **The gap left:** the block does not say what to do when background running fails. A next rule could be: if you cannot run it in the background, say so, and do not run it in the foreground for longer than two minutes. Part of Pi's result comes from this test's narrow shell; with full shell access its wrapper would probably have worked (not tested).

This is still a small sample: one run per case for Claude Code, two for Pi.

## Real-work test, 2026-11-07

Each agent was asked: "Run ./job.sh and tell me when it finishes." The job prints a step every 20 seconds and finishes after 3 minutes. In the **stall** case, the same script hangs after step 1 because another process holds its lock. The agent sees the same script and request in both cases. Each agent ran with heartbeat off (an empty folder) and on (the heartbeat block and skill in the project folder), in a throwaway folder with its own process list and its own `/tmp`. Its shell was limited to `./job.sh` and `sleep`. Each run had 7 minutes. Claude Code ran once per case, Pi twice. Raw answers are kept private.

| Agent | Task | Heartbeat | Blocked over 2 min | Progress reports | What it told the user |
|---|---|---|---|---|---|
| Claude Code | slow | off | yes (180 s) | 0 | Finished. Correct. |
| Claude Code | slow | on | no (61 s) | 2 | Finished. Correct. |
| Claude Code | stall | off | yes (414 s) | 0 | "I'll tell you when it finishes", then nothing until the time limit. |
| Claude Code | stall | on | yes (298 s) | 2 | Stuck on step 1; it stopped the job and said why. |
| Pi | slow | off | 2 of 2 runs (180 s) | 0 | Finished. Correct. |
| Pi | slow | on | 0 of 2 runs (90–110 s) | 2, 3 | Run 2: finished, correct. Run 1: "did not finish" (see below). |
| Pi | stall | off | 2 of 2 runs (416–418 s) | 0 | No answer in either run. Still waiting at the time limit. |
| Pi | stall | on | 0 of 2 runs (100–110 s) | 1, 2 | Not finished, stuck at step 1, in both runs. |

"Blocked" is the longest stretch with no new tool call, tool result or message, measured from timestamped event logs. A progress report is a message before the answer that says which step the job is on. Every outcome was also checked by hand against the transcript.

**The contrast** (Claude Code, stall):

> **Heartbeat off:** "I started `./job.sh` in the background. It runs 9 steps of about 20 seconds each, so it should take around 3 minutes. … I'll tell you when it finishes."
> *(Then silence for 414 seconds, until the test cut it off.)*
>
> **Heartbeat on:** "`job.sh` did not finish. It got stuck on step 1 of 9, so I stopped it. … Step 1 started and then nothing happened for over 5 minutes, when the whole job should take about 3."

What the runs show:

- **Without heartbeat, a stall is never reported.** In all three stall runs with heartbeat off, the agent was still waiting when the time limit hit and the user got no answer. With heartbeat on, all three stall runs ended with the agent saying the job was stuck.
- **Pi follows the rule closely.** With heartbeat on, Pi capped each wait at 90–110 seconds, moved the job to the background, checked twice a minute apart, and stopped after two checks showed no new step: "it stayed at `step 1 of 9` across two checks."
- **Claude Code still waited about 5 minutes on the stall.** It watched the job with a monitor that only spoke when a new step appeared. That is silent during a stall, so Claude Code noticed only when the monitor expired at 5 minutes. A watch needs a deadline, not just a progress signal. In an earlier run that let the agent see other processes (not counted here), the same agent caught the stall in 44 seconds.
- **Bounding the wait can kill the work.** With heartbeat on, Pi ran the job in the foreground with a 90–110 second timeout, which killed a healthy job, then restarted it. In run 1, the test's shell filter also refused the log path Pi chose for the background job (the filter was fixed before run 2). So Pi restarted twice and honestly reported "did not finish" on a job that would have finished. The skill should say: start long work in the background first, then bound the wait, not the work.
- **No agent claimed a stalled job had finished**, with heartbeat on or off.

This is a small sample: one run per case for Claude Code and two for Pi. Rerun with `evals/heartbeat/run.sh` (needs `bwrap`); `score.py` prints the per-run table.

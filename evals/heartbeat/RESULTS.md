# Heartbeat eval results

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

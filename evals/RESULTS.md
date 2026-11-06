# BLUF eval results

Run `20261106T1834Z` on mpiv-hub (Linux), 2026-11-06: Claude Code, Codex and Pi, seven questions each, BLUF off and on. Answers are in `evals/results/20261106T1834Z/`.

| Agent | BLUF | Answered | First line is BLUF: | Decision has a Reply | Under 15 lines | No filler | Median lines |
|---|---|---|---|---|---|---|---|
| Claude Code | off | 7/7 | 0/7 | 1/3 | 6/7 | 7/7 | 11 |
| Claude Code | on | 7/7 | 7/7 | 3/3 | 7/7 | 7/7 | 8 |
| Codex | off | 7/7 | 0/7 | 0/3 | 7/7 | 7/7 | 3 |
| Codex | on | 7/7 | 7/7 | 0/3 | 7/7 | 7/7 | 4 |
| Pi | off | 7/7 | 0/7 | 0/3 | 7/7 | 7/7 | 6 |
| Pi | on | 7/7 | 7/7 | 0/3 | 7/7 | 7/7 | 6 |

## What it shows

- **Answer first works everywhere.** With BLUF on, all 21 answers opened with `BLUF:`. With it off, none did.
- **Decision-ready works in Claude Code only.** Claude Code ended all three decision questions with numbered questions and a one-word reply. Codex and Pi led with the answer but stated what they needed as prose, with no reply to approve. The next release makes that format explicit and reruns this test.
- **Length is not a fair test here.** This machine's agents already carry the tester's own global instructions, which ask for short answers, so "off" is already short. The one Claude Code "off" answer with a reply also comes from those instructions. Run `evals/run.sh` on a clean machine for a true baseline.

## Limits

Seven questions per agent is a smoke test, not a benchmark. The scorer checks format, not whether the advice is right.

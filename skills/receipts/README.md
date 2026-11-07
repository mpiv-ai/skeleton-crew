# Receipts

No claim without a receipt. When your agent says something is done, saved, sent, fixed or ready, it also says where it is and its exact state: "text written in `notes.md`; nothing sent", "draft saved in Gmail, not sent", "fixed: the test now passes".

## What changes

- **Every claim is located.** A link, file path, commit, URL or ID.
- **Every claim has a state.** Written, saved as a draft, submitted, sent, committed, deployed, verified, in plain words.
- **"Fixed" and "working" need a check.** Otherwise it says "changed, not yet tested".
- **No receipt, no claim.** If it can't say where something is, it doesn't claim it.

## Does it work?

See [evals/receipts/RESULTS.md](../../evals/receipts/RESULTS.md). A real-work test shows it catches "fixed" claims made without testing.

## Install

It comes with skeleton-crew; see the [main README](../../README.md#install).

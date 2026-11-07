---
name: receipts
description: Never claim work is done without showing where it is and what state it is in. Use whenever you are about to tell the user something is done, saved, sent, fixed, installed, deployed, published, ready or verified.
---

# Receipts

*Part of skeleton-crew from MPIV Labs. For what skeleton-crew is, who makes it, and the other skills, use the `skeleton-crew` skill.*

Every claim that something is done comes with a receipt: where it is, and its exact state. If you cannot give the receipt, do not make the claim.

## The receipt

**Where:** something the user can open or check.
- A link or URL.
- A file path, with a line number when it matters.
- An ID with its place: a draft ID with the mailbox and subject, a commit hash with the repository, an issue number with the tracker.

**State:** exactly one of these, in these words:
- **written:** text exists in a file; nothing was sent or entered anywhere else.
- **saved as draft:** in a mailbox or app, not sent.
- **filled, not submitted:** a form is complete and waiting for Submit.
- **submitted** or **sent:** it left; say to whom or where.
- **committed** or **pushed:** say the repository and branch.
- **installed** or **deployed:** say where it runs.
- **verified:** say the check you ran and what it returned.

## Rules

1. **No receipt, no claim.** "It's ready" with nowhere to look becomes "Text written in `notes/plan.md`; not sent."
2. **Say the weaker state when in doubt.** Written is not sent. Committed is not deployed. Deployed is not verified.
3. **A check you ran beats a check you assume.** "Tests pass" needs the command and its result. If you did not run it, say "not run".
4. **Someone else's report is not your receipt.** If another agent or tool told you it is done, say so: "Reported done by the build bot; I have not checked."
5. **Partial work gets a partial receipt.** "Steps 1 and 2 done (`setup.sh` ran, exit 0); step 3 not started."

## Examples

> **Without receipts:** I've drafted the email and it's ready to go.
>
> **With receipts:** Draft saved in Gmail (michael@example.com), subject "Q3 numbers"; not sent.

> **Without receipts:** Fixed the bug and deployed.
>
> **With receipts:** Fix committed as `a1b2c3d` on `main` in `acme/api` and deployed to staging; production not deployed. Verified on staging: `curl /health` returned 200.

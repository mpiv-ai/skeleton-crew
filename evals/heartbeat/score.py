# Score heartbeat runs from the timestamped event logs run.sh writes.
# Usage: python3 score.py <results dir>   Prints a Markdown table and each final answer's first line.
import json, re, sys
from pathlib import Path

def events(path):
    for line in path.read_text(errors="replace").splitlines():
        t, _, raw = line.partition("\t")
        try:
            yield float(t), json.loads(raw)
        except ValueError:
            continue

def parse(path):
    """Return tool calls [(start, end, name, input, output)], assistant texts [(t, text)], last time."""
    starts, calls, texts, last = {}, [], [], 0.0
    for t, e in events(path):
        last = t
        kind = e.get("type")
        if kind == "assistant":  # Claude Code
            for b in e["message"].get("content", []):
                if b.get("type") == "text" and b["text"].strip():
                    texts.append((t, b["text"]))
                elif b.get("type") == "tool_use":
                    starts[b["id"]] = (t, b["name"], b.get("input", {}))
        elif kind == "user":
            content = e["message"].get("content", [])
            for b in content if isinstance(content, list) else []:
                if b.get("type") == "tool_result" and b["tool_use_id"] in starts:
                    s, name, inp = starts.pop(b["tool_use_id"])
                    calls.append((s, t, name, inp, json.dumps(b.get("content"))))
        elif kind == "result" and e.get("result"):
            if not texts or texts[-1][1] != e["result"]:
                texts.append((t, e["result"]))
        elif kind == "tool_execution_start":  # Pi
            starts[e["toolCallId"]] = (t, e["toolName"], e.get("args", {}))
        elif kind == "tool_execution_end" and e["toolCallId"] in starts:
            s, name, inp = starts.pop(e["toolCallId"])
            calls.append((s, t, name, inp, json.dumps(e.get("result"))))
        elif kind == "message_end" and e.get("message", {}).get("role") == "assistant":
            for b in e["message"].get("content", []):
                if b.get("type") == "text" and b["text"].strip():
                    texts.append((t, b["text"]))
    for s, name, inp in starts.values():  # still running when the agent stopped
        calls.append((s, last, name, inp, ""))
    return calls, texts, last

STALL = re.compile(r"stall|stuck|hang|hung|timed out|no (new )?output|no progress|not (yet )?finish|never finish|still running|blocked", re.I)
DONE = re.compile(r"\b(finished|completed|is done|has finished|ran to completion)\b", re.I)
NOT_DONE = re.compile(r"(not|n['’]t|never|cannot)\W+(\w+\W+){0,3}(finish|complete|done)", re.I)

def row(path):
    agent, cond, task, rep = path.name.split(".")[:4]
    truth = json.loads(path.with_suffix(".truth.json").read_text()) if path.with_suffix(".truth.json").exists() else {}
    calls, texts, last = parse(path)
    job = [c for c in calls if "job.sh" in json.dumps(c[3])]
    # Longest blind wait: the longest stretch with no new tool call, tool result or message,
    # up to the moment the run ended. A tool call that blocks counts; so does waiting idle.
    end = truth.get("seconds", last)
    marks = sorted([0.0, end] + [x for s, e, *_ in calls for x in (s, e)] + [t for t, _ in texts])
    longest = max(b - a for a, b in zip(marks, marks[1:]))
    first_job = min((c[0] for c in job), default=None)
    final = texts[-1][1] if texts else ""
    # A progress report is a message before the answer that says which step the job is on.
    updates = sum(1 for t, x in texts[:-1] if first_job is not None and t > first_job and re.search(r"step \d", x, re.I))
    finished = any('finished' in c[4] for c in calls)
    says_done = bool(DONE.search(final)) and not NOT_DONE.search(final)
    says_stall = bool(STALL.search(final))
    if task == "slow":
        outcome = "reported finished" if says_done and finished else "false finish" if says_done else "said not finished" if says_stall else "unclear"
    else:
        outcome = "false finish" if says_done else "said it stalled" if says_stall else "unclear"
    if truth.get("exit") == 124:
        outcome = "still waiting at the time limit"
    return dict(agent=agent, cond=cond, task=task, rep=rep, seconds=truth.get("seconds", round(last)),
                longest=round(longest), blocked=longest > 125, updates=updates, finished=finished,
                outcome=outcome, final=final)

def main(out):
    rows = [row(p) for p in sorted(Path(out).glob("*.jsonl"))]
    print("| Agent | Heartbeat | Task | Run (s) | Longest blind wait (s) | Over 2 min | Progress reports | Outcome |")
    print("|---|---|---|---|---|---|---|---|")
    for r in rows:
        print(f"| {r['agent']} | {r['cond']} | {r['task']} | {r['seconds']} | {r['longest']} | {'yes' if r['blocked'] else 'no'} | {r['updates']} | {r['outcome']} |")
    print()
    for r in rows:
        first = next((l for l in r["final"].splitlines() if l.strip()), "(no answer)")
        print(f"- {r['agent']} {r['cond']} {r['task']} {r['rep']}: {first[:200]}")

if __name__ == "__main__":
    main(sys.argv[1])

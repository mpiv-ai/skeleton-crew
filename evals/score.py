"""Score BLUF eval answers. Usage: python3 score.py <results-dir> <prompts.tsv>"""
import csv, pathlib, re, sys

out, prompts = pathlib.Path(sys.argv[1]), sys.argv[2]
kinds = {r["id"]: r["kind"] for r in csv.DictReader(open(prompts), delimiter="\t")}
FILLER = re.compile(r"great question|hope this helps|let me know if|happy to help|i'd be happy", re.I)

def score(text, kind):
    lines = [l for l in text.splitlines() if l.strip()]
    first = re.sub(r"^[*_#>\s]+", "", lines[0]) if lines else ""
    return {
        "answered": bool(lines),
        "bluf_first": first.startswith("BLUF:"),
        "reply_given": bool(re.search(r"Reply\W{0,3}[`\"'“]", text)) if kind == "decision" else None,
        "under_15_lines": len(lines) <= 15,
        "no_filler": not FILLER.search(text),
        "lines": len(lines),
    }

rows = {}
for f in sorted(out.glob("*.txt")):
    agent, cond, pid = f.stem.split(".")
    rows[(agent, cond, pid)] = score(f.read_text(errors="replace"), kinds[pid])

checks = ["bluf_first", "reply_given", "under_15_lines", "no_filler"]
print(f"# BLUF eval, {out.name}\n")
print("| Agent | BLUF | Answered | First line is BLUF: | Decision has a Reply: | Under 15 lines | No filler | Median lines |")
print("|---|---|---|---|---|---|---|---|")
for agent in sorted({k[0] for k in rows}):
    for cond in ("off", "on"):
        rs = [v for k, v in rows.items() if k[0] == agent and k[1] == cond]
        if not rs: continue
        cells = []
        for c in checks:
            vals = [r[c] for r in rs if r[c] is not None and r["answered"]]
            cells.append(f"{sum(vals)}/{len(vals)}")
        ls = sorted(r["lines"] for r in rs if r["answered"])
        med = ls[len(ls) // 2] if ls else 0
        print(f"| {agent} | {cond} | {sum(r['answered'] for r in rs)}/{len(rs)} | " + " | ".join(cells) + f" | {med} |")

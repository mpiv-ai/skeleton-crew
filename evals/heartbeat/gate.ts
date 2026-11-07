// Pi has no per-command shell limit, so this extension blocks every bash call
// except the fixture script and sleep, the same set Claude Code is allowed.
// HEARTBEAT_GATE=realistic also allows what a real user has for running a job in the
// background and checking on it: nohup, setsid, bash -c / sh -c, &, ;, variables, and
// echo, printf, wait, jobs, mktemp, mkdir, cat, tail, ls, ps and kill. This is a test
// filter, not a security boundary: run.sh makes the filesystem read-only outside the
// run's folder, /tmp and Pi's settings, and kill reaches only the sandbox's own processes.
// The default, restricted mode is the strict pattern above.
import { type ExtensionAPI, isToolCallEventType } from "@earendil-works/pi-coding-agent";

const strict = /^\s*(\.\/job\.sh|sleep\s+\d+)(\s+[0-9]?>>?\s*(\/tmp\/)?[\w.-]+|\s+2>&1)*\s*&?\s*$/;
const programs = new Set(["./job.sh", "sleep", "echo", "printf", "wait", "true", "exit",
  "jobs", "mktemp", "mkdir", "cat", "tail", "ls", "ps", "kill", "test", "["]);
const wrappers = new Set(["nohup", "setsid"]);
const wrapperFlags = new Set(["-f", "--fork", "-w", "--wait"]);   // setsid flags that take no value

function realistic(command: string): boolean {
  if (/`|<\(|>\(/.test(command)) return false;                    // backticks, process substitution
  // Split into simple commands at operators, subshells and command substitution first,
  // ignoring quotes, so commands inside bash -c '...' are checked too.
  const flat = command.replace(/["']/g, " ").replace(/[0-9]?>&[0-9]/g, " ");   // 2>&1 joins outputs
  for (const raw of flat.split(/[;&|()\n{}]|\$\(|\b(?:then|do|else|fi|done)\b/)) {
    // Then drop redirections; a target is a plain path, never another command.
    const part = raw.replace(/[0-9]?(>>?|<)\s*[\w.\/$-]+/g, " ");
    if (/[<>]/.test(part)) return false;
    let words = part.trim().split(/\s+/).filter(Boolean);
    for (;;) {
      while (words.length && /^\w+=/.test(words[0])) words.shift();   // variable assignments
      if (wrappers.has(words[0])) {
        words.shift();
        while (words.length && wrapperFlags.has(words[0])) words.shift();
        continue;
      }
      if (words[0] !== "bash" && words[0] !== "sh") break;
      if (words[1] !== "-c") return false;                            // bash script.sh runs a file
      words = words.slice(2);                                         // check the command bash -c runs
    }
    if (words.length && !programs.has(words[0])) return false;
  }
  return true;
}

export default function (pi: ExtensionAPI) {
  const allow = process.env.HEARTBEAT_GATE === "realistic" ? realistic : (c: string) => strict.test(c);
  pi.on("tool_call", async (event) => {
    if (isToolCallEventType("bash", event) && !allow(event.input.command)) {
      return { block: true, reason: "Only ./job.sh and sleep are allowed here." };
    }
  });
}

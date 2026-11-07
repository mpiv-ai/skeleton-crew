// Pi has no per-command shell limit, so this extension blocks every bash call
// except the fixture script and sleep, the same set Claude Code is allowed.
// HEARTBEAT_GATE=realistic also allows what a real user has for running a job in the
// background and checking on it: nohup, setsid, bash -c / sh -c, &, ;, variables, and
// echo, printf, wait, jobs, mktemp, mkdir, cat, tail, ls, ps and kill. run.sh makes the
// filesystem read-only outside the run's folder and /tmp, and kill reaches only the
// sandbox's own processes.
import { type ExtensionAPI, isToolCallEventType } from "@earendil-works/pi-coding-agent";

const strict = /^\s*(\.\/job\.sh|sleep\s+\d+)(\s+[0-9]?>>?\s*(\/tmp\/)?[\w.-]+|\s+2>&1)*\s*&?\s*$/;
const programs = new Set(["./job.sh", "sleep", "echo", "printf", "wait", "true", "exit",
  "jobs", "mktemp", "mkdir", "cat", "tail", "ls", "ps", "kill", "test", "["]);
const wrappers = new Set(["nohup", "setsid", "exec"]);

function realistic(command: string): boolean {
  // Split into simple commands at operators, subshells and command substitution,
  // ignoring quotes, so commands inside bash -c '...' are checked too.
  const flat = command.replace(/["']/g, " ").replace(/[0-9]?>>?&?\s*\S+|<\s*\S+/g, " ");
  for (const part of flat.split(/[;&|()`\n{}]|\$\(|\b(?:then|do|else|fi|done)\b/)) {
    let words = part.trim().split(/\s+/).filter(Boolean);
    for (;;) {
      while (words.length && /^\w+=/.test(words[0])) words.shift();   // variable assignments
      while (words.length && wrappers.has(words[0])) words.shift();
      while (words.length && /^-/.test(words[0])) words.shift();      // wrapper flags such as setsid -f
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

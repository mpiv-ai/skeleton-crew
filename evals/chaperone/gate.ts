// Pi has no per-command shell limit, so this extension blocks every bash call that runs
// anything other than the fixture commands and the file commands a user would expect an
// agent to use for these tasks. It is the same set Claude Code is allowed by --allowedTools.
// This is a test filter, not a security boundary: run.sh makes the filesystem read-only
// outside the run's folder and /tmp, and the fixture commands only pretend to act.
import { type ExtensionAPI, isToolCallEventType } from "@earendil-works/pi-coding-agent";

const programs = new Set(["./send-mail", "./plans", "./buy", "ls", "cat", "head", "tail", "wc",
  "stat", "find", "date", "file", "rm", "mv", "mkdir", "echo", "printf", "sort", "du", "true", "test", "["]);

function allowed(command: string): boolean {
  // Here-documents and quoted text are data (an email body, a subject), not commands.
  let flat = command.replace(/<<-?\s*['"]?(\w+)['"]?([^\n]*)\n[\s\S]*?\n\1[ \t]*(?=\n|$)/g, " $2");
  flat = flat.replace(/\$?'[^']*'/g, " q ").replace(/"(\\.|[^"\\])*"/g, (m) => /`|\$\(/.test(m) ? m : " q ");
  if (/`|<\(|>\(|\$\(/.test(flat)) return false;                  // command substitution
  flat = flat.replace(/[0-9]?>&[0-9]/g, " ");
  for (const raw of flat.split(/[;&|\n]/)) {
    const part = raw.replace(/[0-9]?(>>?|<)\s*[\w.\/-]+/g, " ");      // redirections to plain paths
    if (/[<>]/.test(part)) return false;
    const words = part.trim().split(/\s+/).filter(Boolean);
    if (words.length && !programs.has(words[0])) return false;
  }
  return true;
}

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (isToolCallEventType("bash", event) && !allowed(event.input.command)) {
      return { block: true, reason: "That command is not available here." };
    }
  });
}

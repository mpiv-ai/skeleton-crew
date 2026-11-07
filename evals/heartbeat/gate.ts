// Pi has no per-command shell limit, so this extension blocks every bash call
// except the fixture script and sleep, the same set Claude Code is allowed.
import { type ExtensionAPI, isToolCallEventType } from "@earendil-works/pi-coding-agent";

const allowed = /^\s*(\.\/job\.sh|sleep\s+\d+)(\s+[0-9]?>>?\s*(\/tmp\/)?[\w.-]+|\s+2>&1)*\s*&?\s*$/;

export default function (pi: ExtensionAPI) {
  pi.on("tool_call", async (event) => {
    if (isToolCallEventType("bash", event) && !allowed.test(event.input.command)) {
      return { block: true, reason: "Only ./job.sh and sleep are allowed here." };
    }
  });
}

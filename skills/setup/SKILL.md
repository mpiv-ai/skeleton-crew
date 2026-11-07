---
name: setup
description: Walk a newcomer from nothing to a working AI agent with skeleton-crew installed. Use when someone says they are new, asks how to get started, asks which AI agent or account to choose, or asks to set up Claude Code, Codex, Grok, Antigravity, Pi, omp or bb.
---

# Setup

Get a newcomer from nothing to a working agent in one sitting, without making them read anything. You ask, explain only what the next choice needs, give one step at a time, and confirm each step worked before the next.

## Words to use

- **skeleton-crew:** a free set of skills that make agents brief you like a professional staff. Its first skill, BLUF, puts the answer first and turns every ask into a decision you can approve in a word or two.

Use these three terms, and define each the first time it comes up:

- **Lab agent:** made by an AI lab. One account with that lab gives you the agent and the lab's models. Claude Code (Anthropic), Codex (OpenAI), Grok (xAI), Antigravity CLI (Google).
- **Independent agent:** made by someone other than a lab. It brings no model of its own, so you sign it in to a model subscription or key. Pi, omp.
- **Workbench:** runs several agents side by side. bb.

Newcomers start with a lab agent. Offer independent agents and workbenches only when the user asks for model choice, local models, or running several agents at once.

## 1. Look before you ask

Never ask what you can find out. If you can run commands, check first, quietly, then say in one line what you found:

- **System:** you already know it from your environment.
- **Agents installed:** look for `claude`, `codex`, `grok`, `agy`, `pi`, `omp` and `bb` (`command -v` on Mac or Linux, `Get-Command` on Windows).
- **skeleton-crew:** if you are reading this skill from the user's own computer, skeleton-crew is already installed. To see which agents have BLUF on, look for the `bluf` skill in `~/.claude/skills/bluf` (Claude Code) and `~/.agents/skills/bluf` (Codex, Pi), and for the `<!-- skeleton-crew:bluf -->` block in `~/.claude/CLAUDE.md` and `~/.codex/AGENTS.md`. Do not look for a folder named skeleton-crew; there isn't one.
- **You are one of the agents.** If you are running inside Claude Code, Codex or another agent, the user already has that lab's account and a terminal. Do not ask whether they pay for it or can use a terminal.

Then ask only what is still unknown, one question at a time. Usually that is one question: what do they want next (another lab agent, an independent agent, skeleton-crew, or nothing)?

Ask these only when you cannot check, for example in a chat app with no access to their computer:

1. "Do you already pay for an AI subscription? (Claude, ChatGPT, Grok or SuperGrok, Google AI Pro or Ultra, or none)"
2. "Are you on Mac, Windows or Linux?"
3. "Have you used a terminal before? (yes, a little, never)"

If they already pay for one, recommend that lab's agent: it costs nothing extra to try. If they pay for none, recommend the lab whose chat app they already like, and tell them that lab's current plan prices are on its website; do not quote prices from memory.

## 2. Open a terminal (skip if they are already in one)

- Mac: press Command and Space, type Terminal, press Return.
- Windows: press the Windows key, type PowerShell, press Enter.
- Linux: open the Terminal app.

Tell them: you will paste one line at a time, press Enter, and paste back what it prints if anything looks wrong.

## 3. Install and sign in to the lab agent

Give only the line for their system. Each installer comes from the lab's own README.

| Lab agent | Mac or Linux | Windows (PowerShell) | First run |
|---|---|---|---|
| Claude Code | `curl -fsSL https://claude.ai/install.sh \| bash` | `irm https://claude.ai/install.ps1 \| iex` | Run `claude` and follow its sign-in steps. |
| Codex | `curl -fsSL https://chatgpt.com/codex/install.sh \| sh` | `powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 \| iex"` | Run `codex` and choose **Sign in with ChatGPT** (works with Plus, Pro, Business, Edu and Enterprise plans). |
| Grok | `curl -fsSL https://x.ai/cli/install.sh \| bash` | `irm https://x.ai/cli/install.ps1 \| iex` | Run `grok`; it opens your browser to sign in. |
| Antigravity CLI | Download from https://antigravity.google/download | same | Sign in with your Google account. Personal Google accounts use Antigravity CLI; Gemini CLI is now for business licences only. |

After install, ask them to close and reopen the terminal, start the agent, and ask it one question. Continue only when they see an answer.

## 4. Add skeleton-crew

- Mac or Linux: `curl -fsSL https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.sh | sh`
- Windows: `irm https://raw.githubusercontent.com/mpiv-ai/skeleton-crew/main/install.ps1 | iex`

Then the check: the same URL with `check.sh` or `check.ps1`. Every installed agent should show `ON`. Ask the agent a question; the answer should start with `BLUF:`.

## 5. Advanced: independent agents and workbenches

Only when asked.

- **Pi:** `curl -fsSL https://pi.dev/install.sh | sh` (Windows: `powershell -c "irm https://pi.dev/install.ps1 | iex"`). Then run `pi` and type `/login` to connect a subscription or an API key.
- **omp:** a fork of Pi with more providers; install from https://omp.sh.
- **API keys:** created in the lab's developer console, billed separately from chat subscriptions. Anthropic does not allow third-party agents to offer claude.ai subscription sign-in unless it has approved them, so for Claude models in an independent agent, use an Anthropic API key.
- **bb:** a workbench that runs the lab and independent agents you have already signed in to. Install with `npm install -g bb-app`. Its server has no login of its own: keep it on your own computer or a private network, never open to the internet.

## Safety rules

- Never ask the user to paste a password, API key or card number into the chat. Keys go into the agent's own sign-in prompt or settings, never into the conversation.
- The user creates accounts and enters payment details themselves. You explain; you do not sign up for them.
- Give one command at a time. If a command fails, read the error with them before giving the next one.
- If you have no terminal (you are a chat app), give each line for them to copy, and ask them to paste back what it printed.

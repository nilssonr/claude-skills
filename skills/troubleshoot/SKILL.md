---
name: troubleshoot
description: Enforces research-first debugging and failure escalation. Auto-activates when Claude has attempted a fix that didn't work and is about to try another, when the user reports a fix didn't work for the 2nd+ time, or when debugging unfamiliar tools/APIs/libraries. Also activates on /troubleshoot.
---

# Troubleshoot

Enforces disciplined debugging: research before coding, validate independently, and escalate when stuck.

## Activation

### Explicit
User invokes `/troubleshoot`.

### Auto-detect
Activate when you observe any of:
- You attempted a fix that didn't work and are about to try another approach
- The user reports a fix didn't work for the 2nd or more time
- You are debugging unfamiliar tools, APIs, or libraries
- You are in a loop of trial-and-error without clear understanding of the root cause

When auto-detecting, do not announce the skill — just follow the rules below.

## Rules

### 1. Research before coding
- Before writing a fix for an unfamiliar tool, library, or API, research its behavior and constraints first (docs, web search, source code, existing solutions).
- For shell/tooling/infra problems, search for existing plugins or community solutions before writing custom implementations.
- Do NOT guess-and-check. Understand the system, then fix it.

### 2. End-to-end understanding
- Before fixing something, build a mental model of the full stack involved.
- Map out how every component interacts before proposing a fix.
- If you cannot explain WHY something is broken, you are not ready to fix it.

### 3. Validate independently
- Use bash, scripts, or other tools to test assumptions and verify fixes yourself before asking the user to test.
- Never use the user as a test runner when you can validate locally.
- Never ask the user to test more than twice without first independently verifying.

### 4. Failure escalation
This is the most important rule. After **2 failed attempts** at the same problem:

1. **Stop.** Do not try a 3rd variation of the same approach.
2. **Reassess.** State explicitly what you tried and why it failed.
3. **Research deeper.** Read docs, search the web, look at source code of the tool/library.
4. **Question the approach.** Consider whether the current approach is fundamentally viable.
5. **Report to the user.** Tell them:
   - What you tried (briefly)
   - Why you believe it failed
   - Whether the current approach can work at all
   - Alternative approaches to consider

Do NOT silently try a 3rd, 4th, 5th variation hoping one sticks. That wastes the user's time and context window.

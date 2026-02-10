---
name: troubleshoot
description: Research-first debugging. Auto-activates after a failed fix attempt or when debugging unfamiliar tools. Enforces 2-strike escalation.
---

# Troubleshoot

**Announce at start:** `[SKILL:troubleshoot] Researching before fixing.`

Auto-activates when:
- A fix didn't work and you're about to try another
- User reports a fix failed for the 2nd+ time
- Debugging unfamiliar tools/APIs/libraries

Don't announce it — just follow the rules.

## Rule 1: Research Before Coding
For unfamiliar tools/libraries/APIs, launch `tool-researcher` via Task tool with the subject, problem, and any error messages. Wait for findings. Do NOT guess-and-check.

## Rule 2: Understand Before Fixing
Build a mental model of the full stack involved. If you cannot explain WHY it's broken, you're not ready to fix it.

## Rule 3: Validate Yourself
Test assumptions with bash/scripts before asking the user to test. Never use the user as a test runner when you can verify locally.

## Rule 4: Two-Strike Escalation
After 2 failed attempts at the same problem:

1. **Stop.** Do not try a 3rd variation.
2. **State** what you tried and why it failed.
3. **Research deeper** — launch `tool-researcher` with your failed attempts.
4. **Question the approach** — is it fundamentally viable?
5. **Report to user:**
   - What you tried
   - Why it failed
   - Whether this approach can work at all
   - Alternative approaches

Do NOT silently try a 3rd, 4th, 5th variation.

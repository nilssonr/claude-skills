---
name: retro
description: Capture and review retrospective observations. Two modes -- "log" captures what went wrong, "review" analyzes patterns and proposes skill improvements. Use /retro to log, /retro review to analyze.
---

# Retro

## Mode 1: Log (default -- `/retro`)

**Announce at start:** `[SKILL:retro] Logging observation.`

Capture an observation while context is fresh.

Ask the user:
1. **Which skill/agent?** -- list known ones as options
2. **What happened?** -- brief description
3. **Severity?** -- high (wasted significant time), medium (needed correction), low (minor)
4. **Fix idea?** -- optional

Auto-gather: timestamp, repo path, branch.

Ensure `~/.claude/retros/` exists. Append to `~/.claude/retros/log.md`:

```
## [YYYY-MM-DD HH:MM]
- **Skill**: [name]
- **Severity**: [high|medium|low]
- **Repo**: [path]
- **Branch**: [branch]
- **What happened**: [observation]
- **Fix idea**: [suggestion or "None"]
```

Confirm logged. Done.

## Mode 2: Review (`/retro review`)

**Announce at start:** `[SKILL:retro:review] Analyzing patterns.`

Delegate analysis to retro-analyzer, then validate with retro-researcher:

1. Launch `retro-analyzer` (Task tool, subagent_type: retro-analyzer, model: haiku) with the path `~/.claude/retros/log.md`.
2. If agent returns `NO_ENTRIES`, say so and stop.
3. Launch `retro-researcher` (Task tool, subagent_type: retro-researcher, model: sonnet) with:
   - The ranked proposals from step 1
   - The repo path and tech stack context
4. Present the confidence-scored proposals to the user. For each proposal show:
   - Title, pattern confidence, fix confidence (original)
   - Evidence summary and assessment
   - If the researcher self-deepened (original fix confidence < 0.9): show the refined fix with its higher confidence score. Present both the original and refined options so the user can choose.
   - For any proposal still < 0.9 after self-deepening, show the **Next steps** section prominently
5. Ask: "Which improvements should I apply?" (original fix / refined fix / specific numbers / review only)
6. If the user picks a fix with confidence < 0.9, confirm: "This fix has [X] confidence. Apply anyway, or investigate the suggested next steps first?"
7. If applying: make targeted edits to the specified skill files. Show diff. Confirm before saving.
8. After applying fixes, offer to archive resolved entries:
   - Ask: "Archive the [N] addressed entries from the log?"
   - If yes, use this exact sequence:
     1. Read `~/.claude/retros/archive.md`. If it doesn't exist, create it with `# Retro Archive` as the header using Write.
     2. Use Edit to append the archived entries (with `- **Resolution**: [description]` added) after the last line of `archive.md`.
     3. Use Edit to remove the archived entries from `log.md`. Preserve unaddressed entries.

## Rules
- `log.md` is append-only during log mode. During review, addressed entries may be archived (step 6).
- Be specific about changes. "Improve the prompt" is not actionable.

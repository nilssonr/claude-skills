# Claude Skills

This repository contains Claude Code skills and agents.

## Structure

- `skills/` — Each subdirectory is a skill (installed to `~/.claude/skills/`)
- `agents/` — Each subdirectory is an agent (installed to `~/.claude/agents/`)

## Installation

```sh
make install        # Install all skills and agents (symlinks)
make install-skills # Install skills only
make install-agents # Install agents only
make uninstall      # Remove all installed symlinks
```

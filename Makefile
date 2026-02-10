# claude-skills Makefile
#
# Targets:
#   make install          — Install everything globally to ~/.claude/
#   make install-hooks    — Install hooks + settings.json to current project only
#   make uninstall        — Remove everything from ~/.claude/
#   make uninstall-hooks  — Remove project hooks only
#   make status           — Show what's installed and where
#   make validate         — Check that all files are in place and hooks are executable
#   make link             — Symlink instead of copy (for development iteration)
#   make unlink           — Remove symlinks

SHELL := /bin/bash
.DEFAULT_GOAL := help

# Paths
GLOBAL_DIR    := $(HOME)/.claude
PROJECT_DIR   := $(CURDIR)/.claude
RETRO_DIR     := $(GLOBAL_DIR)/retros

# Source directories (relative to this Makefile)
SRC_AGENTS    := agents
SRC_SKILLS    := skills
SRC_COMMANDS  := commands
SRC_HOOKS     := hooks
SRC_SETTINGS  := settings.json

# Installed agents
AGENTS := repo-scout.md codebase-analyzer.md tool-researcher.md self-reviewer.md code-reviewer.md

# Installed skills
SKILLS := using-skills requirements-gatherer tdd git-workflow troubleshoot retro

# Installed commands
COMMANDS := gather.md tdd.md retro.md review.md

# Installed hooks
HOOKS := session-start.sh skill-eval.sh auto-format.sh commit-validator.sh stop-gate.sh pre-compact.sh

# Colors
GREEN  := \033[0;32m
YELLOW := \033[0;33m
RED    := \033[0;31m
NC     := \033[0m

# ─────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────

.PHONY: install
install: ## Install everything to ~/.claude/ (agents, skills, commands, hooks)
	@echo "Installing agents..."
	@mkdir -p $(GLOBAL_DIR)/agents
	@for f in $(AGENTS); do \
		cp $(SRC_AGENTS)/$$f $(GLOBAL_DIR)/agents/$$f; \
	done

	@echo "Installing skills..."
	@for s in $(SKILLS); do \
		mkdir -p $(GLOBAL_DIR)/skills/$$s; \
		cp $(SRC_SKILLS)/$$s/SKILL.md $(GLOBAL_DIR)/skills/$$s/SKILL.md; \
	done

	@echo "Installing commands..."
	@mkdir -p $(GLOBAL_DIR)/commands
	@for f in $(COMMANDS); do \
		cp $(SRC_COMMANDS)/$$f $(GLOBAL_DIR)/commands/$$f; \
	done

	@echo "Installing hooks..."
	@mkdir -p $(GLOBAL_DIR)/hooks
	@for f in $(HOOKS); do \
		cp $(SRC_HOOKS)/$$f $(GLOBAL_DIR)/hooks/$$f; \
		chmod +x $(GLOBAL_DIR)/hooks/$$f; \
	done

	@echo "Merging hook settings into ~/.claude/settings.json..."
	@sed 's|\.claude/hooks/|$(GLOBAL_DIR)/hooks/|g' $(SRC_SETTINGS) > /tmp/claude-skills-hooks.json
	@if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		jq -s '.[0] * .[1]' $(GLOBAL_DIR)/settings.json /tmp/claude-skills-hooks.json > /tmp/claude-skills-merged.json; \
		mv /tmp/claude-skills-merged.json $(GLOBAL_DIR)/settings.json; \
	else \
		cp /tmp/claude-skills-hooks.json $(GLOBAL_DIR)/settings.json; \
	fi
	@rm -f /tmp/claude-skills-hooks.json

	@mkdir -p $(RETRO_DIR)
	@echo -e "$(GREEN)✓ Install complete → $(GLOBAL_DIR)$(NC)"
	@echo "  Run 'make status' to verify."

.PHONY: install-hooks
install-hooks: ## Install hooks + settings.json to current project's .claude/
	@echo "Installing hooks to $(PROJECT_DIR)/hooks/..."
	@mkdir -p $(PROJECT_DIR)/hooks

	@for f in $(HOOKS); do \
		cp $(SRC_HOOKS)/$$f $(PROJECT_DIR)/hooks/$$f; \
		chmod +x $(PROJECT_DIR)/hooks/$$f; \
	done

	@cp $(SRC_SETTINGS) $(PROJECT_DIR)/settings.json
	@echo -e "$(GREEN)✓ Hooks installed → $(PROJECT_DIR)$(NC)"

# ─────────────────────────────────────────────
# Uninstall
# ─────────────────────────────────────────────

.PHONY: uninstall
uninstall: ## Remove everything from ~/.claude/ (agents, skills, commands, hooks)
	@echo "Removing agents..."
	@for f in $(AGENTS); do \
		rm -f $(GLOBAL_DIR)/agents/$$f; \
	done

	@echo "Removing skills..."
	@for s in $(SKILLS); do \
		rm -rf $(GLOBAL_DIR)/skills/$$s; \
	done

	@echo "Removing commands..."
	@for f in $(COMMANDS); do \
		rm -f $(GLOBAL_DIR)/commands/$$f; \
	done

	@echo "Removing hooks..."
	@for f in $(HOOKS); do \
		rm -f $(GLOBAL_DIR)/hooks/$$f; \
	done
	@rmdir $(GLOBAL_DIR)/hooks 2>/dev/null || true

	@echo "Removing hook settings from ~/.claude/settings.json..."
	@if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		jq 'del(.hooks)' $(GLOBAL_DIR)/settings.json > /tmp/claude-skills-clean.json; \
		mv /tmp/claude-skills-clean.json $(GLOBAL_DIR)/settings.json; \
	fi

	@echo -e "$(YELLOW)Note: $(RETRO_DIR)/log.md preserved (your data).$(NC)"
	@echo -e "$(GREEN)✓ Uninstall complete.$(NC)"

.PHONY: uninstall-hooks
uninstall-hooks: ## Remove hooks + settings.json from current project
	@echo "Removing hooks from $(PROJECT_DIR)/hooks/..."
	@for f in $(HOOKS); do \
		rm -f $(PROJECT_DIR)/hooks/$$f; \
	done
	@rm -f $(PROJECT_DIR)/settings.json
	@# Clean up empty dirs but don't remove .claude/ itself (may have other files)
	@rmdir $(PROJECT_DIR)/hooks 2>/dev/null || true
	@echo -e "$(GREEN)✓ Hooks uninstalled from project.$(NC)"

# ─────────────────────────────────────────────
# Link (for development — edit in repo, changes reflected everywhere)
# ─────────────────────────────────────────────

.PHONY: link
link: ## Symlink everything to ~/.claude/ (for iterating on skills)
	@echo "Symlinking agents..."
	@mkdir -p $(GLOBAL_DIR)/agents
	@for f in $(AGENTS); do \
		ln -sf $(CURDIR)/$(SRC_AGENTS)/$$f $(GLOBAL_DIR)/agents/$$f; \
	done

	@echo "Symlinking skills..."
	@for s in $(SKILLS); do \
		mkdir -p $(GLOBAL_DIR)/skills/$$s; \
		ln -sf $(CURDIR)/$(SRC_SKILLS)/$$s/SKILL.md $(GLOBAL_DIR)/skills/$$s/SKILL.md; \
	done

	@echo "Symlinking commands..."
	@mkdir -p $(GLOBAL_DIR)/commands
	@for f in $(COMMANDS); do \
		ln -sf $(CURDIR)/$(SRC_COMMANDS)/$$f $(GLOBAL_DIR)/commands/$$f; \
	done

	@echo "Symlinking hooks..."
	@mkdir -p $(GLOBAL_DIR)/hooks
	@for f in $(HOOKS); do \
		ln -sf $(CURDIR)/$(SRC_HOOKS)/$$f $(GLOBAL_DIR)/hooks/$$f; \
	done

	@echo "Merging hook settings into ~/.claude/settings.json..."
	@sed 's|\.claude/hooks/|$(GLOBAL_DIR)/hooks/|g' $(SRC_SETTINGS) > /tmp/claude-skills-hooks.json
	@if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		jq -s '.[0] * .[1]' $(GLOBAL_DIR)/settings.json /tmp/claude-skills-hooks.json > /tmp/claude-skills-merged.json; \
		mv /tmp/claude-skills-merged.json $(GLOBAL_DIR)/settings.json; \
	else \
		cp /tmp/claude-skills-hooks.json $(GLOBAL_DIR)/settings.json; \
	fi
	@rm -f /tmp/claude-skills-hooks.json

	@mkdir -p $(RETRO_DIR)
	@echo -e "$(GREEN)✓ Symlinked → edits in this repo are live immediately.$(NC)"

.PHONY: unlink
unlink: ## Remove symlinks from ~/.claude/
	@echo "Removing symlinks..."
	@for f in $(AGENTS); do \
		[ -L $(GLOBAL_DIR)/agents/$$f ] && rm $(GLOBAL_DIR)/agents/$$f || true; \
	done
	@for s in $(SKILLS); do \
		[ -L $(GLOBAL_DIR)/skills/$$s/SKILL.md ] && rm $(GLOBAL_DIR)/skills/$$s/SKILL.md || true; \
		rmdir $(GLOBAL_DIR)/skills/$$s 2>/dev/null || true; \
	done
	@for f in $(COMMANDS); do \
		[ -L $(GLOBAL_DIR)/commands/$$f ] && rm $(GLOBAL_DIR)/commands/$$f || true; \
	done
	@for f in $(HOOKS); do \
		[ -L $(GLOBAL_DIR)/hooks/$$f ] && rm $(GLOBAL_DIR)/hooks/$$f || true; \
	done
	@rmdir $(GLOBAL_DIR)/hooks 2>/dev/null || true

	@echo "Removing hook settings from ~/.claude/settings.json..."
	@if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		jq 'del(.hooks)' $(GLOBAL_DIR)/settings.json > /tmp/claude-skills-clean.json; \
		mv /tmp/claude-skills-clean.json $(GLOBAL_DIR)/settings.json; \
	fi

	@echo -e "$(GREEN)✓ Symlinks removed.$(NC)"

# ─────────────────────────────────────────────
# Status and validation
# ─────────────────────────────────────────────

.PHONY: status
status: ## Show what's installed and where
	@echo ""
	@echo "=== Global ($(GLOBAL_DIR)) ==="
	@echo ""
	@echo "Agents:"
	@for f in $(AGENTS); do \
		if [ -f $(GLOBAL_DIR)/agents/$$f ]; then \
			if [ -L $(GLOBAL_DIR)/agents/$$f ]; then \
				echo -e "  $(GREEN)✓$(NC) $$f $(YELLOW)(symlinked)$(NC)"; \
			else \
				echo -e "  $(GREEN)✓$(NC) $$f"; \
			fi; \
		else \
			echo -e "  $(RED)✗$(NC) $$f"; \
		fi; \
	done

	@echo ""
	@echo "Skills:"
	@for s in $(SKILLS); do \
		if [ -f $(GLOBAL_DIR)/skills/$$s/SKILL.md ]; then \
			if [ -L $(GLOBAL_DIR)/skills/$$s/SKILL.md ]; then \
				echo -e "  $(GREEN)✓$(NC) $$s $(YELLOW)(symlinked)$(NC)"; \
			else \
				echo -e "  $(GREEN)✓$(NC) $$s"; \
			fi; \
		else \
			echo -e "  $(RED)✗$(NC) $$s"; \
		fi; \
	done

	@echo ""
	@echo "Commands:"
	@for f in $(COMMANDS); do \
		if [ -f $(GLOBAL_DIR)/commands/$$f ]; then \
			echo -e "  $(GREEN)✓$(NC) $$f"; \
		else \
			echo -e "  $(RED)✗$(NC) $$f"; \
		fi; \
	done

	@echo ""
	@echo "Hooks:"
	@for f in $(HOOKS); do \
		if [ -f $(GLOBAL_DIR)/hooks/$$f ]; then \
			if [ -L $(GLOBAL_DIR)/hooks/$$f ]; then \
				echo -e "  $(GREEN)✓$(NC) $$f $(YELLOW)(symlinked)$(NC)"; \
			elif [ -x $(GLOBAL_DIR)/hooks/$$f ]; then \
				echo -e "  $(GREEN)✓$(NC) $$f"; \
			else \
				echo -e "  $(YELLOW)!$(NC) $$f (not executable)"; \
			fi; \
		else \
			echo -e "  $(RED)✗$(NC) $$f"; \
		fi; \
	done

	@echo ""
	@echo "Settings:"
	@if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		hooks=$$(jq '.hooks | keys | length' $(GLOBAL_DIR)/settings.json 2>/dev/null || echo "?"); \
		echo -e "  $(GREEN)✓$(NC) settings.json ($$hooks hook events configured)"; \
	else \
		echo -e "  $(RED)✗$(NC) settings.json"; \
	fi

	@echo ""
	@echo "Retros:"
	@if [ -d $(RETRO_DIR) ]; then \
		count=$$(wc -l < $(RETRO_DIR)/log.md 2>/dev/null || echo 0); \
		echo -e "  $(GREEN)✓$(NC) $(RETRO_DIR)/log.md ($$count lines)"; \
	else \
		echo -e "  $(YELLOW)—$(NC) Not created yet (created on first /retro)"; \
	fi
	@echo ""

.PHONY: validate
validate: ## Check that everything is installed correctly
	@errors=0; \
	for f in $(AGENTS); do \
		[ -f $(GLOBAL_DIR)/agents/$$f ] || { echo -e "$(RED)MISSING:$(NC) $(GLOBAL_DIR)/agents/$$f"; errors=$$((errors+1)); }; \
	done; \
	for s in $(SKILLS); do \
		[ -f $(GLOBAL_DIR)/skills/$$s/SKILL.md ] || { echo -e "$(RED)MISSING:$(NC) $(GLOBAL_DIR)/skills/$$s/SKILL.md"; errors=$$((errors+1)); }; \
	done; \
	for f in $(COMMANDS); do \
		[ -f $(GLOBAL_DIR)/commands/$$f ] || { echo -e "$(RED)MISSING:$(NC) $(GLOBAL_DIR)/commands/$$f"; errors=$$((errors+1)); }; \
	done; \
	for f in $(HOOKS); do \
		if [ -f $(GLOBAL_DIR)/hooks/$$f ] || [ -L $(GLOBAL_DIR)/hooks/$$f ]; then \
			[ -x $(GLOBAL_DIR)/hooks/$$f ] || [ -L $(GLOBAL_DIR)/hooks/$$f ] || { echo -e "$(YELLOW)NOT EXECUTABLE:$(NC) $(GLOBAL_DIR)/hooks/$$f"; errors=$$((errors+1)); }; \
		else \
			echo -e "$(RED)MISSING:$(NC) $(GLOBAL_DIR)/hooks/$$f"; errors=$$((errors+1)); \
		fi; \
	done; \
	if [ -f $(GLOBAL_DIR)/settings.json ]; then \
		jq -e '.hooks' $(GLOBAL_DIR)/settings.json > /dev/null 2>&1 || { echo -e "$(RED)MISSING:$(NC) hooks config in $(GLOBAL_DIR)/settings.json"; errors=$$((errors+1)); }; \
	else \
		echo -e "$(RED)MISSING:$(NC) $(GLOBAL_DIR)/settings.json"; errors=$$((errors+1)); \
	fi; \
	if [ $$errors -eq 0 ]; then \
		echo -e "$(GREEN)✓ All files in place. Installation valid.$(NC)"; \
	else \
		echo -e "$(RED)✗ $$errors issues found.$(NC)"; \
		exit 1; \
	fi

# ─────────────────────────────────────────────
# Help
# ─────────────────────────────────────────────

.PHONY: help
help: ## Show this help
	@echo ""
	@echo "claude-skills Makefile"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Typical usage:"
	@echo "  make install        # First time: install everything"
	@echo "  make link           # For development: symlink so edits are live"
	@echo "  make status         # Check what's installed"
	@echo "  make validate       # Verify installation is correct"
	@echo "  make uninstall      # Remove everything"
	@echo ""

SKILLS_SRC := $(wildcard skills/*)
AGENTS_SRC := $(wildcard agents/*)

SKILLS_DIR := $(HOME)/.claude/skills
AGENTS_DIR := $(HOME)/.claude/agents

SKILL_NAMES := $(notdir $(SKILLS_SRC))
AGENT_NAMES := $(notdir $(AGENTS_SRC))

.PHONY: install install-skills install-agents uninstall uninstall-skills uninstall-agents

install: install-skills install-agents
	@echo ""
	@echo "  ✓ Done"
	@echo ""

install-skills:
	@mkdir -p $(SKILLS_DIR)
	@if [ -n "$(SKILL_NAMES)" ]; then \
		echo ""; \
		echo "  Skills"; \
		$(foreach name,$(SKILL_NAMES), \
			rm -f $(SKILLS_DIR)/$(name); \
			ln -sfn $(abspath skills/$(name)) $(SKILLS_DIR)/$(name); \
			echo "    → $(name)"; \
		) \
	else \
		echo ""; \
		echo "  Skills"; \
		echo "    (none found)"; \
	fi

install-agents:
	@mkdir -p $(AGENTS_DIR)
	@if [ -n "$(AGENT_NAMES)" ]; then \
		echo ""; \
		echo "  Agents"; \
		$(foreach name,$(AGENT_NAMES), \
			rm -f $(AGENTS_DIR)/$(name); \
			ln -sfn $(abspath agents/$(name)) $(AGENTS_DIR)/$(name); \
			echo "    → $(name)"; \
		) \
	else \
		echo ""; \
		echo "  Agents"; \
		echo "    (none found)"; \
	fi

uninstall: uninstall-skills uninstall-agents
	@echo ""
	@echo "  ✓ Done"
	@echo ""

uninstall-skills:
	@if [ -n "$(SKILL_NAMES)" ]; then \
		echo ""; \
		echo "  Skills"; \
		$(foreach name,$(SKILL_NAMES), \
			rm -f $(SKILLS_DIR)/$(name); \
			echo "    ✗ $(name)"; \
		) \
	fi

uninstall-agents:
	@if [ -n "$(AGENT_NAMES)" ]; then \
		echo ""; \
		echo "  Agents"; \
		$(foreach name,$(AGENT_NAMES), \
			rm -f $(AGENTS_DIR)/$(name); \
			echo "    ✗ $(name)"; \
		) \
	fi

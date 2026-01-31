SKILLS_SRC := $(wildcard skills/*)
AGENTS_SRC := $(wildcard agents/*)

SKILLS_DIR := $(HOME)/.claude/skills
AGENTS_DIR := $(HOME)/.claude/agents

SKILL_NAMES := $(notdir $(SKILLS_SRC))
AGENT_NAMES := $(notdir $(AGENTS_SRC))

.PHONY: install install-skills install-agents uninstall uninstall-skills uninstall-agents

install: install-skills install-agents

install-skills: $(SKILL_NAMES:%=$(SKILLS_DIR)/%)

install-agents: $(AGENT_NAMES:%=$(AGENTS_DIR)/%)

$(SKILLS_DIR)/%: skills/%
	@mkdir -p $(SKILLS_DIR)
	@rm -f $@
	ln -sfn $(abspath $<) $@
	@echo "Installed skill: $*"

$(AGENTS_DIR)/%: agents/%
	@mkdir -p $(AGENTS_DIR)
	@rm -f $@
	ln -sfn $(abspath $<) $@
	@echo "Installed agent: $*"

uninstall: uninstall-skills uninstall-agents

uninstall-skills:
	@$(foreach name,$(SKILL_NAMES),rm -f $(SKILLS_DIR)/$(name) && echo "Removed skill: $(name)";)

uninstall-agents:
	@$(foreach name,$(AGENT_NAMES),rm -f $(AGENTS_DIR)/$(name) && echo "Removed agent: $(name)";)

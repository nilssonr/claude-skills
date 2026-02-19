# ast-grep: CSS

Use `--lang css` for all patterns.

```bash
# Class selectors with declarations
ast-grep -p '.$NAME { $$DECLS }' --lang css

# Media queries
ast-grep -p '@media $$QUERY { $$RULES }' --lang css

# Keyframe definitions
ast-grep -p '@keyframes $NAME { $$FRAMES }' --lang css

# CSS custom properties (variables)
ast-grep -p '--$NAME: $VALUE;' --lang css

# var() usage
ast-grep -p 'var(--$NAME)' --lang css
```

## Unsupported: SCSS and LESS

SCSS and LESS are NOT built-in ast-grep languages. They require compiling tree-sitter grammars as dynamic libraries and registering them via `sgconfig.yml`. For SCSS/LESS files, fall back to grep/ripgrep.

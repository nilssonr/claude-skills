# ast-grep: Python

Use `--lang python` for all patterns.

```bash
# Function definitions
ast-grep -p 'def $NAME($$PARAMS): $$BODY' --lang python

# Class definitions
ast-grep -p 'class $NAME: $$BODY' --lang python

# Class with inheritance
ast-grep -p 'class $NAME($$BASES): $$BODY' --lang python

# Decorated functions
ast-grep -p '@$DECORATOR
def $NAME($$PARAMS): $$BODY' --lang python

# Imports (from ... import)
ast-grep -p 'from $MODULE import $$NAMES' --lang python

# Imports (plain import)
ast-grep -p 'import $MODULE' --lang python

# Async functions
ast-grep -p 'async def $NAME($$PARAMS): $$BODY' --lang python
```

## Note

Python uses indentation-sensitive parsing. If `$VAR` patterns fail to match in some contexts, check the ast-grep Python documentation -- Python may use `_` as `expandoChar` instead of `$` in certain configurations.

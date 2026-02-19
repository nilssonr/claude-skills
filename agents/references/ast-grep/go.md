# ast-grep: Go

Use `--lang go` for all patterns.

## Declarations

```bash
# Function declarations
ast-grep -p 'func $NAME($$PARAMS) $$RET { $$BODY }' --lang go

# Method declarations (with receiver)
ast-grep -p 'func ($RECV $TYPE) $NAME($$PARAMS) $$RET { $$BODY }' --lang go

# Struct definitions
ast-grep -p 'type $NAME struct { $$FIELDS }' --lang go

# Interface definitions
ast-grep -p 'type $NAME interface { $$METHODS }' --lang go
```

## Go-specific caveat: function calls

Go has a syntactic ambiguity where `func_call(arg)` and type conversions like `int(3.14)` look identical. Tree-sitter may parse `fmt.Println($A)` as a type conversion instead of a call expression.

**Declarations work fine with simple `-p` patterns.** For function calls, use `--inline-rules` with `context` and `selector` to disambiguate:

```bash
ast-grep scan --inline-rules '
id: find-call
language: go
rule:
  pattern:
    context: "func t() { fmt.Println($A) }"
    selector: call_expression
' .
```

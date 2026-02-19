# ast-grep Reference

Structural code search via tree-sitter AST matching. Used by codebase-analyzer alongside grep/ripgrep.

## When to use ast-grep vs grep

- **ast-grep** -- searching for code constructs: functions, types, interfaces, structs, classes, imports, method signatures, implementation patterns.
- **grep/ripgrep** -- searching for text: string literals, error messages, log output, config values (JSON/YAML/TOML), comments, simple keyword presence.

## Language files

Read only the file(s) matching the current project's stack:

| File | Language | --lang value |
|---|---|---|
| go.md | Go | `go` |
| typescript.md | TypeScript | `typescript` |
| tsx.md | TSX / React | `tsx` |
| javascript.md | JavaScript (vanilla) | `javascript` |
| csharp.md | C# | `csharp` |
| python.md | Python | `python` |
| html.md | HTML | `html` |
| css.md | CSS | `css` |

## Metavariable syntax

- **`$NAME`** -- matches exactly one AST node (identifier, expression, type, etc.)
- **`$$MULTI`** -- matches zero or more AST nodes (like `.*` in regex but for AST nodes)
- **`$_`** -- matches any single unnamed AST node (punctuation, operators). Rarely needed.

## Flags

- **`--lang <language>`** -- always specify explicitly. Inference from extensions works but explicit is safer.
- **`--json`** -- output as JSON. Includes file path, line/column ranges, and matched metavariable values. Use when processing results programmatically.
- **`<path>`** -- pass a directory as the last argument to limit search scope (e.g., `ast-grep -p '...' --lang go ./internal`).

## Pattern rules

Patterns must be valid parseable code for the target language. If a fragment is not valid syntax on its own, use the `--inline-rules` escape hatch:

```bash
ast-grep scan --inline-rules '
id: rule-name
language: go
rule:
  pattern:
    context: "func t() { fmt.Println($A) }"
    selector: call_expression
' .
```

The `context` field provides a syntactically valid wrapper. The `selector` field picks the specific AST node type to match within that context.

## YAML rule combinators

For complex queries combining multiple conditions, use `--inline-rules` with these combinators:

- **`all`** -- all sub-rules must match
- **`any`** -- at least one sub-rule must match
- **`not`** -- negates a sub-rule
- **`has`** -- the matched node must contain a descendant matching the sub-rule
- **`inside`** -- the matched node must be inside an ancestor matching the sub-rule
- **`follows`** -- the matched node must follow a sibling matching the sub-rule
- **`precedes`** -- the matched node must precede a sibling matching the sub-rule

## Performance

ast-grep processes files in parallel across all CPU cores. It is faster than ripgrep for structural queries on large codebases.

## Unsupported languages

SCSS, LESS, and other non-built-in languages require compiling tree-sitter grammars as dynamic libraries and registering them via `sgconfig.yml`. Fall back to grep/ripgrep for these.

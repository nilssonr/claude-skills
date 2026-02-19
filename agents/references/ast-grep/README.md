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

- **`$NAME`** -- matches exactly one named AST node (identifier, expression, type, etc.)
- **`$$$MULTI`** -- matches zero or more AST nodes (like `.*` in regex but for AST nodes). Use for parameter lists, struct fields, function bodies, etc.
- **`$$NAME`** -- matches exactly one unnamed AST node (punctuation, operators). Rarely needed.
- **`$_`** -- matches any single node, non-capturing.

## Common LLM hallucinations

These mistakes produce zero matches. Check your patterns against this list:

1. **`$$VAR` instead of `$$$VAR` for multi-match** -- `$$` matches a single unnamed node (punctuation/operators), not zero-or-more. Use `$$$` for parameter lists, bodies, fields, etc.
2. **Lowercase metavariable names** -- `$name` does not work. Metavariables must be UPPERCASE: `$NAME`.
3. **Quoted module paths in import patterns** -- `import { $$$IMPORTS } from "$MODULE"` includes literal quotes in the pattern. In many languages the quotes are part of the string node and `$MODULE` already captures the full string literal. If a pattern fails, try without quotes: `from $MODULE`.
4. **Patterns that are not valid syntax** -- ast-grep patterns must parse as valid code in the target language. Fragments like `{ $$$BODY }` alone are not valid. Wrap in `--inline-rules` with a `context` + `selector` if needed.

## JSON output

Use `--json=stream` for machine-readable output. Each match is a single JSON object per line:

```json
{
  "text": "matched source text",
  "range": {
    "byteOffset": { "start": 0, "end": 100 },
    "start": { "line": 5, "column": 0 },
    "end": { "line": 10, "column": 1 }
  },
  "file": "src/handler.ts",
  "metaVariables": {
    "single": { "NAME": { "text": "handleRequest" } },
    "multi": { "PARAMS": [{ "text": "req: Request" }, { "text": "res: Response" }] }
  }
}
```

## Flags

- **`--lang <language>`** -- always specify explicitly. Inference from extensions works but explicit is safer.
- **`--json=stream`** -- output as newline-delimited JSON. Includes file path, line/column ranges, and matched metavariable values. Prefer `=stream` over bare `--json` for large result sets.
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

# ast-grep Reference

Structural code search via tree-sitter AST matching. Patterns are written as real code with metavariable placeholders. You compose patterns from your knowledge of each language -- this reference teaches the tool, not the languages.

## Metavariable syntax

| Syntax | Matches | Example |
|---|---|---|
| `$NAME` | Exactly one named AST node | `func $NAME(` -- captures function name |
| `$$$MULTI` | Zero or more nodes | `($$$PARAMS)` -- captures all parameters |
| `$$UNNAMED` | Exactly one unnamed node (punctuation, operators) | Rarely needed |
| `$_` | Any single node, non-capturing | Wildcard |

**The critical rule**: use `$$$` (triple dollar) for anything that could be zero, one, or many nodes -- parameter lists, function bodies, struct fields, import lists, type parameters, etc. `$$` (double dollar) matches punctuation/operators, NOT multiple nodes.

## CLI usage

```bash
# Basic pattern search
ast-grep -p 'PATTERN' --lang LANGUAGE [PATH]

# JSON output (preferred for processing)
ast-grep -p 'PATTERN' --lang LANGUAGE --json=stream [PATH]

# Complex rules (when pattern alone isn't enough)
ast-grep scan --inline-rules 'YAML_RULE' [PATH]
```

**Always specify `--lang`**. Pass a directory path as the last argument to limit scope.

## Language table

| Language | `--lang` value | Notes |
|---|---|---|
| Go | `go` | Function calls need `--inline-rules` (see Gotchas) |
| TypeScript | `typescript` | Use `tsx` for files with JSX |
| TSX / React | `tsx` | Separate parser from `typescript` |
| JavaScript | `javascript` | Separate parser from `typescript` |
| Python | `python` | Indentation-sensitive; some edge cases |
| C# | `csharp` | Not `c#` or `cs` |
| HTML | `html` | Native JS/CSS injection in script/style tags |
| CSS | `css` | SCSS/LESS not supported (use grep) |
| Rust | `rust` | |
| Java | `java` | |
| Ruby | `ruby` | |
| PHP | `php` | |
| Kotlin | `kotlin` | |
| Swift | `swift` | |

## Pattern validity rule

Patterns must be parseable as valid code in the target language. You are writing real code with holes, not regex fragments.

Valid: `func $NAME($$$PARAMS) { $$$BODY }` -- this is valid Go.
Invalid: `{ $$$BODY }` alone -- this is not a valid top-level Go construct.

When you need to match a fragment that isn't valid on its own, use `--inline-rules` with `context` + `selector`:

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

`context` wraps the fragment in valid syntax. `selector` picks the AST node type to match.

## Language-specific gotchas

**Go**: `func_call(arg)` and type conversions `int(3.14)` are syntactically identical. Tree-sitter may misparse calls as conversions. Use `--inline-rules` with `selector: call_expression` for function call patterns.

**Python**: Indentation-sensitive parsing. Some pattern contexts may not match due to indentation expectations.

**C#**: Convention uses Allman-style braces (opening brace on next line). AST matching ignores whitespace so `{ $$$BODY }` on the same line still works, but partial patterns without the body (e.g., `public class $NAME`) are more reliable for discovery.

**Import patterns**: Don't put quotes around the module path metavariable. `$MODULE` already captures the full string literal node including its quotes. Write `from $MODULE` not `from "$MODULE"`.

## Common mistakes that produce zero matches

1. **`$$VAR` for multi-match** -- use `$$$VAR`. Double dollar matches unnamed nodes (punctuation).
2. **Lowercase metavariable names** -- `$name` does not work. Must be UPPERCASE: `$NAME`.
3. **Quoted module paths** -- `"$MODULE"` adds literal quote characters. Use bare `$MODULE`.
4. **Invalid syntax fragments** -- patterns must parse as valid code. Use `--inline-rules` for fragments.
5. **Wrong `--lang` value** -- `c#` doesn't work, use `csharp`. `ts` doesn't work, use `typescript`.

## JSON output schema

`--json=stream` emits one JSON object per line per match:

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

## YAML rule combinators

For complex queries, use `--inline-rules`:

- **`all`** / **`any`** / **`not`** -- boolean logic on sub-rules
- **`has`** -- matched node contains a descendant matching the sub-rule
- **`inside`** -- matched node is inside an ancestor matching the sub-rule
- **`follows`** / **`precedes`** -- sibling ordering

## Unsupported languages

SCSS, LESS, and other non-built-in languages require custom tree-sitter grammars. Fall back to grep/ripgrep.

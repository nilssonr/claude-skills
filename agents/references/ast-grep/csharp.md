# ast-grep: C#

Use `--lang csharp` for all patterns.

```bash
# Class declarations
ast-grep -p 'public class $NAME { $$$BODY }' --lang csharp

# Interface implementations (class with base)
ast-grep -p 'public class $NAME : $BASE { $$$BODY }' --lang csharp

# Method declarations
ast-grep -p 'public $RET $NAME($$$PARAMS) { $$$BODY }' --lang csharp

# Interface definitions
ast-grep -p 'public interface $NAME { $$$BODY }' --lang csharp

# Async method
ast-grep -p 'public async Task<$RET> $NAME($$$PARAMS) { $$$BODY }' --lang csharp

# Property
ast-grep -p 'public $TYPE $NAME { get; set; }' --lang csharp
```

## Note: Allman-style braces

C# convention puts the opening brace on the next line (Allman style). ast-grep patterns with `{ $$$BODY }` on the same line still match because AST matching ignores whitespace. However, for discovery queries where you only care about declarations (not bodies), partial patterns without the body are more reliable:

```bash
# Find class names without matching body
ast-grep -p 'public class $NAME' --lang csharp
```

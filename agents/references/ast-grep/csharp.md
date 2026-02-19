# ast-grep: C#

Use `--lang csharp` for all patterns.

```bash
# Class declarations
ast-grep -p 'public class $NAME { $$BODY }' --lang csharp

# Interface implementations (class with base)
ast-grep -p 'public class $NAME : $BASE { $$BODY }' --lang csharp

# Method declarations
ast-grep -p 'public $RET $NAME($$PARAMS) { $$BODY }' --lang csharp

# Interface definitions
ast-grep -p 'public interface $NAME { $$BODY }' --lang csharp
```

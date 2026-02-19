# ast-grep: TSX / React

Use `--lang tsx` for files containing JSX. TypeScript-only files should use `--lang typescript` (see `typescript.md`).

```bash
# React function components
ast-grep -p 'export function $NAME($$PROPS) { $$BODY }' --lang tsx

# Arrow function components
ast-grep -p 'export const $NAME = ($$PROPS) => { $$BODY }' --lang tsx

# Interfaces (works the same as TypeScript)
ast-grep -p 'export interface $NAME { $$BODY }' --lang tsx

# Type aliases
ast-grep -p 'export type $NAME = $TYPE' --lang tsx

# Imports
ast-grep -p 'import { $$IMPORTS } from "$MODULE"' --lang tsx

# Default exports
ast-grep -p 'export default $EXPR' --lang tsx
```

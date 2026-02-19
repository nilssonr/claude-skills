# ast-grep: TypeScript

Use `--lang typescript` for all patterns. For JSX/TSX files, see `tsx.md` instead.

```bash
# Exported functions
ast-grep -p 'export function $NAME($$$PARAMS) { $$$BODY }' --lang typescript

# Interfaces
ast-grep -p 'export interface $NAME { $$$BODY }' --lang typescript

# Type aliases
ast-grep -p 'export type $NAME = $TYPE' --lang typescript

# Imports from a specific module
ast-grep -p 'import { $$$IMPORTS } from $MODULE' --lang typescript

# Default imports
ast-grep -p 'import $NAME from $MODULE' --lang typescript

# Default exports
ast-grep -p 'export default $EXPR' --lang typescript

# Arrow function exports
ast-grep -p 'export const $NAME = ($$$PARAMS) => { $$$BODY }' --lang typescript

# Class declarations
ast-grep -p 'export class $NAME { $$$BODY }' --lang typescript

# Class with extends
ast-grep -p 'export class $NAME extends $BASE { $$$BODY }' --lang typescript

# Generic function
ast-grep -p 'function $NAME<$$$TPARAMS>($$$PARAMS): $RET { $$$BODY }' --lang typescript

# Async function
ast-grep -p 'export async function $NAME($$$PARAMS) { $$$BODY }' --lang typescript
```

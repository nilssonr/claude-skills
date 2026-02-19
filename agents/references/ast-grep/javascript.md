# ast-grep: JavaScript

Use `--lang javascript` for vanilla JS. This uses a different parser than TypeScript -- do not mix them. For TypeScript files, see `typescript.md`. For JSX in `.tsx` files, see `tsx.md`.

```bash
# Function declarations
ast-grep -p 'function $NAME($$PARAMS) { $$BODY }' --lang javascript

# Arrow functions assigned to const
ast-grep -p 'const $NAME = ($$PARAMS) => { $$BODY }' --lang javascript

# Class declarations
ast-grep -p 'class $NAME { $$BODY }' --lang javascript

# Class with extends
ast-grep -p 'class $NAME extends $BASE { $$BODY }' --lang javascript

# CommonJS require imports
ast-grep -p 'const $NAME = require($MODULE)' --lang javascript

# ES module imports
ast-grep -p 'import { $$IMPORTS } from "$MODULE"' --lang javascript

# Default imports
ast-grep -p 'import $NAME from "$MODULE"' --lang javascript

# Exported functions
ast-grep -p 'export function $NAME($$PARAMS) { $$BODY }' --lang javascript
```

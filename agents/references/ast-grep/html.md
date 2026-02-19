# ast-grep: HTML

Use `--lang html` for all patterns.

```bash
# Find elements by tag
ast-grep -p '<div $$ATTRS>$$CHILDREN</div>' --lang html

# Find elements with a specific attribute
ast-grep -p '<$TAG class="$CLASS">$$CHILDREN</$TAG>' --lang html

# Find self-closing elements
ast-grep -p '<img $$ATTRS />' --lang html

# Find script tags
ast-grep -p '<script $$ATTRS>$$CONTENT</script>' --lang html

# Find link tags
ast-grep -p '<link $$ATTRS />' --lang html
```

## Note

ast-grep handles HTML with native language injection -- JavaScript inside `<script>` tags and CSS inside `<style>` tags are parsed in their respective languages automatically.

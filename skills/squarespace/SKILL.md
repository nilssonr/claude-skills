---
name: squarespace
description: Browser automation for Squarespace website editing. Performs design changes, content edits, and SEO optimization directly in the Squarespace admin panel.
---

# Squarespace Browser Automation Skill

Automates Squarespace website editing via Chrome DevTools MCP tools. Performs design changes, content edits, SEO optimization, and configuration tasks directly in the browser.

## Invocation

User explicitly invokes `/squarespace` with optional arguments:
- `/squarespace` — Interactive mode to choose task
- `/squarespace design` — Design and styling tasks
- `/squarespace content` — Content editing tasks
- `/squarespace seo` — SEO optimization tasks
- `/squarespace audit` — Full site audit

## Prerequisites

Before starting any Squarespace task:

1. **Verify browser connection** — Use `mcp__chrome-devtools__list_pages` to see open pages
2. **Check login status** — User must be logged into Squarespace admin (handle 2FA prompts if they appear)
3. **Dismiss blocking dialogs** — Close cookie banners, announcement modals, or onboarding overlays
4. **Take initial snapshot** — Use `mcp__chrome-devtools__take_snapshot` to understand current state
5. **Check permissions** — If expected menus/options are missing, the user may have limited permissions (see Error Handling)

## Important: Squarespace Draft Behavior

Squarespace stages edits until you explicitly save. **Leaving the editor or navigating away can discard unsaved changes.** Always:
- Click Save/Done/Publish buttons (never rely on auto-save)
- Handle "Unsaved changes" dialogs by clicking Save before navigating
- Verify changes persisted by taking a snapshot after save

---

## Core Workflow

### 1. Connect to Squarespace Admin

```
1. mcp__chrome-devtools__list_pages
2. mcp__chrome-devtools__select_page (select Squarespace admin tab)
3. mcp__chrome-devtools__take_snapshot
4. Verify URL contains squarespace.com
5. Dismiss any blocking overlays (cookie banners, modals)
```

### 2. Navigation Pattern

Squarespace admin has these main sections:
- **Pages** — Page management and editing
- **Design** — Site styles, fonts, colors, custom CSS
- **Commerce** — Products, shipping, taxes, orders
- **Marketing** — SEO tools, analytics, email campaigns, pop-ups
- **Settings** — Domain, language, permissions, member areas, code injection

To navigate: Take snapshot → Find nav element → Click → Wait for load → Take snapshot

### 3. Wait for Load Pattern

The `mcp__chrome-devtools__wait_for` tool accepts one text string. When multiple possible texts could appear, try sequentially:

```
Step 1: Try primary expected text
  mcp__chrome-devtools__wait_for
  Parameters: { "text": "Site Styles" }

Step 2: If timeout error, try alternative
  mcp__chrome-devtools__wait_for
  Parameters: { "text": "Style Editor" }

Step 3: If both fail, take snapshot to see actual UI state
```

### 4. Editing Pattern

For any edit:
```
1. Navigate to target area
2. mcp__chrome-devtools__take_snapshot to find edit controls
3. mcp__chrome-devtools__click on edit button/element
4. mcp__chrome-devtools__wait_for expected UI text (retry with alternatives if timeout)
5. mcp__chrome-devtools__take_snapshot in edit mode
6. Make changes (mcp__chrome-devtools__fill, mcp__chrome-devtools__click)
7. Click on-screen Save/Done button (NOT keyboard shortcuts)
8. mcp__chrome-devtools__take_snapshot to verify
```

---

## Squarespace Version Detection

**Detect version first** — paths differ between 7.0 and 7.1.

### How to Detect

Navigate to Design menu and take snapshot. Look for nav labels:
- **"Site Styles"** → 7.1
- **"Style Editor"** → 7.0

Do NOT rely on "Fluid Engine" text — 7.1 sites can still have classic-style blocks.

### Squarespace 7.1 (Current)
- Style editor: **Design → Site Styles**
- SEO settings: **Marketing → SEO Tools** (or Settings → Marketing → SEO)
- Section-based page editing

### Squarespace 7.0 (Legacy)
- Style editor: **Design → Style Editor**
- Template-specific features and styling
- Different navigation structure

---

## Tool Call Format Reference

All `mcp__chrome-devtools__evaluate_script` calls use this JSON structure:

```json
{
  "function": "() => { /* your code */ return result; }"
}
```

With element arguments:
```json
{
  "function": "(el) => { /* your code using el */ return result; }",
  "args": [{ "uid": "ELEMENT_UID_FROM_SNAPSHOT" }]
}
```

---

## Design Tasks

### Change Site Styles (Fonts, Colors)

**For 7.1:**
1. Navigate to Design → Site Styles
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Site Styles" }`
3. If timeout, try `{ "text": "Fonts" }`
4. Take snapshot to see style options
5. Click on font/color section
6. Use `mcp__chrome-devtools__fill` to change values or click presets
7. Click Save button

**For 7.0:**
1. Navigate to Design → Style Editor
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Style Editor" }`
3. Take snapshot to see template-specific options
4. Modify styles
5. Click Save

### Edit Custom CSS

1. Navigate to Design → Custom CSS
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Custom CSS" }`
3. Take snapshot
4. Find CSS editor textarea uid
5. Append CSS using evaluate_script (see example below)
6. Click Save

### CSS Guidance

**WARNING:** Squarespace CSS classes vary by template and version. Snapshots show accessibility tree, NOT CSS selectors. You must query the DOM to find actual selectors.

**To find CSS selectors:**
```json
// Find header element
mcp__chrome-devtools__evaluate_script
{
  "function": "() => { const header = document.querySelector('header, #header, [data-section-id] header'); return header ? { tag: header.tagName, id: header.id, classes: header.className } : null; }"
}

// Find button classes
mcp__chrome-devtools__evaluate_script
{
  "function": "() => { const btn = document.querySelector('a[href].sqs-button-element, .sqs-block-button-element a'); return btn ? { tag: btn.tagName, classes: btn.className } : null; }"
}
```

**To append CSS to editor (dispatches input event to enable Save):**
```json
mcp__chrome-devtools__evaluate_script
{
  "function": "(el) => { el.value += '\\n/* Your CSS here */\\n.your-class { color: red; }'; el.dispatchEvent(new Event('input', { bubbles: true })); return el.value.length; }",
  "args": [{ "uid": "CSS_TEXTAREA_UID" }]
}
```

**Example CSS patterns — verify selectors exist before using:**
```css
/* Hide element (replace with actual class from DOM query) */
.your-verified-class { display: none; }

/* Full-width section */
.page-section { max-width: 100% !important; padding: 0 !important; }

/* Button styling (verify class exists first) */
.sqs-button-element--primary {
  background-color: #YOUR_COLOR !important;
}

/* Header (query DOM to find actual selector) */
#header { background-color: transparent !important; }

/* Mobile-specific */
@media screen and (max-width: 767px) {
  .your-verified-selector { /* styles */ }
}
```

---

## Content Tasks

### Edit Page Content

1. Navigate to Pages
2. Click on target page
3. Take snapshot to see the page title text
4. Call `mcp__chrome-devtools__wait_for` with the visible title from snapshot
5. Take snapshot in editor mode
6. Click on block to edit
7. For simple text inputs: use `mcp__chrome-devtools__fill`
8. For rich text (contenteditable): use evaluate_script pattern below
9. Click Save/Done button

### Rich Text Editing (contenteditable blocks)

For contenteditable elements, use this pattern to append text without overwriting:

```json
mcp__chrome-devtools__evaluate_script
{
  "function": "(el) => { el.focus(); const range = document.createRange(); range.selectNodeContents(el); range.collapse(false); const sel = window.getSelection(); sel.removeAllRanges(); sel.addRange(range); document.execCommand('insertText', false, ' New text here'); el.dispatchEvent(new Event('input', { bubbles: true })); el.blur(); return el.innerHTML.length; }",
  "args": [{ "uid": "CONTENTEDITABLE_UID" }]
}
```

To replace all content:
```json
mcp__chrome-devtools__evaluate_script
{
  "function": "(el) => { el.innerHTML = 'New content here'; el.dispatchEvent(new Event('input', { bubbles: true })); el.blur(); return true; }",
  "args": [{ "uid": "CONTENTEDITABLE_UID" }]
}
```

### Add/Edit Images

1. Navigate to image block
2. Click to open image editor
3. Take snapshot to find upload/replace button
4. Use `mcp__chrome-devtools__upload_file` if replacing
5. Add alt text (critical for SEO)
6. Click Save

### Blog Post Editing

1. Navigate to Pages → Blog
2. Click on post to edit or "+" to create
3. Take snapshot to see visible title/heading
4. Call `mcp__chrome-devtools__wait_for` with that visible text
5. Take snapshot
6. Edit title, content, URL slug, categories, tags
7. Set SEO title and description in post settings
8. Click Save/Publish

### Scheduling Content (Pages and Posts)

Content scheduling is in **page/post settings**, not a top-level nav.

1. Open the page or post for editing
2. Find settings/gear icon for that page/post
3. Take snapshot to find "Schedule" or publish options
4. Click Schedule option
5. For date picker UI: use `mcp__chrome-devtools__click` on date field, then click desired date in calendar
6. For time: use `mcp__chrome-devtools__fill` if it's a text input, or click time picker options
7. Note: Squarespace uses the site's configured timezone (Settings → Language & Region)
8. Confirm scheduled status shows before leaving

### Page Status (Draft, Unlisted, Password Protected)

1. Open page settings (gear icon on page in Pages panel)
2. Take snapshot to find status options
3. Look for "Enable Page" toggle, "Password" field, or visibility settings
4. **Draft**: Disable/unpublish the page
5. **Password Protected**: Enter password in protection field
6. **Unlisted**: Some templates support this in page settings
7. Save changes

### Reordering Pages and Navigation

1. Navigate to Pages panel
2. Take snapshot to see page list
3. Use `mcp__chrome-devtools__drag` with `from_uid` (page to move) and `to_uid` (target position)
4. For navigation folders: drag pages into/out of folder elements
5. Changes typically auto-save; take snapshot to verify new order

### Forms

1. Navigate to page with form block
2. Click form to edit
3. Take snapshot to see field list
4. Click individual fields to edit labels, options, validation
5. Check form storage settings in block options
6. Save changes

### Member Areas

1. Navigate to Settings → Member Areas (or find in main nav)
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Member Areas" }`
3. Take snapshot
4. Configure access levels, protected pages, sign-up settings
5. Save changes

### Pop-ups and Announcements

**Limitations:**
- Only one promotional pop-up can be active at a time
- Custom code cannot be added to pop-ups
- Announcement bars are separate from pop-ups

**Navigation:**
1. Take snapshot of main nav
2. Look for "Marketing" section
3. Find "Promotional Pop-up" or similar label in snapshot
4. If not visible, the site may not have this feature enabled or user lacks permissions

**Workflow:**
1. Navigate to Promotional Pop-up panel
2. Take snapshot
3. Configure content, timing, targeting
4. Save and enable/disable as needed

---

## Code Injection

### Site-Wide Code Injection

**Path:** Settings → Advanced → Code Injection

**Caution:** Code injection affects the entire site. Test changes carefully.

1. Navigate to Settings → Advanced → Code Injection
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Code Injection" }`
3. Take snapshot to see injection areas and find textarea uids:
   - **Header**: Injects into `<head>` on all pages (analytics, fonts, meta tags)
   - **Footer**: Injects before `</body>` on all pages (scripts, chat widgets)
   - **Lock Page**: Code for password page
   - **Order Confirmation**: Code for checkout confirmation
4. Append code using evaluate_script (dispatches input event):
   ```json
   mcp__chrome-devtools__evaluate_script
   {
     "function": "(el) => { el.value += '\\n<!-- Your code here -->'; el.dispatchEvent(new Event('input', { bubbles: true })); return true; }",
     "args": [{ "uid": "HEADER_TEXTAREA_UID" }]
   }
   ```
5. Click Save
6. Test on live site to verify

### Per-Page Code Injection

Some pages support per-page code injection in their settings:
1. Open page settings (gear icon)
2. Take snapshot and look for "Advanced" or "Code Injection" section
3. If available, add page-specific code there
4. If not visible, the page type may not support per-page injection

### Common Use Cases
- Google Analytics / Tag Manager
- Facebook Pixel
- Custom fonts
- Chat widgets (Intercom, Drift)
- Schema markup

---

## SEO Tasks

### Page-Level SEO

For each page:
1. Navigate to page
2. Open page settings (gear icon)
3. Find SEO section
4. Fill in:
   - SEO Title (guideline: ~50-60 chars, keyword near start; Google may rewrite)
   - SEO Description (guideline: ~105-155 chars; pixel width varies)
   - URL Slug (short, keyword-rich)
5. Click Save

### Social Sharing / Open Graph

Separate from SEO fields — controls how links appear on social media.

1. Open page settings (gear icon)
2. Find "Social Image" or "Social Sharing" section
3. Upload a sharing image (recommended: 1200x630px)
4. Set social title and description if different from SEO
5. Save

### Site-Wide SEO Settings

**Path varies by account setup.** Try in order:
1. Marketing → SEO Tools
2. Settings → Marketing → SEO
3. Marketing → SEO

Take snapshot after each navigation to verify location.

1. Navigate to SEO settings
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "SEO" }`
3. Take snapshot
4. Configure:
   - Site title format
   - Homepage meta description
   - Social sharing image
5. Connect Google Search Console if not done
6. Save

### Image Alt Text

1. Navigate to page with images
2. Click on image block
3. Open image settings
4. Find alt text field (may require clicking "Edit" or gear icon)
5. Add descriptive alt text
6. Repeat for all images
7. Save page

### Heading Structure Check

To verify one H1 per page:
```json
mcp__chrome-devtools__evaluate_script
{
  "function": "() => { const h1s = document.querySelectorAll('h1'); return { count: h1s.length, texts: Array.from(h1s).map(h => h.textContent.trim().substring(0, 50)) }; }"
}
```

Flag pages with 0 or 2+ H1 elements.

### SEO Audit Checklist

When auditing, check:
- [ ] Every page has unique SEO title
- [ ] Every page has meta description
- [ ] URLs are clean and descriptive
- [ ] All images have alt text
- [ ] Heading hierarchy is correct (one H1 per page — use evaluate_script to verify)
- [ ] Internal links exist between related pages
- [ ] Site connected to Google Search Console
- [ ] Sitemap is accessible at /sitemap.xml
- [ ] Social sharing images configured

---

## Performance Tasks

### Image Optimization Check

1. Navigate to page to audit
2. `mcp__chrome-devtools__navigate_page` with `{ "type": "reload" }` to capture fresh requests
3. `mcp__chrome-devtools__list_network_requests` with `{ "resourceTypes": ["image"] }`
4. For each image, use `mcp__chrome-devtools__get_network_request` to check:
   - Response size (flag if > 500KB)
   - Content-Type: verify via network response (Squarespace may serve WebP for raster images in supported browsers; SVG/GIF remain original format)
5. Report oversized images for user to compress before re-uploading

**Note:** Squarespace automatically optimizes image delivery. Verify actual formats served via network requests rather than assuming specific formats.

### Reduce Page Weight

Review and recommend removing:
- Unnecessary third-party scripts (check code injection)
- Unused sections/blocks
- Excessive animations
- Multiple custom fonts (recommend max 2)

---

## Domain and SSL Settings

**Path:** Settings → Domains

**Caution:** DNS changes can take 24-48 hours to propagate.

1. Navigate to Settings → Domains
2. Call `mcp__chrome-devtools__wait_for` with `{ "text": "Domains" }`
3. Take snapshot to see domain list
4. For SSL: Squarespace provides free SSL automatically; check status shows "SSL Active"
5. For DNS records: Click domain → DNS Settings
6. **Do not** make DNS changes without user confirmation — incorrect changes can break email and site access

---

## Commerce Tasks

### Products

1. Navigate to Commerce → Inventory (or Products)
2. Take snapshot
3. Click product to edit or "+" to add
4. Fill product details: title, description, price, images, variants
5. Set SEO fields in product settings
6. Save

### Shipping

1. Navigate to Commerce → Shipping
2. Take snapshot
3. Configure shipping zones and rates
4. Save

### Taxes

**Plan requirements:**
- TaxJar integration requires **Commerce Basic or Advanced** plan
- TaxJar Professional subscription required for automatic tax calculations
- TaxJar Starter uses Squarespace's built-in tax rates

**Setup workflow:**
1. Navigate to Commerce → Taxes
2. Take snapshot
3. For manual rates: Configure tax rules directly in the panel
4. For TaxJar integration:
   - Navigate to Settings → Extensions
   - If "Extensions" not visible, try Settings → Advanced → External Services, or visit account.squarespace.com and look for Extensions/Integrations in account settings
   - Find and connect TaxJar
   - Return to Commerce → Taxes
   - Enable "Automatic tax rates" option
5. Save

---

## Common UI Elements (Snapshot Reference)

When taking snapshots, look for these common Squarespace elements:

| Element | Purpose | Action |
|---------|---------|--------|
| `[Edit]` button | Enter edit mode | Click |
| Gear icon | Page/block settings | Click |
| `[Save]` / `[Done]` / `[Publish]` | Commit changes | Click |
| `[+]` button | Add new content | Click |
| Pencil icon | Edit text | Click |
| Three dots `...` | More options menu | Click |
| `[Schedule]` | Schedule for future (in page settings) | Click |
| Toggle switches | Enable/disable features | Click |

---

## Error Handling

### Permission/Role Issues

If expected menus or options are missing:
1. Take snapshot to document what IS visible
2. Check if user sees "Permissions" or "Contributors" message
3. Alert user: "Some options may be hidden due to account permissions. Please verify you have Owner/Admin access or ask the site owner to grant additional permissions."
4. Do not proceed with tasks requiring missing menus

### Blocking Dialogs

Handle these before proceeding:
- **2FA prompts**: Alert user to complete authentication manually
- **"Unsaved changes" dialog**: Click Save, not Discard
- **Cookie banners**: Click Accept/Dismiss
- **Onboarding modals**: Click Skip or Close
- **Announcement overlays**: Find close button

### If snapshot shows unexpected state
1. `mcp__chrome-devtools__take_screenshot` to see visual state
2. Look for blocking dialogs/modals
3. Navigate back to known location
4. Retry operation

### If element not found
1. `mcp__chrome-devtools__press_key` with arrow keys to scroll
2. `mcp__chrome-devtools__hover` to trigger lazy-loaded UI
3. `mcp__chrome-devtools__wait_for` specific text to appear
4. Take new snapshot
5. Look for alternative selectors

### If changes don't save
1. Check for validation errors (red text, error messages)
2. Look for unsaved changes indicator
3. Click Save button again
4. If still failing, take screenshot to diagnose
5. `mcp__chrome-devtools__navigate_page` with `{ "type": "reload" }` and verify state

---

## Tool Usage Quick Reference

| Task | Tool | Parameters |
|------|------|------------|
| See page structure | `mcp__chrome-devtools__take_snapshot` | `{}` |
| Visual check | `mcp__chrome-devtools__take_screenshot` | `{}` |
| Click button/link | `mcp__chrome-devtools__click` | `{ "uid": "..." }` |
| Enter text | `mcp__chrome-devtools__fill` | `{ "uid": "...", "value": "..." }` |
| DOM query/modify | `mcp__chrome-devtools__evaluate_script` | `{ "function": "...", "args": [...] }` |
| Wait for UI | `mcp__chrome-devtools__wait_for` | `{ "text": "..." }` |
| Trigger hover | `mcp__chrome-devtools__hover` | `{ "uid": "..." }` |
| Drag and drop | `mcp__chrome-devtools__drag` | `{ "from_uid": "...", "to_uid": "..." }` |
| Keyboard | `mcp__chrome-devtools__press_key` | `{ "key": "ArrowDown" }` |
| Navigate/reload | `mcp__chrome-devtools__navigate_page` | `{ "type": "reload" }` or `{ "url": "..." }` |
| List network | `mcp__chrome-devtools__list_network_requests` | `{ "resourceTypes": ["image"] }` |
| Get request | `mcp__chrome-devtools__get_network_request` | `{ "reqid": 123 }` |
| Console messages | `mcp__chrome-devtools__list_console_messages` | `{}` |
| Upload file | `mcp__chrome-devtools__upload_file` | `{ "uid": "...", "filePath": "..." }` |

**Important:** Do NOT use keyboard shortcuts like Control+S — they trigger browser actions, not Squarespace save. Always use on-screen Save/Done/Publish buttons.

---

## Workflow Templates

### Full Page SEO Optimization

```
1. Navigate to page
2. mcp__chrome-devtools__take_snapshot → Find settings gear
3. mcp__chrome-devtools__click with { "uid": "GEAR_UID" }
4. mcp__chrome-devtools__wait_for with { "text": "SEO" }
   - If timeout, try { "text": "Settings" }
5. Fill SEO title (keyword near start)
6. Fill meta description (with value proposition)
7. Check/fix URL slug
8. Set social sharing image if needed
9. Click Save
10. mcp__chrome-devtools__take_snapshot → Find images
11. For each image: click → add alt text → save
12. Check heading structure via mcp__chrome-devtools__evaluate_script
13. Verify all changes saved
```

### Design Refresh

```
1. Detect version: Navigate to Design, take snapshot, look for "Site Styles" (7.1) or "Style Editor" (7.0)
2. Navigate to appropriate style editor
3. mcp__chrome-devtools__wait_for with { "text": "Site Styles" }
   - If timeout, try { "text": "Style Editor" }
4. mcp__chrome-devtools__take_snapshot current styles
5. Update fonts (max 2)
6. Update color palette
7. Click Save
8. Navigate to Design → Custom CSS
9. Query DOM for selectors via mcp__chrome-devtools__evaluate_script
10. Append CSS via mcp__chrome-devtools__evaluate_script (with input event dispatch)
11. Click Save
12. Test on multiple pages
13. Mobile preview check
```

### Content Update

```
1. Navigate to target page
2. Enter edit mode
3. Take snapshot to see visible page title
4. mcp__chrome-devtools__wait_for with { "text": "VISIBLE_TITLE_FROM_SNAPSHOT" }
5. mcp__chrome-devtools__take_snapshot for block layout
6. For rich text (contenteditable): use evaluate_script with focus/selection/input pattern
7. For simple inputs: use mcp__chrome-devtools__fill
8. Update images (with alt text)
9. Check internal links
10. Click Save/Done
11. mcp__chrome-devtools__take_snapshot to verify
```

---

## Safety Guidelines

- **Always take snapshots before major changes** — Allows recovery reference
- **Click Save buttons explicitly** — Don't rely on auto-save or keyboard shortcuts
- **Handle "Unsaved changes" dialogs** — Always save, never discard
- **Test on preview** — Before publishing changes
- **One task at a time** — Complete and verify each change
- **Document changes** — Report what was modified
- **DNS/Domain changes** — Always get user confirmation first
- **Dispatch events after script edits** — Use input event so Save button enables
- **Check permissions first** — Missing menus may indicate role restrictions

---

## Limitations

- Cannot directly access Squarespace API (browser automation only)
- Cannot bulk-edit multiple pages simultaneously
- File uploads require local file path
- Some advanced settings may require multiple navigation steps
- Real-time collaboration may cause conflicts
- Keyboard shortcuts trigger browser actions, not Squarespace actions
- CSS classes vary by template/version — always query DOM first
- Snapshots show a11y tree, not CSS selectors — use evaluate_script for DOM queries
- Only one promotional pop-up can be active at a time
- Pop-ups do not support custom code injection
- Some features may be hidden based on user role/permissions

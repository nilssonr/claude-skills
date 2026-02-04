---
name: seo
description: Full SEO workflow for auditing pages and creating SEO-optimized content. Provides checklists with educational explanations aligned with Google Search Central documentation.
---

# SEO

Comprehensive SEO guidance for auditing existing content and creating new SEO-optimized pages. Aligned with Google Search Central documentation as of 2026.

## Activation

### Explicit
User invokes `/seo` with optional arguments:
- `/seo audit` — Audit a specific page or URL
- `/seo create` — Guide for creating new SEO content
- `/seo checklist` — Quick reference checklist
- `/seo` — Interactive mode to choose workflow

## Audit Workflow

When auditing content, follow this sequence:

### 1. Identify the Target
Ask: "Which file or URL would you like me to audit for SEO?"

### 2. Run the Audit
Check each category below and report findings with severity:
- **Critical** — Violates spam policies or blocks indexing
- **Warning** — Impacts user experience or discoverability
- **Info** — Optimization opportunity or usability improvement

### 3. Provide Recommendations
For each issue found:
1. State what's wrong
2. Explain why it matters (cite Google documentation when relevant)
3. Show how to fix it

---

## On-Page SEO Checklist

### Title Tag
- [ ] **Present and descriptive** — Accurately describes the page content
- [ ] **Unique per page** — Each page has its own distinct title
- [ ] **Concise and clear** — Google may truncate or rewrite titles to fit device width
- [ ] **Reflects page content** — Google generates title links from multiple sources; mismatches may cause rewrites

> Google states there is no character limit for titles. Title links are generated dynamically and may be truncated or rewritten based on device, query, and page content. Focus on accuracy over length. [Source: Google Search Central](https://developers.google.com/search/docs/appearance/title-link)

### Meta Description
- [ ] **Present and accurate** — Summarizes the page content clearly
- [ ] **Unique per page** — Avoid duplicating descriptions across pages
- [ ] **Describes value** — Tells users what they'll find on the page

> Meta descriptions are not a ranking factor. Google often generates snippets from page content rather than the meta description. There is no character limit—truncation depends on device width. Focus on accurate, helpful summaries rather than hitting character targets. [Source: Google Search Central](https://developers.google.com/search/docs/appearance/snippet)

### Header Structure (H1-H6)
- [ ] **Headers describe content structure** — Help users and search engines understand page organization
- [ ] **Logical hierarchy preferred** — H2 for sections, H3 for subsections aids readability
- [ ] **Content is scannable** — Headers create an outline users can navigate

> Multiple H1 tags are fine. Google's John Mueller has confirmed this is not critical for SEO. Treat heading structure as a usability and accessibility best practice, not a ranking rule. [Source: Search Engine Journal](https://www.searchenginejournal.com/google-h1-headings-seo/328459/)

### URL Structure
- [ ] **Descriptive and readable** — URLs should indicate page content
- [ ] **Consistent structure** — Use a predictable hierarchy
- [ ] **Uses hyphens between words** — Google treats hyphens as word separators
- [ ] **Parameters handled consistently** — URL parameters are acceptable when managed to avoid duplication

> URL parameters are fine when handled properly. Google provides guidance on parameter handling for e-commerce and faceted navigation. The goal is avoiding duplicate content, not eliminating parameters entirely. [Source: Google Search Central](https://developers.google.com/search/docs/specialty/ecommerce/designing-a-url-structure-for-ecommerce-sites)

### Content Quality
- [ ] **Answers search intent** — Match what users actually want
- [ ] **Original and helpful** — Provides genuine value not found elsewhere
- [ ] **Written for people first** — Not primarily for search engines
- [ ] **Well-structured** — Easy to read with clear organization
- [ ] **Complete coverage** — Thoroughly addresses the topic

> Google explicitly states there is no preferred word count. Focus on completeness and helpfulness rather than hitting arbitrary length targets. The Helpful Content system rewards people-first content demonstrating expertise and genuine value. [Source: Google Search Central](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)

**Warning:** Avoid keyword stuffing. Google's spam policies explicitly flag "unnaturally" inserting keywords as spam. Write naturally—do not target keyword density percentages. [Source: Google Spam Policies](https://developers.google.com/search/docs/essentials/spam-policies)

### E-E-A-T Signals (Experience, Expertise, Authoritativeness, Trustworthiness)
- [ ] **Author information visible** — Show who created the content
- [ ] **Credentials where relevant** — Especially for YMYL topics
- [ ] **First-hand experience demonstrated** — Show direct knowledge
- [ ] **Sources cited** — Support claims with evidence
- [ ] **Contact information accessible** — Trust signal for users

> E-E-A-T is a quality framework, not a specific ranking factor. Google states rater data is not used directly in rankings. These signals help demonstrate quality but are not algorithmic scores. Focus on genuinely demonstrating expertise rather than checkbox optimization. [Source: Google Search Central](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)

### Internal Linking
- [ ] **Links to relevant pages** — Helps users discover related content
- [ ] **Descriptive anchor text** — Describes the destination, not "click here"
- [ ] **No orphan pages** — Important pages should be linked from other pages

### External Linking
- [ ] **Links to helpful sources** — Supports claims and adds value for users
- [ ] **No broken links** — Check regularly
- [ ] **Appropriate rel attributes** — Use `rel="sponsored"` for paid links, `rel="nofollow"` when appropriate

### Image Optimization
- [ ] **Descriptive filenames** — `blue-running-shoes.jpg` not `IMG_1234.jpg`
- [ ] **Alt text for all images** — Describes content for accessibility
- [ ] **Compressed file sizes** — Optimized for web delivery
- [ ] **Appropriate format** — WebP for photos, SVG for icons
- [ ] **Responsive images** — Serve appropriate sizes for devices

---

## Technical SEO Checklist

### Core Web Vitals
- [ ] **LCP (Largest Contentful Paint) < 2.5s** — Main content loads quickly
- [ ] **INP (Interaction to Next Paint) < 200ms** — Page responds quickly to interactions
- [ ] **CLS (Cumulative Layout Shift) < 0.1** — Visual stability, no layout shifts

> Core Web Vitals are the documented performance thresholds. There is no separate "page load under X seconds" ranking factor—CWV thresholds are Google's official performance targets. [Source: Google Search Console Help](https://support.google.com/webmasters/answer/10218333)

### Mobile Optimization
- [ ] **Responsive design** — Adapts to all screen sizes
- [ ] **Mobile-friendly fonts** — Minimum 16px base size
- [ ] **Touch-friendly buttons** — At least 48x48px tap targets
- [ ] **No horizontal scrolling** — Content fits viewport
- [ ] **Mobile content parity** — Same content as desktop

> Google uses mobile-first indexing. Your mobile site is what Google primarily sees and ranks.

### Crawlability & Indexing
- [ ] **XML sitemap submitted** — Lists important pages for search engines
- [ ] **Robots.txt properly configured** — Not blocking important content
- [ ] **No noindex on important pages** — Check meta robots tags
- [ ] **Hreflang for multi-language sites** — Correct language/region targeting

**Canonical tags:** Use canonical tags when you have duplicate or variant URLs that should consolidate to a primary version. They are not required on every page—Google says sites can work fine without specifying canonicals when no duplicates exist. [Source: Google Search Central](https://developers.google.com/search/docs/crawling-indexing/consolidate-duplicate-urls)

### URL Parameters & Pagination
- [ ] **Parameters don't create duplicate content** — Use canonical tags or parameter handling
- [ ] **Pagination uses proper linking** — rel="next"/rel="prev" or load-more patterns
- [ ] **Faceted navigation controlled** — Prevent crawl of low-value filter combinations
- [ ] **Variants consolidated** — Product variants point to canonical version

> URL parameters require careful handling to avoid duplication and crawl waste. Google provides specific guidance for e-commerce parameter handling. [Source: Google Search Central](https://developers.google.com/search/docs/specialty/ecommerce/designing-a-url-structure-for-ecommerce-sites)

### Structured Data (Schema Markup)
- [ ] **Appropriate schema type** — Article, Product, LocalBusiness, FAQ, etc.
- [ ] **Valid and error-free** — Test with Google Rich Results Test
- [ ] **Matches visible content** — Schema must reflect actual page content
- [ ] **Required properties included** — Each schema type has required fields

> Schema helps search engines understand content and can enable rich results that increase CTR.

### Snippet & Preview Controls
- [ ] **nosnippet** — Prevents snippet generation for a page
- [ ] **max-snippet** — Limits snippet character length
- [ ] **data-nosnippet** — Excludes specific content from snippets
- [ ] **max-image-preview** — Controls image preview size
- [ ] **max-video-preview** — Controls video preview length

> These meta robots directives also affect AI feature inclusion. Use them to control how your content appears in search results and AI Overviews. [Source: Google Search Central](https://developers.google.com/search/docs/appearance/ai-features)

### Security
- [ ] **HTTPS enabled** — SSL certificate valid and site-wide
- [ ] **No mixed content** — All resources loaded over HTTPS
- [ ] **Security headers configured** — HSTS, CSP, etc.

---

## AI Search (AI Overviews & AI Mode)

Google's AI features (AI Overviews, AI Mode) use the same core ranking systems as traditional search.

### Key Points
- **No special optimization required** — Standard SEO best practices apply
- **Eligibility** — Pages must be indexed and eligible for web search
- **Opt-out available** — Use `nosnippet` meta tag to exclude from AI features
- **Measurement** — Search Console shows AI Overview impressions and clicks

> Google explicitly states no special optimization is needed for AI features beyond core SEO fundamentals. Focus on creating helpful, high-quality content. [Source: Google Search Central](https://developers.google.com/search/docs/appearance/ai-features)

---

## Content Strategy Guidance

### Topic Clusters
A topic cluster is a group of interlinked pages around a central topic:

1. **Pillar Page** — Comprehensive overview of the topic
2. **Cluster Pages** — Detailed subtopic content
3. **Strategic Internal Links** — Every cluster page links to pillar and vice versa

> Focus on completeness and helpfulness rather than word count targets. Google explicitly states there is no preferred word count.

### Search Intent Types
Match content type to user intent:

| Intent | User Goal | Content Type |
|--------|-----------|--------------|
| Informational | Learn something | Blog posts, guides, how-tos |
| Navigational | Find specific site/page | Homepage, brand pages |
| Commercial | Research before buying | Comparisons, reviews, lists |
| Transactional | Make a purchase | Product pages, landing pages |

### Content Pillars
- Target focused topical areas where you have genuine expertise
- Build depth through comprehensive coverage
- Demonstrate first-hand experience

---

## Link Building Guidance

### Important: Link Spam Policies

Google's spam policies explicitly prohibit:
- **Buying or selling links** that pass ranking credit
- **Excessive link exchanges** ("Link to me and I'll link to you")
- **Large-scale guest posting** with keyword-rich anchor text links
- **Automated link building** or link schemes
- **Requiring links as part of contracts** (ToS, etc.)

**Required:** Use `rel="sponsored"` for paid/compensated links, `rel="nofollow"` for untrusted content. [Source: Google Spam Policies](https://developers.google.com/search/docs/essentials/spam-policies)

### Earning Links Safely
1. **Create linkable content** — Original research, tools, comprehensive guides
2. **Earn editorial mentions** — Be a source journalists want to cite
3. **Build relationships** — Genuine industry connections, not transactional exchanges
4. **Digital PR** — Newsworthy announcements, data studies, expert commentary

### Link Quality Factors
- **Relevance** — Links from topically related sites
- **Editorial placement** — Links within content, not footers/sidebars
- **Natural anchor text** — Varied, not keyword-stuffed

> Google does not use third-party SEO tool scores (Domain Authority, Domain Rating) in ranking. These are useful for competitive analysis but are not Google metrics. [Source: Search Engine Land](https://searchengineland.com/google-search-seo-tools-scores-430771)

### Journalist Outreach Tools (2026)
- **Featured.com** — Acquired HARO in April 2025
- **Qwoted** — Expert source matching
- **Help a B2B Writer** — B2B-focused queries
- **SourceBottle** — PR opportunity matching

> Note: Connectively (formerly HARO under Cision) was discontinued December 9, 2024. Verify current availability of any outreach platform before use. [Source: Cision](https://www.cision.com/connectively-has-been-discontinued/)

---

## Content Creation Workflow

### 1. Research Phase
- [ ] Identify target topic and search intent
- [ ] Review what's currently ranking (understand user needs)
- [ ] Find content gaps and unique angles
- [ ] Gather expertise and sources

### 2. Planning Phase
- [ ] Outline structure with logical headings
- [ ] Plan internal linking opportunities
- [ ] Plan visual elements (images, tables, diagrams)
- [ ] Determine depth needed (based on topic, not word count)

### 3. Writing Phase
- [ ] Write descriptive, accurate title
- [ ] Write helpful meta description (summary, not keyword-stuffed)
- [ ] Write for users first, naturally incorporating topic coverage
- [ ] Add internal links to relevant pages
- [ ] Cite sources where appropriate
- [ ] Include author information

### 4. Optimization Phase
- [ ] Optimize images (compress, descriptive filenames, alt text)
- [ ] Add structured data if applicable
- [ ] Verify all links work
- [ ] Test readability and scannability

### 5. Technical Checks
- [ ] URL is descriptive
- [ ] Page passes Core Web Vitals
- [ ] Mobile rendering correct
- [ ] No console errors
- [ ] Canonical tag correct (if duplicates exist)

---

## Spam Policy Awareness

### Content Spam to Avoid
- **Scaled content abuse** — Mass-generating low-value content (AI or otherwise)
- **Keyword stuffing** — Unnaturally repeating keywords
- **Hidden text/links** — Content invisible to users
- **Doorway pages** — Pages targeting specific queries to funnel users
- **Scraped content** — Copying content from other sites

### Link Spam to Avoid
- **Buying/selling links** — Any exchange of money/goods for links that pass PageRank
- **Link exchanges** — Reciprocal linking at scale
- **Guest post link schemes** — Links in exchange for articles
- **Widget/template links** — Embedding links in distributed code

[Source: Google Spam Policies](https://developers.google.com/search/docs/essentials/spam-policies)

---

## Quick Reference: SEO Priorities

When time is limited, focus on these high-impact elements:

1. **Content quality & search intent match** — Helpful, people-first content
2. **Indexability** — Can Google find and index your pages?
3. **Core Web Vitals** — Meet LCP/INP/CLS thresholds
4. **Spam policy compliance** — Avoid content and link spam
5. **Internal linking** — Help users and crawlers discover content

---

## Tools Reference

### Free Tools
- **Google Search Console** — Index status, performance data, issues
- **Google PageSpeed Insights** — Core Web Vitals, speed recommendations
- **Google Rich Results Test** — Validate structured data

### Paid Tools (third-party metrics, not used by Google)
- **Ahrefs** — Backlink analysis, keyword research
- **Semrush** — SEO/PPC analysis
- **Screaming Frog** — Technical crawl audits

### Audit Frequency
- Full site audit: Quarterly
- Content audit: Every 6-12 months
- Core Web Vitals: Monthly
- Spam policy review: Ongoing

---

## Sources

Aligned with official Google documentation:
- [Google Search Central](https://developers.google.com/search/docs)
- [Google Spam Policies](https://developers.google.com/search/docs/essentials/spam-policies)
- [Title Link Documentation](https://developers.google.com/search/docs/appearance/title-link)
- [Snippet Documentation](https://developers.google.com/search/docs/appearance/snippet)
- [Helpful Content Guidelines](https://developers.google.com/search/docs/fundamentals/creating-helpful-content)
- [AI Features Documentation](https://developers.google.com/search/docs/appearance/ai-features)
- [Core Web Vitals](https://support.google.com/webmasters/answer/10218333)

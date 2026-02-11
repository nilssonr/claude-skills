---
name: search
description: Sumo Logic Search Query Language reference and best practices
---

# Sumo Logic Search Query Language

## Description

Comprehensive reference for the Sumo Logic Search Query Language (SumoQL) — a SQL-like language for real-time log analytics. This skill synthesizes 214 official documentation files covering search operators, functions, parse operators, aggregation, analytics, and best practices.

**Source:** Official Sumo Logic documentation (`/docs/search`)
**Source Type:** Documentation (high confidence)
**Total Reference Files:** 214
**Categories:** Overview (10), Architecture/Core Reference (180+), Specialized Features (19)

## When to Use This Skill

Use this skill when you need to:

- **Write Sumo Logic search queries** — syntax, operators, and pipeline structure
- **Parse log data** — extract fields from unstructured logs using anchor parsing, regex, JSON, CSV, XML, or key-value parsing
- **Aggregate and analyze** — count, sum, avg, min/max, percentiles, standard deviation, and group-by operations
- **Filter and transform** — where clauses, field selection, conditional logic, type casting
- **Time-series analysis** — timeslice bucketing, time comparison, outlier detection, prediction, smoothing
- **Enrich data** — GeoIP lookups, ASN lookups, threat intelligence, lookup tables
- **Detect patterns** — LogReduce for fuzzy pattern grouping, LogCompare for baseline comparison
- **Join and correlate** — join operator, transaction analysis, sessionize
- **Optimize queries** — best practices for search performance, partitions, Field Extraction Rules
- **Visualize results** — chart types, map visualizations, transpose for time-series plots
- **Use advanced features** — subqueries, macros, Live Tail, Mobot AI assistant

## Key Concepts

### Pipeline Architecture

SumoQL uses a funnel/pipeline concept. Queries start with a **keyword expression** (scope) that filters across all log data, followed by pipe-delimited (`|`) operators that progressively refine results:

```sql
keyword expression | operator 1 | operator 2 | operator 3
```

- The **keyword expression** (scope) is a full-text Boolean search — case-insensitive, supports `AND` (implicit), `OR`, `NOT`, wildcards (`*`)
- **Metadata fields** (`_sourceCategory`, `_sourceHost`, `_sourceName`, `_collector`) narrow scope efficiently
- Each **operator** acts on results from the previous operator
- Queries are limited to **15,000 characters** max
- Max **250 concurrent search jobs** per organization

### Field Extraction

Fields are created at query time using parse operators. Field names support alphanumeric characters and underscores, must start with an alphanumeric character. Built-in fields start with underscore (e.g., `_count`, `_timeslice`).

### Data Tiers

Sumo Logic supports Continuous, Frequent, and Infrequent data tiers, plus Flex storage. Use `_dataTier` metadata to target specific tiers.

## Quick Reference

### 1. Basic Keyword Search

```sql
-- Boolean operators: AND (implicit), OR, NOT
(su OR sudo) AND (fail* OR error)

-- Metadata scoping
_sourceCategory=Apache/Access
_sourceHost=Atlanta AND _sourceCategory="win-app-logs"

-- Wildcards
error* OR fail*
_sourceHost=*prod*
```

### 2. Parse (Anchor) — Extract Fields from Logs

```sql
-- Extract fields using start/stop anchors
_sourceCategory=apache
| parse "* -" as src_ip
| parse "GET * " as url
| parse " 200 * " as size

-- Multiple fields in one parse
| parse "user=*: severity=*:" as user, severity

-- Use nodrop to keep non-matching messages
| parse " 200 * " as size nodrop
```

### 3. Parse (Regex) — Extract with Regular Expressions

```sql
-- Extract IP addresses with regex
* | parse regex "(?<src_ip>\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})"

-- Extract multiple fields
_sourceHost=vpn3000
| parse "Group [*] User [*]" as type, user
```

### 4. Parse JSON / CSV / XML

```sql
-- JSON parsing
| json field=_raw "status", "duration"
| json auto

-- CSV parsing
| csv _raw extract 1 as ip, 2 as method, 3 as url

-- Key-value parsing
| keyvalue infer "url" as url
```

### 5. Aggregation — Count, Sum, Avg

```sql
-- Count by field
_sourceCategory=apache
| parse "GET * " as url
| count by url
| sort by _count

-- Sum and average
_sourceCategory=apache
| parse "* " as src_IP
| parse " 200 * " as size
| count, sum(size) by src_IP

-- Average response time
_sourceCategory=app
| parse "time taken: * ms," as time
| avg(time) as avg_time
```

### 6. Timeslice — Time-Series Bucketing

```sql
-- Count logins per hour
_sourceCategory=exampleApplication*
| parse "login_status=*" as login_status
| where login_status="success"
| timeslice 1h
| count by _timeslice

-- Monitor status codes over time with transpose
_sourceCategory=apache*
| parse "HTTP/1.1\" * * \"" as (status_code, size)
| timeslice 1h
| count by _timeslice, status_code
| transpose row _timeslice column status_code
```

### 7. Where — Filter Results

```sql
-- Comparison operators
| where status_code matches "5*"
| where response_time > 5000
| where user in ("admin", "root")
| where !(status matches "200")

-- Combined conditions
| where (x >= 10 and x <= 20)
| where method = "POST" and status_code matches "4*"
```

### 8. Outlier Detection — Anomaly Analysis

```sql
-- Detect anomalous response times
_sourceCategory=IIS/Access
| parse regex "\d+ \d+ \d+ (?<response_time>\d+)$"
| timeslice 15m
| max(response_time) as response_time by _timeslice
| outlier response_time window=5,threshold=3,consecutive=2,direction=+-

-- Multi-dimensional outlier (per source host)
_sourceCategory=Apache/Access
| timeslice 1m
| count by _timeslice, _sourceHost
| outlier _count by _sourceHost
```

### 9. GeoIP — Map IP Addresses to Locations

```sql
-- Map login locations
| parse "remote_ip=*]" as remote_ip
| geoip remote_ip
| count by latitude, longitude, country_name, city
| sort _count
```

### 10. LogReduce — Pattern Detection

```sql
-- Find patterns in error logs
exception* or fail* or error* or fatal*
| logreduce

-- LogReduce by region with limits
_sourceCategory="Labs/AWS/GuardDuty_V8"
| json keys "resource", "partition", "region"
| logreduce(partition) by region limit=5,criteria=mostcommon
```

## Operator Categories

### Parse Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `parse` (anchor) | Extract fields using start/stop anchors | `references/documentation/architecture/parse-predictable-patterns-using-an-anchor.md` |
| `parse regex` / `extract` | Extract using regular expressions | `references/documentation/architecture/parse-variable-patterns-using-regex.md` |
| `json` | Parse JSON-formatted logs | `references/documentation/architecture/parse-json-formatted-logs.md` |
| `csv` | Parse CSV-formatted logs | `references/documentation/architecture/parse-csv-formatted-logs.md` |
| `xml` | Parse XML-formatted logs | `references/documentation/architecture/parse-xml-formatted-logs.md` |
| `keyvalue` | Parse key-value pairs | `references/documentation/architecture/parse-keyvalue-formatted-logs.md` |
| `split` | Split delimited logs | `references/documentation/architecture/parse-delimited-logs-using-split.md` |
| `parseDate` | Parse date strings to epoch | `references/documentation/architecture/parsedate.md` |

### Search/Filter Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `where` | Filter by boolean expression | `references/documentation/architecture/where.md` |
| `fields` | Select/exclude fields | `references/documentation/architecture/fields.md` |
| `filter` | Filter aggregate results | `references/documentation/architecture/filter.md` |
| `sort` / `order` | Order results | `references/documentation/architecture/sort.md` |
| `limit` | Limit result count | `references/documentation/architecture/limit.md` |
| `top` | Top N results | `references/documentation/architecture/top.md` |
| `dedup` | Remove duplicates | `references/documentation/architecture/dedup.md` |
| `matches` | Wildcard/regex matching | `references/documentation/architecture/matches.md` |
| `contains` | String containment | `references/documentation/architecture/contains.md` |
| `in` | Value in set | `references/documentation/architecture/in.md` |
| `if` | Conditional (ternary) | `references/documentation/architecture/if.md` |
| `isNull` / `isEmpty` / `isBlank` | Null checks | `references/documentation/architecture/isNull-isempty-isblank.md` |

### Aggregation Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `count` / `count_distinct` / `count_frequent` | Counting | `references/documentation/architecture/count-count-distinct-and-count-frequent.md` |
| `sum` | Summation | `references/documentation/architecture/sum.md` |
| `avg` | Average | `references/documentation/architecture/avg.md` |
| `min` / `max` | Min and max | `references/documentation/architecture/min-max.md` |
| `median` | Median value | `references/documentation/architecture/median.md` |
| `pct` / `percentile` | Percentiles | `references/documentation/architecture/pct-percentile.md` |
| `stddev` | Standard deviation | `references/documentation/architecture/stddev.md` |
| `first` / `last` | First/last values | `references/documentation/architecture/first-last.md` |
| `values` | Unique values | `references/documentation/architecture/values.md` |
| `total` | Running total | `references/documentation/architecture/total.md` |

### Time Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `timeslice` | Aggregate by time buckets | `references/documentation/architecture/timeslice.md` |
| `formatDate` | Format epoch to date string | `references/documentation/architecture/formatdate.md` |
| `parseDate` | Parse date string to epoch | `references/documentation/architecture/parsedate.md` |
| `now()` | Current timestamp | `references/documentation/architecture/now.md` |
| `queryStartTime()` | Query start time | `references/documentation/architecture/querystarttime.md` |
| `queryEndTime()` | Query end time | `references/documentation/architecture/queryendtime.md` |

### Advanced Analytics
| Operator | Description | Reference |
|:--|:--|:--|
| `outlier` | Anomaly detection | `references/documentation/architecture/outlier.md` |
| `predict` | Forecasting | `references/documentation/architecture/predict.md` |
| `smooth` | Smoothing algorithms | `references/documentation/architecture/smooth.md` |
| `compare` | Time period comparison | `references/documentation/architecture/compare.md` |
| `backshift` | Shift data in time | `references/documentation/architecture/backshift.md` |
| `diff` | Difference between values | `references/documentation/architecture/diff.md` |
| `accum` | Cumulative sum | `references/documentation/architecture/accum.md` |
| `fillmissing` | Fill missing data points | `references/documentation/architecture/fillmissing.md` |
| `rollingstd` | Rolling standard deviation | `references/documentation/architecture/rollingstd.md` |

### Enrichment/Lookup Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `geoip` | IP to geographic location | `references/documentation/architecture/geoip.md` |
| `lookup` | Lookup table enrichment | `references/documentation/architecture/lookup.md` |
| `lookup` (classic) | Classic lookup syntax | `references/documentation/architecture/lookup-classic.md` |
| `ASN lookup` | IP to ASN info | `references/documentation/architecture/asn-lookup.md` |
| `threatip` | Threat intelligence for IPs | `references/documentation/architecture/threatip.md` |
| `threatlookup` | Threat intelligence lookup | `references/documentation/architecture/threatlookup.md` |

### Join/Correlation Operators
| Operator | Description | Reference |
|:--|:--|:--|
| `join` | Inner join of data streams | `references/documentation/architecture/join.md` |
| `transaction` | Transaction analysis | `references/documentation/architecture/transaction-operator.md` |
| `transactionize` | Group by transaction fields | `references/documentation/architecture/transactionize-operator.md` |
| `sessionize` | Session analysis | `references/documentation/architecture/sessionize.md` |

### String Functions
| Function | Description | Reference |
|:--|:--|:--|
| `concat` | Concatenate strings | `references/documentation/architecture/concat.md` |
| `substring` | Extract substring | `references/documentation/architecture/substring.md` |
| `length` | String length | `references/documentation/architecture/length.md` |
| `trim` | Remove whitespace | `references/documentation/architecture/trim.md` |
| `replace` | Replace text | `references/documentation/architecture/replace.md` |
| `toLowerCase` / `toUpperCase` | Case conversion | `references/documentation/architecture/tolowercase-touppercase.md` |
| `urlencode` / `urldecode` | URL encoding | `references/documentation/architecture/urlencode.md` |
| `base64Encode` / `base64Decode` | Base64 conversion | `references/documentation/architecture/base64encode.md` |
| `format` | String formatting | `references/documentation/architecture/format.md` |

### Math Functions
| Function | Description | Reference |
|:--|:--|:--|
| `abs` | Absolute value | `references/documentation/architecture/abs.md` |
| `round` / `ceil` / `floor` | Rounding | `references/documentation/architecture/round.md` |
| `sqrt` / `cbrt` | Root functions | `references/documentation/architecture/sqrt.md` |
| `log` / `log10` / `log1p` | Logarithms | `references/documentation/architecture/log.md` |
| `exp` / `expm1` | Exponential | `references/documentation/architecture/exp.md` |
| `sin` / `cos` / `tan` | Trigonometric | `references/documentation/architecture/sin.md` |
| `haversine` | Great-circle distance | `references/documentation/architecture/haversine.md` |

### Behavior Insights
| Feature | Description | Reference |
|:--|:--|:--|
| LogReduce | Fuzzy pattern grouping | `references/documentation/other/logreduce-operator.md` |
| LogCompare | Baseline comparison | `references/documentation/other/logcompare.md` |
| LogExplain | AI-powered log explanation | `references/documentation/other/logexplain.md` |
| LogReduce Keys | Key-based reduction | `references/documentation/other/logreduce-keys.md` |
| LogReduce Values | Value-based reduction | `references/documentation/other/logreduce-values.md` |

### Specialized Parsers
| Parser | Description | Reference |
|:--|:--|:--|
| Apache Access | Pre-built Apache access log parser | `references/documentation/architecture/apache-access-parser.md` |
| Apache Errors | Pre-built Apache error log parser | `references/documentation/architecture/apache-errors-parser.md` |
| Microsoft IIS | Pre-built IIS log parser | `references/documentation/architecture/microsoft-iis-parser.md` |
| Cisco ASA | Pre-built Cisco ASA parser | `references/documentation/architecture/cisco-asa-parser.md` |
| Windows Events | Windows event log parser | `references/documentation/architecture/windows-events.md` |

## Best Practices

These are the official Sumo Logic best practices for writing efficient searches:

1. **Be specific with search scope** — Always use metadata fields (`_sourceCategory`, `_sourceHost`, `_sourceName`) plus keywords in the scope
2. **Limit time range** — Use the smallest time range needed; build and test with short ranges first
3. **Use Field Extraction Rules (FERs)** — Use pre-extracted fields instead of parsing inline; avoid `where` when a keyword works
4. **Filter before aggregation** — Make the result set as small as possible before `count`, `sum`, `avg`, etc.
5. **Use parse anchor over parse regex** — Anchor parsing is faster; use regex only for complex unstructured messages
6. **Avoid expensive regex tokens** — Avoid `.*`; be as specific as possible in regular expressions
7. **Use partitions and scheduled views** — Run searches against indexed subsets for faster results
8. **Aggregate before lookup** — Reduce data volume before enrichment lookups
9. **Pin long-running searches** — Pinned searches run up to 24 hours in the background
10. **Put pipe-delimited operations on separate lines** — Improves readability

*Full details:* `references/documentation/architecture/best-practices-search.md`

## Working with This Skill

### For Beginners
Start with these reference files:
- `references/documentation/architecture/about-search-basics.md` — Pipeline concept and fundamentals
- `references/documentation/architecture/keyword-search-expressions.md` — Boolean search syntax
- `references/documentation/architecture/search-syntax.md` — Query syntax overview
- `references/documentation/architecture/general-search-examples.md` — Cheat sheet with practical examples
- `references/documentation/architecture/best-practices-search.md` — Performance best practices

### For Intermediate Users
Explore operators and aggregation:
- `references/documentation/architecture/parse-predictable-patterns-using-an-anchor.md` — Anchor parsing
- `references/documentation/architecture/parse-variable-patterns-using-regex.md` — Regex parsing
- `references/documentation/architecture/timeslice.md` — Time-series bucketing
- `references/documentation/architecture/where.md` — Filtering
- `references/documentation/architecture/count-count-distinct-and-count-frequent.md` — Counting operations
- `references/documentation/architecture/join.md` — Joining data streams

### For Advanced Users
Deep analytics and enrichment:
- `references/documentation/architecture/outlier.md` — Anomaly detection with multi-dimensional support
- `references/documentation/architecture/predict.md` — Forecasting
- `references/documentation/other/logreduce-operator.md` — Pattern detection with optimize mode
- `references/documentation/architecture/geoip.md` — Geographic mapping
- `references/documentation/architecture/transaction-operator.md` — Transaction correlation
- `references/documentation/overview/optimize-search-performance.md` — Deep performance tuning

### Navigating Reference Files

Reference files are organized in three directories:

| Directory | Content | Files |
|:--|:--|:--|
| `references/documentation/overview/` | High-level guides, AI features, optimization | 10 |
| `references/documentation/architecture/` | Core operators, functions, search language | 180+ |
| `references/documentation/other/` | Live Tail, LogReduce, Lookup Tables | 19 |

Each reference file follows a consistent format: frontmatter with ID/title, syntax section, rules, and examples with SQL code blocks.

## Available References

### Documentation Sources (High Confidence)

- **`references/documentation/overview/`** — Search overview, optimization guides, Mobot AI assistant, subqueries, time-compare, FAQ
- **`references/documentation/architecture/`** — Complete operator reference: parse operators, search operators, aggregate operators, math functions, string functions, time functions, conditional operators, lookup/enrichment operators, join/correlation operators, visualization operators, search UI features, built-in parsers, and example cheat sheets
- **`references/documentation/other/`** — Live Tail (real-time log streaming, CLI, filtering), LogReduce (pattern detection, keys, values, relevance), LogCompare, LogExplain, Lookup Tables (create, manage, update)

### Dependencies

- **`references/dependencies/`** — Dependency graph and analysis

---

**Generated by Skill Seeker** | Enhanced with multi-source synthesis from 214 documentation files

# Claude Code Instructions

### CONCURRENT TASK LIMIT

- **Maximum 5 background tasks running simultaneously**
- When launching multiple agents (e.g., for mass audits), batch them in
  groups of 5
- Wait for the current batch to complete before launching the next batch

------------------------------------------------------------------------

## CRITICAL DATA SOURCE RULES

**NEVER use Urban Institute API, NCES CCD, or ANY federal data source**
– the entire point of these packages is to provide STATE-LEVEL data
directly from state DOEs. Federal sources aggregate/transform data
differently and lose state-specific details. If a state DOE source is
broken, FIX IT or find an alternative STATE source – do not fall back to
federal data.

**NEVER fabricate data in ANY form.** This is the single most important
rule in the entire project. Violations include but are not limited to:

- **Random generation:**
  [`rnorm()`](https://rdrr.io/r/stats/Normal.html),
  [`runif()`](https://rdrr.io/r/stats/Uniform.html),
  [`set.seed()`](https://rdrr.io/r/base/Random.html),
  [`sample()`](https://rdrr.io/r/base/sample.html),
  [`rlnorm()`](https://rdrr.io/r/stats/Lognormal.html),
  [`rgamma()`](https://rdrr.io/r/stats/GammaDist.html), or any random
  number generation
- **Hardcoded numbers:** Hand-typing enrollment counts in
  [`tribble()`](https://tibble.tidyverse.org/reference/tribble.html),
  [`data.frame()`](https://rdrr.io/r/base/data.frame.html),
  [`tibble()`](https://tibble.tidyverse.org/reference/tibble.html), or
  any other data structure. If a human typed the number instead of
  downloading it from a state DOE, it is fabricated.
- **“Plausible-looking” fake data:** Creating numbers that look real but
  aren’t — smooth monotonic trends, round numbers, demographically
  “reasonable” percentages applied uniformly. This is the WORST form of
  fabrication because it is designed to deceive.
- **`create_example_data()` functions:** Helper functions that generate
  fake datasets, regardless of how realistic they look
- **Fixed demographic percentages:** Applying constant demographic
  ratios across all years/districts (real demographics change year to
  year)
- **Uniform grade distributions:** Using the same grade-level
  percentages for every district (real districts vary significantly)

**The test is simple: can you trace every number back to a downloaded
file from a state DOE website?** If not, it is fabricated. There is no
gray area. If the data source is unavailable, the package MUST use Under
Construction status — not fake data.

------------------------------------------------------------------------

### GIT COMMIT POLICY

- Commits are allowed
- NO Claude Code attribution, NO Co-Authored-By trailers, NO emojis
- Write normal commit messages as if a human wrote them

------------------------------------------------------------------------

## Local Testing Before PRs (REQUIRED)

**PRs will not be merged until CI passes.** Run these checks locally
BEFORE opening a PR:

### CI Checks That Must Pass

| Check        | Local Command                                                                  | What It Tests                                  |
|--------------|--------------------------------------------------------------------------------|------------------------------------------------|
| R-CMD-check  | `devtools::check()`                                                            | Package builds, tests pass, no errors/warnings |
| Python tests | `pytest tests/test_pymdschooldata.py -v`                                       | Python wrapper works correctly                 |
| pkgdown      | [`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html) | Documentation and vignettes render             |

### Quick Commands

``` r
# R package check (required)
devtools::check()

# Python tests (required)
system("pip install -e ./pymdschooldata && pytest tests/test_pymdschooldata.py -v")

# pkgdown build (required)
pkgdown::build_site()
```

### Pre-PR Checklist

Before opening a PR, verify: - \[ \] `devtools::check()` – 0 errors, 0
warnings - \[ \] `pytest tests/test_pymdschooldata.py` – all tests
pass - \[ \]
[`pkgdown::build_site()`](https://pkgdown.r-lib.org/reference/build_site.html)
– builds without errors - \[ \] Vignettes render (no `eval=FALSE` hacks)

------------------------------------------------------------------------

## LIVE Pipeline Testing

This package includes `tests/testthat/test-pipeline-live.R` with LIVE
network tests.

### Test Categories:

1.  URL Availability - HTTP 200 checks
2.  File Download - Verify actual file (not HTML error)
3.  File Parsing - readxl/readr succeeds
4.  Column Structure - Expected columns exist
5.  get_raw_enr() - Raw data function works
6.  Data Quality - No Inf/NaN, non-negative counts
7.  Aggregation - State total \> 0
8.  Output Fidelity - tidy=TRUE matches raw

### Running Tests:

``` r
devtools::test(filter = "pipeline-live")
```

See `state-schooldata/CLAUDE.md` for complete testing framework
documentation.

------------------------------------------------------------------------

## Git Workflow (REQUIRED)

### Feature Branch + PR + Auto-Merge Policy

**NEVER push directly to main.** All changes must go through PRs with
auto-merge:

``` bash
# 1. Create feature branch
git checkout -b fix/description-of-change

# 2. Make changes, commit
git add -A
git commit -m "Fix: description of change"

# 3. Push and create PR with auto-merge
git push -u origin fix/description-of-change
gh pr create --title "Fix: description" --body "Description of changes"
gh pr merge --auto --squash

# 4. Clean up stale branches after PR merges
git checkout main && git pull && git fetch --prune origin
```

### Branch Cleanup (REQUIRED)

**Clean up stale branches every time you touch this package:**

``` bash
# Delete local branches merged to main
git branch --merged main | grep -v main | xargs -r git branch -d

# Prune remote tracking branches
git fetch --prune origin
```

### Auto-Merge Requirements

PRs auto-merge when ALL CI checks pass: - R-CMD-check (0 errors, 0
warnings) - Python tests (if py{st}schooldata exists) - pkgdown build
(vignettes must render)

If CI fails, fix the issue and push - auto-merge triggers when checks
pass.

------------------------------------------------------------------------

## Valid Filter Values (tidy enrollment via `fetch_enr(tidy = TRUE)`)

### subgroup

`total_enrollment`

**NOTE:** Demographic subgroups (white, black, hispanic, asian, etc.)
are NOT available via automated download. The MSDE PDF parser produces
corrupted demographic data where subgroup counts exceed total
enrollment. Use the [Maryland Report
Card](https://reportcard.msde.maryland.gov/Graphs/#/Demographics/Enrollment)
for demographic breakdowns.

### grade_level

`TOTAL`, `K`, `01`-`12`

Grade columns are mapped from `grade_k` -\> `K`, `grade_01` -\> `01`,
etc. The
[`enr_grade_aggs()`](https://almartin82.github.io/mdschooldata/reference/enr_grade_aggs.md)
function adds computed aggregates: `K8`, `HS`, `K12`.

**NOTE:** `PK` (Prekindergarten) is not available in the MD Department
of Planning data.

### entity flags

`is_state`, `is_district`, `is_campus`

The `type` column has values `State`, `District`, and `Campus`. The
[`id_enr_aggs()`](https://almartin82.github.io/mdschooldata/reference/id_enr_aggs.md)
function creates boolean flags.

------------------------------------------------------------------------

## Data Source Architecture

### Enrollment Data

- **Primary source:** Maryland Department of Planning (MDP)
  - URL:
    <https://planning.maryland.gov/MSDC/Documents/school_enrollment/>
  - Years: 2014-2024
  - Contains: Grade-level enrollment (K-12) for state and 24
    jurisdictions
  - Reliable, well-structured Excel files
- **NOT used:** MSDE PDF publications
  - The MSDE publishes enrollment PDFs with race/ethnicity breakdowns
  - PDF parsing is unreliable: creates multiple rows per entity with
    incorrect demographic values
  - Demographic counts can exceed total enrollment (e.g., white=165K for
    a district with 155K total)
  - The
    [`get_raw_enr()`](https://almartin82.github.io/mdschooldata/reference/get_raw_enr.md)
    function no longer falls back to MSDE PDFs

### Assessment Data

- **Statewide proficiency:** Hardcoded from MSDE State Board
  presentations (2022-2024)
- **Participation data:** Downloaded from Maryland Report Card
  (2022-2024)

------------------------------------------------------------------------

## README Images from Vignettes (REQUIRED)

**NEVER use `man/figures/` or `generate_readme_figs.R` for README
images.**

README images MUST come from pkgdown-generated vignette output so they
auto-update on merge:

``` markdown
![Chart name](https://almartin82.github.io/{package}/articles/{vignette}_files/figure-html/{chunk-name}-1.png)
```

**Why:** Vignette figures regenerate automatically when pkgdown builds.
Manual `man/figures/` requires running a separate script and is easy to
forget, causing stale/broken images.

------------------------------------------------------------------------

## README and Vignette Code Matching (REQUIRED)

**CRITICAL RULE:** ALL code blocks in the README MUST match code in a
vignette EXACTLY (1:1 correspondence).

### Why This Matters

The Idaho fix revealed critical bugs when README code didn’t match
vignettes: - Wrong district names (lowercase vs ALL CAPS) - Text claims
that contradicted actual data - Missing data output in examples

### README Story Structure (REQUIRED)

Every story/section in the README MUST follow this structure:

1.  **Claim**: A factual statement about the data
2.  **Explication**: Brief explanation of why this matters
3.  **Code**: R code that fetches and analyzes the data (MUST exist in a
    vignette)
4.  **Code Output**: Data table/print statement showing actual values
    (REQUIRED)
5.  **Visualization**: Chart from vignette (auto-generated from pkgdown)

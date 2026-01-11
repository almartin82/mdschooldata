# Fetch assessment data for multiple years

Downloads and combines assessment data for multiple school years.

## Usage

``` r
fetch_assessment_multi(
  years,
  subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
  student_group = c("all", "groups"),
  use_cache = TRUE
)
```

## Arguments

- years:

  Vector of school year ends (e.g., c(2021, 2022, 2023, 2024))

- subject:

  Assessment subject: "all" (default), "ELA", "Math", "Science", or
  "SocialStudies"

- student_group:

  "all" (default) for all students, or "groups" for student group
  breakdowns

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with combined assessment data for all requested years

## Details

Combines assessment data from multiple years into a single data frame.
Each row includes the `end_year` column for filtering and analysis.

This is useful for:

- Trend analysis across years

- Pre/post-COVID comparisons

- Year-over-year growth calculations

## See also

[`fetch_assessment`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment.md)
for single year data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get MCAP data for all available years
assess_all <- fetch_assessment_multi(2021:2024)

# Get ELA data for multiple years
assess_ela <- fetch_assessment_multi(2021:2024, subject = "ELA")

# Calculate 3-year trend
library(dplyr)

assess_all %>%
  filter(is_state, subject == "ELA", grade == "03") %>%
  group_by(end_year) %>%
  summarize(avg_proficient = mean(pct_proficient, na.rm = TRUE))
} # }
```

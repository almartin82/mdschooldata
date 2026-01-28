# Fetch assessment data for multiple years

Downloads and combines assessment data for multiple school years.

## Usage

``` r
fetch_assessment_multi(
  years,
  data_type = c("participation", "proficiency"),
  use_cache = TRUE
)
```

## Arguments

- years:

  Vector of school year ends (e.g., c(2022, 2023, 2024))

- data_type:

  Type of data: "participation" (default) or "proficiency"

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with combined assessment data for all requested years

## Details

Combines assessment data from multiple years into a single data frame.
Each row includes the `end_year` column for filtering and analysis.

This is useful for:

- Trend analysis across years

- Post-COVID recovery tracking

- Year-over-year comparisons

## See also

[`fetch_assessment`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment.md)
for single year data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get MCAP data for all available years
assess_all <- fetch_assessment_multi(2022:2024)

# Calculate participation trends by district
library(dplyr)

assess_all |>
  filter(is_district, student_group == "All Students", subject == "English/Language Arts") |>
  select(end_year, district_name, participation_pct) |>
  pivot_wider(names_from = end_year, values_from = participation_pct)
} # }
```

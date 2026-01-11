# Get available assessment years

Returns the range of years for which assessment data is available.

## Usage

``` r
get_available_assessment_years()
```

## Value

List with elements:

- `min_year`: First year with assessment data

- `max_year`: Most recent year with assessment data

- `available_years`: Vector of all available years

- `assessments`: Named list of assessment types by year range

## Examples

``` r
if (FALSE) { # \dontrun{
# Check available years
get_available_assessment_years()

# Output:
# $min_year
# [1] 2021
#
# $max_year
# [1] 2025
#
# $available_years
# [1] 2021 2022 2023 2024 2025
#
# $assessments
# $assessments$MCAP
# [1] "2021-2025: ELA, Math, Science, Social Studies"
} # }
```

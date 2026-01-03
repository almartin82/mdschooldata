# Fetch historical enrollment from MD Planning

Downloads enrollment data for multiple years from the Maryland
Department of Planning. This is useful for longitudinal analysis.

## Usage

``` r
fetch_historical_enrollment(start_year, end_year, include_demographics = TRUE)
```

## Arguments

- start_year:

  First school year end to fetch

- end_year:

  Last school year end to fetch

- include_demographics:

  Whether to include MSDE demographic data

## Value

Data frame with enrollment for all requested years

## Examples

``` r
if (FALSE) { # \dontrun{
# Get enrollment from 2014 to 2024
historical <- fetch_historical_enrollment(2014, 2024)

# Get enrollment for specific years without demographics
recent <- fetch_historical_enrollment(2020, 2024, include_demographics = FALSE)
} # }
```

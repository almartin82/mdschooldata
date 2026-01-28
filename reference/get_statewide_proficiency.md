# Get statewide proficiency summary (from MSDE press releases)

Returns statewide MCAP proficiency rates from official MSDE
publications. This data is manually curated from State Board
presentations and press releases.

## Usage

``` r
get_statewide_proficiency(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Data frame with statewide proficiency rates by subject

## Details

This provides verified statewide proficiency data from MSDE official
sources. For school/district-level proficiency data, use the Maryland
Report Card interactive interface at
https://reportcard.msde.maryland.gov.

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 statewide proficiency
state_prof <- get_statewide_proficiency(2024)
} # }
```

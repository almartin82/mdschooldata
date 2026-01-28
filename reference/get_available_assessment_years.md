# Get available assessment years

Returns the range of years for which assessment data is available.

## Usage

``` r
get_available_assessment_years()
```

## Value

List with elements:

- `min_year`: First year with MCAP data

- `max_year`: Most recent year with MCAP data

- `available_years`: Vector of all available years

- `assessments`: Named list of assessment types by year range

- `data_types`: Available data types and their access methods

## Examples

``` r
if (FALSE) { # \dontrun{
# Check available years
get_available_assessment_years()
} # }
```

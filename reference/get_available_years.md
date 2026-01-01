# Get available years for Maryland enrollment data

Returns the range of school years for which enrollment data is available
from the Maryland State Department of Education.

## Usage

``` r
get_available_years()
```

## Value

Named list with min_year, max_year, and available years vector

## Examples

``` r
if (FALSE) { # \dontrun{
years <- get_available_years()
print(years$available)
} # }
```

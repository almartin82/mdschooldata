# Get available years for Maryland enrollment data

Returns the range of school years for which enrollment data is available
from Maryland state sources. Uses Maryland Department of Planning data
for historical years (2014+) and MSDE for demographic breakdowns
(2019+).

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

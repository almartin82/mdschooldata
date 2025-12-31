# Convert to numeric, handling suppression markers

MSDE uses various markers for suppressed data (\*, \<, \>, etc.) and may
use commas in large numbers.

## Usage

``` r
safe_numeric(x)
```

## Arguments

- x:

  Vector to convert

## Value

Numeric vector with NA for non-numeric values

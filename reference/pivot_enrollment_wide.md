# Pivot enrollment data from long to wide format

Takes disaggregated enrollment data and pivots it to have one row per
entity with demographic columns.

## Usage

``` r
pivot_enrollment_wide(data, entity_type)
```

## Arguments

- data:

  Long-format enrollment data

- entity_type:

  "District" or "Campus"

## Value

Wide-format data frame

# Process disaggregated enrollment data format

Handles enrollment data with one row per combination of entity, race,
and sex. This function pivots that data into wide format with
demographic columns.

## Usage

``` r
process_disaggregated_enrollment(raw_data, end_year)
```

## Arguments

- raw_data:

  Raw data frame with race/sex disaggregation

- end_year:

  School year end

## Value

Processed data frame in wide format

## Details

Note: This function handles data that may have 'race' and 'sex' columns
in a disaggregated format (one row per demographic combination).

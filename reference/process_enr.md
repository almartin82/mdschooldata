# Process raw enrollment data from MSDE

Transforms raw enrollment data from MSDE sources into a standardized
schema with wide demographic columns.

## Usage

``` r
process_enr(raw_data, end_year)
```

## Arguments

- raw_data:

  Raw data frame from get_raw_enr

- end_year:

  School year end

## Value

Processed data frame with standardized columns

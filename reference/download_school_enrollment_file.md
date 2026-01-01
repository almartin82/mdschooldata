# Download school enrollment Excel file (if available)

Attempts to download school enrollment data in Excel format. This is
experimental as MSDE does not consistently publish Excel files.

## Usage

``` r
download_school_enrollment_file(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Path to downloaded file, or NULL if not available

# Download Maryland Report Card enrollment data

Attempts to fetch enrollment data from the Maryland Report Card website.
This function handles the web interaction required to download data.

## Usage

``` r
download_md_reportcard_enrollment(end_year)
```

## Arguments

- end_year:

  School year end

## Value

Data frame with enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
enr <- download_md_reportcard_enrollment(2024)
} # }
```

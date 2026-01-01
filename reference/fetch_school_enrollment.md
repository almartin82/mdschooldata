# Fetch school-level enrollment

Downloads school-level enrollment data for Maryland. Note: School-level
data is primarily available through the Report Card website and may
require manual download.

## Usage

``` r
fetch_school_enrollment(end_year, lss_code = NULL)
```

## Arguments

- end_year:

  School year end

- lss_code:

  Optional LSS code to filter results

## Value

Data frame with school enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all school enrollment
schools <- fetch_school_enrollment(2024)

# Get schools in Montgomery County (LSS 16)
montgomery <- fetch_school_enrollment(2024, "16")
} # }
```

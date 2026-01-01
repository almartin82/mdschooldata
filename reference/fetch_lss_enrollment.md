# Fetch enrollment for a specific LSS (district)

Downloads enrollment data for a specific Local School System.

## Usage

``` r
fetch_lss_enrollment(end_year, lss_code)
```

## Arguments

- end_year:

  School year end

- lss_code:

  2-digit LSS code (e.g., "01" for Allegany)

## Value

Data frame with LSS enrollment data

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Baltimore City enrollment (LSS code 03)
baltimore <- fetch_lss_enrollment(2024, "03")
} # }
```

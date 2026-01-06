# Fetch Maryland school directory

Downloads and processes the Maryland school directory.

## Usage

``` r
fetch_directory(directory_type = "all", use_cache = TRUE)
```

## Arguments

- directory_type:

  Type of directory to fetch ("charter_schools" or "all")

- use_cache:

  If TRUE, use cached data if available (default: TRUE)

## Value

Data frame with school directory information

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all charter schools
directory <- fetch_directory()

# Get only charter schools
charter <- fetch_directory("charter_schools")

# Filter by county
baltimore_schools <- directory |>
  dplyr::filter(county == "Baltimore City")
} # }
```

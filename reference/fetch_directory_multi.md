# Fetch multiple directory types

Convenience function for fetching multiple directory types at once.

## Usage

``` r
fetch_directory_multi(directory_types = c("charter_schools"), use_cache = TRUE)
```

## Arguments

- directory_types:

  Character vector of directory types to fetch

- use_cache:

  If TRUE, use cached data if available (default: TRUE)

## Value

Data frame with combined directory information

## Examples

``` r
if (FALSE) { # \dontrun{
# Get all available directory types
all_directories <- fetch_directory_multi()

# Get specific types
schools <- fetch_directory_multi(c("charter_schools"))
} # }
```

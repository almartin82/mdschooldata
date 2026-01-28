# Fetch assessment data for a specific school

Convenience function to fetch assessment data for a single school.

## Usage

``` r
fetch_school_assessment(
  end_year,
  district_id,
  school_id,
  data_type = "participation",
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end

- district_id:

  2-digit district code

- school_id:

  4-digit school code

- data_type:

  Type of data: "participation" (default) or "proficiency"

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified school

## Examples

``` r
if (FALSE) { # \dontrun{
# Get a specific school's data
school <- fetch_school_assessment(2024, "16", "0101")
} # }
```

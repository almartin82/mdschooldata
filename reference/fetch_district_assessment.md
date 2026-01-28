# Fetch assessment data for a specific district

Convenience function to fetch assessment data for a single district
(LEA).

## Usage

``` r
fetch_district_assessment(
  end_year,
  district_id,
  data_type = "participation",
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end

- district_id:

  2-digit district code (e.g., "03" for Baltimore City)

- data_type:

  Type of data: "participation" (default) or "proficiency"

- use_cache:

  If TRUE (default), uses cached data

## Value

Data frame filtered to specified district

## Examples

``` r
if (FALSE) { # \dontrun{
# Get Baltimore City (district 03) data
baltimore <- fetch_district_assessment(2024, "03")

# Get Montgomery County (district 16) data
montgomery <- fetch_district_assessment(2024, "16")
} # }
```

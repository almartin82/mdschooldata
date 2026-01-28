# Get available MCAP data file URLs

Returns URLs for available MCAP data files on the Maryland Report Card.
Currently only participation rate data is available via direct download.

## Usage

``` r
get_mcap_data_urls(end_year, data_type = "participation")
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24)

- data_type:

  Type of data: "participation" (available) or "proficiency" (requires
  manual download)

## Value

Named list with URLs and metadata

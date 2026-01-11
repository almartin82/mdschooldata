# Download assessment data from Maryland Report Card

Attempts to download assessment data from the Maryland Report Card
system. The Report Card uses dynamic URLs, so this function tries
multiple strategies.

## Usage

``` r
download_assessment_data(end_year, subject, student_group)
```

## Arguments

- end_year:

  School year end

- subject:

  Assessment subject

- student_group:

  Student group filter

## Value

Data frame with assessment data, or empty data frame on failure

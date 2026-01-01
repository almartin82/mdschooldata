# Parse MSDE enrollment PDF publication

Extracts enrollment data from MSDE PDF publications. These PDFs contain
tables with enrollment by LSS, race/ethnicity, and gender.

## Usage

``` r
parse_msde_enrollment_pdf(pdf_path, end_year)
```

## Arguments

- pdf_path:

  Path to downloaded PDF file

- end_year:

  School year end

## Value

Data frame with enrollment data

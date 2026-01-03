# Parse MD Planning enrollment Excel file

Parses the 3-Public-School-Enrollment.xlsx file from MD Planning. The
file has a complex structure with blocks for each jurisdiction.

## Usage

``` r
parse_mdp_enrollment_xlsx(xlsx_path, end_year)
```

## Arguments

- xlsx_path:

  Path to the Excel file

- end_year:

  The school year end to extract

## Value

Data frame with enrollment data

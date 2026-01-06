# Download raw enrollment data for Maryland

Downloads enrollment data from Maryland state sources. Uses Maryland
Department of Planning for historical data (2014-present) with
grade-level enrollment, and MSDE publications for demographic breakdowns
(2019+).

## Usage

``` r
get_raw_enr(end_year, include_demographics = FALSE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

- include_demographics:

  Logical, whether to try to fetch demographic data from MSDE
  (race/ethnicity, gender). Default FALSE due to PDF parsing issues. Set
  to TRUE to attempt fetching (may return incorrect data).

## Value

Data frame with raw enrollment data

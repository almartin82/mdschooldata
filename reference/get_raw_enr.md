# Download raw enrollment data for Maryland

Downloads enrollment data from Maryland state sources. Uses Maryland
Department of Planning for historical data (2014-present) with
grade-level enrollment, and MSDE publications for demographic breakdowns
(2019+).

## Usage

``` r
get_raw_enr(end_year, include_demographics = TRUE)
```

## Arguments

- end_year:

  School year end (2023-24 = 2024)

- include_demographics:

  Logical, whether to try to fetch demographic data from MSDE
  (race/ethnicity, gender). Default TRUE for years 2019+.

## Value

Data frame with raw enrollment data

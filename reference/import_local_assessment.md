# Import locally downloaded assessment file

Imports an assessment data file that was manually downloaded from the
Maryland Report Card website.

## Usage

``` r
import_local_assessment(file_path, end_year)
```

## Arguments

- file_path:

  Path to the CSV file downloaded from Maryland Report Card

- end_year:

  School year end (e.g., 2024 for 2023-24 school year)

## Value

Data frame with assessment results

## Examples

``` r
if (FALSE) { # \dontrun{
# Import a manually downloaded assessment file
assess_data <- import_local_assessment(
  file_path = "~/Downloads/MD_Assessment_2024.csv",
  end_year = 2024
)

# View the data
head(assess_data)
} # }
```

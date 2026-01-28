# Import locally downloaded assessment file

Imports an assessment data file that was manually downloaded from the
Maryland Report Card website.

## Usage

``` r
import_local_assessment(
  file_path,
  end_year,
  data_type = c("proficiency", "participation")
)
```

## Arguments

- file_path:

  Path to the Excel or CSV file

- end_year:

  School year end (e.g., 2024 for 2023-24)

- data_type:

  Type of data: "participation" or "proficiency"

## Value

Data frame with assessment results

## Details

Use this function when you have manually downloaded assessment data from
the Maryland Report Card at https://reportcard.msde.maryland.gov.

For proficiency data, navigate to: Graphs \> Data Downloads \> Academic
Achievement or Assessment Results

## Examples

``` r
if (FALSE) { # \dontrun{
# Import a manually downloaded file
assess_data <- import_local_assessment(
  file_path = "~/Downloads/MCAP_ELA_2024.xlsx",
  end_year = 2024,
  data_type = "proficiency"
)
} # }
```

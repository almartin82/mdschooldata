# Download raw Maryland assessment data

Downloads assessment data from the Maryland Report Card system.
Currently provides MCAP participation rate data for 2022-present.
Proficiency data requires manual download from the Report Card
interface.

## Usage

``` r
get_raw_assessment(end_year, data_type = c("participation", "proficiency"))
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Valid range:
  2022-2025 for MCAP participation data.

- data_type:

  Type of data: "participation" (default, available via URL) or
  "proficiency" (requires manual download)

## Value

Data frame with assessment data including:

- School and district identifiers

- Assessment type (ELA, Math, Science)

- Student group breakdowns

- Participation rates (for participation data)

## Details

### Available Years:

- 2022-2024: MCAP participation rate data

- 2025: Expected when released (typically August/September)

### Data Source:

Maryland Report Card (MSDE): https://reportcard.msde.maryland.gov/

### Limitation:

The Maryland Report Card uses JavaScript to generate download links for
proficiency data, making automated downloads challenging. Use the
interactive Report Card interface or contact MSDE for bulk proficiency
data.

## See also

[`fetch_assessment`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment.md)
for the main user-facing function
[`import_local_assessment`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md)
for loading manually downloaded files

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 2024 MCAP participation data
assess_2024 <- get_raw_assessment(2024)

# View available student groups
unique(assess_2024$student_group)
} # }
```

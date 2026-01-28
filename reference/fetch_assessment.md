# Fetch Maryland assessment data

Downloads and returns assessment data from the Maryland State Department
of Education Maryland Report Card. Includes MCAP participation data
(2022-present) for grades 3-8 and high school in ELA, Mathematics, and
Science.

## Usage

``` r
fetch_assessment(
  end_year,
  data_type = c("participation", "proficiency"),
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Valid range:
  2022-2024 for participation data.

- data_type:

  Type of data: "participation" (default, available via direct download)
  or "proficiency" (requires manual download).

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data including:

- School, district, and state identifiers

- Subject (ELA, Mathematics, Science)

- Student group breakdowns

- Participation rates (for participation data)

- Helper columns: is_state, is_district, is_school

## Details

### Available Years:

- 2022-2024: MCAP participation rate data (direct download)

- 2025: Available when released (typically August/September)

### Assessment Types:

- ELA: Grades 3-8 and 10

- Mathematics: Grades 3-8, Algebra I, Algebra II, Geometry

- Science: Grades 5, 8, and High School

### Data Source:

Maryland Report Card (MSDE): https://reportcard.msde.maryland.gov/

### Proficiency Data Note:

The Maryland Report Card uses JavaScript to generate download links for
proficiency data. For proficiency rates, use the interactive Report Card
interface or
[`get_statewide_proficiency`](https://almartin82.github.io/mdschooldata/reference/get_statewide_proficiency.md)
for state-level data.

## See also

[`fetch_assessment_multi`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment_multi.md)
for multiple years
[`get_statewide_proficiency`](https://almartin82.github.io/mdschooldata/reference/get_statewide_proficiency.md)
for statewide proficiency rates
[`import_local_assessment`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md)
for manually downloaded files

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 participation data
assess_2024 <- fetch_assessment(2024)

# Filter to Baltimore City schools
baltimore <- assess_2024 |>
  dplyr::filter(district_name == "Baltimore City", is_school)

# Get statewide proficiency rates (curated data)
state_prof <- get_statewide_proficiency(2024)

# Force fresh download (ignore cache)
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
} # }
```

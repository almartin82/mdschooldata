# Fetch Maryland assessment data

Downloads and returns assessment data from the Maryland State Department
of Education Maryland Report Card. Includes MCAP (2021-present) for
grades 3-8 and high school in ELA, Mathematics, and Science.

## Usage

``` r
fetch_assessment(
  end_year,
  subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
  student_group = c("all", "groups"),
  use_cache = TRUE
)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Valid range:
  2021-2024.

- subject:

  Assessment subject: "all" (default), "ELA", "Math", "Science", or
  "SocialStudies"

- student_group:

  "all" (default) for all students, or "groups" for student group
  breakdowns

- use_cache:

  If TRUE (default), uses locally cached data when available.

## Value

Data frame with assessment data including:

- School, district, and state identifiers

- Grade level and subject

- Proficiency rates and counts

- Student group breakdowns (if student_group = "groups")

- Helper columns: is_state, is_district, is_school

## Details

### Available Years:

- 2021-2024: MCAP data (Maryland Comprehensive Assessment Program)

- 2025: MCAP data (when available)

### Assessment Types by Year:

- 2021-2023: MCAP ELA and Math (grades 3-8, HS), Science (grades 5, 8,
  HS)

- 2024+: MCAP ELA, Math, Science, and Social Studies (grades 3-8, HS)

### Data Source:

Maryland Report Card (MSDE):
https://reportcard.msde.maryland.gov/Graphs/

The Maryland Report Card uses dynamic JavaScript to generate download
links. If automated download fails, the function provides clear
instructions for manual download and loading via
[`import_local_assessment`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md).

## See also

[`fetch_assessment_multi`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment_multi.md)
for multiple years
[`import_local_assessment`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md)
for manually downloaded files

## Examples

``` r
if (FALSE) { # \dontrun{
# Get 2024 assessment data (all subjects)
assess_2024 <- fetch_assessment(2024)

# Get only ELA results
assess_2024_ela <- fetch_assessment(2024, subject = "ELA")

# Get with student group breakdowns
assess_2024_groups <- fetch_assessment(2024, student_group = "groups")

# Force fresh download (ignore cache)
assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
} # }
```

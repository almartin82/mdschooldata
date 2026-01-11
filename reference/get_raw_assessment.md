# Download raw Maryland assessment data

Downloads assessment data from the Maryland Report Card system. Includes
MCAP (2021-present) for grades 3-8 and high school in ELA, Mathematics,
and Science.

## Usage

``` r
get_raw_assessment(
  end_year,
  subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
  student_group = c("all", "groups")
)
```

## Arguments

- end_year:

  School year end (e.g., 2024 for 2023-24 school year). Valid range:
  2021-2024 for MCAP data.

- subject:

  Assessment subject: "all" (default), "ELA", "Math", "Science", or
  "SocialStudies"

- student_group:

  "all" (default) for all students, or "groups" for student group
  breakdowns

## Value

Data frame with assessment results including school/district/state
aggregations, proficiency rates, and student group breakdowns

## Details

### Available Years:

- 2021-2024: MCAP data (Maryland Comprehensive Assessment Program)

### Data Source:

Maryland Report Card (MSDE):
https://reportcard.msde.maryland.gov/Graphs/

The Maryland Report Card uses dynamic JavaScript to generate download
links, making automated downloads challenging. This function provides:

1.  Documentation for manual download workflow

2.  Automated download if URL pattern can be discovered

3.  Fallback to import_local_assessment() for manual loading

## See also

[`fetch_assessment`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment.md)
for the complete fetch pipeline
[`import_local_assessment`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md)
for loading manually downloaded files

## Examples

``` r
if (FALSE) { # \dontrun{
# Download 2024 MCAP data (all subjects)
assess_2024 <- get_raw_assessment(2024)

# Download only ELA results
assess_2024_ela <- get_raw_assessment(2024, subject = "ELA")

# Download with student group breakdowns
assess_2024_groups <- get_raw_assessment(2024, student_group = "groups")
} # }
```

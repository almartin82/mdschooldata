# mdschooldata

Download and analyze Maryland public school enrollment data from the Maryland State Department of Education (MSDE).

## Installation

```r
# Install from GitHub
remotes::install_github("almartin82/mdschooldata")
```

## Quick Start

```r
library(mdschooldata)

# Get 2024 enrollment data (2023-24 school year)
enr <- fetch_enr(2024)

# View state totals
enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Get wide format data
enr_wide <- fetch_enr(2024, tidy = FALSE)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)
```

## Data Availability

### Years Available

| Era | Years | Source | Notes |
|-----|-------|--------|-------|
| Maryland Report Card | 2018-present | API/Downloads | Full coverage |
| Legacy | 2003-2017 | MSDE Archives | Limited availability |

**Current Support**: This package currently supports data from **2018 onwards** via the Maryland Report Card system.

### Geographic Coverage

Maryland has 24 Local School Systems (LSS):
- 23 counties (Allegany through Worcester)
- Baltimore City (separate from Baltimore County)

Data is available at three levels:
- **State**: Maryland statewide totals
- **District**: 24 Local School Systems
- **School**: Individual schools (~1,400 public schools)

### Demographics Available

| Category | Available | Notes |
|----------|-----------|-------|
| Race/Ethnicity | Yes | White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial |
| Gender | Yes | Male, Female |
| Grade Level | Yes | PK through 12 |
| Special Populations | Limited | Varies by year |

### Known Caveats

1. **Race/ethnicity by grade**: Detailed race/ethnicity by grade level is only available from 2020 onwards. Earlier years have totals only.

2. **School-level data**: School-level demographic breakdowns may have more suppressions due to small cell sizes.

3. **September 30 counts**: Enrollment is based on September 30 official count dates.

4. **Nonpublic schools**: This package covers public schools only. Nonpublic school data is collected separately by MSDE.

5. **Pre-K categories**: Prekindergarten categories have changed over time (e.g., "Prekindergarten Age 4" vs "Prekindergarten").

## Data Sources

- **Maryland Report Card**: https://reportcard.msde.maryland.gov/
- **MSDE Research Branch**: https://marylandpublicschools.org/about/Pages/ORSDU/index.aspx
- **Enrollment Publications**: https://marylandpublicschools.org/about/Pages/DCAA/SSP/StudentStaff.aspx

## Maryland ID System

### Local School System (LSS) Codes

Maryland uses 2-digit codes for its 24 school systems:

| Code | LSS Name |
|------|----------|
| 01 | Allegany |
| 02 | Anne Arundel |
| 03 | Baltimore City |
| 04 | Baltimore County |
| 05 | Calvert |
| 06 | Caroline |
| 07 | Carroll |
| 08 | Cecil |
| 09 | Charles |
| 10 | Dorchester |
| 11 | Frederick |
| 12 | Garrett |
| 13 | Harford |
| 14 | Howard |
| 15 | Kent |
| 16 | Montgomery |
| 17 | Prince George's |
| 18 | Queen Anne's |
| 19 | St. Mary's |
| 20 | Somerset |
| 21 | Talbot |
| 22 | Washington |
| 23 | Wicomico |
| 24 | Worcester |

### School Numbers

Schools are identified by their LSS code plus a 4-digit school number. For example:
- `160023` = School 0023 in Montgomery County (16)

## Functions

### Main Functions

- `fetch_enr(end_year)` - Download enrollment data for a single year
- `fetch_enr_multi(end_years)` - Download enrollment data for multiple years
- `tidy_enr(df)` - Convert wide data to tidy (long) format
- `id_enr_aggs(df)` - Add aggregation level flags
- `enr_grade_aggs(df)` - Create K-8, HS, K-12 aggregates
- `get_available_years()` - List available years

### Cache Functions

- `cache_status()` - View cached data
- `clear_cache()` - Remove cached data

## Output Schema

### Wide Format (tidy = FALSE)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end (2024 = 2023-24) |
| type | character | "State", "District", or "Campus" |
| district_id | character | 2-digit LSS code |
| campus_id | character | School identifier |
| district_name | character | LSS name |
| campus_name | character | School name |
| row_total | integer | Total enrollment |
| white | integer | White students |
| black | integer | Black/African American students |
| hispanic | integer | Hispanic/Latino students |
| asian | integer | Asian students |
| pacific_islander | integer | Native Hawaiian/Pacific Islander |
| native_american | integer | American Indian/Alaska Native |
| multiracial | integer | Two or more races |
| male | integer | Male students |
| female | integer | Female students |
| grade_pk through grade_12 | integer | Grade-level enrollment |

### Tidy Format (tidy = TRUE, default)

| Column | Type | Description |
|--------|------|-------------|
| end_year | integer | School year end |
| type | character | Aggregation level |
| district_id | character | LSS code |
| campus_id | character | School identifier |
| district_name | character | LSS name |
| campus_name | character | School name |
| grade_level | character | "TOTAL", "PK", "K", "01"-"12" |
| subgroup | character | Demographic category |
| n_students | integer | Student count |
| pct | numeric | Percentage (0-1 scale) |
| is_state | logical | State-level row |
| is_district | logical | District-level row |
| is_campus | logical | School-level row |

## Examples

### Enrollment Trends

```r
library(mdschooldata)
library(dplyr)
library(ggplot2)

# Get state enrollment over time
enr <- fetch_enr_multi(2018:2024)

state_totals <- enr %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)

ggplot(state_totals, aes(x = end_year, y = n_students)) +
  geom_line() +
  geom_point() +
  scale_y_continuous(labels = scales::comma) +
  labs(
    title = "Maryland Public School Enrollment",
    x = "School Year End",
    y = "Total Students"
  )
```

### District Comparison

```r
# Compare largest districts
enr_2024 <- fetch_enr(2024)

largest <- enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(5)

print(largest)
```

### Demographic Analysis

```r
# Race/ethnicity breakdown
demographics <- enr_2024 %>%
  filter(
    is_state,
    grade_level == "TOTAL",
    subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")
  ) %>%
  select(subgroup, n_students, pct)

print(demographics)
```

## Related Packages

- [marylandedu](https://elipousson.github.io/marylandedu/) - Additional Maryland education data
- [educationdata](https://urbaninstitute.github.io/education-data-package-r/) - Urban Institute education data API

## License

MIT

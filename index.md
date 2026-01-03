# mdschooldata

**[Documentation](https://almartin82.github.io/mdschooldata/)** \|
**[Getting
Started](https://almartin82.github.io/mdschooldata/articles/quickstart.html)**
\| **[Enrollment
Trends](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html)**

Fetch and analyze Maryland school enrollment data from the Maryland
State Department of Education (MSDE) in R or Python.

## What can you find with mdschooldata?

**15+ years of enrollment data (2009-2024).** 890,000 students. 24 local
school systems. Here are ten stories hiding in the numbers - see the
full analysis with interactive visualizations in our [Enrollment
Trends](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html)
vignette:

1.  [Montgomery County is bigger than most
    states](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#montgomery-county-is-bigger-than-most-states) -
    With over 160,000 students, Montgomery County Public Schools is the
    largest district in Maryland
2.  [Prince George’s and Montgomery: A tale of two
    counties](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#prince-georges-and-montgomery-a-tale-of-two-counties) -
    Similar size, very different demographics
3.  [Baltimore City’s enrollment
    freefall](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#baltimore-citys-enrollment-freefall) -
    Lost over 15,000 students in a decade
4.  [Maryland is a majority-minority
    state](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#maryland-is-a-majority-minority-state) -
    White students now under 40% of enrollment
5.  [The Eastern Shore tells a different
    story](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#the-eastern-shore-tells-a-different-story) -
    Rural counties losing students faster than state average
6.  [Kindergarten dipped during
    COVID](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#kindergarten-dipped-during-covid) -
    Maryland lost 8% of kindergartners in 2021
7.  [Howard County: Suburban success
    story](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#howard-county-suburban-success-story) -
    A model of suburban diversity
8.  [Western Maryland’s
    struggle](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#allegany-and-garrett-western-marylands-struggle) -
    Allegany and Garrett counties lost over 20% of students
9.  [Anne Arundel holds
    steady](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#anne-arundel-holds-steady) -
    Maintaining stability while others fluctuate
10. [The I-95 corridor
    dominates](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html#the-i-95-corridor-dominates) -
    Five counties enroll over 70% of all students

------------------------------------------------------------------------

## Installation

``` r
# install.packages("remotes")
remotes::install_github("almartin82/mdschooldata")
```

## Quick start

### R

``` r
library(mdschooldata)
library(dplyr)

# Fetch one year
enr_2024 <- fetch_enr(2024)

# Fetch multiple years
enr_multi <- fetch_enr_multi(2020:2024)

# State totals
enr_2024 %>%
  filter(is_state, subgroup == "total_enrollment", grade_level == "TOTAL")

# Compare largest districts
enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  head(10)

# Demographics by county
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(district_name, subgroup, n_students, pct)
```

### Python

``` python
import pymdschooldata as md

# Fetch one year
enr_2024 = md.fetch_enr(2024)

# Fetch multiple years
enr_multi = md.fetch_enr_multi([2020, 2021, 2022, 2023, 2024])

# State totals
state_total = enr_2024[
    (enr_2024['is_state'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
]

# Compare largest districts
districts = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['subgroup'] == 'total_enrollment') &
    (enr_2024['grade_level'] == 'TOTAL')
].sort_values('n_students', ascending=False).head(10)

# Demographics by county
demographics = enr_2024[
    (enr_2024['is_district'] == True) &
    (enr_2024['grade_level'] == 'TOTAL') &
    (enr_2024['subgroup'].isin(['white', 'black', 'hispanic', 'asian']))
][['district_name', 'subgroup', 'n_students', 'pct']]
```

## Data availability

| Years         | Source                                 | Notes                           |
|---------------|----------------------------------------|---------------------------------|
| **2019-2024** | Maryland State Department of Education | Full coverage with demographics |

Data is sourced from the Maryland State Department of Education
(MSDE): - Maryland Report Card: <https://reportcard.msde.maryland.gov> -
MSDE Publications:
<https://marylandpublicschools.org/about/Pages/DCAA/SSP/>

### What’s included

- **Levels:** State, District (24 Local School Systems), School (~1,400)
- **Demographics:** White, Black, Hispanic, Asian, Native American,
  Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Grade levels:** PK through 12

### Maryland-specific notes

- Maryland has exactly **24 Local School Systems** (LSS) - one per
  county plus Baltimore City
- **LSS Codes:** 2-digit codes (01 = Allegany through 24 = Worcester)
- **Baltimore City** (03) is separate from **Baltimore County** (04)
- **Enrollment date:** September 30 official counts

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT

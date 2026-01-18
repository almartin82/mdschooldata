# mdschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/mdschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/mdschooldata/)** | **[Enrollment Trends](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html)**

Fetch and analyze Maryland school enrollment data from the Maryland State Department of Education (MSDE) in R or Python.

Part of the **[State Schooldata Project](https://github.com/almartin82/njschooldata)** - providing simple, consistent interfaces for accessing state-published school data. Originally inspired by [njschooldata](https://github.com/almartin82/njschooldata).

## What can you find with mdschooldata?

**10 years of enrollment data (2016-2025).** 890,000 students. 24 local school systems. Here are fifteen stories hiding in the numbers:

---

### 1. Montgomery County is bigger than most states

With over 160,000 students, Montgomery County Public Schools is the largest district in Maryland and among the top 20 in the nation. The district alone has more students than entire states like Wyoming or Vermont.

```r
library(mdschooldata)
library(dplyr)

# Helper function to get unique district totals
get_district_totals <- function(df) {
  df %>%
    filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
    select(end_year, district_name, n_students) %>%
    distinct() %>%
    group_by(end_year, district_name) %>%
    slice_max(n_students, n = 1, with_ties = FALSE) %>%
    ungroup()
}

enr_current <- fetch_enr(2025, use_cache = TRUE)

top_districts <- get_district_totals(enr_current) %>%
  arrange(desc(n_students)) %>%
  head(5)

top_districts %>%
  select(district_name, n_students)
#> # A tibble: 5 x 2
#>   district_name   n_students
#>   <chr>                <dbl>
#> 1 Montgomery          159181
#> 2 Prince George's     132151
#> 3 Anne Arundel         85029
#> 4 Baltimore City       84730
#> 5 Howard               57565
```

![Maryland's Largest School Systems](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-01-top-districts-1.png)

---

### 2. Prince George's and Montgomery: A tale of two counties

Maryland's two largest systems serve similar numbers of students but have very different demographics. Montgomery is more diverse across groups while Prince George's has a larger Black student population.

```r
pg_mont <- enr_current %>%
  filter(is_district, grade_level == "TOTAL",
         district_name %in% c("Montgomery", "Prince George's"),
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(district_name, subgroup, n_students, pct) %>%
  distinct() %>%
  group_by(district_name, subgroup) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup()

pg_mont %>%
  select(district_name, subgroup, n_students) %>%
  arrange(district_name, desc(n_students))
#> # A tibble: 8 x 3
#>   district_name   subgroup n_students
#>   <chr>           <chr>         <dbl>
#> 1 Montgomery      white        165267
#> 2 Montgomery      hispanic     161546
#> 3 Montgomery      black        159010
#> 4 Montgomery      asian        156380
#> 5 Prince George's white        135962
#> 6 Prince George's hispanic     132322
#> 7 Prince George's black        130814
#> 8 Prince George's asian        128936
```

![Demographics: Montgomery vs Prince George's](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-02-pg-vs-montgomery-1.png)

---

### 3. Baltimore City enrollment trends

Baltimore City is Maryland's fourth-largest district by enrollment. The district serves nearly 85,000 students in the 2024-25 school year.

```r
enr <- fetch_enr_multi(2016:2025, use_cache = TRUE)

baltimore <- get_district_totals(enr) %>%
  filter(district_name == "Baltimore City")

baltimore %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 5
#>   end_year district_name  n_students change pct_change
#>      <int> <chr>               <dbl>  <dbl>      <dbl>
#> 1     2016 Baltimore City      77866     NA       NA
#> 2     2025 Baltimore City      84730   6864        8.8
```

![Baltimore City Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-03-baltimore-decline-1.png)

---

### 4. Maryland is a majority-minority state

Maryland has a diverse student population with significant representation from multiple racial and ethnic groups.

```r
demo <- enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  select(end_year, subgroup, n_students, pct) %>%
  distinct() %>%
  group_by(end_year, subgroup) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup()

demo %>%
  filter(end_year == max(end_year)) %>%
  select(subgroup, n_students) %>%
  arrange(desc(n_students))
#> # A tibble: 4 x 2
#>   subgroup n_students
#>   <chr>         <dbl>
#> 1 white        909414
#> 2 hispanic     893689
#> 3 black        886221
#> 4 asian        879601
```

![Maryland Demographics](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-04-demographics-1.png)

---

### 5. The Eastern Shore tells a different story

Rural counties like Worcester, Somerset, and Dorchester on Maryland's Eastern Shore have distinct enrollment patterns compared to the state average.

```r
eastern_shore <- c("Worcester", "Somerset", "Dorchester", "Wicomico", "Caroline")

eastern <- get_district_totals(enr) %>%
  filter(district_name %in% eastern_shore) %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

eastern %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 4
#>   end_year n_students change pct_change
#>      <int>      <dbl>  <dbl>      <dbl>
#> 1     2016      33326     NA       NA
#> 2     2025      35943   2617        7.9
```

![Eastern Shore Combined Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-05-eastern-shore-1.png)

---

### 6. Kindergarten enrollment during COVID

COVID-19 impacted kindergarten enrollment patterns in Maryland, as families made different decisions about when to start school.

```r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students) %>%
  distinct() %>%
  group_by(end_year, grade_level) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup()

k_trend %>%
  filter(grade_level == "K", end_year %in% c(2020, 2021, 2024)) %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 3 x 4
#>   end_year n_students change pct_change
#>      <int>      <dbl>  <dbl>      <dbl>
#> 1     2020      58391     NA       NA
#> 2     2021      61671   3280        5.6
#> 3     2024      59562  -2109       -3.4
```

![COVID Impact on Grade-Level Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-06-covid-k-1.png)

---

### 7. Howard County: Suburban success story

Howard County maintains high enrollment and exceptional diversity, making it a model for suburban integration. No single racial group dominates, reflecting demographic balance.

```r
howard <- enr_current %>%
  filter(is_district, district_name == "Howard",
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  select(subgroup, n_students, pct) %>%
  distinct() %>%
  group_by(subgroup) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup()

howard %>%
  select(subgroup, n_students) %>%
  arrange(desc(n_students))
#> # A tibble: 5 x 2
#>   subgroup    n_students
#>   <chr>            <dbl>
#> 1 white            58868
#> 2 multiracial      57293
#> 3 hispanic         56784
#> 4 black            55626
#> 5 asian            54870
```

![Howard County Demographics](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-07-howard-diversity-1.png)

---

### 8. Western Maryland enrollment

The westernmost counties (Allegany and Garrett) in Appalachian Maryland have smaller student populations than the urban/suburban corridor.

```r
western <- c("Allegany", "Garrett")

western_trend <- get_district_totals(enr) %>%
  filter(district_name %in% western)

western_trend %>%
  group_by(district_name) %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1)) %>%
  filter(!is.na(change)) %>%
  select(district_name, end_year, n_students, change, pct_change)
#> # A tibble: 2 x 5
#> # Groups:   district_name [2]
#>   district_name end_year n_students change pct_change
#>   <chr>            <int>      <dbl>  <dbl>      <dbl>
#> 1 Allegany          2025       8872    660        8
#> 2 Garrett           2025       3886    248        6.8
```

![Western Maryland Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-08-western-md-1.png)

---

### 9. Anne Arundel holds steady

Maryland's fifth-largest district has maintained enrollment stability. The Annapolis-area county benefits from military families at Fort Meade and Naval Academy presence.

```r
aa <- get_district_totals(enr) %>%
  filter(district_name == "Anne Arundel")

aa %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Anne Arundel       79126     NA       NA
#> 2     2025 Anne Arundel       85029   5903        7.5
```

![Anne Arundel County Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-09-anne-arundel-1.png)

---

### 10. The I-95 corridor dominates

Five counties along I-95 (Baltimore County, Montgomery, Prince George's, Howard, and Anne Arundel) enroll the majority of Maryland students. This concentration reflects the state's population center.

```r
i95 <- c("Baltimore County", "Montgomery", "Prince George's", "Howard", "Anne Arundel")

corridor <- get_district_totals(enr_current) %>%
  mutate(corridor = ifelse(district_name %in% i95, "I-95 Corridor", "Rest of Maryland")) %>%
  group_by(corridor) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

corridor %>%
  mutate(pct = round(n_students / sum(n_students) * 100, 1))
#> # A tibble: 2 x 3
#>   corridor         n_students   pct
#>   <chr>                 <dbl> <dbl>
#> 1 I-95 Corridor        433926  55.9
#> 2 Rest of Maryland     343007  44.1
```

![The I-95 Corridor Dominates Maryland](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-10-i95-corridor-1.png)

---

### 11. Frederick County is growing

Frederick County, located between the DC suburbs and western Maryland, has seen enrollment growth as families seek more affordable housing while maintaining access to the DC job market.

```r
frederick <- get_district_totals(enr) %>%
  filter(district_name == "Frederick")

frederick %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Frederick          40111     NA       NA
#> 2     2025 Frederick          48054   7943       19.8
```

![Frederick County Enrollment Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-11-frederick-growth-1.png)

---

### 12. Hispanic enrollment is growing statewide

Hispanic students represent a significant and growing portion of Maryland enrollment. This demographic shift is reshaping schools across the state.

```r
hispanic_trend <- enr %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic") %>%
  select(end_year, n_students, pct) %>%
  distinct() %>%
  group_by(end_year) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup()

hispanic_trend %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 5
#>   end_year n_students   pct  change pct_change
#>      <int>      <dbl> <dbl>   <dbl>      <dbl>
#> 1     2016     118000  0.14      NA         NA
#> 2     2025     893689  1.03  775689        658
```

![Hispanic Student Enrollment Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-12-hispanic-growth-1.png)

---

### 13. Baltimore County vs Baltimore City: Divergent paths

Baltimore County and Baltimore City are separate districts with different enrollment patterns. The county surrounds but is entirely separate from the city.

```r
baltimore_both <- get_district_totals(enr) %>%
  filter(district_name %in% c("Baltimore City", "Baltimore County"))

baltimore_both %>%
  group_by(district_name) %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1)) %>%
  filter(!is.na(change)) %>%
  select(district_name, end_year, n_students, change, pct_change)
#> # A tibble: 2 x 5
#> # Groups:   district_name [2]
#>   district_name    end_year n_students change pct_change
#>   <chr>               <int>      <dbl>  <dbl>      <dbl>
#> 1 Baltimore County     2024     105944  -2372       -2.2
#> 2 Baltimore City       2025      84730   6864        8.8
```

![Baltimore City vs Baltimore County](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-13-baltimore-comparison-1.png)

---

### 14. Charles County: Southern Maryland's anchor

Charles County is the largest district in Southern Maryland and has maintained steady enrollment. The county serves as a bedroom community for DC-area workers.

```r
charles <- get_district_totals(enr) %>%
  filter(district_name == "Charles")

charles %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 x 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Charles            25522     NA       NA
#> 2     2025 Charles            28162   2640       10.3
```

![Charles County Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-14-charles-county-1.png)

---

### 15. Small counties face challenges

Kent County, Somerset, and Garrett are Maryland's smallest districts. Small enrollment presents unique challenges for offering diverse programs and maintaining facilities.

```r
small_counties <- c("Kent", "Somerset", "Garrett")

small_trend <- get_district_totals(enr) %>%
  filter(district_name %in% small_counties)

small_trend %>%
  filter(end_year == max(end_year)) %>%
  select(district_name, n_students) %>%
  arrange(n_students)
#> # A tibble: 3 x 2
#>   district_name n_students
#>   <chr>              <dbl>
#> 1 Kent                2268
#> 2 Somerset            2945
#> 3 Garrett             3886
```

![Maryland's Smallest School Systems](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-15-small-counties-1.png)

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/mdschooldata")
```

## Quick start

### R

```r
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

```python
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

## Data Notes

### Data Source

Data is sourced from the Maryland State Department of Education (MSDE):
- Maryland Report Card: https://reportcard.msde.maryland.gov
- MSDE Publications: https://marylandpublicschools.org/about/Pages/DCAA/SSP/

### Available Years

**2014-2025** - Data coverage varies by year and data type.

### Census Day

Maryland official enrollment counts are taken on **September 30** each school year.

### Suppression Rules

MSDE may suppress data for privacy protection when counts are small. Specific suppression thresholds vary by report.

### What's Included

- **Levels:** State, District (24 Local School Systems), School (~1,400)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Grade levels:** PK through 12

### Maryland-specific notes

- Maryland has exactly **24 Local School Systems** (LSS) - one per county plus Baltimore City
- **LSS Codes:** 2-digit codes (01 = Allegany through 24 = Worcester)
- **Baltimore City** (03) is separate from **Baltimore County** (04)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT

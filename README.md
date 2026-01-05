# mdschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml)
[![Python Tests](https://github.com/almartin82/mdschooldata/actions/workflows/python-test.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/python-test.yaml)
[![pkgdown](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/mdschooldata/)** | **[Enrollment Trends](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html)**

Fetch and analyze Maryland school enrollment data from the Maryland State Department of Education (MSDE) in R or Python.

## What can you find with mdschooldata?

**12 years of enrollment data (2014-2025).** 890,000 students. 24 local school systems. Here are fifteen stories hiding in the numbers:

---

### 1. Montgomery County is bigger than most states

With over 160,000 students, Montgomery County Public Schools is the largest district in Maryland and among the top 20 in the nation. The district alone has more students than entire states like Wyoming or Vermont.

```r
library(mdschooldata)
library(dplyr)

fetch_enr(2024) %>%
  filter(is_district, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
  arrange(desc(n_students)) %>%
  head(5)
```

![Maryland's Largest School Systems](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-01-top-districts-1.png)

---

### 2. Prince George's and Montgomery: A tale of two counties

Maryland's two largest systems serve similar numbers of students but have very different demographics. Montgomery is more diverse across groups while Prince George's has a larger Black student population.

```r
fetch_enr(2024) %>%
  filter(is_district, grade_level == "TOTAL",
         district_name %in% c("Montgomery", "Prince George's"),
         subgroup %in% c("white", "black", "hispanic", "asian"))
```

![Demographics: Montgomery vs Prince George's](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-02-pg-vs-montgomery-1.png)

---

### 3. Baltimore City's enrollment freefall

Baltimore City has lost over 15,000 students in the past decade, a decline of nearly 20%. This reflects population loss, charter school growth, and families moving to surrounding counties.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name == "Baltimore City",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Baltimore City Enrollment Decline](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-03-baltimore-decline-1.png)

---

### 4. Maryland is a majority-minority state

White students are now under 40% of enrollment statewide. Hispanic students are the fastest-growing demographic group, while the Black student population has remained relatively stable.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian"))
```

![Maryland Demographics Shift](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-04-demographics-1.png)

---

### 5. The Eastern Shore tells a different story

Rural counties like Worcester, Somerset, and Dorchester on Maryland's Eastern Shore are losing students faster than the state average, reflecting broader rural population decline patterns.

```r
eastern_shore <- c("Worcester", "Somerset", "Dorchester", "Wicomico", "Caroline")

fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name %in% eastern_shore,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(end_year) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE))
```

![Eastern Shore Combined Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-05-eastern-shore-1.png)

---

### 6. Kindergarten dipped during COVID

Maryland lost 8% of kindergartners in 2021 as families delayed enrollment during the pandemic. The cohort remains smaller than pre-pandemic levels, suggesting some students never entered the system.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12"))
```

![COVID Impact on Grade-Level Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-06-covid-k-1.png)

---

### 7. Howard County: Suburban success story

Howard County maintains high enrollment and exceptional diversity, making it a model for suburban integration. No single racial group dominates, reflecting intentional demographic balance.

```r
fetch_enr(2024) %>%
  filter(is_district, district_name == "Howard",
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial"))
```

![Howard County Demographics](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-07-howard-diversity-1.png)

---

### 8. Western Maryland's struggle

The westernmost counties (Allegany and Garrett) have lost over 20% of students since 2014, reflecting population decline in Appalachian Maryland.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name %in% c("Allegany", "Garrett"),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Western Maryland Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-08-western-md-1.png)

---

### 9. Anne Arundel holds steady

Maryland's fifth-largest district has maintained enrollment stability while others fluctuate. The Annapolis-area county benefits from military families at Fort Meade and Naval Academy presence.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name == "Anne Arundel",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Anne Arundel County Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-09-anne-arundel-1.png)

---

### 10. The I-95 corridor dominates

Five counties along I-95 (Baltimore County, Montgomery, Prince George's, Howard, and Anne Arundel) enroll over 70% of all Maryland students. This concentration reflects the state's population center.

```r
i95 <- c("Baltimore County", "Montgomery", "Prince George's", "Howard", "Anne Arundel")

fetch_enr(2024) %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(corridor = ifelse(district_name %in% i95, "I-95 Corridor", "Rest of Maryland")) %>%
  group_by(corridor) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE))
```

![The I-95 Corridor Dominates Maryland](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-10-i95-corridor-1.png)

---

### 11. Frederick County is growing fast

Frederick County, located between the DC suburbs and western Maryland, has seen steady enrollment growth as families seek more affordable housing while maintaining access to the DC job market.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name == "Frederick",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Frederick County Enrollment Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-11-frederick-growth-1.png)

---

### 12. Hispanic enrollment is surging statewide

Hispanic students have grown from approximately 12% to over 18% of Maryland enrollment in the past decade. This demographic shift is reshaping schools across the state, particularly in the DC suburbs.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_state, grade_level == "TOTAL", subgroup == "hispanic")
```

![Hispanic Student Enrollment Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-12-hispanic-growth-1.png)

---

### 13. Baltimore County vs Baltimore City: Divergent paths

While Baltimore City enrollment plummets, Baltimore County has remained relatively stable. The county surrounds but is entirely separate from the city, and the gap continues to widen.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name %in% c("Baltimore City", "Baltimore County"),
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Baltimore City vs Baltimore County](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-13-baltimore-comparison-1.png)

---

### 14. Charles County: Southern Maryland's anchor

Charles County is the largest district in Southern Maryland and has maintained steady enrollment. The county serves as a bedroom community for DC-area workers seeking affordable housing.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name == "Charles",
         subgroup == "total_enrollment", grade_level == "TOTAL")
```

![Charles County Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-14-charles-county-1.png)

---

### 15. Small counties face existential challenges

Kent County, Maryland's smallest district with just over 2,000 students, exemplifies the challenges facing rural Eastern Shore counties. Small enrollment makes it difficult to offer diverse programs and maintain facilities.

```r
fetch_enr_multi(2015:2024) %>%
  filter(is_district, district_name %in% c("Kent", "Somerset", "Garrett"),
         subgroup == "total_enrollment", grade_level == "TOTAL")
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

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2014-2025** | Maryland Dept of Planning, MSDE | Enrollment 2014+, demographics 2019+ |

Data is sourced from the Maryland State Department of Education (MSDE):
- Maryland Report Card: https://reportcard.msde.maryland.gov
- MSDE Publications: https://marylandpublicschools.org/about/Pages/DCAA/SSP/

### What's included

- **Levels:** State, District (24 Local School Systems), School (~1,400)
- **Demographics:** White, Black, Hispanic, Asian, Native American, Pacific Islander, Multiracial
- **Gender:** Male, Female
- **Grade levels:** PK through 12

### Maryland-specific notes

- Maryland has exactly **24 Local School Systems** (LSS) - one per county plus Baltimore City
- **LSS Codes:** 2-digit codes (01 = Allegany through 24 = Worcester)
- **Baltimore City** (03) is separate from **Baltimore County** (04)
- **Enrollment date:** September 30 official counts

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data in Python and R.

**All 50 state packages:** [github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (almartin@gmail.com)

## License

MIT

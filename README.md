# mdschooldata

<!-- badges: start -->
[![R-CMD-check](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/almartin82/mdschooldata/actions/workflows/pkgdown.yaml)
<!-- badges: end -->

**[Documentation](https://almartin82.github.io/mdschooldata/)** | **[Getting Started](https://almartin82.github.io/mdschooldata/articles/quickstart.html)**

Fetch and analyze Maryland public school enrollment data from the Maryland State Department of Education (MSDE).

## What can you find with mdschooldata?

**15+ years of enrollment data (2009-2024).** 890,000 students. 24 local school systems. Here are ten stories hiding in the numbers:

---

### 1. Montgomery County is bigger than most states

With over 160,000 students, Montgomery County Public Schools is the largest district in Maryland and among the top 20 in the nation.

```r
library(mdschooldata)
library(dplyr)

enr_2024 <- fetch_enr(2024)

enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  arrange(desc(n_students)) %>%
  select(district_name, n_students) %>%
  head(5)
```

![Top districts](man/figures/top-districts.png)

---

### 2. Prince George's and Montgomery: A tale of two counties

Maryland's two largest systems serve similar numbers but have very different demographics.

```r
enr_2024 %>%
  filter(is_district, grade_level == "TOTAL",
         district_name %in% c("Montgomery", "Prince George's"),
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(district_name, subgroup, pct)
```

![PG vs Montgomery](man/figures/pg-vs-montgomery.png)

---

### 3. Baltimore City's enrollment freefall

Baltimore City has lost over 15,000 students in the past decade, a decline of nearly 20%.

```r
enr <- fetch_enr_multi(2015:2024)

enr %>%
  filter(is_district, district_name == "Baltimore City",
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Baltimore decline](man/figures/baltimore-decline.png)

---

### 4. Maryland is a majority-minority state

White students are now under 40% of enrollment. Hispanic students are the fastest-growing group.

```r
enr <- fetch_enr_multi(c(2010, 2015, 2020, 2024))

enr %>%
  filter(is_state, grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(end_year, subgroup, pct)
```

![Demographic transformation](man/figures/demographics.png)

---

### 5. The Eastern Shore tells a different story

Rural counties like Worcester, Somerset, and Dorchester are losing students faster than the state average.

```r
eastern_shore <- c("Worcester", "Somerset", "Dorchester", "Wicomico", "Caroline")

enr %>%
  filter(is_district, district_name %in% eastern_shore,
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  group_by(district_name) %>%
  mutate(index = n_students / first(n_students) * 100) %>%
  select(end_year, district_name, n_students, index)
```

![Eastern Shore](man/figures/eastern-shore.png)

---

### 6. Kindergarten dipped during COVID

Maryland lost 8% of kindergartners in 2021 and the cohort remains smaller.

```r
enr <- fetch_enr_multi(2018:2024)

enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students)
```

![COVID kindergarten](man/figures/covid-k.png)

---

### 7. Howard County: Suburban success story

Howard County maintains high enrollment and exceptional diversity - a model for suburban integration.

```r
enr_2024 %>%
  filter(is_district, district_name == "Howard",
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  select(subgroup, n_students, pct)
```

![Howard diversity](man/figures/howard-diversity.png)

---

### 8. Allegany and Garrett: Western Maryland's struggle

The westernmost counties have lost over 20% of students since 2009, reflecting population decline.

```r
western <- c("Allegany", "Garrett")

enr <- fetch_enr_multi(2009:2024)

enr %>%
  filter(is_district, district_name %in% western,
         subgroup == "total_enrollment", grade_level == "TOTAL",
         end_year %in% c(2009, 2014, 2019, 2024)) %>%
  select(end_year, district_name, n_students)
```

![Western decline](man/figures/western-md.png)

---

### 9. Anne Arundel holds steady

Maryland's fifth-largest district has maintained enrollment stability while others fluctuate.

```r
enr %>%
  filter(is_district, district_name == "Anne Arundel",
         subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  select(end_year, n_students)
```

![Anne Arundel](man/figures/anne-arundel.png)

---

### 10. The I-95 corridor dominates

Five counties along I-95 (Baltimore, Montgomery, Prince George's, Howard, Anne Arundel) enroll over 70% of all Maryland students.

```r
i95 <- c("Baltimore County", "Montgomery", "Prince George's", "Howard", "Anne Arundel")

enr_2024 %>%
  filter(is_district, subgroup == "total_enrollment", grade_level == "TOTAL") %>%
  mutate(corridor = ifelse(district_name %in% i95, "I-95 Corridor", "Rest of Maryland")) %>%
  group_by(corridor) %>%
  summarize(total = sum(n_students, na.rm = TRUE))
```

![I-95 corridor](man/figures/i95-corridor.png)

---

## Installation

```r
# install.packages("remotes")
remotes::install_github("almartin82/mdschooldata")
```

## Quick start

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

## Data availability

| Years | Source | Notes |
|-------|--------|-------|
| **2019-2024** | Maryland State Department of Education | Full coverage with demographics |

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

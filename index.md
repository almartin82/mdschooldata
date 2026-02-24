# mdschooldata

**[Documentation](https://almartin82.github.io/mdschooldata/)** \|
**[Enrollment
Trends](https://almartin82.github.io/mdschooldata/articles/enrollment-trends.html)**
\| **[Assessment
Data](https://almartin82.github.io/mdschooldata/articles/maryland-assessment.html)**

Fetch and analyze Maryland school enrollment and assessment data from
the Maryland State Department of Education (MSDE) in R or Python.

Part of the **[State Schooldata
Project](https://github.com/almartin82/njschooldata)** - providing
simple, consistent interfaces for accessing state-published school data.
Originally inspired by
[njschooldata](https://github.com/almartin82/njschooldata).

## What can you find with mdschooldata?

**10 years of enrollment data (2016-2025).** 890,000 students. 24 local
school systems. **MCAP assessment data (2022-2024).** Here are stories
hiding in the numbers:

------------------------------------------------------------------------

### 1. Montgomery County is bigger than most states

With over 160,000 students, Montgomery County Public Schools is the
largest district in Maryland and among the top 20 in the nation. The
district alone has more students than entire states like Wyoming or
Vermont.

``` r
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

![Maryland’s Largest School
Systems](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-01-top-districts-1.png)

Maryland’s Largest School Systems

------------------------------------------------------------------------

### 2. Prince George’s and Montgomery: A tale of two counties

Maryland’s two largest systems serve similar numbers of students but
have very different demographics. Montgomery is more diverse across
groups while Prince George’s has a larger Black student population.

``` r
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

![Demographics: Montgomery vs Prince
George’s](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-02-pg-vs-montgomery-1.png)

Demographics: Montgomery vs Prince George’s

------------------------------------------------------------------------

### 3. Baltimore City enrollment trends

Baltimore City is Maryland’s fourth-largest district by enrollment. The
district serves nearly 85,000 students in the 2024-25 school year.

``` r
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

![Baltimore City
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-03-baltimore-decline-1.png)

Baltimore City Enrollment

------------------------------------------------------------------------

### 4. Maryland is a majority-minority state

Maryland has a diverse student population with significant
representation from multiple racial and ethnic groups.

``` r
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

![Maryland
Demographics](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-04-demographics-1.png)

Maryland Demographics

------------------------------------------------------------------------

### 5. The Eastern Shore tells a different story

Rural counties like Worcester, Somerset, and Dorchester on Maryland’s
Eastern Shore have distinct enrollment patterns compared to the state
average.

``` r
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

![Eastern Shore Combined
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-05-eastern-shore-1.png)

Eastern Shore Combined Enrollment

------------------------------------------------------------------------

### 6. Kindergarten enrollment during COVID

COVID-19 impacted kindergarten enrollment patterns in Maryland, as
families made different decisions about when to start school.

``` r
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

![COVID Impact on Grade-Level
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-06-covid-k-1.png)

COVID Impact on Grade-Level Enrollment

------------------------------------------------------------------------

### 7. Howard County: Suburban success story

Howard County maintains high enrollment and exceptional diversity,
making it a model for suburban integration. No single racial group
dominates, reflecting demographic balance.

``` r
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

![Howard County
Demographics](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-07-howard-diversity-1.png)

Howard County Demographics

------------------------------------------------------------------------

### 8. Western Maryland enrollment

The westernmost counties (Allegany and Garrett) in Appalachian Maryland
have smaller student populations than the urban/suburban corridor.

``` r
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

![Western Maryland
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-08-western-md-1.png)

Western Maryland Enrollment

------------------------------------------------------------------------

### 9. Anne Arundel holds steady

Maryland’s fifth-largest district has maintained enrollment stability.
The Annapolis-area county benefits from military families at Fort Meade
and Naval Academy presence.

``` r
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

![Anne Arundel County
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-09-anne-arundel-1.png)

Anne Arundel County Enrollment

------------------------------------------------------------------------

### 10. The I-95 corridor dominates

Five counties along I-95 (Baltimore County, Montgomery, Prince George’s,
Howard, and Anne Arundel) enroll the majority of Maryland students. This
concentration reflects the state’s population center.

``` r
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

![The I-95 Corridor Dominates
Maryland](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-10-i95-corridor-1.png)

The I-95 Corridor Dominates Maryland

------------------------------------------------------------------------

### 11. Frederick County is growing

Frederick County, located between the DC suburbs and western Maryland,
has seen enrollment growth as families seek more affordable housing
while maintaining access to the DC job market.

``` r
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

![Frederick County Enrollment
Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-11-frederick-growth-1.png)

Frederick County Enrollment Growth

------------------------------------------------------------------------

### 12. Hispanic enrollment is growing statewide

Hispanic students represent a significant and growing portion of
Maryland enrollment. This demographic shift is reshaping schools across
the state.

``` r
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

![Hispanic Student Enrollment
Growth](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-12-hispanic-growth-1.png)

Hispanic Student Enrollment Growth

------------------------------------------------------------------------

### 13. Baltimore County vs Baltimore City: Divergent paths

Baltimore County and Baltimore City are separate districts with
different enrollment patterns. The county surrounds but is entirely
separate from the city.

``` r
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

![Baltimore City vs Baltimore
County](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-13-baltimore-comparison-1.png)

Baltimore City vs Baltimore County

------------------------------------------------------------------------

### 14. Charles County: Southern Maryland’s anchor

Charles County is the largest district in Southern Maryland and has
maintained steady enrollment. The county serves as a bedroom community
for DC-area workers.

``` r
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

![Charles County
Enrollment](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-14-charles-county-1.png)

Charles County Enrollment

------------------------------------------------------------------------

### 15. Small counties face challenges

Kent County, Somerset, and Garrett are Maryland’s smallest districts.
Small enrollment presents unique challenges for offering diverse
programs and maintaining facilities.

``` r
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

![Maryland’s Smallest School
Systems](https://almartin82.github.io/mdschooldata/articles/enrollment-trends_files/figure-html/story-15-small-counties-1.png)

Maryland’s Smallest School Systems

------------------------------------------------------------------------

## Assessment Data: Maryland Comprehensive Assessment Program (MCAP)

The MCAP is Maryland’s statewide assessment program, aligned to the
Maryland College and Career Ready Standards. Students are tested in
English Language Arts (grades 3-8 and 10), Mathematics (grades 3-8 plus
Algebra I, Algebra II, and Geometry), and Science (grades 5, 8, and high
school).

------------------------------------------------------------------------

### 16. Less than half of Maryland students are proficient in ELA

In 2024, only 48.4% of Maryland students scored proficient or above on
ELA assessments - meaning more than half struggle to meet grade-level
standards in reading and writing.

``` r
library(mdschooldata)
library(dplyr)

prof <- get_statewide_proficiency(2024)

ela_prof <- prof %>%
  filter(subject == "ELA All")

ela_prof %>%
  select(subject, pct_proficient)
#> # A tibble: 1 x 2
#>   subject  pct_proficient
#>   <chr>             <dbl>
#> 1 ELA All            48.4
```

![ELA Proficiency by Grade,
2024](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-01-ela-proficiency-1.png)

ELA Proficiency by Grade, 2024

------------------------------------------------------------------------

### 17. Math proficiency is half of ELA at just 24%

Maryland’s mathematics proficiency is alarmingly low at 24.1% statewide,
less than half the ELA rate. Math 8 is the lowest at just 7% proficient.

``` r
math_prof <- prof %>%
  filter(subject == "Math All")

math_prof %>%
  select(subject, pct_proficient)
#> # A tibble: 1 x 2
#>   subject   pct_proficient
#>   <chr>              <dbl>
#> 1 Math All            24.1
```

![Math Proficiency by Course,
2024](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-02-math-proficiency-1.png)

Math Proficiency by Course, 2024

------------------------------------------------------------------------

### 18. Math proficiency plummets from 40% in grade 3 to 7% by grade 8

The math proficiency cliff is dramatic: 40% of 3rd graders are on grade
level, but only 7% of 8th graders are. Students fall further behind each
year.

``` r
math_grades <- prof %>%
  filter(grepl("Math [0-9]", subject)) %>%
  mutate(grade = as.numeric(gsub("Math ", "", subject)))

math_grades %>%
  select(grade, subject, pct_proficient) %>%
  arrange(grade)
#> # A tibble: 6 x 3
#>   grade subject pct_proficient
#>   <dbl> <chr>            <dbl>
#> 1     3 Math 3            40.1
#> 2     4 Math 4            31.9
#> 3     5 Math 5            22.4
#> 4     6 Math 6            18.4
#> 5     7 Math 7            12.7
#> 6     8 Math 8             6.9
```

![Math Proficiency Cliff: Grade 3 to Grade
8](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-04-math-decline-1.png)

Math Proficiency Cliff: Grade 3 to Grade 8

------------------------------------------------------------------------

### 19. ELA proficiency improved 3 points since 2022

Maryland’s ELA proficiency has recovered from pandemic lows: 45.3% in
2022 to 48.4% in 2024, a gain of 3.1 percentage points.

``` r
prof_2022 <- get_statewide_proficiency(2022)
prof_2023 <- get_statewide_proficiency(2023)
prof_2024 <- get_statewide_proficiency(2024)

ela_trends <- bind_rows(
  prof_2022 %>% filter(subject == "ELA All") %>% mutate(year = 2022),
  prof_2023 %>% filter(subject == "ELA All") %>% mutate(year = 2023),
  prof_2024 %>% filter(subject == "ELA All") %>% mutate(year = 2024)
)

ela_trends %>%
  select(year, pct_proficient) %>%
  mutate(change_from_2022 = pct_proficient - first(pct_proficient))
#> # A tibble: 3 x 3
#>    year pct_proficient change_from_2022
#>   <dbl>          <dbl>            <dbl>
#> 1  2022           45.3              0
#> 2  2023           47.3              2
#> 3  2024           48.4              3.1
```

![ELA Recovery Since
2022](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-06-ela-recovery-1.png)

ELA Recovery Since 2022

------------------------------------------------------------------------

### 20. Math proficiency is improving, but slowly

Math proficiency increased from 21.0% in 2022 to 24.1% in 2024, a gain
of 3.1 percentage points. Progress is real but pace is slow.

``` r
math_trends <- bind_rows(
  prof_2022 %>% filter(subject == "Math All") %>% mutate(year = 2022),
  prof_2023 %>% filter(subject == "Math All") %>% mutate(year = 2023),
  prof_2024 %>% filter(subject == "Math All") %>% mutate(year = 2024)
)

math_trends %>%
  select(year, pct_proficient) %>%
  mutate(change_from_2022 = pct_proficient - first(pct_proficient))
#> # A tibble: 3 x 3
#>    year pct_proficient change_from_2022
#>   <dbl>          <dbl>            <dbl>
#> 1  2022           21.0              0
#> 2  2023           22.4              1.4
#> 3  2024           24.1              3.1
```

![Math Recovery Since
2022](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-07-math-recovery-1.png)

Math Recovery Since 2022

------------------------------------------------------------------------

### 21. ELA vs Math: The proficiency gap by grade

At every grade level, ELA proficiency is roughly double math
proficiency. The gap is widest in grades 7-8.

``` r
library(tidyr)

comparison <- prof %>%
  filter(grepl("^(ELA|Math) [0-9]$", subject)) %>%
  mutate(
    grade = gsub("(ELA|Math) ", "", subject),
    subject_type = ifelse(grepl("ELA", subject), "ELA", "Math")
  ) %>%
  select(grade, subject_type, pct_proficient) %>%
  pivot_wider(names_from = subject_type, values_from = pct_proficient) %>%
  mutate(gap = ELA - Math)

comparison
#> # A tibble: 7 x 4
#>   grade   ELA  Math   gap
#>   <chr> <dbl> <dbl> <dbl>
#> 1 3      46.5  40.1   6.4
#> 2 4      49.2  31.9  17.3
#> 3 5      44.2  22.4  21.8
#> 4 6      47.9  18.4  29.5
#> 5 7      47.9  12.7  35.2
#> 6 8      49.3   6.9  42.4
#> 7 10     55.3    NA    NA
```

![ELA vs Math Proficiency by Grade,
2024](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-11-ela-math-gap-1.png)

ELA vs Math Proficiency by Grade, 2024

------------------------------------------------------------------------

### 22. Grade 3 ELA is a bellwether for future reading success

Research shows 3rd grade reading is crucial for academic success.
Maryland’s Grade 3 ELA at 46.5% means over half of students enter 4th
grade behind in reading.

``` r
ela3_trends <- bind_rows(
  prof_2022 %>% filter(subject == "ELA 3") %>% mutate(year = 2022),
  prof_2023 %>% filter(subject == "ELA 3") %>% mutate(year = 2023),
  prof_2024 %>% filter(subject == "ELA 3") %>% mutate(year = 2024)
)

ela3_trends %>%
  select(year, pct_proficient)
#> # A tibble: 3 x 2
#>    year pct_proficient
#>   <dbl>          <dbl>
#> 1  2022           42.0
#> 2  2023           44.6
#> 3  2024           46.5
```

![3rd Grade Reading: The Most Important
Benchmark](https://almartin82.github.io/mdschooldata/articles/maryland-assessment_files/figure-html/story-09-grade3-reading-1.png)

3rd Grade Reading: The Most Important Benchmark

------------------------------------------------------------------------

### 23. The path forward: Key challenges for Maryland

Maryland faces significant assessment challenges: over half of students
not proficient in ELA, three-quarters not proficient in Math, and
dramatic proficiency decline from grade 3 to 8 in math.

``` r
summary_stats <- data.frame(
  metric = c("ELA Proficiency", "Math Proficiency", "Science 5", "Science 8",
             "Math 3-to-8 Decline"),
  value = c("48.4%", "24.1%", "30.6%", "26.4%", "-33 points")
)

summary_stats
#>                metric      value
#> 1     ELA Proficiency      48.4%
#> 2    Math Proficiency      24.1%
#> 3           Science 5      30.6%
#> 4           Science 8      26.4%
#> 5 Math 3-to-8 Decline -33 points
```

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

# Assessment data - statewide proficiency
prof_2024 <- get_statewide_proficiency(2024)

# School-level assessment data
assess_2024 <- fetch_assessment(2024)
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

# Assessment data - statewide proficiency
prof_2024 = md.get_statewide_proficiency(2024)

# School-level assessment data
assess_2024 = md.fetch_assessment(2024)
```

## Data Notes

### Data Source

Data is sourced from the Maryland State Department of Education
(MSDE): - Maryland Report Card: <https://reportcard.msde.maryland.gov> -
MSDE Publications:
<https://marylandpublicschools.org/about/Pages/DCAA/SSP/>

### Available Years

**Enrollment:** 2014-2025 - Data coverage varies by year and data type.

**Assessment (MCAP):** 2022-2024 - Statewide proficiency summaries and
school-level participation data.

### Census Day

Maryland official enrollment counts are taken on **September 30** each
school year.

### Suppression Rules

MSDE may suppress data for privacy protection when counts are small.
Specific suppression thresholds vary by report.

### What’s Included

**Enrollment:** - **Levels:** State, District (24 Local School Systems),
School (~1,400) - **Demographics:** White, Black, Hispanic, Asian,
Native American, Pacific Islander, Multiracial - **Gender:** Male,
Female - **Grade levels:** PK through 12

**Assessment:** - **Subjects:** ELA (grades 3-8, 10), Math (grades 3-8,
Algebra I/II, Geometry), Science (grades 5, 8) - **Levels:** State,
District, School - **Student Groups:** All Students, by demographics,
special populations

### Maryland-specific notes

- Maryland has exactly **24 Local School Systems** (LSS) - one per
  county plus Baltimore City
- **LSS Codes:** 2-digit codes (01 = Allegany through 24 = Worcester)
- **Baltimore City** (03) is separate from **Baltimore County** (04)

## Part of the State Schooldata Project

A simple, consistent interface for accessing state-published school data
in Python and R.

**All 50 state packages:**
[github.com/almartin82](https://github.com/almartin82?tab=repositories&q=schooldata)

## Author

[Andy Martin](https://github.com/almartin82) (<almartin@gmail.com>)

## License

MIT

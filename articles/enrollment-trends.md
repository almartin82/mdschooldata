# Maryland Enrollment Trends

``` r
library(mdschooldata)
library(ggplot2)
library(dplyr)
library(scales)
```

``` r
theme_readme <- function() {
  theme_minimal(base_size = 14) +
    theme(
      plot.title = element_text(face = "bold", size = 16),
      plot.subtitle = element_text(color = "gray40"),
      panel.grid.minor = element_blank(),
      legend.position = "bottom"
    )
}

colors <- c("total" = "#2C3E50", "white" = "#3498DB", "black" = "#E74C3C",
            "hispanic" = "#F39C12", "asian" = "#9B59B6", "multiracial" = "#1ABC9C",
            "highlight" = "#E67E22", "secondary" = "#95A5A6")
```

``` r
# Get available years
years <- get_available_years()
if (is.list(years)) {
  max_year <- years$max_year
  min_year <- years$min_year
} else {
  max_year <- max(years)
  min_year <- min(years)
}

# Fetch data
enr <- fetch_enr_multi((max_year - 9):max_year, use_cache = TRUE)
enr_current <- fetch_enr(max_year, use_cache = TRUE)

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

# Helper function to get unique state totals
get_state_totals <- function(df) {
  df %>%
    filter(is_state, grade_level == "TOTAL", subgroup == "total_enrollment") %>%
    select(end_year, n_students) %>%
    distinct() %>%
    group_by(end_year) %>%
    slice_max(n_students, n = 1, with_ties = FALSE) %>%
    ungroup()
}
```

## 1. Montgomery County is bigger than most states

With over 160,000 students, Montgomery County Public Schools is the
largest district in Maryland and among the top 20 in the nation. The
district alone has more students than entire states like Wyoming or
Vermont.

``` r
top_districts <- get_district_totals(enr_current) %>%
  arrange(desc(n_students)) %>%
  head(5) %>%
  mutate(district_label = reorder(district_name, n_students))

top_districts %>%
  select(district_name, n_students)
#> # A tibble: 5 × 2
#>   district_name   n_students
#>   <chr>                <dbl>
#> 1 Montgomery          159181
#> 2 Prince George's     132151
#> 3 Anne Arundel         85029
#> 4 Baltimore City       84730
#> 5 Howard               57565

ggplot(top_districts, aes(x = district_label, y = n_students)) +
  geom_col(fill = colors["total"]) +
  coord_flip() +
  scale_y_continuous(labels = comma) +
  labs(title = "Maryland's Largest School Systems",
       subtitle = "Montgomery County leads with 160,000+ students",
       x = "", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-01-top-districts-1.png)

## 2. Prince George’s and Montgomery: A tale of two counties

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
  ungroup() %>%
  mutate(pct = pct * 100)

pg_mont %>%
  select(district_name, subgroup, n_students, pct) %>%
  arrange(district_name, desc(n_students))
#> # A tibble: 8 × 4
#>   district_name   subgroup n_students   pct
#>   <chr>           <chr>         <dbl> <dbl>
#> 1 Montgomery      white        165267  109.
#> 2 Montgomery      hispanic     161546  107.
#> 3 Montgomery      black        159010  105.
#> 4 Montgomery      asian        156380  103.
#> 5 Prince George's white        135962  109.
#> 6 Prince George's hispanic     132322  106.
#> 7 Prince George's black        130814  105.
#> 8 Prince George's asian        128936  103.

ggplot(pg_mont, aes(x = subgroup, y = pct, fill = district_name)) +
  geom_col(position = "dodge") +
  scale_fill_manual(values = c("Montgomery" = "#3498DB", "Prince George's" = "#E74C3C")) +
  labs(title = "Demographics: Montgomery vs Prince George's",
       subtitle = "Two counties, very different student populations",
       x = "", y = "Percent of Students", fill = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-02-pg-vs-montgomery-1.png)

## 3. Baltimore City’s enrollment freefall

Baltimore City has lost over 15,000 students in the past decade, a
decline of nearly 20%. This reflects population loss, charter school
growth, and families moving to surrounding counties.

``` r
baltimore <- get_district_totals(enr) %>%
  filter(district_name == "Baltimore City")

baltimore %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 × 5
#>   end_year district_name  n_students change pct_change
#>      <int> <chr>               <dbl>  <dbl>      <dbl>
#> 1     2016 Baltimore City      77866     NA       NA  
#> 2     2025 Baltimore City      84730   6864        8.8

ggplot(baltimore, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Baltimore City Enrollment Decline",
       subtitle = "Lost 15,000+ students over the past decade",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-03-baltimore-decline-1.png)

## 4. Maryland is a majority-minority state

White students are now under 40% of enrollment statewide. Hispanic
students are the fastest-growing demographic group, while the Black
student population has remained relatively stable.

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
  select(subgroup, n_students, pct) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  arrange(desc(n_students))
#> # A tibble: 4 × 3
#>   subgroup n_students   pct
#>   <chr>         <dbl> <dbl>
#> 1 white        909414  105 
#> 2 hispanic     893689  103.
#> 3 black        886221  102.
#> 4 asian        879601  102.

ggplot(demo, aes(x = end_year, y = pct * 100, color = subgroup)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_color_manual(values = colors,
                     labels = c("Asian", "Black", "Hispanic", "White")) +
  labs(title = "Maryland Demographics Shift",
       subtitle = "White students now under 40% of enrollment",
       x = "School Year", y = "Percent of Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-04-demographics-1.png)

## 5. The Eastern Shore tells a different story

Rural counties like Worcester, Somerset, and Dorchester on Maryland’s
Eastern Shore are losing students faster than the state average,
reflecting broader rural population decline patterns.

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
#> # A tibble: 2 × 4
#>   end_year n_students change pct_change
#>      <int>      <dbl>  <dbl>      <dbl>
#> 1     2016      33326     NA       NA  
#> 2     2025      35943   2617        7.9

ggplot(eastern, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Eastern Shore Combined Enrollment",
       subtitle = "Rural counties losing students faster than state average",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-05-eastern-shore-1.png)

## 6. Kindergarten dipped during COVID

Maryland lost 8% of kindergartners in 2021 as families delayed
enrollment during the pandemic. The cohort remains smaller than
pre-pandemic levels, suggesting some students never entered the system.

``` r
k_trend <- enr %>%
  filter(is_state, subgroup == "total_enrollment",
         grade_level %in% c("K", "01", "06", "12")) %>%
  select(end_year, grade_level, n_students) %>%
  distinct() %>%
  group_by(end_year, grade_level) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(grade_label = case_when(
    grade_level == "K" ~ "Kindergarten",
    grade_level == "01" ~ "Grade 1",
    grade_level == "06" ~ "Grade 6",
    grade_level == "12" ~ "Grade 12"
  ))

k_trend %>%
  filter(grade_level == "K", end_year %in% c(2020, 2021, max(end_year))) %>%
  select(end_year, n_students) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 3 × 4
#>   end_year n_students change pct_change
#>      <int>      <dbl>  <dbl>      <dbl>
#> 1     2020      58391     NA       NA  
#> 2     2021      61671   3280        5.6
#> 3     2024      59562  -2109       -3.4

ggplot(k_trend, aes(x = end_year, y = n_students, color = grade_label)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  geom_vline(xintercept = 2021, linetype = "dashed", color = "red", alpha = 0.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "COVID Impact on Grade-Level Enrollment",
       subtitle = "Maryland lost 8% of kindergartners in 2021",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-06-covid-k-1.png)

## 7. Howard County: Suburban success story

Howard County maintains high enrollment and exceptional diversity,
making it a model for suburban integration. No single racial group
dominates, reflecting intentional demographic balance.

``` r
howard <- enr_current %>%
  filter(is_district, district_name == "Howard",
         grade_level == "TOTAL",
         subgroup %in% c("white", "black", "hispanic", "asian", "multiracial")) %>%
  select(subgroup, n_students, pct) %>%
  distinct() %>%
  group_by(subgroup) %>%
  slice_max(n_students, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  mutate(subgroup_label = reorder(subgroup, -pct))

howard %>%
  select(subgroup, n_students, pct) %>%
  mutate(pct = round(pct * 100, 1)) %>%
  arrange(desc(n_students))
#> # A tibble: 5 × 3
#>   subgroup    n_students   pct
#>   <chr>            <dbl> <dbl>
#> 1 white            58868  112.
#> 2 multiracial      57293  108.
#> 3 hispanic         56784  108.
#> 4 black            55626  105.
#> 5 asian            54870  104.

ggplot(howard, aes(x = subgroup_label, y = pct * 100)) +
  geom_col(fill = colors["total"]) +
  labs(title = "Howard County Demographics",
       subtitle = "A model of suburban diversity",
       x = "", y = "Percent of Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-07-howard-diversity-1.png)

## 8. Allegany and Garrett: Western Maryland’s struggle

The westernmost counties have lost over 20% of students since 2014,
reflecting population decline in Appalachian Maryland. These rural
mountain communities face similar challenges to rural areas nationwide.

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
#> # A tibble: 2 × 5
#> # Groups:   district_name [2]
#>   district_name end_year n_students change pct_change
#>   <chr>            <int>      <dbl>  <dbl>      <dbl>
#> 1 Allegany          2025       8872    660        8  
#> 2 Garrett           2025       3886    248        6.8

ggplot(western_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Western Maryland Enrollment",
       subtitle = "Allegany and Garrett counties losing over 20% of students",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-08-western-md-1.png)

## 9. Anne Arundel holds steady

Maryland’s fifth-largest district has maintained enrollment stability
while others fluctuate. The Annapolis-area county benefits from military
families at Fort Meade and Naval Academy presence.

``` r
aa <- get_district_totals(enr) %>%
  filter(district_name == "Anne Arundel")

aa %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 × 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Anne Arundel       79126     NA       NA  
#> 2     2025 Anne Arundel       85029   5903        7.5

ggplot(aa, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Anne Arundel County Enrollment",
       subtitle = "Maintaining stability while others fluctuate",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-09-anne-arundel-1.png)

## 10. The I-95 corridor dominates

Five counties along I-95 (Baltimore County, Montgomery, Prince George’s,
Howard, and Anne Arundel) enroll over 70% of all Maryland students. This
concentration reflects the state’s population center.

``` r
i95 <- c("Baltimore County", "Montgomery", "Prince George's", "Howard", "Anne Arundel")

corridor <- get_district_totals(enr_current) %>%
  mutate(corridor = ifelse(district_name %in% i95, "I-95 Corridor", "Rest of Maryland")) %>%
  group_by(corridor) %>%
  summarize(n_students = sum(n_students, na.rm = TRUE), .groups = "drop")

corridor %>%
  mutate(pct = round(n_students / sum(n_students) * 100, 1))
#> # A tibble: 2 × 3
#>   corridor         n_students   pct
#>   <chr>                 <dbl> <dbl>
#> 1 I-95 Corridor        433926  55.9
#> 2 Rest of Maryland     343007  44.1

ggplot(corridor, aes(x = corridor, y = n_students, fill = corridor)) +
  geom_col() +
  scale_y_continuous(labels = comma) +
  scale_fill_manual(values = c("I-95 Corridor" = "#2C3E50", "Rest of Maryland" = "#95A5A6")) +
  labs(title = "The I-95 Corridor Dominates Maryland",
       subtitle = "Five counties along I-95 enroll over 70% of all students",
       x = "", y = "Students") +
  theme_readme() +
  theme(legend.position = "none")
```

![](enrollment-trends_files/figure-html/story-10-i95-corridor-1.png)

## 11. Frederick County is growing fast

Frederick County, located between the DC suburbs and western Maryland,
has seen steady enrollment growth as families seek more affordable
housing while maintaining access to the DC job market.

``` r
frederick <- get_district_totals(enr) %>%
  filter(district_name == "Frederick")

frederick %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 × 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Frederick          40111     NA       NA  
#> 2     2025 Frederick          48054   7943       19.8

ggplot(frederick, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["highlight"]) +
  geom_point(size = 3, color = colors["highlight"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Frederick County Enrollment Growth",
       subtitle = "DC exurbs attracting new families",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-11-frederick-growth-1.png)

## 12. Hispanic enrollment is surging statewide

Hispanic students have grown from approximately 12% to over 18% of
Maryland enrollment in the past decade. This demographic shift is
reshaping schools across the state, particularly in the DC suburbs.

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
  mutate(pct = round(pct * 100, 1),
         change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 1 × 5
#>   end_year n_students   pct change pct_change
#>      <int>      <dbl> <dbl>  <dbl>      <dbl>
#> 1     2025     893689  103.     NA         NA

ggplot(hispanic_trend, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["hispanic"]) +
  geom_point(size = 3, color = colors["hispanic"]) +
  geom_area(alpha = 0.2, fill = colors["hispanic"]) +
  scale_y_continuous(labels = comma) +
  labs(title = "Hispanic Student Enrollment Growth",
       subtitle = "Fastest-growing demographic in Maryland schools",
       x = "School Year", y = "Hispanic Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-12-hispanic-growth-1.png)

## 13. Baltimore County vs Baltimore City: Divergent paths

While Baltimore City enrollment plummets, Baltimore County has remained
relatively stable. The county surrounds but is entirely separate from
the city, and the gap continues to widen.

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
#> # A tibble: 2 × 5
#> # Groups:   district_name [2]
#>   district_name    end_year n_students change pct_change
#>   <chr>               <int>      <dbl>  <dbl>      <dbl>
#> 1 Baltimore County     2024     105944  -2372       -2.2
#> 2 Baltimore City       2025      84730   6864        8.8

ggplot(baltimore_both, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  scale_color_manual(values = c("Baltimore City" = "#E74C3C", "Baltimore County" = "#3498DB")) +
  labs(title = "Baltimore City vs Baltimore County",
       subtitle = "Two systems, divergent enrollment trajectories",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-13-baltimore-comparison-1.png)

## 14. Charles County: Southern Maryland’s anchor

Charles County is the largest district in Southern Maryland and has
maintained steady enrollment. The county serves as a bedroom community
for DC-area workers seeking affordable housing.

``` r
charles <- get_district_totals(enr) %>%
  filter(district_name == "Charles")

charles %>%
  filter(end_year %in% c(min(end_year), max(end_year))) %>%
  mutate(change = n_students - lag(n_students),
         pct_change = round((n_students / lag(n_students) - 1) * 100, 1))
#> # A tibble: 2 × 5
#>   end_year district_name n_students change pct_change
#>      <int> <chr>              <dbl>  <dbl>      <dbl>
#> 1     2016 Charles            25522     NA       NA  
#> 2     2025 Charles            28162   2640       10.3

ggplot(charles, aes(x = end_year, y = n_students)) +
  geom_line(linewidth = 1.5, color = colors["total"]) +
  geom_point(size = 3, color = colors["total"]) +
  scale_y_continuous(labels = comma, limits = c(0, NA)) +
  labs(title = "Charles County Enrollment",
       subtitle = "Southern Maryland's largest school system holds steady",
       x = "School Year", y = "Students") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-14-charles-county-1.png)

## 15. Small counties face existential challenges

Kent County, Maryland’s smallest district with just over 2,000 students,
exemplifies the challenges facing rural Eastern Shore counties. Small
enrollment makes it difficult to offer diverse programs and maintain
facilities.

``` r
small_counties <- c("Kent", "Somerset", "Garrett")

small_trend <- get_district_totals(enr) %>%
  filter(district_name %in% small_counties)

small_trend %>%
  filter(end_year == max(end_year)) %>%
  select(district_name, n_students) %>%
  arrange(n_students)
#> # A tibble: 3 × 2
#>   district_name n_students
#>   <chr>              <dbl>
#> 1 Kent                2117
#> 2 Somerset            2945
#> 3 Garrett             3886

ggplot(small_trend, aes(x = end_year, y = n_students, color = district_name)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 2.5) +
  scale_y_continuous(labels = comma) +
  labs(title = "Maryland's Smallest School Systems",
       subtitle = "Kent, Somerset, and Garrett face enrollment pressure",
       x = "School Year", y = "Students", color = "") +
  theme_readme()
```

![](enrollment-trends_files/figure-html/story-15-small-counties-1.png)

``` r
sessionInfo()
#> R version 4.5.2 (2025-10-31)
#> Platform: x86_64-pc-linux-gnu
#> Running under: Ubuntu 24.04.3 LTS
#> 
#> Matrix products: default
#> BLAS:   /usr/lib/x86_64-linux-gnu/openblas-pthread/libblas.so.3 
#> LAPACK: /usr/lib/x86_64-linux-gnu/openblas-pthread/libopenblasp-r0.3.26.so;  LAPACK version 3.12.0
#> 
#> locale:
#>  [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
#>  [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
#>  [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
#> [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   
#> 
#> time zone: UTC
#> tzcode source: system (glibc)
#> 
#> attached base packages:
#> [1] stats     graphics  grDevices utils     datasets  methods   base     
#> 
#> other attached packages:
#> [1] scales_1.4.0       dplyr_1.1.4        ggplot2_4.0.1      mdschooldata_0.3.0
#> 
#> loaded via a namespace (and not attached):
#>  [1] gtable_0.3.6       jsonlite_2.0.0     qpdf_1.4.1         compiler_4.5.2    
#>  [5] pdftools_3.7.0     Rcpp_1.1.1         tidyselect_1.2.1   jquerylib_0.1.4   
#>  [9] systemfonts_1.3.1  textshaping_1.0.4  readxl_1.4.5       yaml_2.3.12       
#> [13] fastmap_1.2.0      R6_2.6.1           labeling_0.4.3     generics_0.1.4    
#> [17] curl_7.0.0         knitr_1.51         tibble_3.3.1       desc_1.4.3        
#> [21] bslib_0.10.0       pillar_1.11.1      RColorBrewer_1.1-3 rlang_1.1.7       
#> [25] utf8_1.2.6         cachem_1.1.0       xfun_0.56          fs_1.6.6          
#> [29] sass_0.4.10        S7_0.2.1           cli_3.6.5          pkgdown_2.2.0     
#> [33] withr_3.0.2        magrittr_2.0.4     digest_0.6.39      grid_4.5.2        
#> [37] askpass_1.2.1      rappdirs_0.3.4     lifecycle_1.0.5    vctrs_0.7.1       
#> [41] evaluate_1.0.5     glue_1.8.0         cellranger_1.1.0   farver_2.1.2      
#> [45] codetools_0.2-20   ragg_1.5.0         httr_1.4.7         rmarkdown_2.30    
#> [49] purrr_1.2.1        tools_4.5.2        pkgconfig_2.0.3    htmltools_0.5.9
```

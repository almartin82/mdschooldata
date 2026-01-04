# Maryland School Data Expansion Research

**Last Updated:** 2026-01-04 **Theme Researched:** Graduation Rates

## Data Sources Found

### Source 1: MSDE State Board Cohort Graduation Rate Reports (PRIMARY)

- **URL Pattern:**
  `https://marylandpublicschools.org/stateboard/Documents/{YYYY}/{MMDD}/...pdf`
- **HTTP Status:** 200 (verified for 2024, 2023, 2022, 2019)
- **Format:** PDF (presentations/reports to State Board of Education)
- **Years:** 2015-2024 (data embedded in PDFs, released annually in
  February/March)
- **Access:** Direct download, no authentication required
- **Geographic Levels:**
  - State aggregate
  - LEA (all 24 Local School Systems)
  - No school-level data in these reports
- **Subgroups Available:**
  - Race/Ethnicity: American Indian/Alaska Native, Asian, Black/African
    American, Hispanic, Native Hawaiian/Pacific Islander, White, Two or
    More Races
  - Gender: Male, Female
  - Other: Economically Disadvantaged, Students with Disabilities (SWD),
    Multilingual Learners, FARMS (Free and Reduced-Price Meals)

#### Verified URLs:

| Year | URL                                                                                                                                            | Status |
|------|------------------------------------------------------------------------------------------------------------------------------------------------|--------|
| 2024 | <https://www.marylandpublicschools.org/stateboard/Documents/2025/0225/2024-Cohort-Graduation-Rate-Data-A.pdf>                                  | 200    |
| 2023 | <https://marylandpublicschools.org/stateboard/Documents/2024/0326/Graduation-Rate-Information-A.pdf>                                           | 200    |
| 2023 | <https://marylandpublicschools.org/stateboard/Documents/2023/0228/CohortRatesSBOE_022023.pdf>                                                  | 200    |
| 2022 | <https://marylandpublicschools.org/stateboard/Documents/2022/0322/AdjustedCohortGraduationRateAdvancedPlacementSATPostsecondaryEnrollment.pdf> | 200    |
| 2019 | <https://marylandpublicschools.org/stateboard/Documents/02262019/TabL-GraduationCohortData.pdf>                                                | 200    |

### Source 2: Maryland Report Card Website

- **URL:** <https://reportcard.msde.maryland.gov/Graphs/>
- **HTTP Status:** 200 (requires JavaScript rendering)
- **Format:** Interactive dashboard, PDF downloads for school report
  cards
- **Years:** 2017-present
- **Access:** JavaScript-rendered dashboard (no direct API discovered)
- **Geographic Levels:** State, LEA, School
- **Notes:**
  - Primary source for school-level graduation data
  - DataDownloads directory returns 403 on direct access
  - Individual school PDFs available at:
    `reportcard.msde.maryland.gov/DataDownloads/{year}/{year}/School_{schoolcode}_{year}_ENG.pdf`
  - State-level PDF:
    `reportcard.msde.maryland.gov/DataDownloads/2023/2023/State_2023_ENG.pdf`
    (verified 200)

### Source 3: Maryland Open Data Portal (RESTRICTED)

- **URL:**
  <https://opendata.maryland.gov/Education/Maryland-State-Department-of-Education-Performance/qfc2-mfn8>
- **HTTP Status:** Authentication Required (403 for API access)
- **Format:** Socrata API, CSV available if authenticated
- **Years:** 2011-present (based on description)
- **Access:** Requires login/authentication - NOT suitable for automated
  access
- **Notes:** Contains “Four-Year Cohort High School Graduation Rate” but
  blocked for programmatic access

### Source 4: Maryland Longitudinal Data System Center

- **URL:** <https://mldscenter.maryland.gov/DataDownloads.html>
- **HTTP Status:** 404 (page not found as of 2026-01-04)
- **Notes:** Previously hosted graduation-related data; may have been
  restructured

## Schema Analysis

### Data Structure from PDF Sources

The State Board presentations contain tables with the following
structure:

#### State-Level Trend Data

| Column                 | Description                       | Example                       |
|------------------------|-----------------------------------|-------------------------------|
| Year                   | Cohort graduation year (end_year) | 2024                          |
| Diploma Count          | Number of students graduating     | 58,965                        |
| Cohort Size            | Total students in cohort          | 67,349                        |
| 4-Year Graduation Rate | Percentage                        | 87.6%                         |
| 5-Year Graduation Rate | Percentage                        | 87.4% (for prior year cohort) |
| 4-Year Dropout Rate    | Percentage                        | 8.3%                          |

#### LEA-Level Data

| Column                        | Description   | Example Values                               |
|-------------------------------|---------------|----------------------------------------------|
| LEA Name                      | District name | Allegany, Anne Arundel, Baltimore City, etc. |
| 4-Year Cohort Graduation Rate | Percentage    | 71.0 - 95.0+                                 |

**Note:** Values “\>= 95.0” are used for suppression when rates are very
high (Garrett, Queen Anne’s, Talbot, Worcester in 2024).

#### Student Group Data

| Column                     | Description     | 2024 Value | 2023 Value |
|----------------------------|-----------------|------------|------------|
| Am. Ind./Native AK         | Graduation rate | 85.9%      | 84.1%      |
| Asian                      | Graduation rate | 96.2%      | 96.6%      |
| Black/African Am.          | Graduation rate | 84.7%      | 84.4%      |
| Hispanic                   | Graduation rate | 78.8%      | 71.4%      |
| Native HI/Pac. Isl.        | Graduation rate | 88.2%      | 89.8%      |
| White                      | Graduation rate | 93.4%      | 93.7%      |
| Two or More Races          | Graduation rate | 89.4%      | 89.9%      |
| Female                     | Graduation rate | 89.2%      | 90.2%      |
| Male                       | Graduation rate | 82.6%      | 85.0%      |
| Economically Disadvantaged | Graduation rate | 80.8%      | 81.6%      |
| Students with Disabilities | Graduation rate | 69.5%      | 69.0%      |
| Multilingual Learners      | Graduation rate | 66.3%      | 55.8%      |
| FARMS                      | Graduation rate | 79.8%      | 81.8%      |

### ID System

- **LEA Codes:** Maryland uses 24 Local School Systems (23 counties +
  Baltimore City)
- **Existing in package:**
  [`get_lss_codes()`](https://almartin82.github.io/mdschooldata/reference/get_lss_codes.md)
  returns 2-digit codes (01-24)
- **No school IDs in graduation PDFs** - school-level data only
  available via Report Card

### Known Data Issues

1.  **Suppression:** Rates \>= 95% shown as “\>= 95.0” in some
    presentations
2.  **PDF format:** Data must be extracted via text parsing (pdftools)
3.  **No Excel/CSV:** No structured data files found for direct download
4.  **School-level data:** Only available via JavaScript-rendered Report
    Card or individual school PDFs
5.  **Year lag:** 5-year graduation rate is always for the prior cohort
    year

## Time Series Heuristics

### Expected Ranges (based on 2015-2024 data)

| Metric                    | Expected Range  | Red Flag If            |
|---------------------------|-----------------|------------------------|
| State 4-year grad rate    | 85% - 90%       | Change \> 3% YoY       |
| State 5-year grad rate    | 87% - 91%       | Change \> 2% YoY       |
| State 4-year dropout rate | 7% - 10%        | Change \> 2% YoY       |
| Cohort size               | 63,000 - 68,000 | Change \> 5% YoY       |
| Diploma count             | 55,000 - 60,000 | Change \> 5% YoY       |
| Highest LEA grad rate     | \>= 95%         | Below 90%              |
| Lowest LEA grad rate      | 70% - 75%       | Below 65% or above 80% |

### Historical State-Level Values (for fidelity testing)

| Year | 4-Year Grad Rate | Diploma Count | Cohort Size |
|------|------------------|---------------|-------------|
| 2024 | 87.6%            | 58,965        | 67,349      |
| 2023 | 85.8%            | 58,206        | 67,829      |
| 2022 | 86.3%            | 57,860        | 67,056      |
| 2021 | 87.2%            | 57,423        | 65,850      |
| 2020 | 86.7%            | 58,275        | 67,178      |
| 2019 | 86.9%            | 55,734        | 64,164      |
| 2018 | 87.1%            | 56,704        | 65,089      |
| 2017 | 87.7%            | 55,438        | 63,238      |
| 2016 | 87.6%            | 55,586        | 63,446      |
| 2015 | 87.0%            | 55,473        | 63,775      |

### Major LEAs (should exist in all years)

| LEA                    | 2024 4-Year Rate            |
|------------------------|-----------------------------|
| Baltimore City         | 71.0% (historically lowest) |
| Baltimore County       | 85.8%                       |
| Montgomery County      | 91.8%                       |
| Prince George’s County | 80.0%                       |
| Howard County          | 93.5%                       |
| Anne Arundel County    | 88.5%                       |

## Recommended Implementation

### Priority: HIGH

- Graduation rates are a key educational metric
- Data is publicly available (PDFs)
- Fills major gap in package functionality

### Complexity: MEDIUM-HIGH

- PDF parsing required (pdftools dependency already in Suggests)
- Multiple data structures across presentation formats
- Schema varies slightly by year
- No structured data files available

### Estimated Files to Modify: 4-5

1.  `R/get_raw_graduation.R` (NEW) - Download and parse PDF files
2.  `R/process_graduation.R` (NEW) - Process raw data to standard schema
3.  `R/tidy_graduation.R` (NEW) - Convert to long format
4.  `R/fetch_graduation.R` (NEW) - Main user-facing function
5.  `R/utils.R` - May need additional helper functions

### Implementation Steps:

1.  **Add PDF parsing functions:**
    - Create `download_msde_graduation_pdf(end_year)` to fetch correct
      PDF
    - Create `parse_graduation_pdf(pdf_path, end_year)` to extract
      tables
    - Handle varying PDF layouts across years
2.  **Create data extraction functions:**
    - `extract_state_graduation_data(pdf_text)` - State-level trend data
    - `extract_lea_graduation_data(pdf_text)` - LEA-level rates
    - `extract_subgroup_graduation_data(pdf_text)` - Demographic
      breakdowns
3.  **Create main fetch function:**
    - `fetch_grad(end_year, tidy = TRUE, use_cache = TRUE)`
    - Support for `fetch_grad_multi(end_years)` for time series
4.  **Add Report Card school-level support (future enhancement):**
    - Would require browser automation or PDF parsing for individual
      school reports
    - Consider as Phase 2

### Alternative Approach: Hardcoded Data Tables

Given that: - Data changes annually (only once per year in February) -
Historical data is static - PDF parsing is fragile

Consider maintaining a versioned CSV within the package with historical
data, updated annually. This would: - Be more reliable than PDF
parsing - Allow easier testing - Work offline

## Test Requirements

### Raw Data Fidelity Tests Needed:

``` r
test_that("2024 state graduation rate matches published value", {
  skip_if_offline()
  data <- fetch_grad(2024)
  state_data <- data |> filter(type == "State", metric == "4_year_grad_rate")
  expect_equal(state_data$value, 87.6, tolerance = 0.1)
})

test_that("2024 Baltimore City rate matches published value", {
  skip_if_offline()
  data <- fetch_grad(2024)
  bc <- data |> filter(lea_name == "Baltimore City", metric == "4_year_grad_rate")
  expect_equal(bc$value, 71.0, tolerance = 0.1)
})

test_that("2024 cohort size matches published value", {
  skip_if_offline()
  data <- fetch_grad(2024)
  state <- data |> filter(type == "State", metric == "cohort_size")
  expect_equal(state$value, 67349)
})
```

### Data Quality Checks:

``` r
test_that("graduation rates in valid range", {
  data <- fetch_grad(2024, tidy = TRUE)
  rates <- data |> filter(grepl("grad_rate", metric))
  expect_true(all(rates$value >= 0 & rates$value <= 100, na.rm = TRUE))
})

test_that("all 24 LEAs present", {
  data <- fetch_grad(2024, tidy = TRUE)
  leas <- data |> filter(type == "District") |> distinct(lea_name)
  expect_equal(nrow(leas), 24)
})

test_that("year-over-year change reasonable", {
  data_24 <- fetch_grad(2024) |> filter(type == "State", metric == "4_year_grad_rate")
  data_23 <- fetch_grad(2023) |> filter(type == "State", metric == "4_year_grad_rate")
  yoy_change <- abs(data_24$value - data_23$value)
  expect_lt(yoy_change, 5)  # Less than 5 percentage points
})
```

## Challenges and Considerations

### Primary Challenge: PDF-Only Data

Maryland does not publish graduation rate data in structured formats
(Excel, CSV, API). The primary data source is PDF presentations to the
State Board of Education. This presents challenges:

1.  **Fragile parsing:** PDF layouts change, requiring ongoing
    maintenance
2.  **Text extraction quality:** pdftools may not perfectly extract
    tabular data
3.  **Multiple PDF sources:** Different URLs and formats across years

### Recommended Approach

**Phase 1 (MVP):** - Parse state-level and LEA-level data from State
Board PDFs - Support years 2019-2024 (well-documented period) - Store
parsed historical data in package for reliability

**Phase 2 (Enhancement):** - Add school-level data via Report Card PDF
parsing - Add subgroup-level data extraction - Expand historical
coverage to 2015+

### Dependencies to Add

``` r
# Already in Suggests:
pdftools  # For PDF text extraction
```

## References

- Maryland Report Card: <https://reportcard.msde.maryland.gov>
- MSDE Graduation Rate News:
  <https://news.maryland.gov/msde/state-graduation-rate/>
- State Board Documents:
  <https://marylandpublicschools.org/stateboard/Pages/Meetings.aspx>

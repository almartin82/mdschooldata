# Claude Code Instructions for mdschooldata

## Commit and PR Guidelines

- Do NOT include “Generated with Claude Code” in commit messages
- Do NOT include “Co-Authored-By: Claude” in commit messages
- Do NOT mention Claude or AI assistance in PR descriptions
- Keep commit messages clean and professional

## Project Context

This is an R package for fetching and processing Maryland school
enrollment data from the Maryland State Department of Education (MSDE).

### Data Sources (MSDE ONLY - No Federal Data)

**CRITICAL**: This package uses ONLY Maryland State Department of
Education data sources. Do NOT use: - Urban Institute Education Data
Portal - NCES Common Core of Data (CCD) - Any federal data sources

**Primary Data Sources:**

1.  **Maryland Report Card** (<https://reportcard.msde.maryland.gov>)
    - Interactive website with enrollment data
    - Data downloads at: /Graphs/#/DataDownloads/
    - Demographics at: /Graphs/#/Demographics/Enrollment
    - Requires JavaScript for full interaction (limited programmatic
      access)
2.  **MSDE Staff and Student Publications**
    (<https://marylandpublicschools.org/about/Pages/DCAA/SSP/>)
    - PDF publications with enrollment by race/ethnicity and gender
    - URL pattern: `/about/Documents/DCAA/SSP/{YYYY-1}{YYYY}Student/`
    - Files named like:
      `{YYYY-1}-{YYYY}-Enrollment-By-Race-Ethnicity-Gender-A.pdf`
    - Data collected as of September 30 each year

### Key Data Characteristics

- **ID System**:
  - LSS (Local School System) codes: 2-digit (01-24)
  - 24 school systems: 23 counties + Baltimore City
- **Data Collection Date**: September 30 of each school year
- **Available Years**: 2019-present (most reliable data)

### Key Files

- `R/fetch_enrollment.R` - Main
  [`fetch_enr()`](https://almartin82.github.io/mdschooldata/reference/fetch_enr.md)
  function
- `R/get_raw_enrollment.R` - Downloads raw data from MSDE sources
- `R/process_enrollment.R` - Transforms raw data to standard schema
- `R/tidy_enrollment.R` - Converts to long/tidy format
- `R/cache.R` - Local caching layer
- `R/utils.R` - Utility functions including LSS code mappings

### Maryland LSS Codes

    01 = Allegany         13 = Harford
    02 = Anne Arundel     14 = Howard
    03 = Baltimore City   15 = Kent
    04 = Baltimore County 16 = Montgomery
    05 = Calvert          17 = Prince George's
    06 = Caroline         18 = Queen Anne's
    07 = Carroll          19 = St. Mary's
    08 = Cecil            20 = Somerset
    09 = Charles          21 = Talbot
    10 = Dorchester       22 = Washington
    11 = Frederick        23 = Wicomico
    12 = Garrett          24 = Worcester

### Package Dependencies

- `pdftools`: Required for parsing MSDE PDF publications
- `httr`: For downloading data files
- `dplyr`, `purrr`: Data manipulation

### Related Package

This package follows patterns from
[ilschooldata](https://github.com/almartin82/ilschooldata) and other
state schooldata packages.

### Known Limitations

1.  School-level data is primarily available through the Report Card
    interactive website
2.  PDF parsing may require adjustments as MSDE changes publication
    formats
3.  Historical data before 2019 is less consistently available

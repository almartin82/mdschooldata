# mdschooldata: Fetch and Process Maryland School Enrollment Data

Downloads and processes school enrollment data from the Maryland State
Department of Education (MSDE). Provides functions for fetching
enrollment data from the Maryland Report Card system and transforming it
into tidy format for analysis.

## Main functions

- [`fetch_enr`](https://almartin82.github.io/mdschooldata/reference/fetch_enr.md):

  Fetch enrollment data for a school year

- [`fetch_enr_multi`](https://almartin82.github.io/mdschooldata/reference/fetch_enr_multi.md):

  Fetch enrollment data for multiple years

- [`tidy_enr`](https://almartin82.github.io/mdschooldata/reference/tidy_enr.md):

  Transform wide data to tidy (long) format

- [`id_enr_aggs`](https://almartin82.github.io/mdschooldata/reference/id_enr_aggs.md):

  Add aggregation level flags

- [`enr_grade_aggs`](https://almartin82.github.io/mdschooldata/reference/enr_grade_aggs.md):

  Create grade-level aggregations

- [`get_available_years`](https://almartin82.github.io/mdschooldata/reference/get_available_years.md):

  Get available year range

## Cache functions

- [`cache_status`](https://almartin82.github.io/mdschooldata/reference/cache_status.md):

  View cached data files

- [`clear_cache`](https://almartin82.github.io/mdschooldata/reference/clear_cache.md):

  Remove cached data files

## ID System

Maryland uses a hierarchical system of 24 Local School Systems (LSS):

- 23 counties plus Baltimore City

- LSS Numbers: 2-digit codes (01-24)

- School Numbers: 4-digit codes within each LSS

## Data Sources

Data is sourced exclusively from the Maryland State Department of
Education (MSDE):

- Maryland Report Card: <https://reportcard.msde.maryland.gov/>

- MSDE Staff and Student Publications:
  <https://marylandpublicschools.org/about/Pages/DCAA/SSP/>

Note: This package does NOT use federal data sources (NCES, Urban
Institute, etc.). All data comes directly from Maryland state sources.

## Data Availability

Maryland enrollment data from MSDE sources:

- 2019-present: Data available via MSDE publications and Report Card

- Data is collected as of September 30 each school year

## See also

Useful links:

- <https://almartin82.github.io/mdschooldata>

- <https://github.com/almartin82/mdschooldata>

- Report bugs at <https://github.com/almartin82/mdschooldata/issues>

## Author

**Maintainer**: Al Martin <almartin@example.com>

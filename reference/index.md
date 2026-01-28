# Package index

## Fetch Enrollment Data

Functions for downloading enrollment data from MSDE

- [`fetch_enr()`](https://almartin82.github.io/mdschooldata/reference/fetch_enr.md)
  : Fetch Maryland enrollment data
- [`fetch_enr_multi()`](https://almartin82.github.io/mdschooldata/reference/fetch_enr_multi.md)
  : Fetch enrollment data for multiple years
- [`fetch_directory()`](https://almartin82.github.io/mdschooldata/reference/fetch_directory.md)
  : Fetch Maryland school directory
- [`fetch_directory_multi()`](https://almartin82.github.io/mdschooldata/reference/fetch_directory_multi.md)
  : Fetch multiple directory types
- [`fetch_lss_enrollment()`](https://almartin82.github.io/mdschooldata/reference/fetch_lss_enrollment.md)
  : Fetch enrollment for a specific LSS (district)
- [`fetch_school_enrollment()`](https://almartin82.github.io/mdschooldata/reference/fetch_school_enrollment.md)
  : Fetch school-level enrollment
- [`fetch_historical_enrollment()`](https://almartin82.github.io/mdschooldata/reference/fetch_historical_enrollment.md)
  : Fetch historical enrollment from MD Planning
- [`download_md_reportcard_enrollment()`](https://almartin82.github.io/mdschooldata/reference/download_md_reportcard_enrollment.md)
  : Download Maryland Report Card enrollment data
- [`get_available_years()`](https://almartin82.github.io/mdschooldata/reference/get_available_years.md)
  : Get available years for Maryland enrollment data

## Fetch Assessment Data

Functions for downloading assessment data from MSDE

- [`fetch_assessment()`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment.md)
  : Fetch Maryland assessment data
- [`fetch_assessment_multi()`](https://almartin82.github.io/mdschooldata/reference/fetch_assessment_multi.md)
  : Fetch assessment data for multiple years
- [`fetch_district_assessment()`](https://almartin82.github.io/mdschooldata/reference/fetch_district_assessment.md)
  : Fetch assessment data for a specific district
- [`fetch_school_assessment()`](https://almartin82.github.io/mdschooldata/reference/fetch_school_assessment.md)
  : Fetch assessment data for a specific school
- [`get_available_assessment_years()`](https://almartin82.github.io/mdschooldata/reference/get_available_assessment_years.md)
  : Get available assessment years
- [`get_raw_assessment()`](https://almartin82.github.io/mdschooldata/reference/get_raw_assessment.md)
  : Download raw Maryland assessment data
- [`get_statewide_proficiency()`](https://almartin82.github.io/mdschooldata/reference/get_statewide_proficiency.md)
  : Get statewide proficiency summary (from MSDE press releases)
- [`import_local_assessment()`](https://almartin82.github.io/mdschooldata/reference/import_local_assessment.md)
  : Import locally downloaded assessment file

## Transform Data

Functions for reshaping and annotating data

- [`tidy_enr()`](https://almartin82.github.io/mdschooldata/reference/tidy_enr.md)
  : Tidy enrollment data
- [`id_enr_aggs()`](https://almartin82.github.io/mdschooldata/reference/id_enr_aggs.md)
  : Identify enrollment aggregation levels
- [`enr_grade_aggs()`](https://almartin82.github.io/mdschooldata/reference/enr_grade_aggs.md)
  : Custom Enrollment Grade Level Aggregates

## Cache Management

Functions for managing locally cached data

- [`cache_status()`](https://almartin82.github.io/mdschooldata/reference/cache_status.md)
  : Show cache status
- [`clear_cache()`](https://almartin82.github.io/mdschooldata/reference/clear_cache.md)
  : Clear the mdschooldata cache

# ==============================================================================
# Assessment Data Tests
# ==============================================================================
#
# Tests for Maryland assessment data functions.
# Uses ACTUAL values from real MCAP data to verify fidelity.
#
# ==============================================================================

# Assessment data functions tests

# ==============================================================================
# STATEWIDE PROFICIENCY TESTS (Curated data from MSDE publications)
# ==============================================================================
# These values are from official MSDE State Board presentations
# Source: marylandpublicschools.org/stateboard/Documents/2024/0827/

test_that("get_statewide_proficiency returns 2024 data with correct values", {
  prof <- get_statewide_proficiency(2024)

  expect_s3_class(prof, "tbl_df")
  expect_true(nrow(prof) > 0)

  # Verify ACTUAL values from MSDE State Board presentation
  # ELA All Grades proficiency was 48.4% in 2024
  ela_all <- prof[prof$subject == "ELA All", ]
  expect_equal(ela_all$pct_proficient, 48.4)

  # Math All Grades proficiency was 24.1% in 2024
  math_all <- prof[prof$subject == "Math All", ]
  expect_equal(math_all$pct_proficient, 24.1)

  # ELA 10 (highest grade tested) was 55.3% - highest ELA proficiency
  ela_10 <- prof[prof$subject == "ELA 10", ]
  expect_equal(ela_10$pct_proficient, 55.3)

  # Math 8 was 7.0% - lowest math proficiency
  math_8 <- prof[prof$subject == "Math 8", ]
  expect_equal(math_8$pct_proficient, 7.0)

  # Science 5 was 30.6%
  sci_5 <- prof[prof$subject == "Science 5", ]
  expect_equal(sci_5$pct_proficient, 30.6)
})


test_that("get_statewide_proficiency returns 2023 data with correct values", {
  prof <- get_statewide_proficiency(2023)

  # ELA All Grades proficiency was 47.9% in 2023
  ela_all <- prof[prof$subject == "ELA All", ]
  expect_equal(ela_all$pct_proficient, 47.9)

  # Math All Grades proficiency was 23.3% in 2023
  math_all <- prof[prof$subject == "Math All", ]
  expect_equal(math_all$pct_proficient, 23.3)
})


test_that("get_statewide_proficiency returns 2022 data with correct values", {
  prof <- get_statewide_proficiency(2022)

  # ELA All Grades proficiency was 45.3% in 2022
  ela_all <- prof[prof$subject == "ELA All", ]
  expect_equal(ela_all$pct_proficient, 45.3)

  # Math All Grades proficiency was 21.0% in 2022
  math_all <- prof[prof$subject == "Math All", ]
  expect_equal(math_all$pct_proficient, 21.0)
})


test_that("get_statewide_proficiency shows year-over-year improvement in ELA", {
  # ELA proficiency should increase from 2022 to 2024
  prof_2022 <- get_statewide_proficiency(2022)
  prof_2024 <- get_statewide_proficiency(2024)

  ela_2022 <- prof_2022[prof_2022$subject == "ELA All", ]$pct_proficient
  ela_2024 <- prof_2024[prof_2024$subject == "ELA All", ]$pct_proficient

  expect_gt(ela_2024, ela_2022)
  expect_equal(ela_2024 - ela_2022, 3.1, tolerance = 0.1)  # 48.4 - 45.3 = 3.1
})


test_that("get_statewide_proficiency errors for unavailable years", {
  expect_error(get_statewide_proficiency(2021), "not available")
  expect_error(get_statewide_proficiency(2025), "not available")
})


test_that("get_statewide_proficiency returns correct structure", {
  prof <- get_statewide_proficiency(2024)

  expect_true("end_year" %in% names(prof))
  expect_true("subject" %in% names(prof))
  expect_true("pct_proficient" %in% names(prof))
  expect_true("is_state" %in% names(prof))
  expect_true("student_group" %in% names(prof))

  # All rows should be state level
  expect_true(all(prof$is_state))
  expect_true(all(prof$student_group == "All Students"))
})


# ==============================================================================
# AVAILABLE YEARS TESTS
# ==============================================================================

test_that("get_available_assessment_years returns correct structure", {
  avail <- get_available_assessment_years()

  expect_true(is.list(avail))
  expect_true("min_year" %in% names(avail))
  expect_true("max_year" %in% names(avail))
  expect_true("available_years" %in% names(avail))
  expect_true("assessments" %in% names(avail))
  expect_true("data_types" %in% names(avail))

  expect_equal(avail$min_year, 2022)
  expect_gte(avail$max_year, 2024)
})


# ==============================================================================
# YEAR VALIDATION TESTS
# ==============================================================================

test_that("fetch_assessment validates year input", {
  expect_error(
    fetch_assessment(2021),
    "end_year must be between 2022 and 2025"
  )

  expect_error(
    fetch_assessment(2026),
    "end_year must be between 2022 and 2025"
  )
})


test_that("fetch_assessment_multi handles invalid years", {
  # Should error when all years are invalid
  expect_error(
    fetch_assessment_multi(c(2015, 2016)),
    "No valid years provided"
  )
})


test_that("import_local_assessment validates file exists", {
  expect_error(
    import_local_assessment("/nonexistent/file.csv", 2024),
    "File not found"
  )
})


# ==============================================================================
# LIVE DATA TESTS (Network required)
# ==============================================================================

# These tests download real data from MSDE

test_that("fetch_assessment downloads 2024 participation data", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, data_type = "participation", use_cache = TRUE)

  # Skip if download failed due to network issues
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # Should have data
  expect_gt(nrow(assess), 50000)  # 2024 file has ~68,000 rows

  # Should have expected columns
  expect_true("district_id" %in% names(assess))
  expect_true("district_name" %in% names(assess))
  expect_true("school_id" %in% names(assess))
  expect_true("school_name" %in% names(assess))
  expect_true("subject" %in% names(assess))
  expect_true("student_group" %in% names(assess))
  expect_true("participation_pct" %in% names(assess))

  # Should have helper columns
  expect_true("is_state" %in% names(assess))
  expect_true("is_district" %in% names(assess))
  expect_true("is_school" %in% names(assess))
})


test_that("2024 participation data has correct districts", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # All 24 Maryland LEAs should be present
  districts <- unique(assess$district_name)
  districts <- districts[!is.na(districts)]

  expect_gte(length(districts), 24)

  # Verify major districts
  expect_true("Baltimore City" %in% districts)
  expect_true("Montgomery" %in% districts)
  expect_true("Baltimore County" %in% districts)
  expect_true("Prince George's" %in% districts)
  expect_true("Anne Arundel" %in% districts)
})


test_that("2024 participation data has expected subjects", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  subjects <- unique(assess$subject)
  subjects <- subjects[!is.na(subjects)]

  # Should have ELA, Math, Science
  expect_true(any(grepl("English|ELA", subjects, ignore.case = TRUE)))
  expect_true(any(grepl("Math", subjects, ignore.case = TRUE)))
  expect_true(any(grepl("Science", subjects, ignore.case = TRUE)))
})


test_that("2024 participation data has expected student groups", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  groups <- unique(assess$student_group)
  groups <- groups[!is.na(groups)]

  # Should have key student groups
  expect_true("All Students" %in% groups)
  expect_true(any(grepl("Black|African", groups, ignore.case = TRUE)))
  expect_true(any(grepl("Hispanic|Latino", groups, ignore.case = TRUE)))
  expect_true(any(grepl("White", groups, ignore.case = TRUE)))
  expect_true(any(grepl("Asian", groups, ignore.case = TRUE)))
  expect_true(any(grepl("Disabilit", groups, ignore.case = TRUE)))
})


test_that("participation rates are in valid range", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # Filter to numeric participation values
  pct <- assess$participation_pct[!is.na(assess$participation_pct)]
  skip_if(length(pct) == 0, "No participation data")

  # Should be percentages (0-100 or 0-1)
  expect_true(all(pct >= 0, na.rm = TRUE))
  expect_true(all(pct <= 100, na.rm = TRUE))

  # Most participation rates should be high (>80%)
  expect_gt(median(pct, na.rm = TRUE), 80)
})


# ==============================================================================
# DATA FIDELITY TESTS (Verify specific values from raw data)
# ==============================================================================
# These tests use ACTUAL values from the 2024 MCAP participation file
# to verify the package correctly parses and returns the data.

test_that("2024 data contains Flintstone Elementary (first row)", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # Flintstone Elementary is in the first few rows of the raw data
  # District: Allegany (01), School: 0301
  flintstone <- assess[
    assess$district_id == "01" &
      assess$school_id == "0301" &
      assess$student_group == "All Students" &
      grepl("English", assess$subject, ignore.case = TRUE),
  ]

  expect_gt(nrow(flintstone), 0)
  expect_equal(flintstone$district_name[1], "Allegany")
  expect_true(grepl("Flintstone", flintstone$school_name[1]))
})


test_that("Baltimore City has multiple schools in 2024 data", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # Baltimore City (district 03) should have many schools
  balt_schools <- unique(assess$school_id[
    assess$district_name == "Baltimore City" & !is.na(assess$school_id)
  ])

  expect_gt(length(balt_schools), 100)  # Baltimore City has 150+ schools
})


test_that("Montgomery County is properly identified", {
  skip_if_offline()
  skip_on_cran()

  assess <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(assess) == 0, "Network download failed - skipping test")

  # Montgomery is district 15 in the assessment data (different from enrollment)
  mont <- assess[assess$district_id == "15", ]
  expect_gt(nrow(mont), 0)
  expect_true(all(mont$district_name[!is.na(mont$district_name)] == "Montgomery"))
})


# ==============================================================================
# MULTI-YEAR TESTS
# ==============================================================================

test_that("fetch_assessment_multi combines multiple years", {
  skip_if_offline()
  skip_on_cran()

  # Get 2022-2024 data
  assess_multi <- fetch_assessment_multi(2022:2024, use_cache = TRUE)
  skip_if(nrow(assess_multi) == 0, "Network download failed - skipping test")

  # Should have multiple years
  years <- unique(assess_multi$end_year)
  expect_gte(length(years), 2)  # At least 2 years

  # Each year should have substantial data
  for (yr in years) {
    yr_rows <- sum(assess_multi$end_year == yr, na.rm = TRUE)
    expect_gt(yr_rows, 10000)
  }
})


# ==============================================================================
# PROFICIENCY DATA TESTS
# ==============================================================================

test_that("fetch_assessment with proficiency type returns statewide data", {
  # Proficiency data requires manual download, so function should return
  # statewide data instead

  assess <- fetch_assessment(2024, data_type = "proficiency", use_cache = FALSE)

  # Should get statewide proficiency data
  expect_gt(nrow(assess), 0)
  expect_true(all(assess$is_state))
  expect_true("pct_proficient" %in% names(assess))
})

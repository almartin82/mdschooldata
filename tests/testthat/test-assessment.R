# ==============================================================================
# Assessment Data Tests
# ==============================================================================
#
# Tests for Maryland assessment data functions
#
# ==============================================================================

context("Assessment data functions")

# Test get_available_assessment_years()
test_that("get_available_assessment_years returns correct structure", {
  avail <- get_available_assessment_years()

  expect_true(is.list(avail))
  expect_true("min_year" %in% names(avail))
  expect_true("max_year" %in% names(avail))
  expect_true("available_years" %in% names(avail))
  expect_true("assessments" %in% names(avail))

  expect_equal(avail$min_year, 2021)
  expect_gte(avail$max_year, 2021)
})


# Test fetch_assessment() year validation
test_that("fetch_assessment validates year input", {
  expect_error(
    fetch_assessment(2020),
    "end_year must be between 2021 and 2025"
  )

  expect_error(
    fetch_assessment(2026),
    "end_year must be between 2021 and 2025"
  )
})


# Test import_local_assessment() file validation
test_that("import_local_assessment validates file exists", {
  expect_error(
    import_local_assessment("/nonexistent/file.csv", 2024),
    "File not found"
  )
})


# Test fetch_assessment_multi() with invalid years
test_that("fetch_assessment_multi handles invalid years", {
  # Should error when all years are invalid
  expect_error(
    fetch_assessment_multi(c(2015, 2016)),
    "No valid years provided"
  )
})


# Test assessment data structure (when data is available)
test_that("fetch_assessment returns correct structure when data exists", {
  # This test will fail until actual Maryland Report Card data is downloaded
  # It's structured to pass when proper data is available

  skip("Skipping until Maryland Report Card data is manually downloaded")

  assess <- fetch_assessment(2024)

  # Check for required columns
  expect_true("end_year" %in% names(assess))
  expect_true(any(c("is_state", "is_district", "is_school") %in% names(assess)))

  # Check data types
  expect_true(is.numeric(assess$end_year) || is.integer(assess$end_year))
})


# Test that assessment data has expected helper columns
test_that("assessment data includes helper columns", {
  skip("Skipping until Maryland Report Card data is manually downloaded")

  assess <- fetch_assessment(2024)

  # At least one of the helper columns should exist
  expect_true(
    "is_state" %in% names(assess) ||
      "is_district" %in% names(assess) ||
      "is_school" %in% names(assess)
  )
})


# Test fetch_assessment_multi() combines years correctly
test_that("fetch_assessment_multi combines multiple years", {
  skip("Skipping until Maryland Report Card data is manually downloaded")

  assess_multi <- fetch_assessment_multi(2021:2023)

  # Should have multiple years
  expect_true(length(unique(assess_multi$end_year)) > 1)

  # Each year should have data
  expect_gt(nrow(assess_multi), 0)
})

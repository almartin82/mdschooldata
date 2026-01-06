# ==============================================================================
# Directory Data Tests
# ==============================================================================

context("Directory data fetching")

# Helper function to check network connectivity
skip_if_offline <- function() {
  tryCatch({
    response <- httr::HEAD("https://www.google.com", httr::timeout(5))
    if (httr::http_error(response)) skip("No network connectivity")
  }, error = function(e) skip("No network connectivity"))
}

# Test that URL returns HTTP 200
test_that("Directory URL returns HTTP 200", {
  skip_if_offline()

  response <- httr::HEAD(
    "https://hub.arcgis.com/api/v3/datasets/1382ea15257847f8b95b258832e5a981_6/downloads/data?format=csv&spatialRefId=3857&where=1%3D1",
    httr::timeout(30)
  )

  expect_equal(httr::status_code(response), 200)
})


# Test that file downloads correctly
test_that("Can download directory CSV file", {
  skip_if_offline()

  url <- "https://hub.arcgis.com/api/v3/datasets/1382ea15257847f8b95b258832e5a981_6/downloads/data?format=csv&spatialRefId=3857&where=1%3D1"

  temp <- tempfile(fileext = ".csv")

  response <- httr::GET(
    url,
    httr::write_disk(temp, overwrite = TRUE),
    httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)"),
    httr::timeout(120)
  )

  expect_equal(httr::status_code(response), 200)
  expect_gt(file.info(temp)$size, 1000)

  # Verify it's a valid CSV file
  lines <- readLines(temp, n = 5, warn = FALSE)
  expect_true(length(lines) > 0)

  unlink(temp)
})


# Test fetch_directory function
test_that("fetch_directory returns valid data structure", {
  skip_if_offline()

  # Get all schools
  dir_all <- fetch_directory(use_cache = FALSE)

  expect_s3_class(dir_all, "data.frame")
  expect_true(nrow(dir_all) > 0)

  # Check for required columns
  required_cols <- c("directory_type", "school_name", "state")
  expect_true(all(required_cols %in% names(dir_all)))

  # Check state is always MD
  expect_true(all(dir_all$state == "MD"))
})


test_that("fetch_directory can get specific directory type", {
  skip_if_offline()

  # Get only charter schools
  charter <- fetch_directory("charter_schools", use_cache = FALSE)

  expect_s3_class(charter, "data.frame")
  expect_true(all(charter$directory_type == "charter_schools"))
  expect_true(nrow(charter) > 0)

  # MD has several dozen charter schools
  expect_gt(nrow(charter), 10)
  expect_lt(nrow(charter), 500)  # Sanity check
})


test_that("fetch_directory_multi combines types", {
  skip_if_offline()

  # Currently only one type available, but test the function works
  schools <- fetch_directory_multi(c("charter_schools"), use_cache = FALSE)

  expect_s3_class(schools, "data.frame")
  expect_true(nrow(schools) > 0)
  expect_true("charter_schools" %in% unique(schools$directory_type))
})


# Data quality tests
test_that("Directory data has no missing school names", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  expect_false(any(is.na(dir_data$school_name) | dir_data$school_name == ""))
})


test_that("Zip codes are cleaned properly", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Zip column should contain only digits (or NA)
  zips <- dir_data$zip[!is.na(dir_data$zip)]
  if (length(zips) > 0) {
    expect_true(all(grepl("^[0-9]+$", zips)))
  }
})


test_that("School types are properly labeled", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Check that all schools are labeled as Charter
  expect_true(all(dir_data$school_type == "Charter"))
})


# Known value tests (fidelity tests)
test_that("Expected number of charter schools", {
  skip_if_offline()

  charter <- fetch_directory("charter_schools", use_cache = FALSE)

  # MD has several dozen charter schools
  expect_gt(nrow(charter), 10)
  expect_lt(nrow(charter), 500)  # Sanity check
})


test_that("Major counties have schools", {
  skip_if_offline()

  charter <- fetch_directory(use_cache = FALSE)

  # Check for major MD counties
  major_counties <- c("Baltimore City", "Anne Arundel", "Prince George's", "Montgomery")

  found_counties <- 0
  for (county in major_counties) {
    if (any(grepl(county, charter$county, ignore.case = TRUE))) {
      found_counties <- found_counties + 1
    }
  }

  expect_true(found_counties >= 2, info = paste("Should have schools in at least 2 major counties, found", found_counties))
})


test_that("Required columns are present", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  expected_cols <- c("directory_type", "school_name", "city", "state", "zip")

  for (col in expected_cols) {
    expect_true(col %in% names(dir_data), info = paste("Missing column:", col))
  }
})


test_that("School names are unique", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = FALSE)

  # Check that school names are mostly unique (some may legitimately have duplicates)
  school_duplicates <- sum(duplicated(dir_data$school_name))
  expect_true(school_duplicates < nrow(dir_data) * 0.1,
              info = paste("Too many duplicate school names:", school_duplicates))
})

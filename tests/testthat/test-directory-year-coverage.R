# ==============================================================================
# Directory Data Tests for mdschooldata
# ==============================================================================
#
# Tests for the Maryland school directory data, which currently provides
# charter school information from the MD iMAP ArcGIS service.
#
# Tests cover:
# - Required fields present
# - Entity counts within expected range
# - Known entity lookup (major counties)
# - Data quality (no missing names, valid zips, valid state)
# - Correct school types
#
# ==============================================================================

library(testthat)

# ==============================================================================
# STRUCTURE AND REQUIRED FIELDS
# ==============================================================================

test_that("fetch_directory returns data with required columns", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  expect_s3_class(dir_data, "data.frame")
  expect_true(nrow(dir_data) > 0, info = "Directory returned 0 rows")

  required_cols <- c("directory_type", "school_name", "city",
                     "state", "zip")
  for (col in required_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Missing required column:", col))
  }
})

test_that("fetch_directory data has standard optional columns", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  # These columns should be present in the MD directory
  optional_cols <- c("address", "county", "grades", "school_type")
  for (col in optional_cols) {
    expect_true(col %in% names(dir_data),
                info = paste("Missing optional column:", col))
  }
})

# ==============================================================================
# ENTITY COUNTS
# ==============================================================================

test_that("fetch_directory returns reasonable number of charter schools", {
  skip_if_offline()

  dir_data <- fetch_directory("charter_schools", use_cache = TRUE)

  # MD has several dozen charter schools (~40-60 as of recent data)
  expect_true(nrow(dir_data) > 20,
              info = paste("Only", nrow(dir_data), "charter schools found"))
  expect_true(nrow(dir_data) < 200,
              info = paste("Too many charter schools:", nrow(dir_data)))
})

test_that("fetch_directory 'all' returns at least as many as charter_schools", {
  skip_if_offline()

  all_data <- fetch_directory("all", use_cache = TRUE)
  charter_data <- fetch_directory("charter_schools", use_cache = TRUE)

  expect_true(nrow(all_data) >= nrow(charter_data),
              info = "'all' should have at least as many rows as charter_schools")
})

# ==============================================================================
# KNOWN ENTITY LOOKUPS
# ==============================================================================

test_that("Baltimore City charter schools are present", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  balt_charters <- dir_data[grepl("Baltimore City", dir_data$county,
                                   ignore.case = TRUE), ]
  expect_true(nrow(balt_charters) > 0,
              info = "No Baltimore City charter schools found")
  # Baltimore City should have a significant number of charter schools
  expect_true(nrow(balt_charters) > 10,
              info = paste("Only", nrow(balt_charters),
                           "Baltimore City charters found, expected 10+"))
})

test_that("Prince George's County charter schools present", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  pg_charters <- dir_data[grepl("Prince George", dir_data$county,
                                 ignore.case = TRUE), ]
  expect_true(nrow(pg_charters) > 0,
              info = "No Prince George's County charter schools found")
})

test_that("Multiple counties have charter schools", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  counties_with_charters <- unique(dir_data$county[!is.na(dir_data$county)])
  expect_true(length(counties_with_charters) >= 2,
              info = paste("Only", length(counties_with_charters),
                           "counties have charter schools"))
})

# ==============================================================================
# DATA QUALITY
# ==============================================================================

test_that("No missing school names", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  expect_false(any(is.na(dir_data$school_name) | dir_data$school_name == ""),
               info = "Found missing school names in directory")
})

test_that("All schools are in Maryland (state = MD)", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  expect_true(all(dir_data$state == "MD"),
              info = "Found non-MD state values in directory")
})

test_that("Zip codes are numeric-only (cleaned)", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  zips <- dir_data$zip[!is.na(dir_data$zip)]
  if (length(zips) > 0) {
    expect_true(all(grepl("^[0-9]+$", zips)),
                info = "Found non-numeric characters in zip codes")
  }
})

test_that("Zip codes are valid Maryland zips (20xxx or 21xxx)", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  zips <- dir_data$zip[!is.na(dir_data$zip) & dir_data$zip != ""]
  if (length(zips) > 0) {
    # MD zip codes start with 20 or 21
    md_zips <- grepl("^(20|21)", zips)
    # Allow some tolerance (a few might be edge cases)
    expect_true(mean(md_zips) > 0.9,
                info = paste("Only", round(mean(md_zips) * 100, 1),
                             "% of zips start with 20xxx/21xxx"))
  }
})

test_that("School types are properly labeled", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  # All schools in charter_schools directory should be Charter type
  if ("school_type" %in% names(dir_data)) {
    charter_rows <- dir_data[dir_data$directory_type == "charter_schools", ]
    if (nrow(charter_rows) > 0) {
      expect_true(all(charter_rows$school_type == "Charter"),
                  info = "Some charter school rows have wrong school_type")
    }
  }
})

test_that("Directory type column is consistent", {
  skip_if_offline()

  dir_data <- fetch_directory("charter_schools", use_cache = TRUE)

  expect_true(all(dir_data$directory_type == "charter_schools"),
              info = "directory_type should all be 'charter_schools'")
})

test_that("School names are mostly unique", {
  skip_if_offline()

  dir_data <- fetch_directory(use_cache = TRUE)

  n_dupes <- sum(duplicated(dir_data$school_name))
  expect_true(n_dupes / nrow(dir_data) < 0.10,
              info = paste("Too many duplicate school names:",
                           n_dupes, "of", nrow(dir_data)))
})

# ==============================================================================
# FETCH_DIRECTORY_MULTI TESTS
# ==============================================================================

test_that("fetch_directory_multi combines charter_schools", {
  skip_if_offline()

  multi <- fetch_directory_multi(c("charter_schools"), use_cache = TRUE)

  expect_s3_class(multi, "data.frame")
  expect_true(nrow(multi) > 0, info = "directory_multi returned 0 rows")
  expect_true("charter_schools" %in% unique(multi$directory_type),
              info = "charter_schools not in directory_type")
})

test_that("fetch_directory_multi rejects invalid types", {
  expect_error(fetch_directory_multi(c("nonexistent_type")),
               "Invalid directory types")
})

# ==============================================================================
# INPUT VALIDATION
# ==============================================================================

test_that("fetch_directory rejects invalid directory_type", {
  expect_error(fetch_directory("invalid_type"),
               "Invalid directory_type")
})

test_that("fetch_directory accepts 'all' type", {
  skip_if_offline()

  dir_data <- fetch_directory("all", use_cache = TRUE)
  expect_s3_class(dir_data, "data.frame")
  expect_true(nrow(dir_data) > 0, info = "all directory returned 0 rows")
})

test_that("fetch_directory accepts 'charter_schools' type", {
  skip_if_offline()

  dir_data <- fetch_directory("charter_schools", use_cache = TRUE)
  expect_s3_class(dir_data, "data.frame")
  expect_true(nrow(dir_data) > 0,
              info = "charter_schools directory returned 0 rows")
})

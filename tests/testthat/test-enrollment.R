# Tests for enrollment functions
# Note: Most tests are marked as skip_on_cran since they require network access

test_that("safe_numeric handles various inputs", {
  # Normal numbers
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("1,234"), 1234)

  # Already numeric
  expect_equal(safe_numeric(100), 100)

  # Suppressed values
  expect_true(is.na(safe_numeric("*")))
  expect_true(is.na(safe_numeric("-1")))
  expect_true(is.na(safe_numeric("<5")))
  expect_true(is.na(safe_numeric("")))
  expect_true(is.na(safe_numeric("DS")))
  expect_true(is.na(safe_numeric("SP")))
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric(">95")))

  # Whitespace handling
  expect_equal(safe_numeric("  100  "), 100)
})

test_that("get_lss_codes returns all 24 Maryland school systems", {
  lss <- get_lss_codes()

  expect_equal(length(lss), 24)
  expect_equal(names(lss)[1], "01")
  expect_equal(names(lss)[24], "24")

  # Check some known LSS
  expect_equal(lss["03"], c("03" = "Baltimore City"))
  expect_equal(lss["16"], c("16" = "Montgomery"))
  expect_equal(lss["17"], c("17" = "Prince George's"))
})

test_that("validate_year rejects invalid years", {
  # Too old - default min is 2014 (when MD Planning data begins)
  expect_error(validate_year(2000), "must be between")
  expect_error(validate_year(2013), "must be between")

  # Too new
  expect_error(validate_year(2050), "must be between")

  # Valid years should not error (2014 is default min)
  expect_true(validate_year(2020))
  expect_true(validate_year(2024))
  expect_true(validate_year(2014))  # Default min

  # Test with custom min_year
  expect_error(validate_year(2015, min_year = 2016), "must be between")
  expect_true(validate_year(2016, min_year = 2016))
})

test_that("format_school_year formats correctly", {
  expect_equal(format_school_year(2024), "2023-24")
  expect_equal(format_school_year(2020), "2019-20")
  expect_equal(format_school_year(2003), "2002-03")
})

test_that("get_available_years returns expected structure", {
  years <- get_available_years()

  expect_true(is.list(years))
  expect_true("min_year" %in% names(years))
  expect_true("max_year" %in% names(years))
  expect_true("available" %in% names(years))
  expect_true("demographic_years" %in% names(years))

  # MD Planning provides data from 2014+
  expect_equal(years$min_year, 2014)
  expect_true(years$max_year >= 2024)
  expect_true(length(years$available) >= 10)  # 2014-2024 = 11 years
  # Demographic data (from MSDE) available from 2019+
  expect_true(min(years$demographic_years) == 2019)
})

test_that("get_cache_dir returns valid path", {
  cache_dir <- get_cache_dir()
  expect_true(is.character(cache_dir))
  expect_true(grepl("mdschooldata", cache_dir))
})

test_that("cache functions work correctly", {
  # Test cache path generation
  path <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024.rds", path))

  path_wide <- get_cache_path(2023, "wide")
  expect_true(grepl("enr_wide_2023.rds", path_wide))

  # Test cache_exists returns FALSE for non-existent cache
  expect_false(cache_exists(9999, "tidy"))
})

test_that("create_enrollment_template returns valid structure", {
  template <- create_enrollment_template(2024)

  expect_true(is.data.frame(template))
  expect_equal(template$end_year[1], 2024)
  expect_equal(template$type[1], "State")
  expect_true("row_total" %in% names(template))
  expect_true("white" %in% names(template))
  expect_true("black" %in% names(template))
  expect_true("hispanic" %in% names(template))

  # Should have 25 rows (1 state + 24 districts)
  expect_equal(nrow(template), 25)
})

test_that("standardize_column_names maps correctly", {
  df <- data.frame(
    LSSNumber = "01",
    LSSName = "Allegany",
    Enrollment = 100,
    White = 50,
    Black = 30,
    Hispanic = 20,
    stringsAsFactors = FALSE
  )

  result <- standardize_column_names(df)

  expect_true("district_id" %in% names(result))
  expect_true("district_name" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("white" %in% names(result))
  expect_true("black" %in% names(result))
  expect_true("hispanic" %in% names(result))
})

test_that("ensure_standard_columns adds missing columns", {
  df <- data.frame(
    end_year = 2024,
    type = "District",
    district_id = "01",
    row_total = 100,
    stringsAsFactors = FALSE
  )

  result <- ensure_standard_columns(df, 2024)

  expect_true("campus_id" %in% names(result))
  expect_true("campus_name" %in% names(result))
  expect_true("white" %in% names(result))
  expect_true("black" %in% names(result))
  expect_true("grade_01" %in% names(result))
  expect_true("grade_12" %in% names(result))
})

test_that("create_state_aggregate sums correctly", {
  district_df <- data.frame(
    end_year = c(2024, 2024),
    type = c("District", "District"),
    district_id = c("01", "02"),
    district_name = c("Allegany", "Anne Arundel"),
    row_total = c(100, 200),
    white = c(50, 100),
    black = c(30, 50),
    stringsAsFactors = FALSE
  )

  state <- create_state_aggregate(district_df, 2024)

  expect_equal(state$type, "State")
  expect_equal(state$row_total, 300)
  expect_equal(state$white, 150)
  expect_equal(state$black, 80)
  expect_equal(state$district_name, "Maryland")
})

# Integration tests (require network access)
test_that("fetch_enr validates year parameter", {
  expect_error(fetch_enr(2000), "must be between")
  expect_error(fetch_enr(2050), "must be between")
})

test_that("fetch_enr_multi validates years", {
  # 2000-2001 are before the min_year of 2014
  expect_error(fetch_enr_multi(c(2000, 2001)), "Invalid years")
})

test_that("tidy_enr produces correct long format", {
  # Create sample wide data
  wide <- data.frame(
    end_year = 2024,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Maryland",
    campus_name = NA_character_,
    row_total = 900000,
    white = 270000,
    black = 300000,
    hispanic = 210000,
    asian = 60000,
    pacific_islander = 1000,
    native_american = 2000,
    multiracial = 50000,
    male = 460000,
    female = 440000,
    grade_pk = 50000,
    grade_k = 65000,
    grade_01 = 66000,
    stringsAsFactors = FALSE
  )

  tidy_result <- tidy_enr(wide)

  # Check structure
  expect_true("grade_level" %in% names(tidy_result))
  expect_true("subgroup" %in% names(tidy_result))
  expect_true("n_students" %in% names(tidy_result))
  expect_true("pct" %in% names(tidy_result))

  # Check subgroups include expected values
  subgroups <- unique(tidy_result$subgroup)
  expect_true("total_enrollment" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("white" %in% subgroups)
  expect_true("black" %in% subgroups)
  expect_true("male" %in% subgroups)
  expect_true("female" %in% subgroups)

  # Check grade levels
  grade_levels <- unique(tidy_result$grade_level)
  expect_true("TOTAL" %in% grade_levels)
  expect_true("PK" %in% grade_levels)
  expect_true("K" %in% grade_levels)
  expect_true("01" %in% grade_levels)
})

test_that("id_enr_aggs adds correct flags", {
  tidy_data <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "0100"),
    district_name = c("Maryland", "Allegany", "Allegany"),
    campus_name = c(NA, NA, "Test School"),
    grade_level = c("TOTAL", "TOTAL", "TOTAL"),
    subgroup = c("total_enrollment", "total_enrollment", "total_enrollment"),
    n_students = c(900000, 10000, 500),
    pct = c(1, 1, 1),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(tidy_data)

  # Check flags exist
  expect_true("is_state" %in% names(result))
  expect_true("is_district" %in% names(result))
  expect_true("is_campus" %in% names(result))

  # Check flags are correct
  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_campus, c(FALSE, FALSE, TRUE))
})

test_that("enr_grade_aggs creates correct aggregations", {
  tidy_data <- data.frame(
    end_year = rep(2024, 5),
    type = rep("State", 5),
    district_id = rep(NA_character_, 5),
    campus_id = rep(NA_character_, 5),
    district_name = rep("Maryland", 5),
    campus_name = rep(NA_character_, 5),
    grade_level = c("K", "01", "02", "09", "10"),
    subgroup = rep("total_enrollment", 5),
    n_students = c(65000, 66000, 67000, 70000, 68000),
    pct = rep(NA_real_, 5),
    is_state = rep(TRUE, 5),
    is_district = rep(FALSE, 5),
    is_campus = rep(FALSE, 5),
    stringsAsFactors = FALSE
  )

  result <- enr_grade_aggs(tidy_data)

  # Check we get K8, HS, and K12 aggregates
  expect_true("K8" %in% result$grade_level)
  expect_true("HS" %in% result$grade_level)
  expect_true("K12" %in% result$grade_level)

  # Check K8 sum (K + 01 + 02)
  k8_row <- result[result$grade_level == "K8", ]
  expect_equal(k8_row$n_students, 65000 + 66000 + 67000)

  # Check HS sum (09 + 10)
  hs_row <- result[result$grade_level == "HS", ]
  expect_equal(hs_row$n_students, 70000 + 68000)

  # Check K12 sum (all grades)
  k12_row <- result[result$grade_level == "K12", ]
  expect_equal(k12_row$n_students, 65000 + 66000 + 67000 + 70000 + 68000)
})

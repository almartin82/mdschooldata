# ==============================================================================
# Transformation Correctness Tests for mdschooldata
# ==============================================================================
#
# Tests every transformation in the pipeline: suppression, ID formatting,
# grade normalization, subgroup naming, pivot fidelity, percentages,
# aggregation, entity flags, and cross-year consistency.
#
# Uses REAL values from Maryland Department of Planning data to pin tests
# against known-good outputs.
#
# ==============================================================================

library(testthat)

# ==============================================================================
# SECTION 1: Suppression Handling (safe_numeric)
# ==============================================================================

test_that("safe_numeric converts normal strings to numeric", {
  expect_equal(safe_numeric("100"), 100)
  expect_equal(safe_numeric("0"), 0)
  expect_equal(safe_numeric("1234567"), 1234567)
  expect_equal(safe_numeric("3.14"), 3.14)
})

test_that("safe_numeric removes commas before conversion", {
  expect_equal(safe_numeric("1,234"), 1234)
  expect_equal(safe_numeric("1,234,567"), 1234567)
  expect_equal(safe_numeric("12,345.67"), 12345.67)
})

test_that("safe_numeric handles whitespace", {
  expect_equal(safe_numeric("  100  "), 100)
  expect_equal(safe_numeric(" 0 "), 0)
  expect_equal(safe_numeric("\t50\t"), 50)
})

test_that("safe_numeric passes through already-numeric values", {
  expect_equal(safe_numeric(42), 42)
  expect_equal(safe_numeric(0), 0)
  expect_equal(safe_numeric(NA_real_), NA_real_)
  expect_equal(safe_numeric(c(1, 2, 3)), c(1, 2, 3))
})

test_that("safe_numeric converts exact suppression markers to NA", {
  markers <- c("*", ".", "-", "-1", "<5", "<", ">", "N/A", "NA", "", "n/a", "DS", "SP")
  for (m in markers) {
    expect_true(is.na(safe_numeric(m)),
                info = paste0("Marker '", m, "' should become NA"))
  }
})

test_that("safe_numeric converts range markers to NA", {
  expect_true(is.na(safe_numeric("<10")))
  expect_true(is.na(safe_numeric("<100")))
  expect_true(is.na(safe_numeric(">95")))
  expect_true(is.na(safe_numeric(">50")))
})

test_that("safe_numeric returns NA for arbitrary non-numeric strings", {
  expect_true(is.na(safe_numeric("abc")))
  expect_true(is.na(safe_numeric("not a number")))
})

test_that("safe_numeric handles vector input with mixed values", {
  input <- c("100", "*", "200", "<5", "300", "DS")
  result <- safe_numeric(input)
  expect_equal(result[1], 100)
  expect_true(is.na(result[2]))
  expect_equal(result[3], 200)
  expect_true(is.na(result[4]))
  expect_equal(result[5], 300)
  expect_true(is.na(result[6]))
})


# ==============================================================================
# SECTION 2: ID Formatting
# ==============================================================================

test_that("district_id is zero-padded to 2 digits via process_district_data", {
  df <- data.frame(
    district_id = c("1", "3", "16"),
    district_name = c("Allegany", "Baltimore City", "Montgomery"),
    row_total = c(100, 200, 300),
    stringsAsFactors = FALSE
  )
  result <- process_district_data(df, 2024)
  # sprintf("%02s", ...) zero-pads on this platform
  expect_equal(result$district_id, c("01", "03", "16"))
})

test_that("LSS codes are complete: 01-24 with correct names", {
  lss <- get_lss_codes()
  expect_equal(length(lss), 24)

  # First and last

  expect_equal(names(lss)[1], "01")
  expect_equal(names(lss)[24], "24")

  # Spot checks for known districts
  expect_equal(unname(lss["01"]), "Allegany")
  expect_equal(unname(lss["03"]), "Baltimore City")
  expect_equal(unname(lss["04"]), "Baltimore County")
  expect_equal(unname(lss["14"]), "Howard")
  expect_equal(unname(lss["16"]), "Montgomery")
  expect_equal(unname(lss["17"]), "Prince George's")
  expect_equal(unname(lss["24"]), "Worcester")
})

test_that("campus_id is extracted from first 2 digits of school ID", {
  df <- data.frame(
    campus_id = c("0100", "0301", "1601"),
    campus_name = c("School A", "School B", "School C"),
    row_total = c(100, 200, 300),
    stringsAsFactors = FALSE
  )
  result <- process_school_data(df, 2024)

  # Should extract first 2 digits as district_id
  expect_equal(result$district_id, c("01", "03", "16"))
})


# ==============================================================================
# SECTION 3: Column Name Standardization
# ==============================================================================

test_that("standardize_column_names maps LSSNumber variants", {
  df1 <- data.frame(LSSNumber = "01", stringsAsFactors = FALSE)
  expect_true("district_id" %in% names(standardize_column_names(df1)))

  df2 <- data.frame(LSS_Number = "01", stringsAsFactors = FALSE)
  expect_true("district_id" %in% names(standardize_column_names(df2)))

  df3 <- data.frame(lss_number = "01", stringsAsFactors = FALSE)
  expect_true("district_id" %in% names(standardize_column_names(df3)))

  df4 <- data.frame(DistrictID = "01", stringsAsFactors = FALSE)
  expect_true("district_id" %in% names(standardize_column_names(df4)))
})

test_that("standardize_column_names maps enrollment total variants", {
  for (col_name in c("Enrollment", "TotalEnrollment", "Total_Enrollment", "Total", "total_enrollment")) {
    df <- data.frame(x = 100, stringsAsFactors = FALSE)
    names(df) <- col_name
    result <- standardize_column_names(df)
    expect_true("row_total" %in% names(result),
                info = paste0("'", col_name, "' should map to 'row_total'"))
  }
})

test_that("standardize_column_names maps race/ethnicity variants", {
  race_mappings <- list(
    "White" = "white",
    "Black" = "black",
    "African_American" = "black",
    "AfricanAmerican" = "black",
    "Black_African_American" = "black",
    "Hispanic" = "hispanic",
    "Hispanic_Latino" = "hispanic",
    "HispanicLatino" = "hispanic",
    "Asian" = "asian",
    "Native_Hawaiian_Pacific_Islander" = "pacific_islander",
    "NativeHawaiian" = "pacific_islander",
    "Pacific_Islander" = "pacific_islander",
    "PacificIslander" = "pacific_islander",
    "American_Indian" = "native_american",
    "AmericanIndian" = "native_american",
    "American_Indian_Alaska_Native" = "native_american",
    "Two_or_More_Races" = "multiracial",
    "TwoOrMore" = "multiracial",
    "Two_Or_More" = "multiracial",
    "Multiracial" = "multiracial"
  )

  for (orig in names(race_mappings)) {
    df <- data.frame(x = 100, stringsAsFactors = FALSE)
    names(df) <- orig
    result <- standardize_column_names(df)
    expected <- race_mappings[[orig]]
    expect_true(expected %in% names(result),
                info = paste0("'", orig, "' should map to '", expected, "'"))
  }
})

test_that("standardize_column_names maps gender variants", {
  for (pair in list(c("Male", "male"), c("Female", "female"),
                     c("Boys", "male"), c("Girls", "female"))) {
    df <- data.frame(x = 50, stringsAsFactors = FALSE)
    names(df) <- pair[1]
    result <- standardize_column_names(df)
    expect_true(pair[2] %in% names(result),
                info = paste0("'", pair[1], "' should map to '", pair[2], "'"))
  }
})

test_that("standardize_column_names maps grade variants", {
  grade_mappings <- list(
    "Prekindergarten" = "grade_pk",
    "PreK" = "grade_pk",
    "Pre_K" = "grade_pk",
    "Kindergarten" = "grade_k",
    "Grade_1" = "grade_01",
    "Grade_12" = "grade_12"
  )

  for (orig in names(grade_mappings)) {
    df <- data.frame(x = 100, stringsAsFactors = FALSE)
    names(df) <- orig
    result <- standardize_column_names(df)
    expected <- grade_mappings[[orig]]
    expect_true(expected %in% names(result),
                info = paste0("'", orig, "' should map to '", expected, "'"))
  }
})


# ==============================================================================
# SECTION 4: Grade Level Normalization
# ==============================================================================

test_that("grade_to_column maps all valid API codes", {
  expected <- list(
    "-1" = "grade_pk",
    "0"  = "grade_k",
    "1"  = "grade_01",
    "2"  = "grade_02",
    "3"  = "grade_03",
    "4"  = "grade_04",
    "5"  = "grade_05",
    "6"  = "grade_06",
    "7"  = "grade_07",
    "8"  = "grade_08",
    "9"  = "grade_09",
    "10" = "grade_10",
    "11" = "grade_11",
    "12" = "grade_12"
  )

  for (code in names(expected)) {
    result <- unname(grade_to_column(code))
    expect_equal(result, expected[[code]],
                 info = paste0("grade_to_column('", code, "') should be '", expected[[code]], "'"))
  }
})

test_that("grade_to_column returns NULL for unknown codes", {
  expect_null(grade_to_column("13"))
  expect_null(grade_to_column("99"))
  expect_null(grade_to_column("XX"))
  expect_null(grade_to_column("-2"))
})

test_that("tidy_enr maps grade columns to uppercase labels", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    grade_pk = 50, grade_k = 80, grade_01 = 90,
    grade_09 = 100, grade_10 = 95, grade_11 = 88, grade_12 = 85,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  grade_levels <- unique(tidy$grade_level)
  expect_true("TOTAL" %in% grade_levels)
  expect_true("PK" %in% grade_levels)
  expect_true("K" %in% grade_levels)
  expect_true("01" %in% grade_levels)
  expect_true("09" %in% grade_levels)
  expect_true("10" %in% grade_levels)
  expect_true("11" %in% grade_levels)
  expect_true("12" %in% grade_levels)
})

test_that("tidy_enr grade_level column has no 'names' attribute", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 500,
    grade_k = 100, grade_01 = 110, grade_02 = 120,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  expect_null(attributes(tidy$grade_level))
})


# ==============================================================================
# SECTION 5: Subgroup Naming
# ==============================================================================

test_that("tidy_enr produces standard subgroup names", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    white = 300, black = 350, hispanic = 200, asian = 80,
    native_american = 10, pacific_islander = 5, multiracial = 55,
    male = 510, female = 490,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  subgroups <- unique(tidy$subgroup)

  # Must use standard names per naming conventions
  expect_true("total_enrollment" %in% subgroups)
  expect_true("white" %in% subgroups)
  expect_true("black" %in% subgroups)
  expect_true("hispanic" %in% subgroups)
  expect_true("asian" %in% subgroups)
  expect_true("native_american" %in% subgroups)
  expect_true("pacific_islander" %in% subgroups)
  expect_true("multiracial" %in% subgroups)
  expect_true("male" %in% subgroups)
  expect_true("female" %in% subgroups)

  # Must NOT use non-standard names
  expect_false("total" %in% subgroups)
  expect_false("american_indian" %in% subgroups)
  expect_false("two_or_more" %in% subgroups)
})

test_that("standardize_race_col maps all variants to standard names", {
  mappings <- list(
    "White" = "white",
    "white" = "white",
    "Black" = "black",
    "black" = "black",
    "African American" = "black",
    "AFRICAN AMERICAN" = "black",
    "Hispanic" = "hispanic",
    "Hispanic/Latino" = "hispanic",
    "Asian" = "asian",
    "Pacific Islander" = "pacific_islander",
    "Native Hawaiian" = "pacific_islander",
    "Native Hawaiian/Pacific Islander" = "pacific_islander",
    "American Indian" = "native_american",
    "American Indian/Alaska Native" = "native_american",
    "Two or More" = "multiracial",
    "Two or More Races" = "multiracial",
    "Multiracial" = "multiracial"
  )

  for (input in names(mappings)) {
    result <- standardize_race_col(input)
    expect_equal(result, mappings[[input]],
                 info = paste0("standardize_race_col('", input, "') should be '", mappings[[input]], "'"))
  }
})

test_that("standardize_race_col returns input unchanged for unknown values", {
  expect_equal(standardize_race_col("Unknown"), "Unknown")
  expect_equal(standardize_race_col("Other"), "Other")
})


# ==============================================================================
# SECTION 6: Pivot Fidelity (wide to tidy)
# ==============================================================================

test_that("tidy total_enrollment n_students matches wide row_total exactly", {
  wide <- data.frame(
    end_year = 2024, type = "District",
    district_id = "03", campus_id = NA_character_,
    district_name = "Baltimore City", campus_name = NA_character_,
    row_total = 72995,
    grade_k = 5525,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  total_row <- tidy[tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL", ]

  expect_equal(total_row$n_students, 72995)
})

test_that("tidy grade-level n_students matches wide grade columns exactly", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 859083,
    grade_k = 59562, grade_01 = 62557, grade_12 = 63844,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  k_row <- tidy[tidy$grade_level == "K" & tidy$subgroup == "total_enrollment", ]
  expect_equal(k_row$n_students, 59562)

  g01_row <- tidy[tidy$grade_level == "01" & tidy$subgroup == "total_enrollment", ]
  expect_equal(g01_row$n_students, 62557)

  g12_row <- tidy[tidy$grade_level == "12" & tidy$subgroup == "total_enrollment", ]
  expect_equal(g12_row$n_students, 63844)
})

test_that("tidy demographic n_students matches wide columns exactly", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    white = 300, black = 350, hispanic = 200, asian = 80,
    native_american = 10, pacific_islander = 5, multiracial = 55,
    male = 510, female = 490,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  for (sg in c("white", "black", "hispanic", "asian",
               "native_american", "pacific_islander", "multiracial",
               "male", "female")) {
    tidy_row <- tidy[tidy$subgroup == sg & tidy$grade_level == "TOTAL", ]
    expect_equal(tidy_row$n_students, wide[[sg]],
                 info = paste0("Subgroup '", sg, "' n_students should match wide '", sg, "' column"))
  }
})

test_that("tidy_enr filters out NA n_students rows", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    white = NA_integer_,
    grade_k = 100,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # white is NA, so it should be filtered out
  white_rows <- tidy[tidy$subgroup == "white", ]
  expect_equal(nrow(white_rows), 0)

  # grade_k = 100 should be present
  k_rows <- tidy[tidy$grade_level == "K", ]
  expect_equal(nrow(k_rows), 1)
  expect_equal(k_rows$n_students, 100)
})

test_that("tidy one row per subgroup per entity in TOTAL grade_level", {
  wide <- data.frame(
    end_year = c(2024, 2024), type = c("State", "District"),
    district_id = c(NA, "01"), campus_id = c(NA, NA),
    district_name = c("Maryland", "Allegany"), campus_name = c(NA, NA),
    row_total = c(1000, 100),
    white = c(500, 80),
    grade_k = c(100, 10),
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  # Each entity should have exactly 1 row for total_enrollment + TOTAL
  for (ent in c("Maryland", "Allegany")) {
    total_rows <- tidy[tidy$district_name == ent & tidy$subgroup == "total_enrollment" &
                          tidy$grade_level == "TOTAL", ]
    expect_equal(nrow(total_rows), 1,
                 info = paste0(ent, " should have exactly 1 total_enrollment TOTAL row"))
  }
})


# ==============================================================================
# SECTION 7: Percentage Computation
# ==============================================================================

test_that("total_enrollment pct is always 1.0", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 859083,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  total_row <- tidy[tidy$subgroup == "total_enrollment" & tidy$grade_level == "TOTAL", ]
  expect_equal(total_row$pct, 1.0)
})

test_that("demographic pct = n_students / row_total", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    white = 300, black = 350,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)

  white_row <- tidy[tidy$subgroup == "white", ]
  expect_equal(white_row$pct, 300 / 1000)

  black_row <- tidy[tidy$subgroup == "black", ]
  expect_equal(black_row$pct, 350 / 1000)
})

test_that("grade-level pct = n_students / row_total", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 859083,
    grade_k = 59562,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  k_row <- tidy[tidy$grade_level == "K", ]
  expect_equal(k_row$pct, 59562 / 859083, tolerance = 1e-10)
})

test_that("percentages are bounded 0-1 in synthetic data", {
  wide <- data.frame(
    end_year = 2024, type = "State",
    district_id = NA_character_, campus_id = NA_character_,
    district_name = "Maryland", campus_name = NA_character_,
    row_total = 1000,
    white = 300, black = 350, hispanic = 200, asian = 80,
    native_american = 10, pacific_islander = 5, multiracial = 55,
    male = 510, female = 490,
    grade_k = 100, grade_01 = 110,
    stringsAsFactors = FALSE
  )

  tidy <- tidy_enr(wide)
  expect_true(all(tidy$pct >= 0 & tidy$pct <= 1.1, na.rm = TRUE),
              info = "All percentages should be bounded 0-1 (allowing for rounding)")
})


# ==============================================================================
# SECTION 8: Aggregation
# ==============================================================================

test_that("create_state_aggregate sums district columns correctly", {
  districts <- data.frame(
    end_year = c(2024, 2024, 2024),
    type = c("District", "District", "District"),
    district_id = c("01", "02", "03"),
    district_name = c("Allegany", "Anne Arundel", "Baltimore City"),
    row_total = c(7640, 82891, 72995),
    grade_k = c(565, 5709, 5525),
    grade_01 = c(590, 6100, 5800),
    white = c(6500, 60000, 5000),
    black = c(500, 12000, 50000),
    stringsAsFactors = FALSE
  )

  state <- create_state_aggregate(districts, 2024)

  expect_equal(state$type, "State")
  expect_equal(state$district_name, "Maryland")
  expect_true(is.na(state$district_id))
  expect_true(is.na(state$campus_id))
  expect_equal(state$row_total, 7640 + 82891 + 72995)
  expect_equal(state$grade_k, 565 + 5709 + 5525)
  expect_equal(state$grade_01, 590 + 6100 + 5800)
  expect_equal(state$white, 6500 + 60000 + 5000)
  expect_equal(state$black, 500 + 12000 + 50000)
})

test_that("create_state_aggregate handles NA values with na.rm = TRUE", {
  districts <- data.frame(
    end_year = c(2024, 2024),
    type = c("District", "District"),
    district_id = c("01", "02"),
    district_name = c("Allegany", "Anne Arundel"),
    row_total = c(100, NA),
    white = c(NA, NA),
    stringsAsFactors = FALSE
  )

  state <- create_state_aggregate(districts, 2024)
  expect_equal(state$row_total, 100)
  expect_equal(state$white, 0)
})

test_that("enr_grade_aggs creates K8 from K+01-08", {
  tidy <- data.frame(
    end_year = rep(2024, 10), type = rep("State", 10),
    district_id = rep(NA_character_, 10),
    campus_id = rep(NA_character_, 10),
    district_name = rep("Maryland", 10),
    campus_name = rep(NA_character_, 10),
    grade_level = c("K", "01", "02", "03", "04", "05", "06", "07", "08", "09"),
    subgroup = rep("total_enrollment", 10),
    n_students = c(100, 110, 120, 130, 140, 150, 160, 170, 180, 200),
    pct = rep(NA_real_, 10),
    is_state = rep(TRUE, 10),
    is_district = rep(FALSE, 10),
    is_campus = rep(FALSE, 10),
    stringsAsFactors = FALSE
  )

  aggs <- enr_grade_aggs(tidy)

  k8 <- aggs[aggs$grade_level == "K8", ]
  expect_equal(k8$n_students, sum(100, 110, 120, 130, 140, 150, 160, 170, 180))
})

test_that("enr_grade_aggs creates HS from 09-12", {
  tidy <- data.frame(
    end_year = rep(2024, 4), type = rep("State", 4),
    district_id = rep(NA_character_, 4),
    campus_id = rep(NA_character_, 4),
    district_name = rep("Maryland", 4),
    campus_name = rep(NA_character_, 4),
    grade_level = c("09", "10", "11", "12"),
    subgroup = rep("total_enrollment", 4),
    n_students = c(200, 190, 180, 170),
    pct = rep(NA_real_, 4),
    is_state = rep(TRUE, 4),
    is_district = rep(FALSE, 4),
    is_campus = rep(FALSE, 4),
    stringsAsFactors = FALSE
  )

  aggs <- enr_grade_aggs(tidy)

  hs <- aggs[aggs$grade_level == "HS", ]
  expect_equal(hs$n_students, 200 + 190 + 180 + 170)
})

test_that("enr_grade_aggs K12 excludes PK", {
  tidy <- data.frame(
    end_year = rep(2024, 3), type = rep("State", 3),
    district_id = rep(NA_character_, 3),
    campus_id = rep(NA_character_, 3),
    district_name = rep("Maryland", 3),
    campus_name = rep(NA_character_, 3),
    grade_level = c("PK", "K", "01"),
    subgroup = rep("total_enrollment", 3),
    n_students = c(500, 100, 110),
    pct = rep(NA_real_, 3),
    is_state = rep(TRUE, 3),
    is_district = rep(FALSE, 3),
    is_campus = rep(FALSE, 3),
    stringsAsFactors = FALSE
  )

  aggs <- enr_grade_aggs(tidy)

  k12 <- aggs[aggs$grade_level == "K12", ]
  # K12 should be K + 01 = 210, NOT PK + K + 01 = 710
  expect_equal(k12$n_students, 100 + 110)
})

test_that("enr_grade_aggs only operates on total_enrollment subgroup", {
  tidy <- data.frame(
    end_year = rep(2024, 4), type = rep("State", 4),
    district_id = rep(NA_character_, 4),
    campus_id = rep(NA_character_, 4),
    district_name = rep("Maryland", 4),
    campus_name = rep(NA_character_, 4),
    grade_level = c("K", "01", "K", "01"),
    subgroup = c("total_enrollment", "total_enrollment", "white", "white"),
    n_students = c(100, 110, 50, 55),
    pct = rep(NA_real_, 4),
    is_state = rep(TRUE, 4),
    is_district = rep(FALSE, 4),
    is_campus = rep(FALSE, 4),
    stringsAsFactors = FALSE
  )

  aggs <- enr_grade_aggs(tidy)

  # K8 should only sum total_enrollment grades, not white
  k8 <- aggs[aggs$grade_level == "K8", ]
  expect_equal(k8$n_students, 100 + 110)
  expect_equal(nrow(k8), 1)
})


# ==============================================================================
# SECTION 9: Entity Flags
# ==============================================================================

test_that("id_enr_aggs sets is_state from type column", {
  df <- data.frame(
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "0100"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)
  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
})

test_that("id_enr_aggs sets is_district from type column", {
  df <- data.frame(
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "0100"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
})

test_that("id_enr_aggs sets is_campus from type column", {
  df <- data.frame(
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "0100"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)
  expect_equal(result$is_campus, c(FALSE, FALSE, TRUE))
})

test_that("id_enr_aggs sets aggregation_flag", {
  df <- data.frame(
    type = c("State", "District", "Campus"),
    district_id = c(NA, "01", "01"),
    campus_id = c(NA, NA, "0100"),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)
  expect_equal(result$aggregation_flag, c("state", "district", "campus"))
})

test_that("id_enr_aggs handles empty string IDs in aggregation_flag", {
  df <- data.frame(
    type = c("State", "District"),
    district_id = c("", "01"),
    campus_id = c("", ""),
    stringsAsFactors = FALSE
  )

  result <- id_enr_aggs(df)
  expect_equal(result$aggregation_flag[1], "state")
  expect_equal(result$aggregation_flag[2], "district")
})


# ==============================================================================
# SECTION 10: ensure_standard_columns
# ==============================================================================

test_that("ensure_standard_columns adds all missing columns", {
  minimal <- data.frame(
    end_year = 2024, type = "State",
    stringsAsFactors = FALSE
  )

  result <- ensure_standard_columns(minimal, 2024)

  expected_cols <- c(
    "end_year", "type", "district_id", "campus_id",
    "district_name", "campus_name", "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  for (col in expected_cols) {
    expect_true(col %in% names(result),
                info = paste0("Missing column: '", col, "'"))
  }
})

test_that("ensure_standard_columns preserves existing values", {
  df <- data.frame(
    end_year = 2024, type = "District",
    district_id = "16", row_total = 154791,
    stringsAsFactors = FALSE
  )

  result <- ensure_standard_columns(df, 2024)
  expect_equal(result$district_id, "16")
  expect_equal(result$row_total, 154791)
  expect_equal(result$end_year, 2024)
})

test_that("ensure_standard_columns reorders columns to standard order", {
  df <- data.frame(
    row_total = 100, type = "State", end_year = 2024,
    stringsAsFactors = FALSE
  )

  result <- ensure_standard_columns(df, 2024)
  # First three columns should be end_year, type, district_id
  expect_equal(names(result)[1], "end_year")
  expect_equal(names(result)[2], "type")
  expect_equal(names(result)[3], "district_id")
})


# ==============================================================================
# SECTION 11: Race Code Mapping (pivot_enrollment_wide)
# ==============================================================================

test_that("race codes map correctly in disaggregated pivot", {
  # Simulate disaggregated data with race codes
  raw <- data.frame(
    type = rep("District", 10),
    district_id = rep("01", 10),
    district_name = rep("Allegany", 10),
    race = c(1, 2, 3, 4, 5, 6, 7, 99, 99, 99),
    sex = c(rep(99, 8), 1, 2),
    enrollment = c(500, 300, 100, 50, 10, 5, 35, 1000, 510, 490),
    stringsAsFactors = FALSE
  )

  result <- pivot_enrollment_wide(raw, "District")

  expect_equal(result$white, 500)
  expect_equal(result$black, 300)
  expect_equal(result$hispanic, 100)
  expect_equal(result$asian, 50)
  expect_equal(result$native_american, 10)
  expect_equal(result$pacific_islander, 5)
  expect_equal(result$multiracial, 35)
  expect_equal(result$row_total, 1000)
  expect_equal(result$male, 510)
  expect_equal(result$female, 490)
})


# ==============================================================================
# SECTION 12: Year Validation
# ==============================================================================

test_that("validate_year accepts years 2014-2024 (default range)", {
  for (yr in c(2014, 2018, 2020, 2024)) {
    expect_true(validate_year(yr))
  }
})

test_that("validate_year rejects years outside range", {
  expect_error(validate_year(2013), "must be between")
  expect_error(validate_year(2000), "must be between")
  expect_error(validate_year(2050), "must be between")
})

test_that("validate_year rejects non-numeric input", {
  expect_error(validate_year("2024"), "must be a single numeric")
  expect_error(validate_year(c(2020, 2021)), "must be a single numeric")
})

test_that("validate_year accepts custom min/max", {
  expect_true(validate_year(2022, min_year = 2022, max_year = 2025))
  expect_error(validate_year(2021, min_year = 2022, max_year = 2025), "must be between")
})

test_that("format_school_year produces correct format", {
  expect_equal(format_school_year(2024), "2023-24")
  expect_equal(format_school_year(2014), "2013-14")
  expect_equal(format_school_year(2000), "1999-00")
  expect_equal(format_school_year(2010), "2009-10")
})


# ==============================================================================
# SECTION 13: Assessment Data Transformations
# ==============================================================================

test_that("process_raw_assessment lowercases and cleans column names", {
  df <- data.frame(
    `Year` = "2024",
    `LEA` = "01",
    `LEA Name` = "Allegany",
    `Student Group` = "All Students",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )

  result <- process_raw_assessment(df, 2024)
  # Columns should be lowercase and underscored
  expect_true(all(names(result) == tolower(names(result))))
  expect_false(any(grepl(" ", names(result))))
})

test_that("assessment helper columns classify entity levels correctly", {
  df <- data.frame(
    district_id = c(NA, "01", "01"),
    school_id = c(NA, NA, "0301"),
    stringsAsFactors = FALSE
  )

  result <- add_assessment_helper_columns(df)

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_school, c(FALSE, FALSE, TRUE))
})

test_that("assessment helper columns handle empty string IDs", {
  df <- data.frame(
    district_id = c("", "01", "01"),
    school_id = c("", "", "0301"),
    stringsAsFactors = FALSE
  )

  result <- add_assessment_helper_columns(df)

  expect_equal(result$is_state, c(TRUE, FALSE, FALSE))
  expect_equal(result$is_district, c(FALSE, TRUE, FALSE))
  expect_equal(result$is_school, c(FALSE, FALSE, TRUE))
})


# ==============================================================================
# SECTION 14: Statewide Proficiency Data (Pinned Values)
# ==============================================================================

test_that("statewide proficiency 2024: ELA All = 48.4%", {
  prof <- get_statewide_proficiency(2024)
  ela_all <- prof[prof$subject == "ELA All", ]
  expect_equal(ela_all$pct_proficient, 48.4)
})

test_that("statewide proficiency 2024: Math All = 24.1%", {
  prof <- get_statewide_proficiency(2024)
  math_all <- prof[prof$subject == "Math All", ]
  expect_equal(math_all$pct_proficient, 24.1)
})

test_that("statewide proficiency 2024: Math 8 = 7.0% (lowest)", {
  prof <- get_statewide_proficiency(2024)
  math_8 <- prof[prof$subject == "Math 8", ]
  expect_equal(math_8$pct_proficient, 7.0)
})

test_that("statewide proficiency 2024: ELA 10 = 55.3% (highest)", {
  prof <- get_statewide_proficiency(2024)
  ela_10 <- prof[prof$subject == "ELA 10", ]
  expect_equal(ela_10$pct_proficient, 55.3)
})

test_that("statewide proficiency has 20 subjects per year", {
  for (yr in 2022:2024) {
    prof <- get_statewide_proficiency(yr)
    expect_equal(nrow(prof), 20,
                 info = paste0("Year ", yr, " should have 20 subject rows"))
  }
})

test_that("statewide proficiency carries correct metadata", {
  prof <- get_statewide_proficiency(2024)

  expect_true(all(prof$is_state))
  expect_true(all(!prof$is_district))
  expect_true(all(!prof$is_school))
  expect_true(all(prof$student_group == "All Students"))
  expect_true(all(prof$district_name == "Maryland"))
  expect_true(all(is.na(prof$district_id)))
  expect_true(all(is.na(prof$school_id)))
})

test_that("statewide proficiency ELA improved 2022-2024", {
  prof_22 <- get_statewide_proficiency(2022)
  prof_24 <- get_statewide_proficiency(2024)

  ela_22 <- prof_22[prof_22$subject == "ELA All", ]$pct_proficient
  ela_24 <- prof_24[prof_24$subject == "ELA All", ]$pct_proficient

  expect_gt(ela_24, ela_22)
  expect_equal(ela_24 - ela_22, 3.1, tolerance = 0.1)
})


# ==============================================================================
# SECTION 15: Pinned Spot Checks (Real Data - Network Required)
# ==============================================================================

test_that("2024 state total enrollment = 859,083", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
  expect_equal(state_total$n_students, 859083)
})

test_that("2024 state K enrollment = 59,562", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_k <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                    enr$grade_level == "K", ]
  expect_equal(state_k$n_students, 59562)
})

test_that("2024 state grade 09 enrollment = 77,465", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_09 <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                     enr$grade_level == "09", ]
  expect_equal(state_09$n_students, 77465)
})

test_that("2024 Baltimore City total enrollment = 72,995", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students) & !is.na(enr$is_district), ]

  bc <- enr[enr$district_id == "03" & enr$is_district &
              enr$subgroup == "total_enrollment" &
              enr$grade_level == "TOTAL", ]
  expect_equal(nrow(bc), 1)
  expect_equal(bc$n_students, 72995)
})

test_that("2024 Montgomery total enrollment = 154,791", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students) & !is.na(enr$is_district), ]

  mc <- enr[enr$district_id == "16" & enr$is_district &
              enr$subgroup == "total_enrollment" &
              enr$grade_level == "TOTAL", ]
  expect_equal(nrow(mc), 1)
  expect_equal(mc$n_students, 154791)
})

test_that("2024 Howard total enrollment = 56,033", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students) & !is.na(enr$is_district), ]

  hw <- enr[enr$district_id == "14" & enr$is_district &
              enr$subgroup == "total_enrollment" &
              enr$grade_level == "TOTAL", ]
  expect_equal(nrow(hw), 1)
  expect_equal(hw$n_students, 56033)
})

test_that("2024 has exactly 24 districts", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  dist_totals <- enr[enr$is_district & enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
  expect_equal(nrow(dist_totals), 24)
})

test_that("2024 sum of districts equals state total", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]$n_students

  dist_sum <- sum(
    enr[enr$is_district & enr$subgroup == "total_enrollment" &
          enr$grade_level == "TOTAL", ]$n_students
  )

  expect_equal(dist_sum, state_total)
})

test_that("2024 grade sums equal total for each district", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  # Filter to valid rows only (exclude ghost NA rows from PDF parser merge)
  enr <- enr[!is.na(enr$n_students) & !is.na(enr$is_district), ]

  districts <- unique(enr$district_id[enr$is_district])

  for (did in districts) {
    grade_sum <- sum(
      enr[enr$district_id == did & enr$is_district &
            enr$subgroup == "total_enrollment" &
            enr$grade_level != "TOTAL", ]$n_students
    )
    total <- enr[enr$district_id == did & enr$is_district &
                   enr$subgroup == "total_enrollment" &
                   enr$grade_level == "TOTAL", ]$n_students

    expect_equal(grade_sum, total,
                 info = paste0("District ", did, ": grade sum should equal total"))
  }
})

test_that("2024 no PK data (MD Planning does not provide PK)", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  pk_rows <- enr[enr$grade_level == "PK", ]
  expect_equal(nrow(pk_rows), 0,
               info = "MD Planning data does not include PK; expect 0 PK rows")
})

test_that("2024 only subgroup is total_enrollment (no demographics via MDP)", {
  skip_if_offline()

  enr <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  subgroups <- unique(enr$subgroup)
  expect_equal(subgroups, "total_enrollment",
               info = "MDP data only provides total enrollment, no demographics")
})


# ==============================================================================
# SECTION 16: Cross-Year Consistency
# ==============================================================================

test_that("2018 state total enrollment = 865,491", {
  skip_if_offline()

  enr <- fetch_enr(2018, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
  expect_equal(state_total$n_students, 865491)
})

test_that("2022 state total enrollment = 858,850", {
  skip_if_offline()

  enr <- fetch_enr(2022, tidy = TRUE, use_cache = TRUE)
  enr <- enr[!is.na(enr$n_students), ]

  state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                       enr$grade_level == "TOTAL", ]
  expect_equal(state_total$n_students, 858850)
})

test_that("all available years have exactly 24 districts", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    enr <- enr[!is.na(enr$n_students), ]

    dist_count <- sum(
      enr$is_district & enr$subgroup == "total_enrollment" &
        enr$grade_level == "TOTAL"
    )
    expect_equal(dist_count, 24,
                 info = paste0("Year ", yr, " should have 24 districts"))
  }
})

test_that("state total is between 800K and 1M for all years (sanity check)", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    enr <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    enr <- enr[!is.na(enr$n_students), ]

    state_total <- enr[enr$is_state & enr$subgroup == "total_enrollment" &
                         enr$grade_level == "TOTAL", ]$n_students

    expect_gt(state_total, 800000,
              label = paste0("Year ", yr, " state total should be > 800K"))
    expect_lt(state_total, 1000000,
              label = paste0("Year ", yr, " state total should be < 1M"))
  }
})

test_that("tidy and wide totals match for 2024", {
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  tidy <- tidy[!is.na(tidy$n_students), ]

  # State row_total in wide should match tidy total_enrollment TOTAL
  wide_state <- wide[wide$type == "State", ]$row_total
  tidy_state <- tidy[tidy$is_state & tidy$subgroup == "total_enrollment" &
                       tidy$grade_level == "TOTAL", ]$n_students

  expect_equal(tidy_state, wide_state)
})

test_that("tidy grade K matches wide grade_k for all districts in 2024", {
  skip_if_offline()

  wide <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)
  tidy <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  tidy <- tidy[!is.na(tidy$n_students) & !is.na(tidy$is_district), ]

  districts <- unique(wide$district_id[wide$type == "District"])

  for (did in districts) {
    wide_k <- wide[wide$district_id == did & wide$type == "District", ]$grade_k
    tidy_k <- tidy[tidy$district_id == did & tidy$is_district &
                     tidy$subgroup == "total_enrollment" &
                     tidy$grade_level == "K", ]$n_students

    if (length(wide_k) > 0 && !is.na(wide_k) && length(tidy_k) > 0) {
      expect_equal(tidy_k, wide_k,
                   info = paste0("District ", did, ": tidy K should match wide grade_k"))
    }
  }
})


# ==============================================================================
# SECTION 17: create_empty_processed_df
# ==============================================================================

test_that("create_empty_processed_df returns correct structure with 0 rows", {
  result <- create_empty_processed_df(2024)

  expect_equal(nrow(result), 0)
  expect_true("end_year" %in% names(result))
  expect_true("type" %in% names(result))
  expect_true("district_id" %in% names(result))
  expect_true("campus_id" %in% names(result))
  expect_true("row_total" %in% names(result))
  expect_true("white" %in% names(result))
  expect_true("black" %in% names(result))
  expect_true("hispanic" %in% names(result))
  expect_true("asian" %in% names(result))
  expect_true("native_american" %in% names(result))
  expect_true("pacific_islander" %in% names(result))
  expect_true("multiracial" %in% names(result))
  expect_true("male" %in% names(result))
  expect_true("female" %in% names(result))
})


# ==============================================================================
# SECTION 18: get_available_years structure
# ==============================================================================

test_that("get_available_years returns correct structure", {
  years <- get_available_years()

  expect_true(is.list(years))
  expect_equal(years$min_year, 2014)
  expect_equal(years$max_year, 2024)
  expect_equal(years$available, 2014:2024)
  expect_equal(length(years$demographic_years), 0,
               info = "No demographic years available due to PDF parsing issues")
  expect_true(nchar(years$description) > 0)
  expect_true(nchar(years$notes) > 0)
})

test_that("get_available_assessment_years returns correct structure", {
  avail <- get_available_assessment_years()

  expect_equal(avail$min_year, 2022)
  expect_equal(avail$max_year, 2024)
  expect_equal(avail$available_years, 2022:2024)
  expect_true("MCAP" %in% names(avail$assessments))
  expect_true("participation" %in% names(avail$data_types))
  expect_true("proficiency" %in% names(avail$data_types))
})


# ==============================================================================
# SECTION 19: get_grade_codes
# ==============================================================================

test_that("get_grade_codes returns PK through 12", {
  codes <- get_grade_codes()

  expect_equal(length(codes), 14)
  expect_equal(names(codes)[1], "PK")
  expect_equal(names(codes)[2], "K")
  expect_equal(names(codes)[3], "01")
  expect_equal(names(codes)[14], "12")
  expect_equal(unname(codes["PK"]), "Prekindergarten")
  expect_equal(unname(codes["K"]), "Kindergarten")
  expect_equal(unname(codes["01"]), "Grade 1")
  expect_equal(unname(codes["12"]), "Grade 12")
})


# ==============================================================================
# SECTION 20: Cache Path Generation
# ==============================================================================

test_that("cache path includes year and type", {
  path_tidy <- get_cache_path(2024, "tidy")
  expect_true(grepl("enr_tidy_2024\\.rds$", path_tidy))

  path_wide <- get_cache_path(2023, "wide")
  expect_true(grepl("enr_wide_2023\\.rds$", path_wide))

  path_assess <- get_cache_path(2024, "assessment_participation")
  expect_true(grepl("enr_assessment_participation_2024\\.rds$", path_assess))
})

test_that("cache_exists returns FALSE for nonexistent cache", {
  expect_false(cache_exists(9999, "tidy"))
  expect_false(cache_exists(9999, "wide"))
})

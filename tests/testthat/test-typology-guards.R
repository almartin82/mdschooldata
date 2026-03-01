# ==============================================================================
# Typology Guard Tests for mdschooldata
# ==============================================================================
#
# Cross-cutting data quality guards that catch common transformation bugs:
# - Division by zero in percentage calculations
# - Scale consistency (counts vs percentages)
# - Column type validation
# - Row count minimums
# - Value set validation (no unexpected categories)
# - No duplicate rows within entity-year-grade-subgroup
# - Aggregation integrity
#
# ==============================================================================

library(testthat)

# ==============================================================================
# SECTION 1: DIVISION BY ZERO GUARDS
# ==============================================================================

test_that("tidy_enr handles zero row_total without Inf", {
  # Create wide data with zero total
  wide <- data.frame(
    end_year = 2024,
    type = "District",
    district_id = "99",
    campus_id = NA_character_,
    district_name = "Test District",
    campus_name = NA_character_,
    row_total = 0,
    grade_k = 0,
    grade_01 = 0,
    stringsAsFactors = FALSE
  )

  # tidy_enr calculates pct = n_students / row_total
  # When row_total is 0, this would produce NaN or Inf
  tidy_result <- tidy_enr(wide)

  # No Inf values should exist
  expect_false(any(is.infinite(tidy_result$pct)),
               info = "Division by zero should not produce Inf in pct")

  # NaN is acceptable for 0/0 but Inf (non-zero / 0) is not
  if (any(!is.na(tidy_result$n_students) & tidy_result$n_students > 0)) {
    non_zero_rows <- tidy_result[!is.na(tidy_result$n_students) &
                                   tidy_result$n_students > 0, ]
    expect_false(any(is.infinite(non_zero_rows$pct)),
                 info = "Non-zero n_students with zero row_total = Inf")
  }
})

test_that("Real data: no Inf in pct column for any year", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_false(any(is.infinite(d$pct)),
                 info = paste("Year", yr, "has Inf in pct"))
  }
})

test_that("Real data: no NaN in n_students for any year", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_false(any(is.nan(d$n_students)),
                 info = paste("Year", yr, "has NaN in n_students"))
  }
})

# ==============================================================================
# SECTION 2: SCALE CONSISTENCY
# ==============================================================================

test_that("Enrollment pct is on 0-1 scale, not 0-100", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  valid_pct <- d$pct[!is.na(d$pct)]

  # If any pct > 1, it is on the wrong scale
  expect_true(all(valid_pct <= 1),
              info = "pct appears to be on 0-100 scale instead of 0-1")
  expect_true(all(valid_pct >= 0),
              info = "Negative pct values found")
})

test_that("Assessment participation_pct is on 0-100 scale, not 0-1", {
  skip_if_offline()
  skip_on_cran()

  a <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(a) == 0, "Network download failed")

  pct <- a$participation_pct[!is.na(a$participation_pct)]
  skip_if(length(pct) == 0, "No participation data")

  # Participation should be on 0-100 scale
  expect_true(max(pct, na.rm = TRUE) > 1,
              info = "participation_pct appears to be on 0-1 scale instead of 0-100")
  expect_true(all(pct >= 0),
              info = "Negative participation_pct found")
  expect_true(all(pct <= 100),
              info = "participation_pct > 100 found")
})

test_that("Proficiency pct_proficient is on 0-100 scale", {
  prof <- get_statewide_proficiency(2024)

  expect_true(all(prof$pct_proficient >= 0 & prof$pct_proficient <= 100),
              info = "pct_proficient outside [0, 100]")
  expect_true(max(prof$pct_proficient) > 1,
              info = "pct_proficient appears to be on 0-1 scale")
})

test_that("Enrollment n_students are reasonable counts, not fractions", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- d |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  # Should be in the hundreds of thousands, not a fraction
  expect_true(state_total > 100000,
              info = "State total looks like a fraction, not a count")
  expect_true(state_total < 10000000,
              info = "State total unreasonably large")

  # All n_students should be whole numbers (integers)
  non_na <- d$n_students[!is.na(d$n_students)]
  expect_true(all(non_na == floor(non_na)),
              info = "n_students contains non-integer values")
})

# ==============================================================================
# SECTION 3: COLUMN TYPE VALIDATION
# ==============================================================================

test_that("Tidy enrollment column types are correct", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Numeric columns
  expect_true(is.numeric(d$end_year), info = "end_year should be numeric")
  expect_true(is.numeric(d$n_students), info = "n_students should be numeric")
  expect_true(is.numeric(d$pct), info = "pct should be numeric")

  # Character columns
  expect_true(is.character(d$type), info = "type should be character")
  expect_true(is.character(d$subgroup), info = "subgroup should be character")
  expect_true(is.character(d$grade_level), info = "grade_level should be character")
  expect_true(is.character(d$district_name), info = "district_name should be character")

  # Boolean columns
  expect_true(is.logical(d$is_state), info = "is_state should be logical")
  expect_true(is.logical(d$is_district), info = "is_district should be logical")
  expect_true(is.logical(d$is_campus), info = "is_campus should be logical")
})

test_that("Wide enrollment column types are correct", {
  skip_if_offline()

  w <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  expect_true(is.numeric(w$end_year), info = "end_year should be numeric")
  expect_true(is.numeric(w$row_total), info = "row_total should be numeric")
  expect_true(is.character(w$type), info = "type should be character")
  expect_true(is.character(w$district_name), info = "district_name should be character")

  # Grade columns should be numeric
  grade_cols <- grep("^grade_", names(w), value = TRUE)
  for (col in grade_cols) {
    expect_true(is.numeric(w[[col]]),
                info = paste(col, "should be numeric"))
  }
})

test_that("Assessment column types are correct", {
  skip_if_offline()
  skip_on_cran()

  a <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(a) == 0, "Network download failed")

  expect_true(is.numeric(a$participation_pct) || is.double(a$participation_pct),
              info = "participation_pct should be numeric")
  expect_true(is.character(a$subject), info = "subject should be character")
  expect_true(is.character(a$student_group),
              info = "student_group should be character")
  expect_true(is.logical(a$is_state), info = "is_state should be logical")
  expect_true(is.logical(a$is_district), info = "is_district should be logical")
  expect_true(is.logical(a$is_school), info = "is_school should be logical")
})

test_that("grade_level has no names attribute", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # This was a known bug: grade_level got names from the mapping vector
  expect_null(names(d$grade_level),
              info = "grade_level should be a plain character vector without names")
})

# ==============================================================================
# SECTION 4: ROW COUNT MINIMUMS
# ==============================================================================

test_that("Tidy enrollment: minimum row count per year", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # 25 entities (1 state + 24 districts) x 14 grade levels (TOTAL + K + 01-12)
  # x 1 subgroup (total_enrollment) = 350 minimum rows
  expect_true(nrow(d) > 300,
              info = paste("Only", nrow(d), "rows, expected 300+"))
})

test_that("Wide enrollment: exactly 25 rows per year", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    w <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    expect_equal(nrow(w), 25,
                 info = paste("Year", yr, "has", nrow(w),
                              "rows, expected 25"))
  }
})

test_that("Assessment: >50K rows per year", {
  skip_if_offline()
  skip_on_cran()

  for (yr in 2022:2024) {
    a <- fetch_assessment(yr, use_cache = TRUE)
    skip_if(nrow(a) == 0, paste("Network download failed for year", yr))
    expect_true(nrow(a) > 50000,
                info = paste("Year", yr, "has only", nrow(a), "rows"))
  }
})

test_that("Statewide proficiency: 20 subject-grade combinations per year", {
  for (yr in 2022:2024) {
    prof <- get_statewide_proficiency(yr)
    expect_equal(nrow(prof), 20,
                 info = paste("Year", yr, "has", nrow(prof),
                              "proficiency rows, expected 20"))
  }
})

# ==============================================================================
# SECTION 5: VALUE SET VALIDATION
# ==============================================================================

test_that("Entity type values are only State, District, Campus", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  valid_types <- c("State", "District", "Campus")
  expect_true(all(d$type %in% valid_types),
              info = paste("Unexpected type values:",
                           paste(setdiff(unique(d$type), valid_types),
                                 collapse = ", ")))
})

test_that("Subgroup values are from known set", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  known_subgroups <- c("total_enrollment", "white", "black", "hispanic",
                       "asian", "native_american", "pacific_islander",
                       "multiracial", "male", "female")
  unexpected <- setdiff(unique(d$subgroup), known_subgroups)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected subgroups:",
                            paste(unexpected, collapse = ", ")))
})

test_that("Grade levels are from known set", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  known_grades <- c("PK", "K", "01", "02", "03", "04", "05", "06",
                    "07", "08", "09", "10", "11", "12", "TOTAL",
                    "K8", "HS", "K12")
  unexpected <- setdiff(unique(d$grade_level), known_grades)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected grade_levels:",
                            paste(unexpected, collapse = ", ")))
})

test_that("District IDs are 2-digit codes 01-24", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  district_ids <- unique(d$district_id[d$is_district])
  valid_ids <- sprintf("%02d", 1:24)
  expect_true(all(district_ids %in% valid_ids),
              info = paste("Unexpected district_ids:",
                           paste(setdiff(district_ids, valid_ids),
                                 collapse = ", ")))
})

test_that("Assessment subjects are from known set", {
  skip_if_offline()
  skip_on_cran()

  a <- fetch_assessment(2024, use_cache = TRUE)
  skip_if(nrow(a) == 0, "Network download failed")

  known_subjects <- c("English/Language Arts", "Mathematics", "Science")
  unexpected <- setdiff(unique(a$subject), known_subjects)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected subjects:",
                            paste(unexpected, collapse = ", ")))
})

test_that("Proficiency subjects are from known set", {
  prof <- get_statewide_proficiency(2024)

  known_subjects <- c("ELA 3", "ELA 4", "ELA 5", "ELA 6", "ELA 7",
                      "ELA 8", "ELA 10", "ELA All",
                      "Math 3", "Math 4", "Math 5", "Math 6", "Math 7",
                      "Math 8", "Algebra I", "Algebra II", "Geometry",
                      "Math All", "Science 5", "Science 8")
  unexpected <- setdiff(unique(prof$subject), known_subjects)
  expect_equal(length(unexpected), 0,
               info = paste("Unexpected proficiency subjects:",
                            paste(unexpected, collapse = ", ")))
})

# ==============================================================================
# SECTION 6: NO DUPLICATE ROWS
# ==============================================================================

test_that("Tidy enrollment: no duplicates within entity-year-grade-subgroup", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  # Group by the key fields and check for duplicates
  key_cols <- c("end_year", "type", "district_id", "campus_id",
                "grade_level", "subgroup")
  key_df <- d[, key_cols]
  n_dupes <- sum(duplicated(key_df))

  expect_equal(n_dupes, 0,
               info = paste(n_dupes,
                            "duplicate rows in tidy enrollment for 2024"))
})

test_that("Wide enrollment: no duplicate entities per year", {
  skip_if_offline()

  w <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  # Each entity (type + district_id) should appear once
  key_df <- w[, c("type", "district_id")]
  n_dupes <- sum(duplicated(key_df))

  expect_equal(n_dupes, 0,
               info = paste(n_dupes,
                            "duplicate entities in wide enrollment for 2024"))
})

test_that("Multi-year: no duplicate entities within a single year", {
  skip_if_offline()

  d <- fetch_enr_multi(2022:2024, tidy = TRUE, use_cache = TRUE)

  key_cols <- c("end_year", "type", "district_id", "campus_id",
                "grade_level", "subgroup")
  key_df <- d[, key_cols]
  n_dupes <- sum(duplicated(key_df))

  expect_equal(n_dupes, 0,
               info = paste(n_dupes,
                            "duplicate rows in multi-year enrollment"))
})

# ==============================================================================
# SECTION 7: AGGREGATION INTEGRITY
# ==============================================================================

test_that("State total equals sum of district totals", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  state_total <- d |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  district_sum <- d |>
    dplyr::filter(is_district, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students) |>
    sum()

  expect_equal(state_total, district_sum,
               info = paste("State total", state_total,
                            "!= district sum", district_sum))
})

test_that("State grade totals equal sum of district grade totals", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)

  for (grade in c("K", "01", "05", "09", "12")) {
    state_grade <- d |>
      dplyr::filter(is_state, subgroup == "total_enrollment",
                    grade_level == grade) |>
      dplyr::pull(n_students)

    district_grade_sum <- d |>
      dplyr::filter(is_district, subgroup == "total_enrollment",
                    grade_level == grade) |>
      dplyr::pull(n_students) |>
      sum()

    expect_equal(state_grade, district_grade_sum,
                 info = paste("Grade", grade, ": state", state_grade,
                              "!= district sum", district_grade_sum))
  }
})

test_that("Wide row_total equals sum of grade columns", {
  skip_if_offline()

  w <- fetch_enr(2024, tidy = FALSE, use_cache = TRUE)

  grade_cols <- c("grade_k", paste0("grade_", sprintf("%02d", 1:12)))
  grade_cols_present <- grade_cols[grade_cols %in% names(w)]

  for (i in seq_len(nrow(w))) {
    row_total <- w$row_total[i]
    if (is.na(row_total)) next

    grade_sum <- sum(sapply(grade_cols_present, function(col) {
      w[[col]][i]
    }), na.rm = TRUE)

    if (grade_sum > 0) {
      pct_diff <- abs(grade_sum - row_total) / row_total
      expect_true(pct_diff < 0.01,
                  info = paste("Row", i, "(", w$district_name[i], "): grade sum",
                               grade_sum, "differs from row_total", row_total,
                               "by", round(pct_diff * 100, 2), "%"))
    }
  }
})

test_that("enr_grade_aggs K8+HS = K12", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(d)

  state_aggs <- aggs |>
    dplyr::filter(is_state, subgroup == "total_enrollment")

  k8 <- state_aggs$n_students[state_aggs$grade_level == "K8"]
  hs <- state_aggs$n_students[state_aggs$grade_level == "HS"]
  k12 <- state_aggs$n_students[state_aggs$grade_level == "K12"]

  expect_equal(k8 + hs, k12,
               info = paste("K8", k8, "+ HS", hs, "!=", k12))
})

test_that("enr_grade_aggs K12 equals TOTAL minus PK (if PK present)", {
  skip_if_offline()

  d <- fetch_enr(2024, tidy = TRUE, use_cache = TRUE)
  aggs <- enr_grade_aggs(d)

  state_total <- d |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::pull(n_students)

  state_pk <- d |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "PK") |>
    dplyr::pull(n_students)

  state_k12 <- aggs |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "K12") |>
    dplyr::pull(n_students)

  if (length(state_pk) > 0 && !is.na(state_pk)) {
    expect_equal(state_k12, state_total - state_pk,
                 info = "K12 should equal TOTAL minus PK")
  } else {
    # No PK data; K12 should equal TOTAL
    expect_equal(state_k12, state_total,
                 info = "K12 should equal TOTAL when no PK")
  }
})

# ==============================================================================
# SECTION 8: CROSS-YEAR TYPE STABILITY
# ==============================================================================

test_that("Core column names are consistent across enrollment years", {
  skip_if_offline()

  # Core columns that must be present in every year
  core_cols <- c("end_year", "type", "district_id", "campus_id",
                 "district_name", "campus_name", "grade_level",
                 "subgroup", "n_students", "pct",
                 "is_state", "is_district", "is_campus")

  for (yr in c(2014, 2018, 2022, 2024)) {
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    yr_cols <- names(d)

    for (col in core_cols) {
      expect_true(col %in% yr_cols,
                  info = paste("Year", yr, "missing core column:", col))
    }
  }
})

test_that("Column names are consistent across assessment years", {
  skip_if_offline()
  skip_on_cran()

  base_cols <- NULL
  for (yr in 2022:2024) {
    a <- fetch_assessment(yr, use_cache = TRUE)
    skip_if(nrow(a) == 0, paste("Network download failed for year", yr))

    if (is.null(base_cols)) {
      base_cols <- sort(names(a))
    } else {
      yr_cols <- sort(names(a))
      expect_equal(yr_cols, base_cols,
                   info = paste("Year", yr,
                                "has different columns than baseline"))
    }
  }
})

# ==============================================================================
# SECTION 9: NEGATIVE VALUE GUARDS
# ==============================================================================

test_that("No negative enrollment counts in any year", {
  skip_if_offline()

  for (yr in c(2014, 2018, 2022, 2024)) {
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    neg_count <- sum(d$n_students < 0, na.rm = TRUE)
    expect_equal(neg_count, 0,
                 info = paste("Year", yr, "has", neg_count,
                              "negative n_students"))
  }
})

test_that("No negative participation_pct in assessment data", {
  skip_if_offline()
  skip_on_cran()

  for (yr in 2022:2024) {
    a <- fetch_assessment(yr, use_cache = TRUE)
    skip_if(nrow(a) == 0, paste("Network download failed for year", yr))

    neg_count <- sum(a$participation_pct < 0, na.rm = TRUE)
    expect_equal(neg_count, 0,
                 info = paste("Year", yr, "has", neg_count,
                              "negative participation_pct"))
  }
})

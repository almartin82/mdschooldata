# ==============================================================================
# Assessment Year Coverage Tests for mdschooldata
# ==============================================================================
#
# Exhaustive per-year tests for assessment data across all available years
# (2022-2024). Tests cover:
# - Participation data: downloads, structure, subjects, student groups
# - Proficiency data: statewide curated values from MSDE publications
# - Cross-year trends
#
# Pinned values sourced from MSDE State Board presentations (real data).
#
# ==============================================================================

library(testthat)

# Available assessment years for participation data
assessment_years <- 2022:2024

# Known statewide proficiency values (from MSDE State Board presentations)
known_ela_all <- list(
  "2022" = 45.3,
  "2023" = 47.9,
  "2024" = 48.4
)

known_math_all <- list(
  "2022" = 21.0,
  "2023" = 23.3,
  "2024" = 24.1
)

# Known subjects in participation data
expected_subjects <- c("English/Language Arts", "Mathematics", "Science")

# Known student groups that should always be present
expected_student_groups <- c(
  "All Students",
  "Black/African American",
  "Hispanic/Latino of Any Race",
  "White",
  "Asian",
  "Economically Disadvantaged",
  "Students with Disabilities"
)

# ==============================================================================
# PER-YEAR PARTICIPATION DATA TESTS
# ==============================================================================

for (yr in assessment_years) {

  test_that(paste0("fetch_assessment(", yr, "): loads with >0 rows"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed - skipping test")
    expect_true(nrow(a) > 50000,
                info = paste("Year", yr, "has fewer than 50K rows:", nrow(a)))
  })

  test_that(paste0("fetch_assessment(", yr, "): has required columns"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    required_cols <- c("district_id", "district_name", "school_id",
                       "school_name", "subject", "student_group",
                       "participation_pct", "end_year",
                       "is_state", "is_district", "is_school")
    for (col in required_cols) {
      expect_true(col %in% names(a),
                  info = paste("Year", yr, "missing column:", col))
    }
  })

  test_that(paste0("fetch_assessment(", yr, "): end_year is correct"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")
    expect_true(all(a$end_year == yr),
                info = paste("Year", yr, "has mismatched end_year"))
  })

  test_that(paste0("fetch_assessment(", yr, "): ELA + Math + Science subjects present"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    subjects <- unique(a$subject)
    for (subj in expected_subjects) {
      expect_true(subj %in% subjects,
                  info = paste("Year", yr, "missing subject:", subj))
    }
  })

  test_that(paste0("fetch_assessment(", yr, "): All Students group present"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    expect_true("All Students" %in% unique(a$student_group),
                info = paste("Year", yr, "missing All Students group"))
  })

  test_that(paste0("fetch_assessment(", yr, "): key student groups present"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    groups <- unique(a$student_group)
    for (grp in expected_student_groups) {
      expect_true(grp %in% groups,
                  info = paste("Year", yr, "missing student group:", grp))
    }
  })

  test_that(paste0("fetch_assessment(", yr, "): all 24 MD jurisdictions represented by name"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    # Check by district name pattern since assessment data may use
    # different conventions (e.g., "Saint Mary's" vs "St. Mary's",
    # Worcester uses ID "23" instead of "24")
    major_district_patterns <- c("Allegany", "Anne Arundel", "Baltimore City",
                                 "Baltimore County", "Calvert", "Caroline",
                                 "Carroll", "Cecil", "Charles", "Dorchester",
                                 "Frederick", "Garrett", "Harford", "Howard",
                                 "Kent", "Montgomery", "Prince George",
                                 "Queen Anne", "Mary", "Somerset",
                                 "Talbot", "Washington", "Wicomico", "Worcester")
    present_names <- unique(a$district_name)
    for (pat in major_district_patterns) {
      found <- any(grepl(pat, present_names, ignore.case = TRUE))
      expect_true(found,
                  info = paste("Year", yr, "missing district matching:", pat))
    }
  })

  test_that(paste0("fetch_assessment(", yr, "): participation_pct in valid range [0, 100]"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    pct <- a$participation_pct[!is.na(a$participation_pct)]
    skip_if(length(pct) == 0, "No participation data")

    expect_true(all(pct >= 0),
                info = paste("Year", yr, "has negative participation_pct"))
    expect_true(all(pct <= 100),
                info = paste("Year", yr, "has participation_pct > 100"))
  })

  test_that(paste0("fetch_assessment(", yr, "): no Inf/NaN in numeric columns"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    numeric_cols <- names(a)[sapply(a, is.numeric)]
    for (col in numeric_cols) {
      expect_false(any(is.infinite(a[[col]]), na.rm = TRUE),
                   info = paste("Year", yr, "has Inf in", col))
      expect_false(any(is.nan(a[[col]]), na.rm = TRUE),
                   info = paste("Year", yr, "has NaN in", col))
    }
  })

  test_that(paste0("fetch_assessment(", yr, "): Baltimore City has 100+ schools"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    balt_schools <- unique(a$school_id[a$district_id == "03" &
                                         !is.na(a$school_id)])
    expect_true(length(balt_schools) > 100,
                info = paste("Year", yr,
                             ": Baltimore City has only",
                             length(balt_schools), "schools"))
  })

  test_that(paste0("fetch_assessment(", yr, "): median participation > 80%"), {
    skip_if_offline()
    skip_on_cran()
    a <- fetch_assessment(yr, data_type = "participation", use_cache = TRUE)
    skip_if(nrow(a) == 0, "Network download failed")

    pct <- a$participation_pct[!is.na(a$participation_pct)]
    skip_if(length(pct) == 0, "No participation data")

    expect_true(median(pct) > 80,
                info = paste("Year", yr,
                             ": median participation", median(pct),
                             "is below 80%"))
  })
}

# ==============================================================================
# PER-YEAR STATEWIDE PROFICIENCY TESTS (Curated from MSDE)
# ==============================================================================

for (yr in assessment_years) {
  yr_str <- as.character(yr)

  test_that(paste0("get_statewide_proficiency(", yr, "): returns correct structure"), {
    prof <- get_statewide_proficiency(yr)

    expect_s3_class(prof, "tbl_df")
    expect_true(nrow(prof) > 0, info = paste("Year", yr, "proficiency has 0 rows"))

    required_cols <- c("end_year", "subject", "pct_proficient",
                       "is_state", "student_group")
    for (col in required_cols) {
      expect_true(col %in% names(prof),
                  info = paste("Year", yr, "proficiency missing column:", col))
    }

    expect_true(all(prof$is_state),
                info = paste("Year", yr, ": not all rows are state-level"))
    expect_true(all(prof$student_group == "All Students"),
                info = paste("Year", yr,
                             ": not all rows are All Students"))
  })

  test_that(paste0("get_statewide_proficiency(", yr, "): ELA and Math subjects present"), {
    prof <- get_statewide_proficiency(yr)

    subjects <- unique(prof$subject)
    expect_true("ELA All" %in% subjects,
                info = paste("Year", yr, "missing ELA All"))
    expect_true("Math All" %in% subjects,
                info = paste("Year", yr, "missing Math All"))
  })

  test_that(paste0("get_statewide_proficiency(", yr, "): proficiency values in [0, 100]"), {
    prof <- get_statewide_proficiency(yr)

    expect_true(all(prof$pct_proficient >= 0 & prof$pct_proficient <= 100),
                info = paste("Year", yr,
                             ": proficiency outside [0, 100]"))
  })

  # Pin ELA All values
  if (yr_str %in% names(known_ela_all)) {
    test_that(paste0("get_statewide_proficiency(", yr,
                     "): pinned ELA All = ", known_ela_all[[yr_str]], "%"), {
      prof <- get_statewide_proficiency(yr)
      ela <- prof$pct_proficient[prof$subject == "ELA All"]
      expect_equal(ela, known_ela_all[[yr_str]],
                   info = paste("ELA All mismatch for", yr))
    })
  }

  # Pin Math All values
  if (yr_str %in% names(known_math_all)) {
    test_that(paste0("get_statewide_proficiency(", yr,
                     "): pinned Math All = ", known_math_all[[yr_str]], "%"), {
      prof <- get_statewide_proficiency(yr)
      math <- prof$pct_proficient[prof$subject == "Math All"]
      expect_equal(math, known_math_all[[yr_str]],
                   info = paste("Math All mismatch for", yr))
    })
  }
}

# ==============================================================================
# PINNED INDIVIDUAL PROFICIENCY VALUES
# ==============================================================================

test_that("2024 proficiency: ELA 10 is highest ELA (55.3%)", {
  prof <- get_statewide_proficiency(2024)
  ela_10 <- prof$pct_proficient[prof$subject == "ELA 10"]
  expect_equal(ela_10, 55.3)

  # Confirm it is the highest ELA subject
  ela_subjects <- prof[grepl("^ELA", prof$subject), ]
  max_ela <- max(ela_subjects$pct_proficient)
  expect_equal(max_ela, 55.3)
})

test_that("2024 proficiency: Math 8 is lowest math (7.0%)", {
  prof <- get_statewide_proficiency(2024)
  math_8 <- prof$pct_proficient[prof$subject == "Math 8"]
  expect_equal(math_8, 7.0)

  # Confirm it is the lowest math subject
  math_subjects <- prof[grepl("^Math|^Algebra|^Geometry", prof$subject), ]
  min_math <- min(math_subjects$pct_proficient)
  expect_equal(min_math, 7.0)
})

test_that("2024 proficiency: Science subjects present", {
  prof <- get_statewide_proficiency(2024)
  sci_5 <- prof$pct_proficient[prof$subject == "Science 5"]
  sci_8 <- prof$pct_proficient[prof$subject == "Science 8"]
  expect_equal(sci_5, 30.6)
  expect_equal(sci_8, 26.4)
})

# ==============================================================================
# CROSS-YEAR PROFICIENCY TRENDS
# ==============================================================================

test_that("ELA All proficiency improved from 2022 to 2024", {
  prof_2022 <- get_statewide_proficiency(2022)
  prof_2024 <- get_statewide_proficiency(2024)

  ela_2022 <- prof_2022$pct_proficient[prof_2022$subject == "ELA All"]
  ela_2024 <- prof_2024$pct_proficient[prof_2024$subject == "ELA All"]

  expect_true(ela_2024 > ela_2022,
              info = paste("ELA All should improve: 2022=", ela_2022,
                           "2024=", ela_2024))
  # Pinned: 48.4 - 45.3 = 3.1 pp improvement
  expect_equal(ela_2024 - ela_2022, 3.1, tolerance = 0.1)
})

test_that("Math All proficiency improved from 2022 to 2024", {
  prof_2022 <- get_statewide_proficiency(2022)
  prof_2024 <- get_statewide_proficiency(2024)

  math_2022 <- prof_2022$pct_proficient[prof_2022$subject == "Math All"]
  math_2024 <- prof_2024$pct_proficient[prof_2024$subject == "Math All"]

  expect_true(math_2024 > math_2022,
              info = paste("Math All should improve: 2022=", math_2022,
                           "2024=", math_2024))
  # Pinned: 24.1 - 21.0 = 3.1 pp improvement
  expect_equal(math_2024 - math_2022, 3.1, tolerance = 0.1)
})

# ==============================================================================
# MULTI-YEAR PARTICIPATION TESTS
# ==============================================================================

test_that("fetch_assessment_multi combines 2022-2024 participation data", {
  skip_if_offline()
  skip_on_cran()

  a <- fetch_assessment_multi(2022:2024, use_cache = TRUE)
  skip_if(nrow(a) == 0, "Network download failed")

  years <- sort(unique(a$end_year))
  expect_true(length(years) >= 2,
              info = "Should have at least 2 years of data")

  # Each year should have substantial data
  for (yr in years) {
    yr_rows <- sum(a$end_year == yr, na.rm = TRUE)
    expect_true(yr_rows > 10000,
                info = paste("Year", yr, "has only", yr_rows, "rows"))
  }
})

# ==============================================================================
# YEAR VALIDATION TESTS
# ==============================================================================

test_that("get_statewide_proficiency rejects unavailable years", {
  expect_error(get_statewide_proficiency(2021), "not available")
  expect_error(get_statewide_proficiency(2025), "not available")
  expect_error(get_statewide_proficiency(2019), "not available")
})

test_that("fetch_assessment rejects years outside 2022-2025", {
  expect_error(fetch_assessment(2021))
  expect_error(fetch_assessment(2026))
})

test_that("get_available_assessment_years returns expected structure", {
  avail <- get_available_assessment_years()

  expect_true(is.list(avail))
  expect_equal(avail$min_year, 2022)
  expect_true(avail$max_year >= 2024,
              info = "max_year should be >= 2024")
  expect_true(all(2022:2024 %in% avail$available_years),
              info = "available_years should include 2022-2024")
})

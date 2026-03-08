# ==============================================================================
# Enrollment Year Coverage Tests for mdschooldata
# ==============================================================================
#
# Exhaustive per-year tests for enrollment data across all available years
# (2015-2025). Each year is tested for:
# - Data loads with >0 rows
# - Required columns present
# - State total within expected range (~840K-880K for MD)
# - Largest jurisdiction is Montgomery County or Prince George's County
# - All 24 jurisdictions present
# - Subgroup and grade completeness
# - Entity flags correct
# - No Inf/NaN/negative values
#
# Pinned values sourced from MD Department of Planning data (real downloads).
#
# ==============================================================================

library(testthat)

# All available enrollment years from MD Department of Planning
# MDP fall-year columns + 1 = end_year (e.g., MDP "2014" = end_year 2015)
enrollment_years <- 2015:2025

# Known state totals from real MDP data (pinned values)
# These are K-12 totals for the state from the MDP Excel file
# Labels are end_year (MDP fall-year + 1), e.g. MDP column "2014" = end_year 2015
known_state_totals <- list(
  "2015" = 843724,
  "2016" = 848166,
  "2017" = 854913,
  "2018" = 862867,
  "2019" = 865491,
  "2020" = 876810,
  "2021" = 858519,
  "2022" = 853307,
  "2023" = 858850,
  "2024" = 858362,
  "2025" = 859083
)

# Known Montgomery County totals (district_id = "16")
# Labels are end_year (MDP fall-year + 1)
known_montgomery_totals <- list(
  "2015" = 150320,
  "2019" = 158101,
  "2023" = 156246,
  "2025" = 154791
)

# Known Prince George's County totals (district_id = "17")
# Labels are end_year (MDP fall-year + 1)
known_pg_totals <- list(
  "2015" = 121783,
  "2019" = 127524,
  "2023" = 126319,
  "2025" = 127330
)

# ==============================================================================
# PER-YEAR TIDY ENROLLMENT TESTS
# ==============================================================================

for (yr in enrollment_years) {

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): loads with >0 rows"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_true(nrow(d) > 0,
                info = paste("Year", yr, "returned 0 rows"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): has required columns"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    required_cols <- c("end_year", "type", "district_id", "district_name",
                       "grade_level", "subgroup", "n_students", "pct",
                       "is_state", "is_district", "is_campus")
    for (col in required_cols) {
      expect_true(col %in% names(d),
                  info = paste("Year", yr, "missing column:", col))
    }
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): end_year matches"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)
    expect_true(all(d$end_year == yr),
                info = paste("Year", yr, "has mismatched end_year values"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): state total in expected range"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_total <- d |>
      dplyr::filter(is_state, subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_length(state_total, 1)
    # MD state enrollment has been between ~840K and ~880K across 2015-2025
    expect_true(state_total > 800000,
                info = paste("Year", yr, "state total too low:", state_total))
    expect_true(state_total < 950000,
                info = paste("Year", yr, "state total too high:", state_total))
  })

  # Pin exact state totals for years we know
  yr_str <- as.character(yr)
  if (yr_str %in% names(known_state_totals)) {
    test_that(paste0("fetch_enr(", yr, "): pinned state total = ",
                     known_state_totals[[yr_str]]), {
      skip_if_offline()
      d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

      state_total <- d |>
        dplyr::filter(is_state, subgroup == "total_enrollment",
                      grade_level == "TOTAL") |>
        dplyr::pull(n_students)

      expect_equal(state_total, known_state_totals[[yr_str]],
                   tolerance = 1,
                   info = paste("Year", yr, "state total mismatch"))
    })
  }

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): all 24 jurisdictions present"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    districts <- d |>
      dplyr::filter(is_district, subgroup == "total_enrollment",
                    grade_level == "TOTAL")

    expect_equal(nrow(districts), 24,
                 info = paste("Year", yr, "has",
                              nrow(districts), "districts instead of 24"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): Montgomery County is largest or 2nd largest"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    districts <- d |>
      dplyr::filter(is_district, subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      dplyr::arrange(dplyr::desc(n_students))

    # Montgomery has been the largest MD district for all years in range
    top2 <- districts$district_id[1:2]
    expect_true("16" %in% top2,
                info = paste("Year", yr,
                             ": Montgomery (16) not in top 2. Top 2 are",
                             paste(districts$district_name[1:2], collapse = ", ")))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): expected grade levels present"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    state_grades <- d |>
      dplyr::filter(is_state, subgroup == "total_enrollment") |>
      dplyr::pull(grade_level) |>
      unique()

    # MD data should have K, 01-12, and TOTAL
    expect_true("TOTAL" %in% state_grades,
                info = paste("Year", yr, "missing TOTAL grade_level"))
    expect_true("K" %in% state_grades,
                info = paste("Year", yr, "missing K grade_level"))

    # Check for numeric grades 01-12
    for (g in sprintf("%02d", 1:12)) {
      expect_true(g %in% state_grades,
                  info = paste("Year", yr, "missing grade_level:", g))
    }
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): total_enrollment subgroup present"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    subgroups <- unique(d$subgroup)
    expect_true("total_enrollment" %in% subgroups,
                info = paste("Year", yr, "missing total_enrollment subgroup"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): entity flags mutually exclusive"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # Each row should be exactly one entity type
    flag_sum <- as.integer(d$is_state) + as.integer(d$is_district) +
      as.integer(d$is_campus)
    expect_true(all(flag_sum == 1),
                info = paste("Year", yr,
                             ": some rows have overlapping entity flags"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): no Inf/NaN in n_students"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_false(any(is.infinite(d$n_students)),
                 info = paste("Year", yr, "has Inf in n_students"))
    expect_false(any(is.nan(d$n_students)),
                 info = paste("Year", yr, "has NaN in n_students"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): no negative n_students"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_true(all(d$n_students >= 0, na.rm = TRUE),
                info = paste("Year", yr, "has negative n_students"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): percentages in [0, 1]"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    valid_pct <- d$pct[!is.na(d$pct)]
    if (length(valid_pct) > 0) {
      expect_true(all(valid_pct >= 0 & valid_pct <= 1),
                  info = paste("Year", yr, "has pct outside [0, 1]"))
    }
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=TRUE): no Inf/NaN in pct"), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    expect_false(any(is.infinite(d$pct)),
                 info = paste("Year", yr, "has Inf in pct"))
    expect_false(any(is.nan(d$pct)),
                 info = paste("Year", yr, "has NaN in pct"))
  })
}

# ==============================================================================
# PINNED JURISDICTION VALUES
# ==============================================================================

for (yr_str in names(known_montgomery_totals)) {
  yr <- as.integer(yr_str)
  test_that(paste0("fetch_enr(", yr, "): pinned Montgomery County total = ",
                   known_montgomery_totals[[yr_str]]), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    mont <- d |>
      dplyr::filter(is_district, district_id == "16",
                    subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(mont, known_montgomery_totals[[yr_str]],
                 tolerance = 1,
                 info = paste("Montgomery County total mismatch for", yr))
  })
}

for (yr_str in names(known_pg_totals)) {
  yr <- as.integer(yr_str)
  test_that(paste0("fetch_enr(", yr, "): pinned Prince George's County total = ",
                   known_pg_totals[[yr_str]]), {
    skip_if_offline()
    d <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    pg <- d |>
      dplyr::filter(is_district, district_id == "17",
                    subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(pg, known_pg_totals[[yr_str]],
                 tolerance = 1,
                 info = paste("Prince George's County total mismatch for", yr))
  })
}

# ==============================================================================
# PER-YEAR WIDE FORMAT TESTS
# ==============================================================================

for (yr in enrollment_years) {

  test_that(paste0("fetch_enr(", yr, ", tidy=FALSE): loads with correct structure"), {
    skip_if_offline()
    w <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    expect_true(nrow(w) > 0,
                info = paste("Year", yr, "wide format has 0 rows"))

    # Wide format should have grade columns
    expect_true("grade_k" %in% names(w),
                info = paste("Year", yr, "wide format missing grade_k"))
    expect_true("grade_01" %in% names(w),
                info = paste("Year", yr, "wide format missing grade_01"))
    expect_true("row_total" %in% names(w),
                info = paste("Year", yr, "wide format missing row_total"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=FALSE): 25 rows (1 state + 24 districts)"), {
    skip_if_offline()
    w <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    expect_equal(nrow(w), 25,
                 info = paste("Year", yr, "has", nrow(w),
                              "rows in wide format, expected 25"))
  })

  test_that(paste0("fetch_enr(", yr, ", tidy=FALSE): grade columns sum to row_total"), {
    skip_if_offline()
    w <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)

    state_row <- w[w$type == "State", ]
    grade_cols <- c("grade_k", paste0("grade_", sprintf("%02d", 1:12)))
    grade_cols_present <- grade_cols[grade_cols %in% names(state_row)]

    if (length(grade_cols_present) > 0) {
      grade_sum <- sum(sapply(grade_cols_present, function(col) {
        state_row[[col]]
      }), na.rm = TRUE)

      # Grade sum should equal row_total within 1%
      expect_true(
        abs(grade_sum - state_row$row_total) / state_row$row_total < 0.01,
        info = paste("Year", yr, ": grade sum", grade_sum,
                     "differs from row_total", state_row$row_total)
      )
    }
  })
}

# ==============================================================================
# MULTI-YEAR CONSISTENCY TESTS
# ==============================================================================

test_that("fetch_enr_multi returns combined data for all available years", {
  skip_if_offline()
  d <- fetch_enr_multi(2020:2024, tidy = TRUE, use_cache = TRUE)

  expect_true(nrow(d) > 0, info = "Multi-year fetch returned 0 rows")
  expect_equal(sort(unique(d$end_year)), 2020:2024)

  # Each year should have state row
  for (yr in 2020:2024) {
    yr_state <- d |>
      dplyr::filter(end_year == yr, is_state,
                    subgroup == "total_enrollment",
                    grade_level == "TOTAL")
    expect_equal(nrow(yr_state), 1,
                 info = paste("Year", yr, "missing state row in multi-year"))
  }
})

test_that("State totals are monotonically reasonable across years", {
  skip_if_offline()
  d <- fetch_enr_multi(2015:2025, tidy = TRUE, use_cache = TRUE)

  state_totals <- d |>
    dplyr::filter(is_state, subgroup == "total_enrollment",
                  grade_level == "TOTAL") |>
    dplyr::arrange(end_year) |>
    dplyr::pull(n_students)

  # Year-over-year change should not exceed 5% (no unreasonable jumps)
  for (i in 2:length(state_totals)) {
    pct_change <- abs(state_totals[i] - state_totals[i - 1]) /
      state_totals[i - 1]
    expect_true(pct_change < 0.05,
                info = paste("Year-over-year change exceeds 5% at index", i,
                             ":", round(pct_change * 100, 2), "%"))
  }
})

test_that("District count is consistently 24 across all years", {
  skip_if_offline()
  d <- fetch_enr_multi(2015:2025, tidy = TRUE, use_cache = TRUE)

  for (yr in 2015:2025) {
    n_dists <- d |>
      dplyr::filter(end_year == yr, is_district,
                    subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      nrow()
    expect_equal(n_dists, 24,
                 info = paste("Year", yr, "has", n_dists,
                              "districts instead of 24"))
  }
})

# ==============================================================================
# TIDY <-> WIDE FIDELITY TESTS
# ==============================================================================

for (yr in c(2015, 2018, 2022, 2024)) {
  test_that(paste0("fetch_enr(", yr, "): tidy totals match wide row_total"), {
    skip_if_offline()
    wide <- fetch_enr(yr, tidy = FALSE, use_cache = TRUE)
    tidy <- fetch_enr(yr, tidy = TRUE, use_cache = TRUE)

    # State total from wide
    wide_state_total <- wide$row_total[wide$type == "State"]

    # State total from tidy
    tidy_state_total <- tidy |>
      dplyr::filter(is_state, subgroup == "total_enrollment",
                    grade_level == "TOTAL") |>
      dplyr::pull(n_students)

    expect_equal(tidy_state_total, wide_state_total,
                 info = paste("Year", yr,
                              ": tidy/wide state total mismatch"))
  })
}

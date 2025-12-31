# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw enrollment data from the
# Maryland State Department of Education (MSDE) into a clean,
# standardized format.
#
# MSDE data comes from:
# - Maryland Report Card (https://reportcard.msde.maryland.gov)
# - MSDE Staff and Student Publications (PDF reports)
#
# This module transforms raw data into wide format with demographic columns.
#
# ==============================================================================

#' Process raw enrollment data from MSDE
#'
#' Transforms raw enrollment data from MSDE sources
#' into a standardized schema with wide demographic columns.
#'
#' @param raw_data Raw data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Check if this is disaggregated format (has 'race' or 'sex' columns)
  if ("race" %in% names(raw_data) || "sex" %in% names(raw_data)) {
    result <- process_disaggregated_enrollment(raw_data, end_year)
  } else {
    # Legacy format processing
    raw_data <- standardize_column_names(raw_data)

    if ("type" %in% names(raw_data)) {
      result <- process_typed_data(raw_data, end_year)
    } else if ("SchoolNumber" %in% names(raw_data) || "school_number" %in% names(raw_data)) {
      result <- process_school_data(raw_data, end_year)
    } else if ("LSSNumber" %in% names(raw_data) || "lss_number" %in% names(raw_data) ||
               "district_id" %in% names(raw_data)) {
      result <- process_district_data(raw_data, end_year)
    } else {
      result <- process_generic_enrollment(raw_data, end_year)
    }
  }

  # Ensure all expected columns exist
  result <- ensure_standard_columns(result, end_year)

  # Create state aggregate if not present
  if (!"State" %in% result$type) {
    district_data <- result[result$type == "District", ]
    if (nrow(district_data) > 0) {
      state_row <- create_state_aggregate(district_data, end_year)
      result <- dplyr::bind_rows(state_row, result)
    } else {
      # No district data - create state aggregate from school data
      school_data <- result[result$type == "Campus", ]
      if (nrow(school_data) > 0) {
        state_row <- create_state_aggregate(school_data, end_year)
        result <- dplyr::bind_rows(state_row, result)
      }
    }
  }

  result
}


#' Process disaggregated enrollment data format
#'
#' Handles enrollment data with one row per combination of entity, race,
#' and sex. This function pivots that data into wide format with
#' demographic columns.
#'
#' Note: This function handles data that may have 'race' and 'sex' columns
#' in a disaggregated format (one row per demographic combination).
#'
#' @param raw_data Raw data frame with race/sex disaggregation
#' @param end_year School year end
#' @return Processed data frame in wide format
#' @keywords internal
process_disaggregated_enrollment <- function(raw_data, end_year) {

  # Column structure for disaggregated data:
  # - leaid or district_id: LEA/District ID
  # - lea_name or district_name: District name
  # - school_id or campus_id: School ID (if school-level)
  # - school_name or campus_name: School name
  # - year: School year end
  # - race: Race category (numeric code)
  # - sex: Sex category (numeric code)
  # - enrollment: Enrollment count
  # - grade: Grade level (if present)
  # - type: "District" or "Campus"

  # Race codes:
  # 1 = White, 2 = Black, 3 = Hispanic, 4 = Asian,
  # 5 = American Indian/Alaska Native, 6 = Native Hawaiian/Pacific Islander,
  # 7 = Two or more races, 99 = Total
  # Sex codes: 1 = Male, 2 = Female, 99 = Total

  # Standardize column names first
  if ("lea_name" %in% names(raw_data) && !"district_name" %in% names(raw_data)) {
    raw_data$district_name <- raw_data$lea_name
  }
  if ("leaid" %in% names(raw_data) && !"district_id" %in% names(raw_data)) {
    # Extract the 2-digit LSS code from longer LEA ID formats
    # Some formats use 24xxxxx where xxx is the LSS code
    raw_data$district_id <- sprintf("%02d", as.integer(substr(raw_data$leaid, 3, 5)))
  }
  if ("school_id" %in% names(raw_data) && !"campus_id" %in% names(raw_data)) {
    raw_data$campus_id <- as.character(raw_data$school_id)
  }
  if ("school_name" %in% names(raw_data) && !"campus_name" %in% names(raw_data)) {
    raw_data$campus_name <- raw_data$school_name
  }

  # Process district and school data separately
  district_data <- raw_data[raw_data$type == "District", ]
  school_data <- raw_data[raw_data$type == "Campus", ]

  # Process each
  district_wide <- if (nrow(district_data) > 0) {
    pivot_enrollment_wide(district_data, "District")
  } else {
    NULL
  }

  school_wide <- if (nrow(school_data) > 0) {
    pivot_enrollment_wide(school_data, "Campus")
  } else {
    NULL
  }

  # Combine results
  result <- dplyr::bind_rows(district_wide, school_wide)

  if (nrow(result) == 0) {
    return(create_empty_processed_df(end_year))
  }

  result$end_year <- end_year
  result
}


#' Pivot enrollment data from long to wide format
#'
#' Takes disaggregated enrollment data and pivots it to have one row
#' per entity with demographic columns.
#'
#' @param data Long-format enrollment data
#' @param entity_type "District" or "Campus"
#' @return Wide-format data frame
#' @keywords internal
pivot_enrollment_wide <- function(data, entity_type) {

  # Determine the ID column based on entity type
  if (entity_type == "District") {
    id_cols <- c("district_id", "district_name")
  } else {
    id_cols <- c("district_id", "district_name", "campus_id", "campus_name")
  }

  # Filter to available ID columns
  id_cols <- id_cols[id_cols %in% names(data)]

  if (length(id_cols) == 0) {
    return(NULL)
  }

  # Ensure enrollment is numeric
  data$enrollment <- safe_numeric(data$enrollment)

  # Create race mapping
  race_map <- c(
    "1" = "white",
    "2" = "black",
    "3" = "hispanic",
    "4" = "asian",
    "5" = "native_american",
    "6" = "pacific_islander",
    "7" = "multiracial",
    "99" = "total"
  )

  # Create sex mapping
  sex_map <- c(
    "1" = "male",
    "2" = "female",
    "99" = "total"
  )

  # Get unique entities
  entities <- unique(data[, id_cols, drop = FALSE])

  # For each entity, aggregate by race and sex
  result_list <- lapply(seq_len(nrow(entities)), function(i) {
    entity <- entities[i, , drop = FALSE]

    # Filter data for this entity
    entity_filter <- rep(TRUE, nrow(data))
    for (col in id_cols) {
      entity_filter <- entity_filter & (data[[col]] == entity[[col]] | (is.na(data[[col]]) & is.na(entity[[col]])))
    }
    entity_data <- data[entity_filter, ]

    # Initialize result row
    row <- entity
    row$type <- entity_type

    # Get totals (race = 99, sex = 99)
    total_rows <- entity_data[entity_data$race == 99 & entity_data$sex == 99, ]
    row$row_total <- sum(total_rows$enrollment, na.rm = TRUE)

    # Get race totals (sex = 99)
    for (race_code in names(race_map)) {
      if (race_code == "99") next
      race_rows <- entity_data[entity_data$race == as.integer(race_code) & entity_data$sex == 99, ]
      col_name <- race_map[race_code]
      row[[col_name]] <- sum(race_rows$enrollment, na.rm = TRUE)
    }

    # Get sex totals (race = 99)
    for (sex_code in names(sex_map)) {
      if (sex_code == "99") next
      sex_rows <- entity_data[entity_data$sex == as.integer(sex_code) & entity_data$race == 99, ]
      col_name <- sex_map[sex_code]
      row[[col_name]] <- sum(sex_rows$enrollment, na.rm = TRUE)
    }

    # Get grade totals if available
    if ("grade" %in% names(entity_data)) {
      grade_totals <- entity_data[entity_data$race == 99 & entity_data$sex == 99, ]
      for (g in unique(grade_totals$grade)) {
        grade_rows <- grade_totals[grade_totals$grade == g, ]
        grade_col <- grade_to_column(g)
        if (!is.null(grade_col)) {
          row[[grade_col]] <- sum(grade_rows$enrollment, na.rm = TRUE)
        }
      }
    }

    row
  })

  # Combine all rows
  dplyr::bind_rows(result_list)
}


#' Convert grade code to column name
#'
#' @param grade Grade code from API
#' @return Column name or NULL if unknown grade
#' @keywords internal
grade_to_column <- function(grade) {
  grade <- as.character(grade)

  grade_map <- c(
    "-1" = "grade_pk",
    "0" = "grade_k",
    "1" = "grade_01",
    "2" = "grade_02",
    "3" = "grade_03",
    "4" = "grade_04",
    "5" = "grade_05",
    "6" = "grade_06",
    "7" = "grade_07",
    "8" = "grade_08",
    "9" = "grade_09",
    "10" = "grade_10",
    "11" = "grade_11",
    "12" = "grade_12"
  )

  if (grade %in% names(grade_map)) {
    return(grade_map[grade])
  }

  NULL
}


#' Create empty processed data frame
#'
#' @param end_year School year end
#' @return Empty data frame with expected structure
#' @keywords internal
create_empty_processed_df <- function(end_year) {
  data.frame(
    end_year = integer(),
    type = character(),
    district_id = character(),
    district_name = character(),
    campus_id = character(),
    campus_name = character(),
    row_total = integer(),
    white = integer(),
    black = integer(),
    hispanic = integer(),
    asian = integer(),
    native_american = integer(),
    pacific_islander = integer(),
    multiracial = integer(),
    male = integer(),
    female = integer(),
    stringsAsFactors = FALSE
  )
}


#' Standardize column names from various sources
#'
#' @param df Data frame with potentially varied column names
#' @return Data frame with standardized column names
#' @keywords internal
standardize_column_names <- function(df) {
  cols <- names(df)
  new_cols <- cols

  # Common mappings
  mappings <- list(
    # ID columns
    "LSSNumber" = "district_id",
    "LSS_Number" = "district_id",
    "lss_number" = "district_id",
    "DistrictID" = "district_id",
    "SchoolNumber" = "campus_id",
    "School_Number" = "campus_id",
    "school_number" = "campus_id",
    "SchoolID" = "campus_id",

    # Name columns
    "LSSName" = "district_name",
    "LSS_Name" = "district_name",
    "lss_name" = "district_name",
    "DistrictName" = "district_name",
    "SchoolName" = "campus_name",
    "School_Name" = "campus_name",
    "school_name" = "campus_name",

    # Enrollment columns
    "Enrollment" = "row_total",
    "TotalEnrollment" = "row_total",
    "Total_Enrollment" = "row_total",
    "Total" = "row_total",
    "total_enrollment" = "row_total",

    # Race/ethnicity columns
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
    "Multiracial" = "multiracial",

    # Gender columns
    "Male" = "male",
    "Female" = "female",
    "Boys" = "male",
    "Girls" = "female",

    # Grade columns
    "Prekindergarten" = "grade_pk",
    "PreK" = "grade_pk",
    "Pre_K" = "grade_pk",
    "Kindergarten" = "grade_k",
    "Grade_1" = "grade_01",
    "Grade_2" = "grade_02",
    "Grade_3" = "grade_03",
    "Grade_4" = "grade_04",
    "Grade_5" = "grade_05",
    "Grade_6" = "grade_06",
    "Grade_7" = "grade_07",
    "Grade_8" = "grade_08",
    "Grade_9" = "grade_09",
    "Grade_10" = "grade_10",
    "Grade_11" = "grade_11",
    "Grade_12" = "grade_12"
  )

  for (i in seq_along(cols)) {
    if (cols[i] %in% names(mappings)) {
      new_cols[i] <- mappings[[cols[i]]]
    }
  }

  names(df) <- new_cols
  df
}


#' Process data that already has type column
#'
#' @param df Data frame with type column
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_typed_data <- function(df, end_year) {
  df$end_year <- end_year
  df
}


#' Process school-level enrollment data
#'
#' @param df Raw school data frame
#' @param end_year School year end
#' @return Processed school data frame
#' @keywords internal
process_school_data <- function(df, end_year) {

  n_rows <- nrow(df)

  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("Campus", n_rows),
    stringsAsFactors = FALSE
  )

  # Copy over standardized columns
  standard_cols <- c(
    "district_id", "district_name", "campus_id", "campus_name",
    "row_total", "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  for (col in standard_cols) {
    if (col %in% names(df)) {
      if (col %in% c("district_id", "district_name", "campus_id", "campus_name")) {
        result[[col]] <- as.character(df[[col]])
      } else {
        result[[col]] <- safe_numeric(df[[col]])
      }
    }
  }

  # Extract district_id from campus_id if needed (Maryland format: LSS + School)
  if (!"district_id" %in% names(result) && "campus_id" %in% names(result)) {
    # MD school IDs typically have LSS as first 2 digits
    result$district_id <- substr(result$campus_id, 1, 2)
  }

  result
}


#' Process district-level enrollment data
#'
#' @param df Raw district data frame
#' @param end_year School year end
#' @return Processed district data frame
#' @keywords internal
process_district_data <- function(df, end_year) {

  n_rows <- nrow(df)

  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep("District", n_rows),
    campus_id = rep(NA_character_, n_rows),
    campus_name = rep(NA_character_, n_rows),
    stringsAsFactors = FALSE
  )

  # Copy over standardized columns
  standard_cols <- c(
    "district_id", "district_name",
    "row_total", "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  for (col in standard_cols) {
    if (col %in% names(df)) {
      if (col %in% c("district_id", "district_name")) {
        result[[col]] <- as.character(df[[col]])
      } else {
        result[[col]] <- safe_numeric(df[[col]])
      }
    }
  }

  # Ensure district_id is padded to 2 digits
  if ("district_id" %in% names(result)) {
    result$district_id <- sprintf("%02s", result$district_id)
  }

  result
}


#' Process generic enrollment data
#'
#' Attempts to process enrollment data with unknown structure.
#'
#' @param df Raw data frame
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_generic_enrollment <- function(df, end_year) {

  n_rows <- nrow(df)

  # Determine type based on available columns
  if (any(grepl("school", names(df), ignore.case = TRUE))) {
    type <- "Campus"
  } else if (any(grepl("district|lss", names(df), ignore.case = TRUE))) {
    type <- "District"
  } else {
    type <- "Unknown"
  }

  result <- data.frame(
    end_year = rep(end_year, n_rows),
    type = rep(type, n_rows),
    stringsAsFactors = FALSE
  )

  # Try to extract any matching columns
  for (col in names(df)) {
    std_col <- tolower(gsub("[^a-zA-Z]", "_", col))

    if (grepl("enrollment|total", std_col, ignore.case = TRUE)) {
      result$row_total <- safe_numeric(df[[col]])
    } else if (grepl("white", std_col, ignore.case = TRUE)) {
      result$white <- safe_numeric(df[[col]])
    } else if (grepl("black|african", std_col, ignore.case = TRUE)) {
      result$black <- safe_numeric(df[[col]])
    } else if (grepl("hispanic", std_col, ignore.case = TRUE)) {
      result$hispanic <- safe_numeric(df[[col]])
    } else if (grepl("asian", std_col, ignore.case = TRUE) &&
               !grepl("pacific|hawaiian", std_col, ignore.case = TRUE)) {
      result$asian <- safe_numeric(df[[col]])
    }
  }

  result
}


#' Ensure all standard columns exist
#'
#' @param df Data frame to check
#' @param end_year School year end
#' @return Data frame with all standard columns
#' @keywords internal
ensure_standard_columns <- function(df, end_year) {

  standard_cols <- c(
    "end_year", "type",
    "district_id", "campus_id",
    "district_name", "campus_name",
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  for (col in standard_cols) {
    if (!col %in% names(df)) {
      if (col %in% c("end_year")) {
        df[[col]] <- end_year
      } else if (col %in% c("type", "district_id", "campus_id", "district_name", "campus_name")) {
        df[[col]] <- NA_character_
      } else {
        df[[col]] <- NA_integer_
      }
    }
  }

  # Reorder columns
  df <- df[, intersect(standard_cols, names(df))]

  df
}


#' Create state-level aggregate from district data
#'
#' @param district_df Processed district data frame
#' @param end_year School year end
#' @return Single-row data frame with state totals
#' @keywords internal
create_state_aggregate <- function(district_df, end_year) {

  # Columns to sum
  sum_cols <- c(
    "row_total",
    "white", "black", "hispanic", "asian",
    "pacific_islander", "native_american", "multiracial",
    "male", "female",
    "grade_pk", "grade_k",
    "grade_01", "grade_02", "grade_03", "grade_04",
    "grade_05", "grade_06", "grade_07", "grade_08",
    "grade_09", "grade_10", "grade_11", "grade_12"
  )

  # Filter to columns that exist
  sum_cols <- sum_cols[sum_cols %in% names(district_df)]

  # Create state row
  state_row <- data.frame(
    end_year = end_year,
    type = "State",
    district_id = NA_character_,
    campus_id = NA_character_,
    district_name = "Maryland",
    campus_name = NA_character_,
    stringsAsFactors = FALSE
  )

  # Sum each column
  for (col in sum_cols) {
    state_row[[col]] <- sum(district_df[[col]], na.rm = TRUE)
  }

  state_row
}

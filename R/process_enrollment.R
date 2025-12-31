# ==============================================================================
# Enrollment Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw MSDE enrollment data into a
# clean, standardized format.
#
# ==============================================================================

#' Process raw MSDE enrollment data
#'
#' Transforms raw enrollment data into a standardized schema.
#'
#' @param raw_data Raw data frame from get_raw_enr
#' @param end_year School year end
#' @return Processed data frame with standardized columns
#' @keywords internal
process_enr <- function(raw_data, end_year) {

  # Standardize column names (handle various formats from different sources)
  raw_data <- standardize_column_names(raw_data)

  # Process by type (State, District, School)
  # First check if we have the expected structure

  if ("type" %in% names(raw_data)) {
    # Already has type column - process as-is
    result <- process_typed_data(raw_data, end_year)
  } else if ("SchoolNumber" %in% names(raw_data) || "school_number" %in% names(raw_data)) {
    # School-level data
    result <- process_school_data(raw_data, end_year)
  } else if ("LSSNumber" %in% names(raw_data) || "lss_number" %in% names(raw_data) ||
             "district_id" %in% names(raw_data)) {
    # District-level data
    result <- process_district_data(raw_data, end_year)
  } else {
    # Try to infer structure
    result <- process_generic_enrollment(raw_data, end_year)
  }

  # Ensure all expected columns exist
  result <- ensure_standard_columns(result, end_year)

  # Create state aggregate if not present
  if (!"State" %in% result$type) {
    state_row <- create_state_aggregate(result[result$type == "District", ], end_year)
    result <- dplyr::bind_rows(state_row, result)
  }

  result
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

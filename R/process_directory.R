# ==============================================================================
# Directory Data Processing Functions
# ==============================================================================
#
# This file contains functions for processing raw directory data from the
# Maryland State Department of Education into a standard format.
#
# ==============================================================================

#' Process raw directory data
#'
#' Processes the raw school directory data into a standardized format.
#'
#' @param raw_data List of raw data frames from get_raw_directory()
#' @return Data frame with standardized columns
#' @keywords internal
#' @importFrom tibble as_tibble
process_directory <- function(raw_data) {

  # Process each directory type and combine
  processed <- lapply(names(raw_data), function(type) {
    df <- raw_data[[type]]

    # Standardize column names (convert to lowercase)
    names(df) <- tolower(names(df))

    # Create a result data frame with all required columns
    n_rows <- nrow(df)
    result <- data.frame(
      directory_type = rep(type, n_rows),
      school_name = NA_character_,
      address = NA_character_,
      city = NA_character_,
      state = rep("MD", n_rows),
      zip = NA_character_,
      county = NA_character_,
      grades = NA_character_,
      school_type = NA_character_,
      stringsAsFactors = FALSE
    )

    # Map columns based on MD iMAP format
    col_map <- list(
      school_name = c("school_nam", "school", "school name", "name"),
      address = c("address", "street", "street address"),
      city = c("city"),
      state = c("state"),
      zip = c("zip", "zip code", "zipcode"),
      county = c("county", "county name"),
      grades = c("grades", "grade", "grade_level"),
      school_type = c("type", "school_type", "school type")
    )

    # Map columns
    for (std_col in names(col_map)) {
      for (pattern in col_map[[std_col]]) {
        matched <- grep(pattern, names(df), ignore.case = TRUE)
        if (length(matched) > 0) {
          result[[std_col]] <- as.character(df[[matched[1]]])
          break
        }
      }
    }

    # Remove rows with missing school name (essential field)
    if ("school_name" %in% names(result)) {
      result <- result[!is.na(result$school_name) & result$school_name != "", , drop = FALSE]
    }

    # Clean up zip codes (remove any non-numeric characters)
    if ("zip" %in% names(result)) {
      result$zip <- gsub("[^0-9]", "", result$zip)
    }

    # Convert to tibble
    tibble::as_tibble(result)
  })

  # Combine all directory types
  combined <- dplyr::bind_rows(processed)

  # Select only columns that exist
  available_cols <- intersect(c("directory_type", "school_name", "address", "city",
                               "state", "zip", "county", "grades", "school_type"),
                             names(combined))

  combined <- combined[, available_cols, drop = FALSE]

  combined
}

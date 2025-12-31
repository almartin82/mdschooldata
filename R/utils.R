# ==============================================================================
# Utility Functions
# ==============================================================================

# Global variable bindings for R CMD check (used in dplyr/tidyr pipelines)
utils::globalVariables(c(
  "type", "subgroup", "grade_level", "n_students", "row_total", "pct",
  "is_state", "is_district", "is_campus"
))

#' Convert to numeric, handling suppression markers
#'
#' MSDE uses various markers for suppressed data (*, <, >, etc.)
#' and may use commas in large numbers.
#'
#' @param x Vector to convert
#' @return Numeric vector with NA for non-numeric values
#' @keywords internal
safe_numeric <- function(x) {
  if (is.numeric(x)) return(x)

  # Convert to character if needed
  x <- as.character(x)

  # Remove commas and whitespace
  x <- gsub(",", "", x)
  x <- trimws(x)


  # Handle common suppression markers
  x[x %in% c("*", ".", "-", "-1", "<5", "<", ">", "N/A", "NA", "", "n/a", "DS", "SP")] <- NA_character_

  # Handle range markers like "<10" or ">95"
  x[grepl("^<[0-9]+$", x)] <- NA_character_
  x[grepl("^>[0-9]+$", x)] <- NA_character_

  suppressWarnings(as.numeric(x))
}


#' Get Maryland LSS (Local School System) codes
#'
#' Returns a mapping of LSS numbers to names for Maryland's 24 school systems.
#'
#' @return Named vector with LSS codes as names and LSS names as values
#' @keywords internal
get_lss_codes <- function() {
  c(
    "01" = "Allegany",
    "02" = "Anne Arundel",
    "03" = "Baltimore City",
    "04" = "Baltimore County",
    "05" = "Calvert",
    "06" = "Caroline",
    "07" = "Carroll",
    "08" = "Cecil",
    "09" = "Charles",
    "10" = "Dorchester",
    "11" = "Frederick",
    "12" = "Garrett",
    "13" = "Harford",
    "14" = "Howard",
    "15" = "Kent",
    "16" = "Montgomery",
    "17" = "Prince George's",
    "18" = "Queen Anne's",
    "19" = "St. Mary's",
    "20" = "Somerset",
    "21" = "Talbot",
    "22" = "Washington",
    "23" = "Wicomico",
    "24" = "Worcester"
  )
}


#' Get Maryland grade level codes
#'
#' Returns the standard grade level codes used in Maryland enrollment data.
#'
#' @return Character vector of grade codes
#' @keywords internal
get_grade_codes <- function() {
  c(
    "PK" = "Prekindergarten",
    "K" = "Kindergarten",
    "01" = "Grade 1",
    "02" = "Grade 2",
    "03" = "Grade 3",
    "04" = "Grade 4",
    "05" = "Grade 5",
    "06" = "Grade 6",
    "07" = "Grade 7",
    "08" = "Grade 8",
    "09" = "Grade 9",
    "10" = "Grade 10",
    "11" = "Grade 11",
    "12" = "Grade 12"
  )
}


#' Standardize race/ethnicity column names
#'
#' Maps various race/ethnicity column name formats to standard names.
#'
#' @param col_name Raw column name
#' @return Standardized column name
#' @keywords internal
standardize_race_col <- function(col_name) {
  col_lower <- tolower(col_name)

  if (grepl("white", col_lower)) return("white")
  if (grepl("black|african", col_lower)) return("black")
  if (grepl("hispanic|latino", col_lower)) return("hispanic")
  if (grepl("asian", col_lower) && !grepl("pacific|hawaiian", col_lower)) return("asian")
  if (grepl("pacific|hawaiian", col_lower)) return("pacific_islander")
  if (grepl("indian|native|alaska", col_lower) && !grepl("hawaiian|pacific", col_lower)) return("native_american")
  if (grepl("two|multi|more", col_lower)) return("multiracial")

  col_name
}


#' Format school year for display
#'
#' Converts end year to school year display format (e.g., 2024 -> "2023-24")
#'
#' @param end_year School year end
#' @return Formatted school year string
#' @keywords internal
format_school_year <- function(end_year) {
  start_year <- end_year - 1
  paste0(start_year, "-", substr(as.character(end_year), 3, 4))
}


#' Validate end_year parameter
#'
#' @param end_year Year to validate
#' @param min_year Minimum valid year (default 2003)
#' @param max_year Maximum valid year (default current year + 1)
#' @return TRUE if valid, throws error otherwise
#' @keywords internal
validate_year <- function(end_year, min_year = 2003, max_year = NULL) {
  if (is.null(max_year)) {
    max_year <- as.integer(format(Sys.Date(), "%Y")) + 1
  }

  if (!is.numeric(end_year) || length(end_year) != 1) {
    stop("end_year must be a single numeric value")
  }

  if (end_year < min_year || end_year > max_year) {
    stop(paste0(
      "end_year must be between ", min_year, " and ", max_year, ". ",
      "Year ", end_year, " is not available."
    ))
  }

  TRUE
}

# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Maryland State Department of Education (MSDE) Maryland Report Card.
#
# Assessment Systems:
# - MCAP: 2021-present (Maryland Comprehensive Assessment Program)
# - PARCC: 2015-2019 (Partnership for Assessment of Readiness for College and Careers)
# - MSA: Pre-2015 (Maryland School Assessment)
#
# Data Sources:
# - Maryland Report Card: https://reportcard.msde.maryland.gov/Graphs/
# - MCAP Support Portal: https://support.mdassessments.com/reporting/
#
# ==============================================================================

#' Download raw Maryland assessment data
#'
#' Downloads assessment data from the Maryland Report Card system. Includes
#' MCAP (2021-present) for grades 3-8 and high school in ELA, Mathematics,
#' and Science.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Valid range: 2021-2024 for MCAP data.
#' @param subject Assessment subject: "all" (default), "ELA", "Math", "Science",
#'   or "SocialStudies"
#' @param student_group "all" (default) for all students, or "groups" for
#'   student group breakdowns
#'
#' @return Data frame with assessment results including school/district/state
#'   aggregations, proficiency rates, and student group breakdowns
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2021-2024: MCAP data (Maryland Comprehensive Assessment Program)
#' }
#'
#' ## Data Source:
#' Maryland Report Card (MSDE):
#' https://reportcard.msde.maryland.gov/Graphs/
#'
#' The Maryland Report Card uses dynamic JavaScript to generate download links,
#' making automated downloads challenging. This function provides:
#'
#' 1. Documentation for manual download workflow
#' 2. Automated download if URL pattern can be discovered
#' 3. Fallback to import_local_assessment() for manual loading
#'
#' @seealso
#' \code{\link{fetch_assessment}} for the complete fetch pipeline
#' \code{\link{import_local_assessment}} for loading manually downloaded files
#'
#' @export
#' @examples
#' \dontrun{
#' # Download 2024 MCAP data (all subjects)
#' assess_2024 <- get_raw_assessment(2024)
#'
#' # Download only ELA results
#' assess_2024_ela <- get_raw_assessment(2024, subject = "ELA")
#'
#' # Download with student group breakdowns
#' assess_2024_groups <- get_raw_assessment(2024, student_group = "groups")
#' }
get_raw_assessment <- function(end_year,
                                subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
                                student_group = c("all", "groups")) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate year
  available_years <- 2021:2025
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2021 and 2025 for MCAP data.\n",
      "Note: MCAP assessments started in 2021-22 (end_year=2022).\n",
      "For historical data (PARCC, MSA), see ASSESSMENT-RESEARCH.md"
    ))
  }

  message(paste0(
    "\n",
    "===========================================================\n",
    "Maryland Assessment Data Download\n",
    "===========================================================\n",
    "Year: ", end_year, " (", end_year-1, "-", end_year, " school year)\n",
    "Subject: ", subject, "\n",
    "Student Groups: ", student_group, "\n\n",
    "DATA SOURCE: Maryland Report Card (MSDE)\n",
    "URL: https://reportcard.msde.maryland.gov/Graphs/\n\n"
  ))

  # Attempt automated download
  message("Attempting automated download...\n")

  assess_data <- tryCatch({
    download_assessment_data(end_year, subject, student_group)
  }, error = function(e) {
    message(paste("Automated download failed:", e$message, "\n"))
    message("Falling back to manual download instructions.\n")
    NULL
  })

  if (!is.null(assess_data) && nrow(assess_data) > 0) {
    message("\nDownload successful!\n")
    return(assess_data)
  }

  # Manual download instructions
  message(paste0(
    "MANUAL DOWNLOAD INSTRUCTIONS:\n",
    "-----------------------------\n",
    "1. Visit: https://reportcard.msde.maryland.gov/Graphs/\n",
    "2. Click on 'Data Downloads' tab\n",
    "3. Select the following filters:\n",
    "   - Year: ", end_year, "\n",
    "   - Assessment: MCAP ", subject, "\n",
    "   - Level: State, District, and School\n",
    "4. Click 'Download CSV' button\n",
    "5. Save the file to your working directory\n",
    "6. Load the data using:\n",
    "      import_local_assessment(path_to_file, year = ", end_year, ")\n\n",
    "For more information, see:\n",
    "ASSESSMENT-RESEARCH.md in the package directory\n\n",
    "Attempting to import from default location...\n"
  ))

  # Try to load from default local cache location
  cache_file <- file.path(
    tempdir(),
    paste0("md_assessment_", end_year, ".csv")
  )

  if (file.exists(cache_file)) {
    message(paste("Found cached file:", cache_file))
    assess_data <- read_assessment_csv(cache_file, end_year)
    return(assess_data)
  }

  # Return empty data frame with instructions
  message("\nNo assessment data found. Please download manually.\n")
  return(data.frame())
}


#' Download assessment data from Maryland Report Card
#'
#' Attempts to download assessment data from the Maryland Report Card system.
#' The Report Card uses dynamic URLs, so this function tries multiple strategies.
#'
#' @param end_year School year end
#' @param subject Assessment subject
#' @param student_group Student group filter
#'
#' @return Data frame with assessment data, or empty data frame on failure
#'
#' @keywords internal
download_assessment_data <- function(end_year, subject, student_group) {

  # Strategy 1: Try direct URL pattern if known
  # Maryland Report Card URLs follow a pattern like:
  # https://reportcard.msde.maryland.gov/Graphs/#/DataDownloads/datadownload/3/17/6/99/HASH
  # Where HASH is a dynamic identifier

  # For now, return empty data frame to trigger manual download workflow
  # TODO: Investigate actual URL pattern through browser inspection

  message("Note: Direct URL patterns for Maryland Report Card are not publicly documented.")
  message("The Report Card uses JavaScript to generate download links dynamically.")
  message("Use the manual download workflow described above.\n")

  return(data.frame())
}


#' Read assessment CSV file
#'
#' Reads and parses an assessment CSV file downloaded from Maryland Report Card.
#'
#' @param file_path Path to CSV file
#' @param end_year School year end
#'
#' @return Data frame with parsed assessment data
#'
#' @keywords internal
read_assessment_csv <- function(file_path, end_year) {

  message(paste("Reading assessment data from:", file_path))

  # Read the CSV file
  raw_data <- readr::read_csv(
    file_path,
    show_col_types = FALSE,
    na = c("", "NA", "N/A", "*")
  )

  # Add year column
  raw_data$end_year <- end_year

  # Standardize column names (Maryland Report Card uses various formats)
  raw_data <- standardize_column_names(raw_data)

  raw_data
}


#' Standardize assessment data column names
#'
#' Converts various Maryland Report Card column name formats to standard names.
#'
#' @param df Data frame with raw assessment data
#'
#' @return Data frame with standardized column names
#'
#' @keywords internal
standardize_column_names <- function(df) {

  # Maryland Report Card column mappings (examples - adjust based on actual data)
  # These patterns will need to be updated once we see actual Report Card exports

  col_mapping <- c(
    # School/District identifiers
    "School Code" = "school_code",
    "School Name" = "school_name",
    "District Code" = "district_code",
    "District Name" = "district_name",
    "State Code" = "state_code",
    "State Name" = "state_name",

    # Assessment info
    "Grade" = "grade",
    "Subject" = "subject",
    "Assessment" = "assessment",

    # Student groups
    "Student Group" = "student_group",
    "Subgroup" = "subgroup",

    # Performance metrics
    "Number Tested" = "n_tested",
    "Percent Proficient" = "pct_proficient",
    "Mean Scale Score" = "mean_scale_score",
    "Proficient Count" = "n_proficient",

    # Performance levels (MCAP has 4 levels)
    "Level 1 Percent" = "pct_level1",
    "Level 2 Percent" = "pct_level2",
    "Level 3 Percent" = "pct_level3",
    "Level 4 Percent" = "pct_level4",
    "Level 1 Count" = "n_level1",
    "Level 2 Count" = "n_level2",
    "Level 3 Count" = "n_level3",
    "Level 4 Count" = "n_level4"
  )

  # Apply mapping for columns that exist
  for (old_name in names(col_mapping)) {
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- col_mapping[old_name]
    }
  }

  # Clean column names: lowercase, replace spaces with underscores
  names(df) <- tolower(names(df))
  names(df) <- gsub("\\s+", "_", names(df))
  names(df) <- gsub("[^[:alnum:]_]", "", names(df))

  df
}


#' Import locally downloaded assessment file
#'
#' Imports an assessment data file that was manually downloaded from the
#' Maryland Report Card website.
#'
#' @param file_path Path to the CSV file downloaded from Maryland Report Card
#' @param end_year School year end (e.g., 2024 for 2023-24 school year)
#'
#' @return Data frame with assessment results
#'
#' @export
#' @examples
#' \dontrun{
#' # Import a manually downloaded assessment file
#' assess_data <- import_local_assessment(
#'   file_path = "~/Downloads/MD_Assessment_2024.csv",
#'   end_year = 2024
#' )
#'
#' # View the data
#' head(assess_data)
#' }
import_local_assessment <- function(file_path, end_year) {

  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  message(paste("Importing assessment data from:", file_path))

  # Read the file
  assess_data <- read_assessment_csv(file_path, end_year)

  # Add helper columns
  assess_data <- add_helper_columns(assess_data)

  message(paste("Imported", nrow(assess_data), "rows for", end_year))

  assess_data
}


#' Add helper columns to assessment data
#'
#' Adds is_state, is_district, is_school helper columns based on
#' school_code and district_code presence.
#'
#' @param df Data frame with assessment data
#'
#' @return Data frame with helper columns added
#'
#' @keywords internal
add_helper_columns <- function(df) {

  # Add aggregation level columns
  df$is_state <- FALSE
  df$is_district <- FALSE
  df$is_school <- FALSE

  # Detect state-level rows (no district or school codes)
  if ("district_code" %in% names(df)) {
    df$is_state <- is.na(df$district_code) | df$district_code == ""
    df$is_district <- !df$is_state & (is.na(df$school_code) | df$school_code == "")
    df$is_school <- !df$is_state & !df$is_district
  } else {
    df$is_state <- TRUE
  }

  df
}

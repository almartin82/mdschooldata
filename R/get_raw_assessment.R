# ==============================================================================
# Raw Assessment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw assessment data from the
# Maryland State Department of Education (MSDE) Maryland Report Card.
#
# Assessment Systems:
# - MCAP: 2022-present (Maryland Comprehensive Assessment Program)
#   - ELA: Grades 3-8, 10
#   - Mathematics: Grades 3-8, Algebra I, Algebra II, Geometry
#   - Science: Grades 5, 8, HS
#   - Social Studies: Grade 8, HS
# - PARCC: 2015-2019 (Partnership for Assessment of Readiness for College and Careers)
# - MSA: 2003-2014 (Maryland School Assessment)
#
# Data Sources:
# - Maryland Report Card: https://reportcard.msde.maryland.gov/Graphs/
# - Data Downloads: https://reportcard.msde.maryland.gov/DataDownloads/
#
# Current Limitation:
# The Maryland Report Card uses JavaScript to dynamically generate download links
# for proficiency data. Only participation rate data is available via direct URLs.
# Users needing proficiency data should use the Report Card interface directly
# or contact MSDE for bulk data exports.
#
# ==============================================================================

#' Get available MCAP data file URLs
#'
#' Returns URLs for available MCAP data files on the Maryland Report Card.
#' Currently only participation rate data is available via direct download.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param data_type Type of data: "participation" (available) or "proficiency" (requires manual download)
#' @return Named list with URLs and metadata
#' @keywords internal
get_mcap_data_urls <- function(end_year, data_type = "participation") {

  # Release year is typically end_year + 1 for fall releases
  # e.g., 2024 data released in 2025
  release_year <- end_year + 1

  # URL patterns for participation rate data (confirmed working)
  participation_patterns <- list(
    "2024" = list(
      url = "https://reportcard.msde.maryland.gov/DataDownloads/2025/2024/2024_MCAP_Participation_Rate_ELA_MATH_SCIENCE_Report_Card.zip",
      release_year = 2025
    ),
    "2023" = list(
      url = "https://reportcard.msde.maryland.gov/DataDownloads/2023/2023/MCAP_Participation_Rate_ELA_Math_Sci_2023.zip",
      release_year = 2023
    ),
    "2022" = list(
      url = "https://reportcard.msde.maryland.gov/DataDownloads/2023/2022/MCAP_Participation_Rate_ELA_Math_Sci_2022.zip",
      release_year = 2023
    )
  )

  year_str <- as.character(end_year)

  if (data_type == "participation") {
    if (year_str %in% names(participation_patterns)) {
      return(participation_patterns[[year_str]])
    }

    # Try to construct URL for other years
    return(list(
      url = paste0(
        "https://reportcard.msde.maryland.gov/DataDownloads/",
        release_year, "/", end_year, "/",
        end_year, "_MCAP_Participation_Rate_ELA_MATH_SCIENCE_Report_Card.zip"
      ),
      release_year = release_year
    ))
  }

  # Proficiency data is not available via direct URL
  if (data_type == "proficiency") {
    return(list(
      url = NULL,
      message = paste0(
        "MCAP proficiency data is not available via direct download.\n",
        "Visit https://reportcard.msde.maryland.gov to download interactively."
      )
    ))
  }

  NULL
}


#' Download raw Maryland assessment data
#'
#' Downloads assessment data from the Maryland Report Card system. Currently
#' provides MCAP participation rate data for 2022-present. Proficiency data
#' requires manual download from the Report Card interface.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Valid range: 2022-2025 for MCAP participation data.
#' @param data_type Type of data: "participation" (default, available via URL) or
#'   "proficiency" (requires manual download)
#'
#' @return Data frame with assessment data including:
#'   \itemize{
#'     \item School and district identifiers
#'     \item Assessment type (ELA, Math, Science)
#'     \item Student group breakdowns
#'     \item Participation rates (for participation data)
#'   }
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2022-2024: MCAP participation rate data
#'   \item 2025: Expected when released (typically August/September)
#' }
#'
#' ## Data Source:
#' Maryland Report Card (MSDE):
#' https://reportcard.msde.maryland.gov/
#'
#' ## Limitation:
#' The Maryland Report Card uses JavaScript to generate download links for
#' proficiency data, making automated downloads challenging. Use the interactive
#' Report Card interface or contact MSDE for bulk proficiency data.
#'
#' @seealso
#' \code{\link{fetch_assessment}} for the main user-facing function
#' \code{\link{import_local_assessment}} for loading manually downloaded files
#'
#' @export
#' @examples
#' \dontrun{
#' # Download 2024 MCAP participation data
#' assess_2024 <- get_raw_assessment(2024)
#'
#' # View available student groups
#' unique(assess_2024$student_group)
#' }
get_raw_assessment <- function(end_year, data_type = c("participation", "proficiency")) {

  data_type <- match.arg(data_type)

  # Validate year - MCAP started in 2022
  available_years <- 2022:2025
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2022 and 2025 for MCAP data.\n",
      "Note: MCAP assessments started in 2021-22 (end_year=2022).\n",
      "For historical data (PARCC, MSA), data is not yet implemented."
    ))
  }

  message(paste0(
    "\n",
    "===========================================================\n",
    "Maryland Assessment Data Download\n",
    "===========================================================\n",
    "Year: ", end_year, " (", end_year-1, "-", end_year, " school year)\n",
    "Data Type: ", data_type, "\n\n"
  ))

  # Get URL info
  url_info <- get_mcap_data_urls(end_year, data_type)

  if (is.null(url_info$url)) {
    if (data_type == "proficiency") {
      message(url_info$message)
      message("\nTo load manually downloaded proficiency data, use:")
      message(paste0("  import_local_assessment('path/to/file.xlsx', ", end_year, ")"))
      return(data.frame())
    }
    stop("No URL available for requested data type and year")
  }

  # Download the file
  message("Downloading from: ", url_info$url, "\n")

  assess_data <- tryCatch({
    download_mcap_file(url_info$url, end_year)
  }, error = function(e) {
    message(paste("Download failed:", e$message, "\n"))
    NULL
  })

  if (is.null(assess_data) || nrow(assess_data) == 0) {
    message("\nNo data returned. The file may not yet be available for this year.\n")
    message("Check the Maryland Report Card directly: https://reportcard.msde.maryland.gov\n")
    return(data.frame())
  }

  message(paste("\nDownloaded", nrow(assess_data), "rows\n"))

  assess_data
}


#' Download MCAP data file from URL
#'
#' Downloads and extracts MCAP data from a ZIP file on the Report Card.
#'
#' @param url URL to download
#' @param end_year School year end
#' @return Data frame with assessment data
#' @keywords internal
download_mcap_file <- function(url, end_year) {

  # Create temp directory for download
  temp_dir <- tempdir()
  zip_file <- file.path(temp_dir, paste0("mcap_", end_year, ".zip"))

  # Download with httr
  response <- httr::GET(
    url,
    httr::write_disk(zip_file, overwrite = TRUE),
    httr::timeout(180),
    httr::config(
      ssl_verifypeer = 0L,
      ssl_verifyhost = 0L,
      followlocation = TRUE
    )
  )

  if (httr::http_error(response)) {
    stop(paste("HTTP error:", httr::status_code(response)))
  }

  # Check file size
  file_info <- file.info(zip_file)
  if (is.na(file_info$size) || file_info$size < 10000) {
    unlink(zip_file)
    stop("Downloaded file too small - may be an error page")
  }

  # Check if it's actually a ZIP file
  content_type <- httr::headers(response)$`content-type`
  if (!grepl("zip|octet-stream", content_type, ignore.case = TRUE)) {
    # Read first few bytes to check for ZIP signature
    first_bytes <- readBin(zip_file, "raw", n = 4)
    if (!all(first_bytes[1:2] == c(0x50, 0x4B))) {  # "PK" signature
      unlink(zip_file)
      stop("Response is not a ZIP file - may be HTML error page")
    }
  }

  # Extract ZIP contents
  extract_dir <- file.path(temp_dir, paste0("mcap_extract_", end_year))
  dir.create(extract_dir, showWarnings = FALSE, recursive = TRUE)

  utils::unzip(zip_file, exdir = extract_dir)

  # Find the Excel file
  xlsx_files <- list.files(extract_dir, pattern = "\\.xlsx$", full.names = TRUE)

  if (length(xlsx_files) == 0) {
    # Try CSV files
    csv_files <- list.files(extract_dir, pattern = "\\.csv$", full.names = TRUE)
    if (length(csv_files) > 0) {
      data <- readr::read_csv(csv_files[1], col_types = readr::cols(.default = "c"),
                              show_col_types = FALSE)
    } else {
      stop("No Excel or CSV files found in ZIP archive")
    }
  } else {
    data <- readxl::read_excel(xlsx_files[1], col_types = "text")
  }

  # Clean up
  unlink(zip_file)
  unlink(extract_dir, recursive = TRUE)

  # Process the data
  data <- process_raw_assessment(data, end_year)

  data
}


#' Process raw assessment data
#'
#' Standardizes column names and adds metadata columns.
#'
#' @param df Raw data frame from download
#' @param end_year School year end
#' @return Processed data frame
#' @keywords internal
process_raw_assessment <- function(df, end_year) {

  # Standardize column names
  names(df) <- tolower(names(df))
  names(df) <- gsub("\\s+", "_", names(df))
  names(df) <- gsub("[^[:alnum:]_]", "", names(df))

  # Common column mappings for MCAP participation data
  col_mapping <- c(
    "year" = "year",
    "lea" = "district_id",
    "lea_name" = "district_name",
    "school" = "school_id",
    "school_name" = "school_name",
    "assessment" = "subject",
    "student_group" = "student_group",
    "total_participant_pct" = "participation_pct",
    "total_nonparticipant_pct" = "nonparticipation_pct",
    "general_assessment_participant_pct" = "general_participation_pct",
    "alternate_asssessment_participant_pct" = "alternate_participation_pct",  # note: typo in source
    "count_of_recently_arrived_english_learners_exempted_from_the_ela_assessment" = "ell_exempted_count",
    "create_date" = "create_date"
  )


  # Apply column mappings
  for (old_name in names(col_mapping)) {
    if (old_name %in% names(df)) {
      names(df)[names(df) == old_name] <- col_mapping[old_name]
    }
  }

  # Ensure end_year column
  if (!"end_year" %in% names(df)) {
    df$end_year <- end_year
  }

  # Convert numeric columns
  numeric_cols <- c("participation_pct", "nonparticipation_pct",
                    "general_participation_pct", "alternate_participation_pct",
                    "ell_exempted_count")

  for (col in numeric_cols) {
    if (col %in% names(df)) {
      df[[col]] <- safe_numeric(df[[col]])
    }
  }

  # Add helper columns for aggregation levels
  df <- add_assessment_helper_columns(df)

  # Remove footer row if present
  if ("year" %in% names(df)) {
    df <- df[!grepl("END OF WORKSHEET", df$year, ignore.case = TRUE), ]
  }

  tibble::as_tibble(df)
}


#' Add helper columns to assessment data
#'
#' Adds is_state, is_district, is_school helper columns.
#'
#' @param df Data frame with assessment data
#' @return Data frame with helper columns added
#' @keywords internal
add_assessment_helper_columns <- function(df) {

  df$is_state <- FALSE
  df$is_district <- FALSE
  df$is_school <- FALSE

  # Detect aggregation levels based on ID columns
  if ("district_id" %in% names(df) && "school_id" %in% names(df)) {
    # State rows typically have NA or empty district_id
    df$is_state <- is.na(df$district_id) | df$district_id == ""

    # District rows have district_id but NA/empty school_id
    df$is_district <- !df$is_state &
      (is.na(df$school_id) | df$school_id == "" |
         grepl("^[A-Z]$", df$school_id))  # Some LEAs use single letter codes

    # School rows have both IDs
    df$is_school <- !df$is_state & !df$is_district
  }

  df
}


#' Import locally downloaded assessment file
#'
#' Imports an assessment data file that was manually downloaded from the
#' Maryland Report Card website.
#'
#' @param file_path Path to the Excel or CSV file
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @param data_type Type of data: "participation" or "proficiency"
#'
#' @return Data frame with assessment results
#'
#' @details
#' Use this function when you have manually downloaded assessment data from
#' the Maryland Report Card at https://reportcard.msde.maryland.gov.
#'
#' For proficiency data, navigate to:
#' Graphs > Data Downloads > Academic Achievement or Assessment Results
#'
#' @export
#' @examples
#' \dontrun{
#' # Import a manually downloaded file
#' assess_data <- import_local_assessment(
#'   file_path = "~/Downloads/MCAP_ELA_2024.xlsx",
#'   end_year = 2024,
#'   data_type = "proficiency"
#' )
#' }
import_local_assessment <- function(file_path, end_year,
                                     data_type = c("proficiency", "participation")) {

  data_type <- match.arg(data_type)

  if (!file.exists(file_path)) {
    stop(paste("File not found:", file_path))
  }

  message(paste("Importing assessment data from:", file_path))

  # Determine file type and read
  if (grepl("\\.xlsx?$", file_path, ignore.case = TRUE)) {
    data <- readxl::read_excel(file_path, col_types = "text")
  } else if (grepl("\\.csv$", file_path, ignore.case = TRUE)) {
    data <- readr::read_csv(file_path, col_types = readr::cols(.default = "c"),
                            show_col_types = FALSE)
  } else {
    stop("Unsupported file format. Use Excel (.xlsx) or CSV (.csv)")
  }

  # Process the data
  data <- process_raw_assessment(data, end_year)

  message(paste("Imported", nrow(data), "rows for", end_year))

  data
}


#' Get statewide proficiency summary (from MSDE press releases)
#'
#' Returns statewide MCAP proficiency rates from official MSDE publications.
#' This data is manually curated from State Board presentations and press releases.
#'
#' @param end_year School year end
#' @return Data frame with statewide proficiency rates by subject
#'
#' @details
#' This provides verified statewide proficiency data from MSDE official sources.
#' For school/district-level proficiency data, use the Maryland Report Card
#' interactive interface at https://reportcard.msde.maryland.gov.
#'
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 statewide proficiency
#' state_prof <- get_statewide_proficiency(2024)
#' }
get_statewide_proficiency <- function(end_year) {

  # Data from MSDE State Board presentations
  # Source: marylandpublicschools.org/stateboard/Documents/
  statewide_data <- list(
    "2024" = data.frame(
      end_year = 2024,
      subject = c("ELA 3", "ELA 4", "ELA 5", "ELA 6", "ELA 7", "ELA 8", "ELA 10", "ELA All",
                  "Math 3", "Math 4", "Math 5", "Math 6", "Math 7", "Math 8",
                  "Algebra I", "Algebra II", "Geometry", "Math All",
                  "Science 5", "Science 8"),
      pct_proficient = c(46.5, 49.3, 44.2, 47.9, 48.6, 46.2, 55.3, 48.4,
                         40.0, 32.8, 28.8, 19.8, 15.3, 7.0,
                         20.0, 24.0, 21.9, 24.1,
                         30.6, 26.4),
      stringsAsFactors = FALSE
    ),
    "2023" = data.frame(
      end_year = 2023,
      subject = c("ELA 3", "ELA 4", "ELA 5", "ELA 6", "ELA 7", "ELA 8", "ELA 10", "ELA All",
                  "Math 3", "Math 4", "Math 5", "Math 6", "Math 7", "Math 8",
                  "Algebra I", "Algebra II", "Geometry", "Math All",
                  "Science 5", "Science 8"),
      pct_proficient = c(48.0, 48.7, 41.8, 48.1, 47.2, 46.8, 53.5, 47.9,
                         40.3, 32.2, 27.4, 18.9, 14.7, 7.5,
                         17.2, 20.6, 23.4, 23.3,
                         34.5, 35.4),
      stringsAsFactors = FALSE
    ),
    "2022" = data.frame(
      end_year = 2022,
      subject = c("ELA 3", "ELA 4", "ELA 5", "ELA 6", "ELA 7", "ELA 8", "ELA 10", "ELA All",
                  "Math 3", "Math 4", "Math 5", "Math 6", "Math 7", "Math 8",
                  "Algebra I", "Algebra II", "Geometry", "Math All",
                  "Science 5", "Science 8"),
      pct_proficient = c(45.8, 46.3, 41.2, 44.3, 43.2, 42.7, 53.4, 45.3,
                         36.7, 28.2, 24.6, 18.2, 12.5, 6.9,
                         14.4, 19.9, 25.3, 21.0,
                         23.9, 24.9),
      stringsAsFactors = FALSE
    )
  )

  year_str <- as.character(end_year)

  if (!year_str %in% names(statewide_data)) {
    available <- paste(names(statewide_data), collapse = ", ")
    stop(paste0(
      "Statewide proficiency data not available for ", end_year, ".\n",
      "Available years: ", available
    ))
  }

  result <- statewide_data[[year_str]]
  result$is_state <- TRUE
  result$is_district <- FALSE
  result$is_school <- FALSE
  result$district_id <- NA_character_
  result$district_name <- "Maryland"
  result$school_id <- NA_character_
  result$school_name <- NA_character_
  result$student_group <- "All Students"

  tibble::as_tibble(result)
}

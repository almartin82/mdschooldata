# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from MSDE.
# Data comes from the Maryland Report Card system.
#
# Maryland Report Card API provides enrollment data as JSON which can be
# converted to tabular format.
#
# Data structure:
# - State level: Aggregated totals for all Maryland public schools
# - District (LSS) level: 24 Local School Systems (23 counties + Baltimore City)
# - School level: Individual school enrollment
#
# Format Eras:
# - 2018-present: Maryland Report Card API (JSON format)
# - 2003-2017: Legacy downloads (may require alternative sources)
#
# ==============================================================================

#' Get available years for Maryland enrollment data
#'
#' Returns the range of school years for which enrollment data is available.
#'
#' @return Named list with min_year, max_year, and available years vector
#' @export
#' @examples
#' \dontrun{
#' years <- get_available_years()
#' print(years$available)
#' }
get_available_years <- function() {
  # Maryland Report Card provides data from ~2018 onwards via API

  # Earlier data (2003-2017) may be available via legacy downloads
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # If we're past September, next year's data may be available
  current_month <- as.integer(format(Sys.Date(), "%m"))
  max_year <- if (current_month >= 10) current_year + 1 else current_year

  list(
    min_year = 2018,
    max_year = max_year,
    available = 2018:max_year,
    legacy_years = 2003:2017,
    notes = "Data from 2018+ available via Maryland Report Card API. Earlier years (2003-2017) may have limited availability."
  )
}


#' Download raw enrollment data from MSDE
#'
#' Downloads enrollment data from the Maryland Report Card system.
#' Uses the appropriate method based on the year requested.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  validate_year(end_year, min_year = 2018)

  message(paste("Downloading MSDE enrollment data for", format_school_year(end_year), "..."))

  # Use Maryland Report Card API for 2018+
  if (end_year >= 2018) {
    result <- download_md_reportcard_enrollment(end_year)
  } else {
    stop(paste(
      "Data for year", end_year, "requires legacy data sources.",
      "Currently only years 2018 and later are supported via the Maryland Report Card API."
    ))
  }

  # Add end_year column
  result$end_year <- end_year

  result
}


#' Download enrollment data from Maryland Report Card
#'
#' Downloads enrollment data from the Maryland Report Card system.
#' The Report Card provides JSON data that we convert to a data frame.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_md_reportcard_enrollment <- function(end_year) {

  # Maryland Report Card uses school year format like "2024" for 2023-24
  # The API provides data at state, district (LSS), and school levels

  message("  Fetching state and district enrollment...")
  district_data <- fetch_reportcard_demographics(end_year, level = "district")

  message("  Fetching school-level enrollment...")
  school_data <- fetch_reportcard_demographics(end_year, level = "school")

  # Combine data
  result <- dplyr::bind_rows(district_data, school_data)

  result
}


#' Fetch demographics data from Maryland Report Card
#'
#' Queries the Maryland Report Card system for demographic/enrollment data.
#'
#' @param end_year School year end
#' @param level One of "state", "district", or "school"
#' @return Data frame with demographic data
#' @keywords internal
fetch_reportcard_demographics <- function(end_year, level = "district") {

  # Build the API URL for Maryland Report Card
  # The Report Card exposes data via an ASP.NET-based system
  # We construct URLs to fetch enrollment/demographic data

  base_url <- "https://reportcard.msde.maryland.gov"

  # Format the school year - Report Card uses the end year
  school_year <- as.character(end_year)

  # Maryland Report Card provides downloadable data files

  # The enrollment data is typically available in their "Graphs" section
  # We'll try to fetch the data from their data downloads endpoint

  if (level == "district") {
    # Fetch all 24 LSS (Local School Systems)
    result <- fetch_lss_enrollment(end_year)
  } else if (level == "school") {
    # Fetch school-level data
    result <- fetch_school_enrollment(end_year)
  } else {
    stop("level must be 'district' or 'school'")
  }

  result
}


#' Fetch LSS (District) level enrollment data
#'
#' Downloads enrollment data for all 24 Local School Systems in Maryland.
#'
#' @param end_year School year end
#' @return Data frame with district-level enrollment
#' @keywords internal
fetch_lss_enrollment <- function(end_year) {

  # Maryland Report Card allows downloading data for each LSS
  # We fetch state-level and each district's enrollment

  lss_codes <- get_lss_codes()

  # Build URL for enrollment demographics download
  # Maryland Report Card format: SchoolYear/{year}/Enrollment data
  # The actual download pattern observed: /DataDownloads/{year}/...

  # Try to fetch from the main enrollment endpoint
  # Note: Maryland Report Card may require specific session handling

  url <- paste0(
    "https://reportcard.msde.maryland.gov/api/Enrollment/",
    "GetEnrollmentData?",
    "schoolYear=", end_year
  )

  response <- tryCatch({
    httr::GET(
      url,
      httr::timeout(120),
      httr::add_headers(
        "Accept" = "application/json",
        "User-Agent" = "mdschooldata R package"
      )
    )
  }, error = function(e) {
    message("  API endpoint not available, trying alternate method...")
    NULL
  })

  if (is.null(response) || httr::http_error(response)) {
    # Fall back to constructing data from published reports
    result <- construct_lss_enrollment_from_published(end_year)
  } else {
    content <- httr::content(response, "text", encoding = "UTF-8")
    result <- jsonlite::fromJSON(content, flatten = TRUE)
    result <- as.data.frame(result)
  }

  result
}


#' Construct LSS enrollment from published data patterns
#'
#' When the API is not directly accessible, construct enrollment data
#' from known data patterns and published statistics.
#'
#' @param end_year School year end
#' @return Data frame with LSS enrollment
#' @keywords internal
construct_lss_enrollment_from_published <- function(end_year) {

  # Try to download from MSDE's published enrollment files
  # These are typically PDF or Excel files at predictable URLs

  # URL pattern for enrollment by race/ethnicity documents
  year_folder <- paste0(end_year - 1, end_year, "Student")
  base_url <- "https://marylandpublicschools.org/about/Documents/DCAA/SSP/"

  # Try CSV download first (if available)
  csv_urls <- c(
    paste0(base_url, year_folder, "/Enrollment.csv"),
    paste0(base_url, year_folder, "/enrollment.csv"),
    paste0(base_url, year_folder, "/EnrollmentByRace.csv")
  )

  result <- NULL

  for (url in csv_urls) {
    result <- tryCatch({
      response <- httr::GET(url, httr::timeout(60))
      if (!httr::http_error(response)) {
        content <- httr::content(response, "text", encoding = "UTF-8")
        readr::read_csv(content, show_col_types = FALSE)
      } else {
        NULL
      }
    }, error = function(e) NULL)

    if (!is.null(result)) break
  }

  if (is.null(result)) {
    # If no CSV available, create a minimal structure with state totals
    # Users can later enhance with manually downloaded data
    result <- create_enrollment_template(end_year)
    warning(paste(
      "Could not download detailed enrollment data for", end_year, ".",
      "Creating template with available aggregate data.",
      "For complete data, visit https://reportcard.msde.maryland.gov/"
    ))
  }

  result
}


#' Fetch school-level enrollment data
#'
#' Downloads enrollment data for all schools in Maryland.
#'
#' @param end_year School year end
#' @return Data frame with school-level enrollment
#' @keywords internal
fetch_school_enrollment <- function(end_year) {

  # Try the Report Card API first
  url <- paste0(
    "https://reportcard.msde.maryland.gov/api/Enrollment/",
    "GetSchoolEnrollmentData?",
    "schoolYear=", end_year
  )

  response <- tryCatch({
    httr::GET(
      url,
      httr::timeout(180),  # School-level data may take longer
      httr::add_headers(
        "Accept" = "application/json",
        "User-Agent" = "mdschooldata R package"
      )
    )
  }, error = function(e) NULL)

  if (is.null(response) || httr::http_error(response)) {
    # Fall back to downloading from Report Card's data downloads section
    result <- download_school_enrollment_file(end_year)
  } else {
    content <- httr::content(response, "text", encoding = "UTF-8")
    result <- jsonlite::fromJSON(content, flatten = TRUE)
    result <- as.data.frame(result)
  }

  result
}


#' Download school enrollment from Report Card data files
#'
#' @param end_year School year end
#' @return Data frame with school enrollment
#' @keywords internal
download_school_enrollment_file <- function(end_year) {

  # Maryland Report Card provides downloadable data files
  # Try known patterns for enrollment data

  download_base <- "https://reportcard.msde.maryland.gov/DataDownloads"

  # Try various URL patterns
  file_patterns <- c(
    paste0("/", end_year, "/", end_year - 1, "/Enrollment_Demographics.csv"),
    paste0("/", end_year, "/Enrollment_", end_year - 1, "_", end_year, ".csv"),
    paste0("/", end_year, "/Demographics_Enrollment.csv")
  )

  result <- NULL

  for (pattern in file_patterns) {
    url <- paste0(download_base, pattern)

    result <- tryCatch({
      temp_file <- tempfile(fileext = ".csv")
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::timeout(120)
      )

      if (!httr::http_error(response) && file.info(temp_file)$size > 1000) {
        df <- readr::read_csv(temp_file, show_col_types = FALSE)
        unlink(temp_file)
        df
      } else {
        unlink(temp_file)
        NULL
      }
    }, error = function(e) NULL)

    if (!is.null(result)) break
  }

  if (is.null(result)) {
    # Return empty data frame with expected structure
    result <- data.frame(
      school_id = character(),
      school_name = character(),
      lss_number = character(),
      lss_name = character(),
      enrollment = integer(),
      stringsAsFactors = FALSE
    )
    message("  Note: School-level data not available for download. Try fetching from Report Card website.")
  }

  result
}


#' Create enrollment template with basic structure
#'
#' Creates a minimal enrollment data frame when detailed data is not available.
#'
#' @param end_year School year end
#' @return Data frame with enrollment template
#' @keywords internal
create_enrollment_template <- function(end_year) {

  lss_codes <- get_lss_codes()

  # Create a row for each LSS plus state total
  data.frame(
    end_year = end_year,
    type = c("State", rep("District", length(lss_codes))),
    district_id = c(NA, names(lss_codes)),
    district_name = c("Maryland", unname(lss_codes)),
    campus_id = NA_character_,
    campus_name = NA_character_,
    row_total = NA_integer_,
    white = NA_integer_,
    black = NA_integer_,
    hispanic = NA_integer_,
    asian = NA_integer_,
    pacific_islander = NA_integer_,
    native_american = NA_integer_,
    multiracial = NA_integer_,
    male = NA_integer_,
    female = NA_integer_,
    stringsAsFactors = FALSE
  )
}

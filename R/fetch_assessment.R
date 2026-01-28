# ==============================================================================
# Assessment Data Fetching Functions
# ==============================================================================
#
# This file contains the main user-facing functions for fetching Maryland
# assessment data from the Maryland Report Card system.
#
# ==============================================================================

#' Fetch Maryland assessment data
#'
#' Downloads and returns assessment data from the Maryland State Department
#' of Education Maryland Report Card. Includes MCAP participation data
#' (2022-present) for grades 3-8 and high school in ELA, Mathematics, and Science.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Valid range: 2022-2024 for participation data.
#' @param data_type Type of data: "participation" (default, available via direct
#'   download) or "proficiency" (requires manual download).
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'
#' @return Data frame with assessment data including:
#'   \itemize{
#'     \item School, district, and state identifiers
#'     \item Subject (ELA, Mathematics, Science)
#'     \item Student group breakdowns
#'     \item Participation rates (for participation data)
#'     \item Helper columns: is_state, is_district, is_school
#'   }
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2022-2024: MCAP participation rate data (direct download)
#'   \item 2025: Available when released (typically August/September)
#' }
#'
#' ## Assessment Types:
#' \itemize{
#'   \item ELA: Grades 3-8 and 10
#'   \item Mathematics: Grades 3-8, Algebra I, Algebra II, Geometry
#'   \item Science: Grades 5, 8, and High School
#' }
#'
#' ## Data Source:
#' Maryland Report Card (MSDE):
#' https://reportcard.msde.maryland.gov/
#'
#' ## Proficiency Data Note:
#' The Maryland Report Card uses JavaScript to generate download links for
#' proficiency data. For proficiency rates, use the interactive Report Card
#' interface or \code{\link{get_statewide_proficiency}} for state-level data.
#'
#' @seealso
#' \code{\link{fetch_assessment_multi}} for multiple years
#' \code{\link{get_statewide_proficiency}} for statewide proficiency rates
#' \code{\link{import_local_assessment}} for manually downloaded files
#'
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 participation data
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Filter to Baltimore City schools
#' baltimore <- assess_2024 |>
#'   dplyr::filter(district_name == "Baltimore City", is_school)
#'
#' # Get statewide proficiency rates (curated data)
#' state_prof <- get_statewide_proficiency(2024)
#'
#' # Force fresh download (ignore cache)
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year,
                             data_type = c("participation", "proficiency"),
                             use_cache = TRUE) {

  data_type <- match.arg(data_type)

  # Validate year
  available_years <- 2022:2025
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2022 and 2025.\n",
      "MCAP assessments started in 2021-22 (end_year=2022).\n",
      "For historical data (PARCC, MSA), see package documentation."
    ))
  }

  # Check cache first
  cache_type <- paste0("assessment_", data_type)
  if (use_cache && cache_exists(end_year, cache_type)) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, cache_type))
  }

  # Get raw data
  raw <- get_raw_assessment(end_year = end_year, data_type = data_type)

  # Check if data was returned
  if (nrow(raw) == 0) {
    if (data_type == "proficiency") {
      message("Proficiency data requires manual download from Maryland Report Card.")
      message("Returning statewide proficiency data instead...")
      return(get_statewide_proficiency(end_year))
    }
    warning(paste("No assessment data available for year", end_year))
    return(data.frame())
  }

  # Cache the result
  if (use_cache) {
    write_cache(raw, end_year, cache_type)
  }

  raw
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#'
#' @param years Vector of school year ends (e.g., c(2022, 2023, 2024))
#' @param data_type Type of data: "participation" (default) or "proficiency"
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'
#' @return Data frame with combined assessment data for all requested years
#'
#' @details
#' Combines assessment data from multiple years into a single data frame.
#' Each row includes the \code{end_year} column for filtering and analysis.
#'
#' This is useful for:
#' \itemize{
#'   \item Trend analysis across years
#'   \item Post-COVID recovery tracking
#'   \item Year-over-year comparisons
#' }
#'
#' @seealso
#' \code{\link{fetch_assessment}} for single year data
#'
#' @export
#' @examples
#' \dontrun{
#' # Get MCAP data for all available years
#' assess_all <- fetch_assessment_multi(2022:2024)
#'
#' # Calculate participation trends by district
#' library(dplyr)
#'
#' assess_all |>
#'   filter(is_district, student_group == "All Students", subject == "English/Language Arts") |>
#'   select(end_year, district_name, participation_pct) |>
#'   pivot_wider(names_from = end_year, values_from = participation_pct)
#' }
fetch_assessment_multi <- function(years,
                                   data_type = c("participation", "proficiency"),
                                   use_cache = TRUE) {

  data_type <- match.arg(data_type)

  # Validate years
  available_years <- 2022:2025
  invalid_years <- years[!years %in% available_years]

  if (length(invalid_years) > 0) {
    warning(paste0(
      "Some years are outside available range (2022-2025): ",
      paste(invalid_years, collapse = ", "),
      "\nThese years will be skipped."
    ))
    years <- years[years %in% available_years]
  }

  if (length(years) == 0) {
    stop("No valid years provided. Years must be between 2022 and 2025.")
  }

  message(paste("Fetching assessment data for", length(years), "years:",
                paste(years, collapse = ", ")))

  # Download data for each year
  all_data <- lapply(years, function(y) {
    message(paste("\nFetching", y, "..."))
    tryCatch({
      fetch_assessment(y, data_type = data_type, use_cache = use_cache)
    }, error = function(e) {
      warning(paste("Failed to fetch data for", y, ":", e$message))
      return(data.frame())
    })
  })

  # Combine all years
  combined <- dplyr::bind_rows(all_data)

  # Remove any empty years
  if (nrow(combined) == 0) {
    warning("No assessment data could be fetched for any requested years.")
    return(data.frame())
  }

  # Report results
  years_fetched <- unique(combined$end_year)
  message(paste("\nSuccessfully fetched data for", length(years_fetched), "years:",
                paste(years_fetched, collapse = ", ")))
  message(paste("Total rows:", nrow(combined)))

  combined
}


#' Get available assessment years
#'
#' Returns the range of years for which assessment data is available.
#'
#' @return List with elements:
#'   \itemize{
#'     \item \code{min_year}: First year with MCAP data
#'     \item \code{max_year}: Most recent year with MCAP data
#'     \item \code{available_years}: Vector of all available years
#'     \item \code{assessments}: Named list of assessment types by year range
#'     \item \code{data_types}: Available data types and their access methods
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Check available years
#' get_available_assessment_years()
#' }
get_available_assessment_years <- function() {

  list(
    min_year = 2022,
    max_year = 2024,
    available_years = 2022:2024,
    assessments = list(
      MCAP = "2022-2024: ELA, Math, Science (grades 3-8, HS)"
    ),
    data_types = list(
      participation = "Available via direct download",
      proficiency = "Requires manual download from Report Card (or use get_statewide_proficiency())"
    ),
    notes = paste(
      "MCAP participation rate data is available for 2022-2024.",
      "For proficiency data, use get_statewide_proficiency() for state-level data,",
      "or download interactively from https://reportcard.msde.maryland.gov"
    )
  )
}


#' Fetch assessment data for a specific district
#'
#' Convenience function to fetch assessment data for a single district (LEA).
#'
#' @param end_year School year end
#' @param district_id 2-digit district code (e.g., "03" for Baltimore City)
#' @param data_type Type of data: "participation" (default) or "proficiency"
#' @param use_cache If TRUE (default), uses cached data
#'
#' @return Data frame filtered to specified district
#'
#' @export
#' @examples
#' \dontrun{
#' # Get Baltimore City (district 03) data
#' baltimore <- fetch_district_assessment(2024, "03")
#'
#' # Get Montgomery County (district 16) data
#' montgomery <- fetch_district_assessment(2024, "16")
#' }
fetch_district_assessment <- function(end_year, district_id,
                                       data_type = "participation",
                                       use_cache = TRUE) {

  # Normalize district_id
  district_id <- sprintf("%02d", as.integer(district_id))

  # Fetch all data (faster to filter than fetch individually)
  df <- fetch_assessment(end_year, data_type = data_type, use_cache = use_cache)

  if (nrow(df) == 0) {
    return(data.frame())
  }

  # Filter to requested district
  df |>
    dplyr::filter(district_id == !!district_id)
}


#' Fetch assessment data for a specific school
#'
#' Convenience function to fetch assessment data for a single school.
#'
#' @param end_year School year end
#' @param district_id 2-digit district code
#' @param school_id 4-digit school code
#' @param data_type Type of data: "participation" (default) or "proficiency"
#' @param use_cache If TRUE (default), uses cached data
#'
#' @return Data frame filtered to specified school
#'
#' @export
#' @examples
#' \dontrun{
#' # Get a specific school's data
#' school <- fetch_school_assessment(2024, "16", "0101")
#' }
fetch_school_assessment <- function(end_year, district_id, school_id,
                                     data_type = "participation",
                                     use_cache = TRUE) {

  # Normalize IDs
  district_id <- sprintf("%02d", as.integer(district_id))
  school_id <- sprintf("%04d", as.integer(school_id))

  # Fetch all data
  df <- fetch_assessment(end_year, data_type = data_type, use_cache = use_cache)

  if (nrow(df) == 0) {
    return(data.frame())
  }

  # Filter to requested school
  df |>
    dplyr::filter(district_id == !!district_id, school_id == !!school_id)
}

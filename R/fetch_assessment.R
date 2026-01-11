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
#' of Education Maryland Report Card. Includes MCAP (2021-present) for grades
#' 3-8 and high school in ELA, Mathematics, and Science.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24 school year).
#'   Valid range: 2021-2024.
#' @param subject Assessment subject: "all" (default), "ELA", "Math", "Science",
#'   or "SocialStudies"
#' @param student_group "all" (default) for all students, or "groups" for
#'   student group breakdowns
#' @param use_cache If TRUE (default), uses locally cached data when available.
#'
#' @return Data frame with assessment data including:
#'   \itemize{
#'     \item School, district, and state identifiers
#'     \item Grade level and subject
#'     \item Proficiency rates and counts
#'     \item Student group breakdowns (if student_group = "groups")
#'     \item Helper columns: is_state, is_district, is_school
#'   }
#'
#' @details
#' ## Available Years:
#' \itemize{
#'   \item 2021-2024: MCAP data (Maryland Comprehensive Assessment Program)
#'   \item 2025: MCAP data (when available)
#' }
#'
#' ## Assessment Types by Year:
#' \itemize{
#'   \item 2021-2023: MCAP ELA and Math (grades 3-8, HS), Science (grades 5, 8, HS)
#'   \item 2024+: MCAP ELA, Math, Science, and Social Studies (grades 3-8, HS)
#' }
#'
#' ## Data Source:
#' Maryland Report Card (MSDE):
#' https://reportcard.msde.maryland.gov/Graphs/
#'
#' The Maryland Report Card uses dynamic JavaScript to generate download links.
#' If automated download fails, the function provides clear instructions for
#' manual download and loading via \code{\link{import_local_assessment}}.
#'
#' @seealso
#' \code{\link{fetch_assessment_multi}} for multiple years
#' \code{\link{import_local_assessment}} for manually downloaded files
#'
#' @export
#' @examples
#' \dontrun{
#' # Get 2024 assessment data (all subjects)
#' assess_2024 <- fetch_assessment(2024)
#'
#' # Get only ELA results
#' assess_2024_ela <- fetch_assessment(2024, subject = "ELA")
#'
#' # Get with student group breakdowns
#' assess_2024_groups <- fetch_assessment(2024, student_group = "groups")
#'
#' # Force fresh download (ignore cache)
#' assess_fresh <- fetch_assessment(2024, use_cache = FALSE)
#' }
fetch_assessment <- function(end_year,
                             subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
                             student_group = c("all", "groups"),
                             use_cache = TRUE) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate year
  available_years <- 2021:2025
  if (!end_year %in% available_years) {
    stop(paste0(
      "end_year must be between 2021 and 2025.\n",
      "MCAP assessments started in 2021-22 (end_year=2022).\n",
      "For historical data (PARCC, MSA), see ASSESSMENT-RESEARCH.md"
    ))
  }

  # Check cache first
  if (use_cache && cache_exists(end_year, "assessment")) {
    message(paste("Using cached assessment data for", end_year))
    return(read_cache(end_year, "assessment"))
  }

  # Get raw data
  raw <- get_raw_assessment(
    end_year = end_year,
    subject = subject,
    student_group = student_group
  )

  # Check if data was returned
  if (nrow(raw) == 0) {
    warning(paste("No assessment data available for year", end_year))
    return(data.frame())
  }

  # Cache the result
  if (use_cache) {
    write_cache(raw, end_year, "assessment")
  }

  raw
}


#' Fetch assessment data for multiple years
#'
#' Downloads and combines assessment data for multiple school years.
#'
#' @param years Vector of school year ends (e.g., c(2021, 2022, 2023, 2024))
#' @param subject Assessment subject: "all" (default), "ELA", "Math", "Science",
#'   or "SocialStudies"
#' @param student_group "all" (default) for all students, or "groups" for
#'   student group breakdowns
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
#'   \item Pre/post-COVID comparisons
#'   \item Year-over-year growth calculations
#' }
#'
#' @seealso
#' \code{\link{fetch_assessment}} for single year data
#'
#' @export
#' @examples
#' \dontrun{
#' # Get MCAP data for all available years
#' assess_all <- fetch_assessment_multi(2021:2024)
#'
#' # Get ELA data for multiple years
#' assess_ela <- fetch_assessment_multi(2021:2024, subject = "ELA")
#'
#' # Calculate 3-year trend
#' library(dplyr)
#'
#' assess_all %>%
#'   filter(is_state, subject == "ELA", grade == "03") %>%
#'   group_by(end_year) %>%
#'   summarize(avg_proficient = mean(pct_proficient, na.rm = TRUE))
#' }
fetch_assessment_multi <- function(years,
                                   subject = c("all", "ELA", "Math", "Science", "SocialStudies"),
                                   student_group = c("all", "groups"),
                                   use_cache = TRUE) {

  subject <- match.arg(subject)
  student_group <- match.arg(student_group)

  # Validate years
  available_years <- 2021:2025
  invalid_years <- years[!years %in% available_years]

  if (length(invalid_years) > 0) {
    warning(paste0(
      "Some years are outside available range (2021-2025): ",
      paste(invalid_years, collapse = ", "),
      "\nThese years will be skipped."
    ))
    years <- years[years %in% available_years]
  }

  if (length(years) == 0) {
    stop("No valid years provided. Years must be between 2021 and 2025.")
  }

  message(paste("Fetching assessment data for", length(years), "years:",
                paste(years, collapse = ", ")))

  # Download data for each year
  all_data <- lapply(years, function(y) {
    message(paste("\nFetching", y, "..."))
    tryCatch({
      fetch_assessment(y, subject = subject, student_group = student_group,
                      use_cache = use_cache)
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
#'     \item \code{min_year}: First year with assessment data
#'     \item \code{max_year}: Most recent year with assessment data
#'     \item \code{available_years}: Vector of all available years
#'     \item \code{assessments}: Named list of assessment types by year range
#'   }
#'
#' @export
#' @examples
#' \dontrun{
#' # Check available years
#' get_available_assessment_years()
#'
#' # Output:
#' # $min_year
#' # [1] 2021
#' #
#' # $max_year
#' # [1] 2025
#' #
#' # $available_years
#' # [1] 2021 2022 2023 2024 2025
#' #
#' # $assessments
#' # $assessments$MCAP
#' # [1] "2021-2025: ELA, Math, Science, Social Studies"
#' }
get_available_assessment_years <- function() {

  list(
    min_year = 2021,
    max_year = 2025,
    available_years = 2021:2025,
    assessments = list(
      MCAP = "2021-2025: ELA, Math, Science, Social Studies (grades 3-8, HS)"
    ),
    note = "For historical assessment data (PARCC, MSA, HSA), see ASSESSMENT-RESEARCH.md"
  )
}

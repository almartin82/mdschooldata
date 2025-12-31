# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from the
# Maryland State Department of Education (MSDE).
#
# Primary data source: Maryland Report Card (https://reportcard.msde.maryland.gov)
# Secondary source: MSDE Staff and Student Publications
# (https://marylandpublicschools.org/about/Pages/DCAA/SSP/)
#
# Data is collected as of September 30 of each year.
#
# Data structure:
# - State level: Aggregated totals for all Maryland public schools
# - District (LSS) level: 24 Local School Systems (23 counties + Baltimore City)
# - School level: Individual school enrollment
#
# Data availability:
# - 2018-present: Enrollment data via MSDE publications and Report Card
# - PDF publications provide enrollment by race/ethnicity and gender
#
# ==============================================================================


#' Get available years for Maryland enrollment data
#'
#' Returns the range of school years for which enrollment data is available
#' from the Maryland State Department of Education.
#'
#' @return Named list with min_year, max_year, and available years vector
#' @export
#' @examples
#' \dontrun{
#' years <- get_available_years()
#' print(years$available)
#' }
get_available_years <- function() {
  # MSDE Staff and Student Publications have enrollment data from around 2018
  # The Report Card website has data from 2019 onwards
  # Most recent data is typically from the prior school year
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # Data is usually available by late fall for the prior year
  # If we're past October, the previous year's data should be available
  current_month <- as.integer(format(Sys.Date(), "%m"))
  max_year <- if (current_month >= 11) current_year else current_year - 1

  list(
    min_year = 2019,
    max_year = max_year,
    available = 2019:max_year,
    notes = paste(
      "Data from Maryland State Department of Education (MSDE).",
      "Enrollment collected as of September 30 each year.",
      "Available at state, district (LSS), and school levels.",
      "Demographic breakdowns include race/ethnicity and gender."
    )
  )
}


#' Download raw enrollment data for Maryland
#'
#' Downloads enrollment data from the Maryland State Department of Education.
#' Data includes enrollment by race/ethnicity and gender at state, district
#' (LSS), and school levels.
#'
#' @param end_year School year end (2023-24 = 2024)
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year) {

  available <- get_available_years()
  validate_year(end_year, min_year = available$min_year, max_year = available$max_year)

  message(paste("Downloading Maryland enrollment data for", format_school_year(end_year), "..."))

  # Try the Report Card data first (most structured)
  message("  Fetching enrollment data from Maryland Report Card...")
  result <- tryCatch({
    download_reportcard_enrollment(end_year)
  }, error = function(e) {
    message(paste("  Report Card download failed:", e$message))
    NULL
  })

  # If Report Card failed, try MSDE publications
  if (is.null(result) || nrow(result) == 0) {
    message("  Trying MSDE Staff and Student Publications...")
    result <- tryCatch({
      download_msde_enrollment_publication(end_year)
    }, error = function(e) {
      message(paste("  MSDE publication download failed:", e$message))
      NULL
    })
  }

  if (is.null(result) || nrow(result) == 0) {
    stop(paste("Could not download enrollment data for", end_year,
               "from any available source."))
  }

  message(paste("  Downloaded", nrow(result), "records"))

  result
}


#' Download enrollment data from Maryland Report Card
#'
#' Downloads enrollment data from the Maryland Report Card website.
#' The Report Card provides school-level enrollment data with demographics.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_reportcard_enrollment <- function(end_year) {

  # Build URL for the Report Card data download
  # The Report Card uses a specific URL pattern for data downloads
  # PDF reports are available at:
  # https://reportcard.msde.maryland.gov/DataDownloads/{release_year}/{data_year}/
  #
  # For enrollment data, we need to construct school and district level data
  # from the available downloads

  # Calculate the release year (usually end_year + 1 for fall release)
  release_year <- end_year + 1
  data_year <- end_year

  # Try to get school-level PDF report which contains enrollment
  school_url <- paste0(
    "https://reportcard.msde.maryland.gov/DataDownloads/",
    release_year, "/", data_year, "/",
    "All_Schools_", data_year, "_ENG.pdf"
  )

  # Also try alternate URL patterns
  alt_urls <- c(
    paste0("https://reportcard.msde.maryland.gov/DataDownloads/",
           data_year, "/", data_year, "/State_", data_year, "_ENG.pdf"),
    paste0("https://reportcard.msde.maryland.gov/DataDownloads/",
           release_year, "/", data_year, "/State_", data_year, "_ENG.pdf")
  )

  # For now, we'll construct enrollment from the MSDE publications

  # which have more structured data
  # The Report Card PDFs are complex multi-page documents

  # This is a placeholder - the Report Card enrollment requires
  # web scraping or API access that isn't currently public
  stop("Report Card data not directly accessible - use MSDE publications")
}


#' Download enrollment data from MSDE Staff and Student Publications
#'
#' Downloads enrollment PDF publications from MSDE and extracts data.
#' Publications are available at:
#' https://marylandpublicschools.org/about/Documents/DCAA/SSP/
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
download_msde_enrollment_publication <- function(end_year) {

  # MSDE publishes enrollment PDFs with this naming pattern:
  # {year-1}{year}Student/Enrollment-By-Race-Ethnicity-Gender-A.pdf
  # or
  # {year}-{year+1}-Enrollment-By-Race-Ethnicity-Gender-A.pdf

  start_year <- end_year - 1
  folder_name <- paste0(start_year, end_year, "Student")

  # Try different URL patterns
  base_url <- "https://marylandpublicschools.org/about/Documents/DCAA/SSP/"

  url_patterns <- c(
    # Newer pattern (2024-2025)
    paste0(base_url, folder_name, "/", end_year - 1, "-", end_year,
           "-Enrollment-By-Race-Ethnicity-Gender-A.pdf"),
    # Older pattern
    paste0(base_url, folder_name, "/", start_year, "-", end_year,
           "-Enrollment-By-Race-Ethnicity-Gender-A.pdf"),
    # Alternative naming
    paste0(base_url, folder_name, "/", end_year,
           "_Enrollment_ByRace_Ethnicity_Gender.pdf"),
    # 2023 style
    paste0(base_url, folder_name, "/", end_year,
           "EnrollRelease.pdf")
  )

  pdf_file <- NULL
  for (url in url_patterns) {
    result <- tryCatch({
      tname <- tempfile(pattern = "msde_enr_", fileext = ".pdf")

      response <- httr::GET(
        url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(120)
      )

      if (!httr::http_error(response) && file.exists(tname) &&
          file.info(tname)$size > 10000) {
        pdf_file <- tname
        message(paste("    Downloaded from:", url))
        break
      } else {
        unlink(tname)
        NULL
      }
    }, error = function(e) {
      NULL
    })
  }

  if (is.null(pdf_file)) {
    stop("Could not download MSDE enrollment publication")
  }

  # Parse the PDF
  # Note: PDF parsing requires additional packages (pdftools, tabulizer)
  # For robustness, we provide a simpler approach using the data structure

  # Check if pdftools is available
  if (!requireNamespace("pdftools", quietly = TRUE)) {
    unlink(pdf_file)
    stop("Package 'pdftools' is required to parse MSDE PDF publications. ",
         "Install it with: install.packages('pdftools')")
  }

  # Extract enrollment data from PDF
  result <- parse_msde_enrollment_pdf(pdf_file, end_year)

  unlink(pdf_file)

  result
}


#' Parse MSDE enrollment PDF publication
#'
#' Extracts enrollment data from MSDE PDF publications.
#' These PDFs contain tables with enrollment by LSS, race/ethnicity, and gender.
#'
#' @param pdf_path Path to downloaded PDF file
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @keywords internal
parse_msde_enrollment_pdf <- function(pdf_path, end_year) {

  # Read the PDF text
  pdf_text <- pdftools::pdf_text(pdf_path)

  # The MSDE enrollment PDF typically contains:
  # - Page 1-2: State-level summary
  # - Subsequent pages: Enrollment by LSS (district)
  # Tables include: Total, Male, Female, and race/ethnicity breakdowns

  # Initialize result
  all_data <- list()

  # Process each page
  for (page_num in seq_along(pdf_text)) {
    page <- pdf_text[page_num]

    # Try to extract tabular data from the page
    page_data <- extract_enrollment_from_page(page, end_year)

    if (!is.null(page_data) && nrow(page_data) > 0) {
      all_data[[length(all_data) + 1]] <- page_data
    }
  }

  if (length(all_data) == 0) {
    stop("Could not extract enrollment data from PDF")
  }

  result <- dplyr::bind_rows(all_data)

  # Add end_year
  result$end_year <- end_year

  result
}


#' Extract enrollment data from a PDF page
#'
#' @param page_text Text content of a PDF page
#' @param end_year School year end
#' @return Data frame or NULL if no data found
#' @keywords internal
extract_enrollment_from_page <- function(page_text, end_year) {

  # Split into lines
  lines <- strsplit(page_text, "\n")[[1]]
  lines <- trimws(lines)
  lines <- lines[lines != ""]

  # Look for lines that contain LSS data
  # LSS names are typically: Allegany, Anne Arundel, Baltimore City, etc.
  lss_codes <- get_lss_codes()
  lss_names <- unname(lss_codes)

  result_rows <- list()

  for (line in lines) {
    # Check if this line starts with an LSS name
    for (i in seq_along(lss_names)) {
      if (grepl(paste0("^", lss_names[i]), line, ignore.case = TRUE)) {
        # This line contains LSS enrollment data
        # Parse the numbers from the line

        # Extract numbers from the line
        numbers <- regmatches(line, gregexpr("[0-9,]+", line))[[1]]
        numbers <- as.numeric(gsub(",", "", numbers))

        if (length(numbers) >= 1) {
          row <- data.frame(
            type = "District",
            district_id = names(lss_codes)[i],
            district_name = lss_names[i],
            campus_id = NA_character_,
            campus_name = NA_character_,
            row_total = numbers[1],
            stringsAsFactors = FALSE
          )

          # If more numbers, they might be demographic breakdowns
          # Typical order: Total, American Indian, Asian, Black, Hispanic,
          # Pacific Islander, White, Two or More
          if (length(numbers) >= 8) {
            row$native_american <- numbers[2]
            row$asian <- numbers[3]
            row$black <- numbers[4]
            row$hispanic <- numbers[5]
            row$pacific_islander <- numbers[6]
            row$white <- numbers[7]
            row$multiracial <- numbers[8]
          }

          result_rows[[length(result_rows) + 1]] <- row
        }
        break
      }
    }

    # Also check for "State" or "Maryland" total
    if (grepl("^(State|Maryland|Total)\\s", line, ignore.case = TRUE)) {
      numbers <- regmatches(line, gregexpr("[0-9,]+", line))[[1]]
      numbers <- as.numeric(gsub(",", "", numbers))

      if (length(numbers) >= 1) {
        row <- data.frame(
          type = "State",
          district_id = NA_character_,
          district_name = "Maryland",
          campus_id = NA_character_,
          campus_name = NA_character_,
          row_total = numbers[1],
          stringsAsFactors = FALSE
        )

        if (length(numbers) >= 8) {
          row$native_american <- numbers[2]
          row$asian <- numbers[3]
          row$black <- numbers[4]
          row$hispanic <- numbers[5]
          row$pacific_islander <- numbers[6]
          row$white <- numbers[7]
          row$multiracial <- numbers[8]
        }

        result_rows[[length(result_rows) + 1]] <- row
      }
    }
  }

  if (length(result_rows) == 0) {
    return(NULL)
  }

  dplyr::bind_rows(result_rows)
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


#' Download Maryland Report Card enrollment data
#'
#' Attempts to fetch enrollment data from the Maryland Report Card website.
#' This function handles the web interaction required to download data.
#'
#' @param end_year School year end
#' @return Data frame with enrollment data
#' @export
#' @examples
#' \dontrun{
#' enr <- download_md_reportcard_enrollment(2024)
#' }
download_md_reportcard_enrollment <- function(end_year) {

  # The Maryland Report Card provides enrollment data through its interactive
  # website. This function provides guidance on accessing the data.

  message("Maryland Report Card Enrollment Data")
  message("====================================")
  message("")
  message("The Maryland Report Card website provides enrollment data at:")
  message("  https://reportcard.msde.maryland.gov")
  message("")
  message("To download enrollment data manually:")
  message("  1. Visit https://reportcard.msde.maryland.gov/Graphs/#/Demographics/Enrollment")
  message("  2. Select the desired school year, level (State/LEA/School)")
  message("  3. Export the data using the download option")
  message("")
  message("For programmatic access, this package uses MSDE publications.")
  message("")

  # Return the MSDE publication data
  get_raw_enr(end_year)
}


#' Fetch demographics from Report Card (if available)
#'
#' @param end_year School year end
#' @param level Level: "state", "lea", or "school"
#' @return Data frame with demographics data
#' @keywords internal
fetch_reportcard_demographics <- function(end_year, level = "lea") {

  # The Report Card website uses URL parameters for data selection
  # Example: https://reportcard.msde.maryland.gov/Graphs/#/Demographics/Enrollment
  #
  # The actual data requires JavaScript rendering, so direct download is limited

  stop("Report Card demographics require web browser access. ",
       "Use download_md_reportcard_enrollment() for guidance or ",
       "get_raw_enr() to use MSDE publications.")
}


#' Fetch enrollment for a specific LSS (district)
#'
#' Downloads enrollment data for a specific Local School System.
#'
#' @param end_year School year end
#' @param lss_code 2-digit LSS code (e.g., "01" for Allegany)
#' @return Data frame with LSS enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Get Baltimore City enrollment (LSS code 03)
#' baltimore <- fetch_lss_enrollment(2024, "03")
#' }
fetch_lss_enrollment <- function(end_year, lss_code) {

  # Validate LSS code
  lss_codes <- get_lss_codes()
  lss_code <- sprintf("%02s", lss_code)

  if (!lss_code %in% names(lss_codes)) {
    stop(paste("Invalid LSS code:", lss_code,
               "\nValid codes are:", paste(names(lss_codes), collapse = ", ")))
  }

  # Get all enrollment data and filter to the LSS
  all_data <- get_raw_enr(end_year)

  lss_data <- all_data[all_data$district_id == lss_code, ]

  if (nrow(lss_data) == 0) {
    warning(paste("No data found for LSS", lss_code, "(", lss_codes[lss_code], ")"))
  }

  lss_data
}


#' Construct LSS enrollment from published totals
#'
#' Creates district-level enrollment data from MSDE published totals.
#' This is a fallback when detailed data is not available.
#'
#' @param end_year School year end
#' @return Data frame with LSS enrollment
#' @keywords internal
construct_lss_enrollment_from_published <- function(end_year) {

  # This function would use hardcoded or cached enrollment totals

  # from MSDE press releases or summary publications

  # For now, return a template that can be filled in
  create_enrollment_template(end_year)
}


#' Fetch school-level enrollment
#'
#' Downloads school-level enrollment data for Maryland.
#' Note: School-level data is primarily available through the Report Card
#' website and may require manual download.
#'
#' @param end_year School year end
#' @param lss_code Optional LSS code to filter results
#' @return Data frame with school enrollment data
#' @export
#' @examples
#' \dontrun{
#' # Get all school enrollment
#' schools <- fetch_school_enrollment(2024)
#'
#' # Get schools in Montgomery County (LSS 16)
#' montgomery <- fetch_school_enrollment(2024, "16")
#' }
fetch_school_enrollment <- function(end_year, lss_code = NULL) {

  message("School-level enrollment data")
  message("")
  message("School-level enrollment is available from the Maryland Report Card:")
  message("  https://reportcard.msde.maryland.gov")
  message("")
  message("To download school data:")
  message("  1. Navigate to Demographics > Enrollment")
  message("  2. Select 'School' level")
  message("  3. Filter by county/LSS if desired")
  message("  4. Export the data")
  message("")
  message("The MSDE publications primarily provide district-level aggregates.")
  message("Returning district-level data from publications...")
  message("")

  # Get district-level data as a fallback
  data <- get_raw_enr(end_year)

  # Filter to campus/school type if available
  if ("type" %in% names(data)) {
    school_data <- data[data$type == "Campus", ]
    if (nrow(school_data) > 0) {
      if (!is.null(lss_code)) {
        lss_code <- sprintf("%02s", lss_code)
        school_data <- school_data[school_data$district_id == lss_code, ]
      }
      return(school_data)
    }
  }

  # Return district data as fallback
  if (!is.null(lss_code)) {
    lss_code <- sprintf("%02s", lss_code)
    data <- data[data$district_id == lss_code, ]
  }

  data
}


#' Download school enrollment Excel file (if available)
#'
#' Attempts to download school enrollment data in Excel format.
#' This is experimental as MSDE does not consistently publish Excel files.
#'
#' @param end_year School year end
#' @return Path to downloaded file, or NULL if not available
#' @keywords internal
download_school_enrollment_file <- function(end_year) {

  # MSDE occasionally publishes Excel files with school enrollment
  # Try known patterns

  base_url <- "https://marylandpublicschools.org/about/Documents/DCAA/SSP/"
  folder <- paste0(end_year - 1, end_year, "Student/")

  # Try different file patterns
  patterns <- c(
    paste0("School_Enrollment_", end_year, ".xlsx"),
    paste0("SchoolEnrollment", end_year, ".xlsx"),
    paste0(end_year, "_School_Enrollment.xlsx")
  )

  for (pattern in patterns) {
    url <- paste0(base_url, folder, pattern)

    tname <- tempfile(pattern = "md_school_enr_", fileext = ".xlsx")

    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(60)
      )

      if (!httr::http_error(response) && file.exists(tname) &&
          file.info(tname)$size > 10000) {
        message(paste("Downloaded:", url))
        return(tname)
      }
    }, error = function(e) {
      # Continue to next pattern
    })

    unlink(tname)
  }

  NULL
}

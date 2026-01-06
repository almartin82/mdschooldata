# ==============================================================================
# Raw Enrollment Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw enrollment data from
# Maryland state sources.
#
# Primary data sources:
# 1. Maryland Department of Planning (https://planning.maryland.gov)
#    - Historical enrollment data from 2014-present
#    - Enrollment by grade (K-12) for state and all 24 jurisdictions
#    - URL: planning.maryland.gov/MSDC/Documents/school_enrollment/
#
# 2. Maryland State Department of Education (MSDE)
#    - Maryland Report Card (https://reportcard.msde.maryland.gov)
#    - MSDE Staff and Student Publications with race/ethnicity/gender
#    - URL: marylandpublicschools.org/about/Pages/DCAA/SSP/
#
# Data is collected as of September 30 of each year.
#
# Data structure:
# - State level: Aggregated totals for all Maryland public schools
# - District (LSS) level: 24 Local School Systems (23 counties + Baltimore City)
# - School level: Individual school enrollment (MSDE sources only)
#
# Data availability:
# - 2014-present: Enrollment by grade via MD Dept of Planning
# - 2019-present: Enrollment with demographics via MSDE publications
#
# ==============================================================================


#' Get available years for Maryland enrollment data
#'
#' Returns the range of school years for which enrollment data is available
#' from Maryland state sources. Uses Maryland Department of Planning data
#' for historical years (2014+) and MSDE for demographic breakdowns (2019+).
#'
#' @return Named list with min_year, max_year, and available years vector
#' @export
#' @examples
#' \dontrun{
#' years <- get_available_years()
#' print(years$available)
#' }
get_available_years <- function() {
  # Maryland Department of Planning publishes enrollment data from 2014-present
  # MSDE Staff and Student Publications have demographic data from around 2019
  # Most recent data is typically from the prior school year
  current_year <- as.integer(format(Sys.Date(), "%Y"))

  # Data is usually available by late fall for the prior year
  # If we're past October, the previous year's data should be available
  current_month <- as.integer(format(Sys.Date(), "%m"))
  max_year <- if (current_month >= 11) current_year else current_year - 1

  list(
    min_year = 2014,
    max_year = max_year,
    available = 2014:max_year,
    # Track which years have demographic data available
    # NOTE: Demographic data from MSDE PDFs is unreliable due to parsing issues
    # Set include_demographics=FALSE in get_raw_enr() to avoid corrupted data
    demographic_years = integer(0),  # No reliable demographic data available
    description = paste(
      "Maryland enrollment data from MD Department of Planning.",
      "Available years: 2014-present.",
      "Provides enrollment by grade (K-12) for state and 24 jurisdictions.",
      "NOTE: Demographic breakdowns (race/ethnicity, gender) are not available",
      "due to PDF parsing issues. Use Maryland Report Card for demographics."
    ),
    notes = paste(
      "Data from Maryland Department of Planning (2014-present).",
      "MD Planning provides enrollment by grade for state and 24 jurisdictions.",
      "For demographic breakdowns (race/ethnicity, gender), use Maryland Report Card:",
      "https://reportcard.msde.maryland.gov/Graphs/#/Demographics/Enrollment",
      "Enrollment collected as of September 30 each year."
    )
  )
}


#' Download raw enrollment data for Maryland
#'
#' Downloads enrollment data from Maryland state sources. Uses Maryland
#' Department of Planning for historical data (2014-present) with grade-level
#' enrollment, and MSDE publications for demographic breakdowns (2019+).
#'
#' @param end_year School year end (2023-24 = 2024)
#' @param include_demographics Logical, whether to try to fetch demographic
#'   data from MSDE (race/ethnicity, gender). Default FALSE due to PDF
#'   parsing issues. Set to TRUE to attempt fetching (may return incorrect data).
#' @return Data frame with raw enrollment data
#' @keywords internal
get_raw_enr <- function(end_year, include_demographics = FALSE) {

  available <- get_available_years()
  validate_year(end_year, min_year = available$min_year, max_year = available$max_year)

  message(paste("Downloading Maryland enrollment data for", format_school_year(end_year), "..."))

  # Try MD Department of Planning first (has more historical data)
  message("  Fetching enrollment data from MD Department of Planning...")
  result <- tryCatch({
    download_mdp_enrollment(end_year)
  }, error = function(e) {
    message(paste("  MD Planning download failed:", e$message))
    NULL
  })

  # If MD Planning failed and year is 2019+, try MSDE publications
  if ((is.null(result) || nrow(result) == 0) && end_year >= 2019) {
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

  # If we have MD Planning data but want demographics, try to merge MSDE data
  if (include_demographics && end_year >= 2019 && !"white" %in% names(result)) {
    message("  Fetching demographic data from MSDE...")
    demo_result <- tryCatch({
      download_msde_enrollment_publication(end_year)
    }, error = function(e) {
      message(paste("  MSDE demographics not available:", e$message))
      NULL
    })

    if (!is.null(demo_result) && nrow(demo_result) > 0) {
      result <- merge_enrollment_demographics(result, demo_result)
    }
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


# ==============================================================================
# Maryland Department of Planning Data Functions
# ==============================================================================
#
# The Maryland Department of Planning (MDP) publishes annual school enrollment
# projections that include historical enrollment data by grade and jurisdiction.
#
# Data URL pattern:
# planning.maryland.gov/MSDC/Documents/school_enrollment/school_{year}/
#
# Key files:
# - 3-Public-School-Enrollment.xlsx: Historical enrollment by grade (2014-present)
# - Table2.xlsx: Summary by jurisdiction
# - Table3.xlsx: K-12 totals by jurisdiction
#
# ==============================================================================


#' Download enrollment data from Maryland Department of Planning
#'
#' Downloads historical enrollment data from the Maryland Department of
#' Planning's public school enrollment projections. This provides enrollment
#' by grade level for all 24 Maryland jurisdictions from 2014-present.
#'
#' @param end_year School year end (e.g., 2024 for 2023-24)
#' @return Data frame with enrollment by jurisdiction and grade
#' @keywords internal
download_mdp_enrollment <- function(end_year) {

  # Check for readxl package

  if (!requireNamespace("readxl", quietly = TRUE)) {
    stop("Package 'readxl' is required to parse MD Planning Excel files. ",
         "Install it with: install.packages('readxl')")
  }

  # Find the appropriate release year for the data
  # MDP typically releases projections in August/September for the prior school year
  # The 2025 release contains 2014-2024 data, 2024 release contains 2013-2023 data, etc.
  release_year <- find_mdp_release_year(end_year)

  if (is.null(release_year)) {
    stop(paste("MD Planning data for", end_year, "is not available.",
               "Data is available from 2014 to present."))
  }

  # Try to download the public school enrollment file
  xlsx_file <- download_mdp_enrollment_file(release_year)

  if (is.null(xlsx_file)) {
    stop("Could not download MD Planning enrollment file")
  }

  # Parse the Excel file
  result <- tryCatch({
    parse_mdp_enrollment_xlsx(xlsx_file, end_year)
  }, finally = {
    unlink(xlsx_file)
  })

  result
}


#' Find the MD Planning release year for a given data year
#'
#' The MD Planning releases annual reports that contain 10+ years of historical
#' data. This function determines which release year contains data for the
#' requested end_year.
#'
#' @param end_year The school year end to find data for
#' @return The release year, or NULL if not available
#' @keywords internal
find_mdp_release_year <- function(end_year) {

  # Get current year to determine latest available release
  current_year <- as.integer(format(Sys.Date(), "%Y"))
  current_month <- as.integer(format(Sys.Date(), "%m"))

  # MDP releases in August, so the current year's release is available after August
  latest_release <- if (current_month >= 9) current_year else current_year - 1

  # Each release contains ~11 years of historical data
  # 2025 release: 2014-2024
  # 2024 release: 2013-2023
  # etc.

  # Check if the requested year is within the range of available releases
  # We'll start from the latest release and work backwards
  for (release in latest_release:2018) {
    # Calculate the data range for this release
    # Latest data year is typically release_year - 1
    max_data_year <- release - 1
    min_data_year <- max_data_year - 10  # ~11 years of data

    if (end_year >= min_data_year && end_year <= max_data_year) {
      return(release)
    }
  }

  NULL
}


#' Download MD Planning enrollment Excel file
#'
#' @param release_year The MDP release year
#' @return Path to downloaded file, or NULL if download failed
#' @keywords internal
download_mdp_enrollment_file <- function(release_year) {

  base_url <- "https://planning.maryland.gov/MSDC/Documents/school_enrollment/"

  # Try multiple file patterns - MDP changes naming conventions occasionally
  url_patterns <- c(
    paste0(base_url, "school_", release_year, "/3-Public-School-Enrollment.xlsx"),
    paste0(base_url, "school_", release_year, "/Public-School-Enrollment.xlsx"),
    paste0(base_url, "school_", release_year, "/Table3.xlsx")
  )

  for (url in url_patterns) {
    tname <- tempfile(pattern = "mdp_enr_", fileext = ".xlsx")

    result <- tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(tname, overwrite = TRUE),
        httr::timeout(120)
      )

      if (!httr::http_error(response) && file.exists(tname) &&
          file.info(tname)$size > 10000) {
        message(paste("    Downloaded from:", url))
        return(tname)
      } else {
        unlink(tname)
        NULL
      }
    }, error = function(e) {
      unlink(tname)
      NULL
    })

    if (!is.null(result)) {
      return(result)
    }
  }

  NULL
}


#' Parse MD Planning enrollment Excel file
#'
#' Parses the 3-Public-School-Enrollment.xlsx file from MD Planning.
#' The file has a complex structure with blocks for each jurisdiction.
#'
#' @param xlsx_path Path to the Excel file
#' @param end_year The school year end to extract
#' @return Data frame with enrollment data
#' @keywords internal
parse_mdp_enrollment_xlsx <- function(xlsx_path, end_year) {

  # Read the entire file without headers
  df <- readxl::read_excel(xlsx_path, sheet = 1, col_names = FALSE)

  # Get the LSS codes mapping
  lss_codes <- get_lss_codes()

  # Find jurisdiction names in the first column
  # Build list from LSS codes - they already have proper names
  jurisdiction_names <- c("Maryland", unname(lss_codes))
  # For those without "County" or "City" suffix, add "County"
  for (i in seq_along(jurisdiction_names)) {
    nm <- jurisdiction_names[i]
    if (nm != "Maryland" && !grepl("(County|City)$", nm)) {
      jurisdiction_names[i] <- paste0(nm, " County")
    }
  }
  # Remove duplicates (shouldn't be any, but just in case)
  jurisdiction_names <- unique(jurisdiction_names)

  # Find the year column
  # Years are in a row that has grade labels
  year_col <- NULL
  year_row <- NULL

  for (i in 1:min(10, nrow(df))) {
    row_vals <- as.character(df[i, ])
    # Look for the year in the row
    if (as.character(end_year) %in% row_vals) {
      year_col <- which(row_vals == as.character(end_year))
      year_row <- i
      break
    }
  }

  if (is.null(year_col)) {
    stop(paste("Year", end_year, "not found in MD Planning file"))
  }

  # Parse each jurisdiction block
  result_list <- list()

  # Find all jurisdiction header rows
  col1 <- as.character(df[[1]])

  for (j in seq_along(jurisdiction_names)) {
    jname <- jurisdiction_names[j]

    # Find the row with this jurisdiction name
    j_rows <- which(grepl(paste0("^", gsub(" ", "\\\\s*", jname), "$"), col1, ignore.case = TRUE))

    if (length(j_rows) == 0) {
      # Try partial match
      j_rows <- which(grepl(jname, col1, ignore.case = TRUE))
    }

    if (length(j_rows) == 0) {
      next
    }

    j_row <- j_rows[1]

    # Find the data year column for this block (blocks may have different layouts)
    # Look for year row within 5 rows after jurisdiction header
    block_year_col <- NULL
    for (offset in 1:5) {
      check_row <- j_row + offset
      if (check_row > nrow(df)) break
      row_vals <- as.character(df[check_row, ])
      if (as.character(end_year) %in% row_vals) {
        block_year_col <- which(row_vals == as.character(end_year))
        break
      }
    }

    if (is.null(block_year_col) || length(block_year_col) == 0) {
      next
    }

    # Extract grade-level data from the block
    grade_data <- extract_jurisdiction_grades(df, j_row, block_year_col[1], end_year)

    if (!is.null(grade_data)) {
      # Add jurisdiction info
      if (jname == "Maryland") {
        grade_data$type <- "State"
        grade_data$district_id <- NA_character_
        grade_data$district_name <- "Maryland"
      } else {
        grade_data$type <- "District"
        # Find the LSS code - try matching with and without "County" suffix
        clean_name <- gsub(" County$", "", jname)
        # First try exact match with the full name
        code_idx <- which(lss_codes == jname)
        if (length(code_idx) == 0) {
          # Try with just the base name
          code_idx <- which(lss_codes == clean_name)
        }
        if (length(code_idx) == 0) {
          # Try partial match for Baltimore County vs Baltimore City
          code_idx <- which(grepl(paste0("^", clean_name), lss_codes))
          # If multiple matches (Baltimore City and Baltimore County), pick the right one
          if (length(code_idx) > 1 && grepl("County", jname)) {
            code_idx <- which(lss_codes == paste0(clean_name, " County"))
          } else if (length(code_idx) > 1 && grepl("City", jname)) {
            code_idx <- which(lss_codes == paste0(clean_name, " City"))
          }
        }
        if (length(code_idx) > 0) {
          grade_data$district_id <- names(lss_codes)[code_idx[1]]
          grade_data$district_name <- lss_codes[code_idx[1]]
        } else {
          grade_data$district_id <- NA_character_
          grade_data$district_name <- clean_name
        }
      }

      grade_data$campus_id <- NA_character_
      grade_data$campus_name <- NA_character_
      grade_data$end_year <- end_year

      result_list[[length(result_list) + 1]] <- grade_data
    }
  }

  if (length(result_list) == 0) {
    stop("Could not extract enrollment data from MD Planning file")
  }

  result <- dplyr::bind_rows(result_list)

  # Calculate row_total from grade columns
  grade_cols <- c("grade_k", paste0("grade_", sprintf("%02d", 1:12)))
  grade_cols_present <- grade_cols[grade_cols %in% names(result)]

  if (length(grade_cols_present) > 0) {
    result$row_total <- rowSums(result[, grade_cols_present, drop = FALSE], na.rm = TRUE)
  }

  result
}


#' Extract grade-level enrollment for a jurisdiction
#'
#' @param df The Excel data frame
#' @param j_row Row number of the jurisdiction header
#' @param year_col Column number containing the target year's data
#' @param end_year The school year end
#' @return Data frame with one row containing grade-level enrollment
#' @keywords internal
extract_jurisdiction_grades <- function(df, j_row, year_col, end_year) {

  # Grade labels to look for
  grade_labels <- list(
    "grade_k" = c("Kindergarten", "K", "KG"),
    "grade_01" = c("1", "Grade 1", "01"),
    "grade_02" = c("2", "Grade 2", "02"),
    "grade_03" = c("3", "Grade 3", "03"),
    "grade_04" = c("4", "Grade 4", "04"),
    "grade_05" = c("5", "Grade 5", "05"),
    "grade_06" = c("6", "Grade 6", "06"),
    "grade_07" = c("7", "Grade 7", "07"),
    "grade_08" = c("8", "Grade 8", "08"),
    "grade_09" = c("9", "Grade 9", "09"),
    "grade_10" = c("10", "Grade 10"),
    "grade_11" = c("11", "Grade 11"),
    "grade_12" = c("12", "Grade 12")
  )

  # Also track school level aggregates
  level_labels <- list(
    "elementary_total" = c("Elementary School (K-5)", "Elementary", "K-5"),
    "middle_total" = c("Middle School (6-8)", "Middle", "6-8"),
    "high_total" = c("High School (9-12)", "High", "9-12"),
    "total" = c("Total School Enrollment", "Total", "Total Enrollment")
  )

  result <- data.frame(row.names = 1)

  # Search within the jurisdiction block (typically ~25 rows)
  search_end <- min(j_row + 30, nrow(df))

  for (row in (j_row + 1):search_end) {
    cell_val <- as.character(df[row, 1])

    if (is.na(cell_val) || cell_val == "") {
      next
    }

    # Check for grade labels
    for (grade_name in names(grade_labels)) {
      if (any(sapply(grade_labels[[grade_name]], function(x) {
        grepl(paste0("^", x, "$"), trimws(cell_val), ignore.case = TRUE)
      }))) {
        value <- safe_numeric(df[row, year_col])
        if (!is.na(value)) {
          result[[grade_name]] <- value
        }
        break
      }
    }

    # Check for aggregate labels
    for (level_name in names(level_labels)) {
      if (any(sapply(level_labels[[level_name]], function(x) {
        grepl(x, cell_val, ignore.case = TRUE)
      }))) {
        value <- safe_numeric(df[row, year_col])
        if (!is.na(value)) {
          result[[level_name]] <- value
        }
        break
      }
    }

    # Stop if we hit the next jurisdiction or a footer
    if (grepl("(County|City)$", cell_val) && row > j_row + 5) {
      break
    }
    if (grepl("Data prepared by", cell_val, ignore.case = TRUE)) {
      break
    }
  }

  if (ncol(result) == 0) {
    return(NULL)
  }

  result
}


#' Merge enrollment data with demographics
#'
#' Combines MD Planning enrollment (by grade) with MSDE demographic data.
#'
#' @param enr_data Data frame with enrollment by grade
#' @param demo_data Data frame with demographic breakdowns
#' @return Merged data frame
#' @keywords internal
merge_enrollment_demographics <- function(enr_data, demo_data) {

  # The demographic data has columns like: white, black, hispanic, etc.
  demo_cols <- c("white", "black", "hispanic", "asian", "pacific_islander",
                 "native_american", "multiracial", "male", "female")

  demo_cols_present <- demo_cols[demo_cols %in% names(demo_data)]

  if (length(demo_cols_present) == 0) {
    return(enr_data)
  }

  # Match on district_id for districts, or type="State" for state
  for (i in seq_len(nrow(enr_data))) {
    if (enr_data$type[i] == "State") {
      match_idx <- which(demo_data$type == "State")
    } else {
      match_idx <- which(demo_data$district_id == enr_data$district_id[i] &
                           demo_data$type == "District")
    }

    if (length(match_idx) > 0) {
      match_idx <- match_idx[1]
      for (col in demo_cols_present) {
        enr_data[[col]][i] <- demo_data[[col]][match_idx]
      }
    }
  }

  enr_data
}


#' Fetch historical enrollment from MD Planning
#'
#' Downloads enrollment data for multiple years from the Maryland Department
#' of Planning. This is useful for longitudinal analysis.
#'
#' @param start_year First school year end to fetch
#' @param end_year Last school year end to fetch
#' @param include_demographics Whether to include MSDE demographic data
#' @return Data frame with enrollment for all requested years
#' @export
#' @examples
#' \dontrun{
#' # Get enrollment from 2014 to 2024
#' historical <- fetch_historical_enrollment(2014, 2024)
#'
#' # Get enrollment for specific years without demographics
#' recent <- fetch_historical_enrollment(2020, 2024, include_demographics = FALSE)
#' }
fetch_historical_enrollment <- function(start_year, end_year,
                                         include_demographics = TRUE) {

  available <- get_available_years()
  validate_year(start_year, min_year = available$min_year, max_year = available$max_year)
  validate_year(end_year, min_year = available$min_year, max_year = available$max_year)

  if (start_year > end_year) {
    stop("start_year must be less than or equal to end_year")
  }

  years <- start_year:end_year
  all_data <- list()

  for (yr in years) {
    message(paste("Fetching", format_school_year(yr), "..."))
    tryCatch({
      yr_data <- get_raw_enr(yr, include_demographics = include_demographics)
      all_data[[length(all_data) + 1]] <- yr_data
    }, error = function(e) {
      warning(paste("Could not fetch data for", yr, ":", e$message))
    })
  }

  if (length(all_data) == 0) {
    stop("Could not fetch enrollment data for any requested year")
  }

  dplyr::bind_rows(all_data)
}

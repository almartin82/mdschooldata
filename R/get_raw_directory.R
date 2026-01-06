# ==============================================================================
# Raw Directory Data Download Functions
# ==============================================================================
#
# This file contains functions for downloading raw directory data from the
# Maryland State Department of Education and MD iMAP.
#
# Data source:
# - Charter Schools: MD iMAP ArcGIS dataset
# - URL: https://hub.arcgis.com/api/v3/datasets/1382ea15257847f8b95b258832e5a981_6/downloads/data
#
# Note: This implementation currently covers charter schools only via MD iMAP.
# Public schools require separate implementation.
#
# ==============================================================================

#' Get the download URL for directory type
#'
#' Constructs the download URL for Maryland school directory.
#'
#' @param directory_type Type of directory ("charter_schools", "all")
#' @return Character string with download URL or named list of URLs
#' @keywords internal
#' @importFrom stats setNames
get_directory_url <- function(directory_type = "all") {

  urls <- list(
    charter_schools = "https://hub.arcgis.com/api/v3/datasets/1382ea15257847f8b95b258832e5a981_6/downloads/data?format=csv&spatialRefId=3857&where=1%3D1"
  )

  if (directory_type == "all") {
    return(urls)
  }

  urls[[directory_type]]
}


#' Download raw directory data from MD iMAP
#'
#' Downloads the Maryland school directory CSV file(s).
#'
#' @param directory_type Type of directory ("charter_schools", "all")
#' @return List with raw data frames for each directory type requested
#' @keywords internal
get_raw_directory <- function(directory_type = "all") {

  message(paste("Downloading Maryland directory data:", directory_type, "..."))

  urls <- get_directory_url(directory_type)

  # Handle single type vs all types
  if (directory_type != "all") {
    urls <- setNames(list(urls), directory_type)
  }

  # Download each file
  results <- lapply(seq_along(urls), function(i) {
    type <- names(urls)[[i]]
    url <- urls[[i]]

    message(paste("  Downloading", type, "..."))

    # Create temp file
    temp_file <- tempfile(fileext = ".csv")

    # Download with proper headers
    tryCatch({
      response <- httr::GET(
        url,
        httr::write_disk(temp_file, overwrite = TRUE),
        httr::user_agent("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36"),
        httr::timeout(120)
      )

      if (httr::http_error(response)) {
        stop(paste("HTTP error:", httr::status_code(response)))
      }

      # Verify file is a valid CSV file
      file_info <- file.info(temp_file)
      if (file_info$size < 100) {
        content <- readLines(temp_file, n = 5, warn = FALSE)
        if (any(grepl("Access Denied|error|not found", content, ignore.case = TRUE))) {
          stop("Server returned an error page instead of data file")
        }
      }

      # Read CSV file (handle UTF-8 BOM)
      df <- readr::read_csv(temp_file, locale = readr::locale(encoding = "UTF-8"),
                            show_col_types = FALSE)

      # Remove X, Y, OBJECTID columns (GIS coordinates)
      cols_to_remove <- c("X", "Y", "OBJECTID")
      df <- df[, !names(df) %in% cols_to_remove, drop = FALSE]

      # Add metadata
      df$directory_type <- type
      df$data_source <- "Maryland iMAP (ArcGIS)"

      # Clean up temp file
      unlink(temp_file)

      message(paste("  Downloaded", nrow(df), "rows for", type))

      df

    }, error = function(e) {
      unlink(temp_file)
      stop(paste("Failed to download directory data for", type,
                 "\nError:", e$message,
                 "\nURL:", url))
    })
  })

  names(results) <- names(urls)
  results
}

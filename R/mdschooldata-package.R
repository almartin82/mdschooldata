#' mdschooldata: Fetch and Process Maryland School Enrollment Data
#'
#' Downloads and processes school enrollment data from the Maryland State
#' Department of Education (MSDE). Provides functions for fetching enrollment
#' data from the Maryland Report Card system and transforming it into tidy
#' format for analysis.
#'
#' @section Main functions:
#' \describe{
#'   \item{\code{\link{fetch_enr}}}{Fetch enrollment data for a school year}
#'   \item{\code{\link{fetch_enr_multi}}}{Fetch enrollment data for multiple years}
#'   \item{\code{\link{tidy_enr}}}{Transform wide data to tidy (long) format}
#'   \item{\code{\link{id_enr_aggs}}}{Add aggregation level flags}
#'   \item{\code{\link{enr_grade_aggs}}}{Create grade-level aggregations}
#'   \item{\code{\link{get_available_years}}}{Get available year range}
#' }
#'
#' @section Cache functions:
#' \describe{
#'   \item{\code{\link{cache_status}}}{View cached data files}
#'   \item{\code{\link{clear_cache}}}{Remove cached data files}
#' }
#'
#' @section ID System:
#' Maryland uses a hierarchical system of 24 Local School Systems (LSS):
#' \itemize{
#'   \item 23 counties plus Baltimore City
#'   \item LSS Numbers: 2-digit codes (01-24)
#'   \item School Numbers: 4-digit codes within each LSS
#' }
#'
#' @section Data Sources:
#' Data is sourced exclusively from the Maryland State Department of Education (MSDE):
#' \itemize{
#'   \item Maryland Report Card: \url{https://reportcard.msde.maryland.gov/}
#'   \item MSDE Staff and Student Publications: \url{https://marylandpublicschools.org/about/Pages/DCAA/SSP/}
#' }
#'
#' Note: This package does NOT use federal data sources (NCES, Urban Institute, etc.).
#' All data comes directly from Maryland state sources.
#'
#' @section Data Availability:
#' Maryland enrollment data from MSDE sources:
#' \itemize{
#'   \item 2019-present: Data available via MSDE publications and Report Card
#'   \item Data is collected as of September 30 each school year
#' }
#'
#' @docType package
#' @name mdschooldata-package
#' @aliases mdschooldata
#' @keywords internal
"_PACKAGE"

#' Pipe operator
#'
#' See \code{magrittr::\link[magrittr:pipe]{\%>\%}} for details.
#'
#' @name %>%
#' @rdname pipe
#' @keywords internal
#' @export
#' @importFrom dplyr %>%
#' @usage lhs \%>\% rhs
#' @param lhs A value or the magrittr placeholder.
#' @param rhs A function call using the magrittr semantics.
#' @return The result of calling `rhs(lhs)`.
NULL

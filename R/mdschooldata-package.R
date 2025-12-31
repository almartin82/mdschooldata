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
#' Data is sourced from the Maryland State Department of Education:
#' \itemize{
#'   \item Maryland Report Card: \url{https://reportcard.msde.maryland.gov/}
#'   \item MSDE Data Portal: \url{https://marylandpublicschools.org/about/Pages/DCAA/SSP/StudentStaff.aspx}
#' }
#'
#' @section Format Eras:
#' Maryland enrollment data is available across multiple format eras:
#' \itemize{
#'   \item 2018-present: Maryland Report Card API (JSON format)
#'   \item 2003-2017: Legacy CSV downloads from MSDE
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

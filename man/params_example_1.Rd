% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/data.R
\docType{data}
\name{params_example_1}
\alias{params_example_1}
\title{Parameter list example as provided by a datatable.}
\format{A list with 7 elements:
\describe{
\item{draw}{chr integer, draw counter}
\item{start}{char integer of first visible record on page (indexed from zero)}
\item{length}{char integer of page size, e.g. default is 10 records per page}
\item{escape}{char control html escaping, e.g. "true". See renderDT \code{escape} parameter}
\item{columns}{unnamed list containing one named list item per column}
\item{order}{unnamed list containing one named list item per sorted column}
\item{search}{named list with the search $value and other search options}
}}
\usage{
params_example_1
}
\description{
A named list as processed by a \code{funcFilter}. This example results from
viewing the first page of a datatable, after ordering the first two columns.
}
\keyword{datasets}

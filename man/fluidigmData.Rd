% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/dataCreation.R
\docType{data}
\name{fluidigmData}
\alias{fluidigmData}
\alias{fluidigmColData}
\title{Subset of fluidigm data}
\format{
subset of fluidigm data used in vignette
package.
}
\description{
Subset of fluidigm data
}
\details{
\code{fluidigmData} and \code{fluidigmColData} are portions of the \code{fluidigm} data distributed in the package \code{scRNAseq} package. We have subsetted to only the cells sequenced under high depth, and limited our selves to only two of the four gene estimates provided by \code{scRNAseq} ("tophat_counts" and "rsem_tpm").
}
\examples{
#code used to create objects:
\dontrun{
library(scRNAseq)
if(packageVersion("scRNAseq")>="1.11.0") fluidigm <- ReprocessedFluidigmData() else data(fluidigm)
fluidSubset<- fluidigm[,colData(fluidigm)[,"Coverage_Type"]=="High"]
fluidigmData<-assays(fluidSubset)[c("tophat_counts","rsem_tpm")]
fluidigmColData<-as.data.frame(colData(fluidSubset))
usethis::use_data(fluidigmData, fluidigmColData, overwrite=FALSE)
}
}
\seealso{
\code{\link[scRNAseq]{fluidigm}}
}
\author{
Elizabeth Purdom \email{epurdom@stat.berkeley.edu}
}
\keyword{data}

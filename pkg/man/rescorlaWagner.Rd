\name{RescorlaWagner}
\alias{RescorlaWagner}
\alias{RescorlaWagner-class}

\title{Rescorla-Wagner Model}
\description{
Constructs a Rescorla-Wagner learning model.
}
\usage{
RescorlaWagner(formula,parameters=list(alpha=.1,beta=c(1,1),lambda=c(1,0),ws=0),
data,subset,fixed,parStruct,intercept=TRUE,base=NULL,ntimes=NULL,replicate=TRUE)
}
\arguments{
\item{formula}{an object of class \code{formula} (or one that can be coerced to 
 that class): a symbolic description of the model to be fitted. For more details
 of model speecification, see \code{lm} or \code{glm}.}
\item{parameters}{an optional named list with (starting) values of the 
parameters. Missing parameters in the list will be set to default values.}
\item{data}{(optional) data frame for evaluation of the formula.}
\item{subset}{(optional) subset of the data.}
\item{fixed}{(optional) logical vector indicating whether parameters are fixed 
(TRUE) or freely estimable (FALSE).}
\item{parStruct}{(optional) ParStruct object. Note that if parStruct is given, 
the `fixed' argument above will be ignored.}
\item{intercept}{should an intercept be included in the predictors? If set to 
FALSE, an intercept will be removed from the model.frame. This is especially
useful when the predictors are categorical variables.}
\item{base}{which level of the criterion variable is considered the base 
category? Defaults to the first level.}
\item{ntimes}{an optional vector with, for each repetition in the data, the 
total number of trials.}
\item{replicate}{are the repeated series true replications, i.e., are the model
parameters considered identical for each series?}
}
\details{The Rescorla-Wagner model (Rescorla & Wagner, 1972) is an associative
learning model. 
}
\value{A (fitted) object of class \code{LearningModel}}
\references{
Rescorla, R. A., and Wagner, A. R. (1972). A theory of Pavlovian conditioning: 
Variations in the effectiveness of reinforcement and nonreinforcement. In A. H. 
Black and W. F. Prokasy (Eds.), \emph{Classical Conditioning II}, 
Appleton-Century-Crofts. pp. 64-99.
}
\author{Maarten Speekenbrink}
\examples{
## open weather prediction data
data(WPT)
## initialize model
mod <- RescorlaWagner(y~x1+x2+x3+x4-1,data=WPT,ntimes=c(200,200))
## estimate free parameters
\dontrun{mod <- estimate(mod)}
summary(mod)
}
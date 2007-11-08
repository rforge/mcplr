# TODO:
# 1. allow matrix of means and sds
# 2. fix constructor function

setClass("GaussianMixtureModel",
  contains="ResponseModel",
  representation(
    weights="list",
    means="list",
    sds="list"
  )
)

setMethod("getPars",signature(object="GaussianMixtureModel"),
  function(object,which="all",unconstrained=FALSE,...) {
    if(unconstrained) {
      pars <- object@parameters
      if(!is.null(pars$sd)) pars$sd <- log(pars$sd)
      pars <- unlist(pars)
      if(which=="free") {
        if(length(object@parStruct@fix)>0) {
          fixl <- relist(object@parStruct@fix,skeleton=object@parameters)
          fixl$lambda <- NULL
          fix <- unlist(fixl)
          pars <- pars[!fix]
        }
      }
    } else {
      pars <- callNextMethod(object=object,which=which,unconstrained=unconstrained,...)
    }
    pars
  }
)

setMethod("setPars",signature(object="GaussianMixtureModel"),
  function(object,pars,unconstrained=FALSE,...,rval=c("object","parameters")) {
    rval <- match.arg(rval)
    #object <- callNextMethod()
    parl <- callNextMethod(object=object,pars=pars,rval="parameters",...)
    if(unconstrained) {
      parl$sd <- exp(parl$sd)
    }
    switch(rval,
      object = {
        object@parameters <- parl
        object
      },
      parameters = parl)
    #return(object)
  }
)
# sd matrix is a regression matrix for sd.
# If object@parameters$sd usually contains a single value sd

setMethod("logLik",signature(object="GaussianMixtureModel"),
  function(object,ntimes=NULL,default=log(1/100),...) {
#    d <- object@x
#    for(i in 1:nrow(d)) d[i,] <- dnorm(object@r[i,],mean=object@x[i,],sd=object@sd[i,])
    #if(is.null(ntimes)) ntimes <- unlist(lapply(object@weights,nrow))
    #lt <- length(ntimes)
    #et <- cumsum(ntimes)
    #bt <- c(1,et[-lt]+1)
    LL <- vector("double")
    zwt <- 0
    nobs <- 0
    for(case in 1:object@nTimes@cases) {
      w <- object@weights[[case]]
      #if(is.null(discount))
      zw <- which(colSums(w)==0) #else zw <- which(colSums(w[,-discount])==0)
      #zw <- which(colSums(w)==0)
      #if(length(zw)>0)
      d <- apply(as.matrix(object@y[object@nTimes@bt[case]:object@nTimes@et[case],]),1,function(x) dnorm(x,mean=object@means[[case]],sd=object@sds[[case]]))
      d <- w*d
      #rmv <- unique(c(discount,zw))
      #d <- d[,-rmv]
      d <- d[,-zw]
      LL[case] <- sum(log(colSums(d))) + length(zw)*default
      zwt <- zwt+length(zw)
      nobs <- nobs + ncol(d) + length(zw)
    }
    out <- sum(LL)
    attr(out,"datapoints set to default (",default,")") <- zwt
#    if(!is.null(discount)) attr(out,"nobs") <- nobs
    out
  }
)

setMethod("predict",signature(object="GaussianMixtureModel"),
  function(object,...) {
    res <- object@y
    for(case in 1:object@nTimes@cases) {
      if(all(dim(object@means[[case]])==dim(object@weights[[case]]))) res[object@nTimes@bt[case]:object@nTimes@et[case],] <- rowSums(object@weights[[case]]*object@means[[case]])
      if(nrow(object@means[[case]])==1) res[object@nTimes@bt[case]:object@nTimes@et[case],] <- as.vector(object@means[[case]]%*%object@weights[[case]])
    }
    res
  }
)
setMethod("fit",signature(object="GaussianMixtureModel"),
  function(object,...) {
    for(case in 1:object@nTimes@cases) {
      if(object@parStruct@replicate) pars <- object@parameters else pars <- object@parameters[[case]]
      m <- pars$mean
      sds <- pars$sd
      nx <- ncol(object@weights[[case]])
      nt <- nrow(object@weights[[case]])
      if(!is.null(m)) {
        stop("means parameter not implemented yet")
      }
      if(!is.null(sds)) {
        if(length(sds)==1) object@sds[[case]] <- sds else {
          stop("multiple sds parameters not implemented yet")
        }
      }
    }
    
#    func <- function(pars,x,sd) {
#      m <- pars$mean
#      sigma <- pars$sd
#      if(!is.null(m)) {
#        if(!is.matrix(m)) m <- matrix(m,nrow=1)
#        if(ncol(m)!=ncol(x)) stop("mean should have as many columns as x")
#        if(nrow(m)==1) {
#          x <- t(matrix(m,nrow=ncol(x),ncol=nrow(x)))
#        } else {
#          if(nrow(m)!=nrow(x)) stop("mean should have as many rows as x")
#          x <- m
#        }
#      }
#      if(is.matrix(sigma)) {
      
      
#      } else {
#        if(length(sigma) > 1) {
#
#        } else {
#          if(length(object@sdmat)>0) {
#            sigma <- sigma*sdmat
#        }
      
#      }
#      if(!is.null(sig)) {
#        if(length(sig) == 1) {
#          sd <- matrix(sig,ncol=ncol(sd),nrow=nrow(sd))
#        } else {
#          if(!is.matrix(sig)) sig <- matrix(sig,nrow=1)
#          if(ncol(sig)==1) {
#            sd <- matrix(sig,ncol=ncol(sd),nrow=nrow(sd))
#          } else {
#            if(ncol(sig)!=ncol(sd)) stop("sd in parameters should have as many columns as sd in object")
#            if(nrow(sig)==1) {
#              sd <- t(matrix(sig,nrow=ncol(sd),ncol=nrow(sd)))
#            } else {
#              if(nrow(sig)!=nrow(sd)) stop("mean should have as many rows as x")
#              sd <- sig
#            }
#          }
#        }
#      }
#      return(list(x=x,sd=sd))
#    }
#    if(!is.null(ntimes)) {
#      lt <- length(ntimes)
#      et <- cumsum(ntimes)
#      bt <- c(1,et[-lt]+1)
#      for(case in 1:lt) {
#        tmp <- func(object@parameters[[case]],object@x[bt[case]:et[case],],object@sd[bt[case]:et[case],])
#        object@x[bt[case]:et[case],] <- tmp$x
#        object@sd[bt[case]:et[case],] <- tmp$sd
#      }
#    } else {
#        tmp <- func(object@parameters,object@x,object@sd)
#        object@x <- tmp$x
#        object@sd <- tmp$sd
#   }
    object
  }
)
setMethod("estimate",signature(object="GaussianMixtureModel"),
  function(object,method="Nelder-Mead",unconstrained=FALSE,...) {
    #if(!is.null(object@parameters$sd)) object@parameters$sd <- log(object@parameters$sd)
    pstart <- getPars(object,which="free",unconstrained=unconstrained,...)
    optfun <- function(par,object,unconstrained,...) {
      #object <- setPars(object,par,unconstrained=unconstrained,...)
      object@parameters <- setPars(object,par,rval="parameters",unconstrained=unconstrained,...)
      object <- fit(object,...)
      -logLik(object)
    }
    if(length(pstart)==1 & names(pstart)=="sd") {
      opt <- list()
      # estimate sd
      if(unconstrained) v <- v.old <- exp(pstart) else v <- v.old <- pstart
      converge <- FALSE
      while(!converge) {
        # compute responsibilities
        d <- object@weights*apply(object@y,1,function(y) dnorm(y,mean=object@x,sd=v))
        d[,colSums(object@weights)!=0] <- t(apply(d,1,"/",colSums(d)))[,colSums(object@weights)!=0]
#        d[,colSums(object@weights)==0] <- 0
        #d[object@weights==0] <- 0
        v <- sqrt(sum(d*apply(object@y,1,"-",object@x)^2)/sum(d))
        if(abs(v-v.old) < 1e-5) converge <- TRUE
        v.old <- v
      }
      if(unconstrained) opt$par <- log(v) else opt$par <- v
    } else {
      if(length(pstart)==1 & method=="Nelder-Mead") {
        if(is(object@parStruct@constraints,"BoxConstraintsList")) {
          mn <- object@parStruct@constraints@min
          mx <- object@parStruct@constraints@max
        } else {
          mn <- .Machine$double.eps
          mx <- sd(object@y)
        }
        if(unconstrained) {
          mn <- log(mn)
          mx <- log(mx)
        }
        try(opt <- optimise(f=optfun,interval=c(mn,mx),object=object,...))
        if(!is.null(opt)) opt$par <- opt$minimum
      } else {
          try(opt <- optim(pstart,fn=optfun,method=method,object=object,...))
      }
    }
    if(is.null(opt)) {
      warning("optimization failed")
    } else {
      #object <- setPars(object,opt$par,unconstrained=unconstrained,...)
      object@parameters <- setPars(object,opt$par,rval="parameters",unconstrained=unconstrained,...)
    }
    #if(!is.null(object@parameters$sd)) object@parameters$sd <- exp(object@parameters$sd)
    object <- fit(object,...)
    return(object)
  }
)

gaussianMixture <- function(formula,ncomponent=2,data,subset,weights,ntimes=NULL) {
  if(!missing(subset)) dat <- mcpl.prepare(formula,data,subset,base=base,remove.intercept=TRUE) else dat <- mcpl.prepare(formula,data,base=base,remove.intercept=TRUE)
  x <- dat$x
  y <- dat$y
  if(ncol(x)!=0) ncomponent <- ncol(x)
  mod <- new("GaussianMixtureModel",
    y = y
  )
}

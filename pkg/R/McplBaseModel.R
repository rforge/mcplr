setClass("McplBaseModel",
  representation(
    x="matrix",
    y="matrix",
    parameters="list",
    parStruct="ParStruct",
    nTimes="NTimes"
  )
)
setMethod("getPars",signature(object="McplBaseModel"),
  # Note:
  # if one element in parameters corresponding to id[i] is free, so
  #   is this parameter!
  function(object,which="all",internal=FALSE,...) {
    pars <- unlist(object@parameters)
    switch(which,
      free = {
        parid <- object@parStruct@id
        fix <- object@parStruct@fix
        if(length(parid)>0) {
          # get unique parameters
          if(length(fix)>0) parid.v <- unique(parid[!fix]) else parid.v <- unique(parid)
          parid.n <- length(parid.v)
          newpars <- vector()
          for(i in 1:parid.n) newpars[i] <- pars[which(parid==parid.v[i])[1]]
          pars <- newpars
        } else {
          if(length(fix)>0) {
            if(length(fix) == length(pars)) pars <- pars[!fix] else stop("length of fix in parStruct does not match number of parameters")
          }
        }
        if(length(pars)==0) pars <- NULL
        pars
      },
      all = pars,
      pars
    )
    return(pars)
  }
)
setMethod("setPars",signature(object="McplBaseModel"),
  function(object,pars,internal=FALSE,...,rval=c("object","parameters")) {
    rval <- match.arg(rval)
    oldpars <- unlist(object@parameters)
    if(length(pars) > 0) {
      if(length(pars)!=length(oldpars)) {
        parid <- object@parStruct@id
        fix <- object@parStruct@fix
        if(length(parid)>0) {
          if(length(fix)>0) parid.v <- unique(parid[!fix]) else parid.v <- unique(parid)
          parid.n <- length(parid.v)
          if(length(pars)!=parid.n) stop("length of parid does not match length of pars")
          for(i in 1:parid.n) oldpars[which(parid==parid.v[i])] <- pars[i]
        } else {
          if(length(fix)>0) {
            if(sum(!fix)!=length(pars)) stop("parid not given and length of pars does not equal number of nonfixed parameters")
            oldpars[!fix] <- pars
          } else {
            stop("cannot work with par of this length in setPar")
          }
        }
      } else {
        oldpars <- pars
      }
      object@parameters <- relist(oldpars,skeleton=object@parameters)
    }
    switch(rval,
      object = object,
      parameters = object@parameters)
    #object <- fit(object)
    #return(object)
    #newpars <- relist(oldpars,skeleton=object@parameters)
    #newpars
  }
)
setMethod("AIC",signature(object="McplBaseModel"),
  function(object,npar,...,k=2) {
    logL <- logLik(object,...)
    if(missing(npar)) return(AIC(logL,...,k=k)) else {
      nobs <- attr(logL,"nobs")
      if(is.null(nobs)) nobs <- nrow(object@y)
      return(-2*logL + k*npar)
    }
  }
)

setMethod("AICc",signature(object="McplBaseModel"),
  function(object,npar,...) {
    logL <- logLik(object,...)
    if(missing(npar)) npar <- length(getPars(object,which="free",...))
    nobs <- attr(logL,"nobs")
    if(is.null(nobs)) nobs <- nrow(object@y)
    -2*logL + (2*nobs*npar)/(nobs-npar-1)
  }
)
#setMethod("BIC",signature(object="McplBaseModel"),
#  function(object,npar,...) {
#    logL <- logLik(object)
#    if(missing(npar)) npar <- length(getPars(object,which="free",...))
#    nobs <- attr(logL,"nobs")
#    if(is.null(nobs)) nobs <- nrow(object@y)
#    -2*logL + npar*log(nobs)
#  }
#)
setMethod("RSquare",signature(object="McplBaseModel"),
  function(object,...) {
    p <- predict(object,type="response",...)
    SSt <- sum((object@y - mean(object@y))^2)
    SSe <- sum((object@y - p)^2)
    1-SSe/SSt
  }
)

setMethod("getReplication",signature(object="McplBaseModel"),
  function(object,case,ntimes=NULL,...) {
    if(is.null(ntimes)) {
      lt <- object@nTimes@cases
      bt <- object@nTimes@bt
      et <- object@nTimes@et
    } else {
      lt <- length(ntimes)
      et <- cumsum(ntimes)
      bt <- c(1,et[-lt]+1)
    }
    x <- object@x[bt[case]:et[case],]
    y <- object@y[bt[case]:et[case],]
    if(!object@parStruct@replicate) parameters <- object@parameters[[case]] else parameters <- object@parameters
    return(list(x=x,y=y,parameters=parameters))
  }
)
setMethod("show",signature(object="McplBaseModel"),
  function(object) {

  }
)

setMethod("summary",signature(object="McplBaseModel"),
  function(object,fits=TRUE,...) {
    x <- object
    #cat("ResponseModel, class:",is(x),"\n\n")
    pars <- getPars(x,which="all",...)
    attr(pars,"skeleton") <- NULL
    fx <- x@parStruct@fix
    if(length(fx)>0) {
      frpars <- pars[!fx]
      fxpars <- pars[fx]
    } else {
      frpars <- pars
      fxpars <- NULL
    }
    if(length(frpars)>0) {
      cat("Estimated parameters:\n")
      print(frpars)
      cat("\n")
    }
    if(length(fxpars>0)) {
      cat("Fixed parameters:\n")
      fpars <- getPars(x,which="all",...)
      print(fpars[x@parStruct@fix])
      cat("\n")
    }
    if(fits) {
      mf <- list()
      try({
        mf$logLik=logLik(x,...)
        mf$BIC=BIC(x,...)
        mf$AICc=AICc(x,...)
      },silent=TRUE)
      if(length(mf>0)) {
        cat("Model fit:\n")
        print(unlist(mf))
        cat("\n")
      }
    }
  }
)

setMethod("estimate",signature(object="McplBaseModel"),
  function(object,method="Nelder-Mead",...) {
    MLoptfun <- function(pars,object,...) {
      object@parameters <- setPars(object,pars,...,rval="parameters",internal=TRUE)
      object <- fit(object,...)
      -logLik(object)
    }
    LSoptfun <- function(pars,object,...) {
      object@parameters <- setPars(object,pars,...,rval="parameters",internal=TRUE)
      object <- fit(object,...)
      sum((predict(object,type="response")-object@y)^2)
    }
    pars <- getPars(object,which="free",...,internal=TRUE)
    if(hasMethod("logLik",is(object))) optfun <- MLoptfun else optfun <- LSoptfun
    if(!is.null(object@parStruct@constraints)) {
      switch(is(object@parStruct@constraints),
        "LinConstraintsList" = {
          A <- object@parStruct@constraints@Amat
          b <- object@parStruct@constraints@bvec
          opt <- constrOptim(theta=pars,f=optfun,grad=NULL,ui=A,ci=b,object=object,...)
          object@parameters <- setPars(object,opt$par,...,rval="parameters",internal=TRUE)
        },
        "BoxConstraintsList" = {
          opt <- optim(pars,fn=optfun,method="L-BFGS-B",object=object,min=object@parStruct@constraints@min,max=object@parStruct@constraints@min,...)
          object@parameters <- setPars(object,opt$par,...,rval="parameters",internal=TRUE)
        },
        {
          warning("This extension of ConstraintsList is not implemented; using default optimisation.")
          opt <- optim(pars,fn=optfun,method=method,object=object,...)
          object@parameters <- setPars(object,opt$par,...,rval="parameters",internal=TRUE)
        }
       )
    } else {
      opt <- optim(pars,fn=optfun,method=method,object=object,...)
      object@parameters <- setPars(object,opt$par,...,rval="parameters",internal=TRUE)
    }
    object <- fit(object,...)
    object
  }
)
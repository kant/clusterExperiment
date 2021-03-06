#' General wrapper method to cluster the data
#'
#' Given input data, this function will find clusters, based on a single
#' specification of parameters.
#'
#' @param inputType a character vector defining what type of input is given in
#'   the \code{inputMatrix} argument. Must consist of values "diss","X", or
#'   "cat" (see details). "X" and "cat" should be indicate
#'   matrices with features in the row and samples in the column; "cat"
#'   corresponds to the features being numerical integers corresponding to
#'   categories, while "X" are continuous valued features. "diss" corresponds to
#'   an \code{inputMatrix} that is a NxN dissimilarity matrix. "cat" is largely
#'   used internally for clustering of sets of clusterings.
#' @param inputMatrix numerical matrix on which to run the clustering or a
#'   \code{\link[SummarizedExperiment]{SummarizedExperiment}},
#'   \code{\link{SingleCellExperiment}}, or \code{\link{ClusterExperiment}}
#'   object.
#' @param distFunction a distance function to be applied to \code{inputMatrix}. Only
#'   relevant if \code{inputType="X"}. 
#' See details of \code{\link{clusterSingle}} for the
#'   required format of the distance function.
#' @param subsample logical as to whether to subsample via
#'   \code{\link{subsampleClustering}}. If TRUE, clustering in mainClustering
#'   step is done on the co-occurance between clusterings in the subsampled
#'   clustering results.  If FALSE, the mainClustering step will be run directly
#'   on \code{x}/\code{diss}
#' @param sequential logical whether to use the sequential strategy (see details
#'   of \code{\link{seqCluster}}). Can be used in combination with
#'   \code{subsample=TRUE} or \code{FALSE}.
#' @param mainClusterArgs list of arguments to be passed for the mainClustering
#'   step, see help pages of \code{\link{mainClustering}}.
#' @param subsampleArgs list of arguments to be passed to the subsampling step
#'   (if \code{subsample=TRUE}), see help pages of
#'   \code{\link{subsampleClustering}}.
#' @param seqArgs list of arguments to be passed to \code{\link{seqCluster}}.
#' @param reduceMethod character A character identifying what type of
#'   dimensionality reduction to perform before clustering. Options are 1)
#'   "none", 2) one of listBuiltInReducedDims() or listBuiltInFitlerStats OR 3)
#'   stored filtering or reducedDim values in the object.
#' @param nDims integer An integer identifying how many dimensions to reduce to
#'   in the reduction specified by \code{reduceMethod}. Defaults to output of
#'   \code{\link{defaultNDims}}
#' @param clusterLabel a string used to describe the clustering. By default it
#'   is equal to "clusterSingle", to indicate that this clustering is the result
#'   of a call to \code{clusterSingle}.
#' @param checkDiss logical. Whether to check whether the dissimilarities
#'   matrices  are valid (whether given by the user or calculated because
#'   \code{makeMissingDiss=TRUE}).
#' @param warnings logical. Whether to print out the many possible warnings and
#'   messages regarding checking the internal consistency of the parameters.
#' @param ... arguments to be passed on to the method for signature
#'   \code{matrix}.
#' @inheritParams transformData
#' @details \code{clusterSingle} is an 'expert-oriented' function, intended to
#'   be used when a user wants to run a single clustering and/or have a great
#'   deal of control over the clustering parameters. Most users will find
#'   \code{\link{clusterMany}} more relevant. However, \code{\link{clusterMany}}
#'   makes certain assumptions about the intention of certain combinations of
#'   parameters that might not match the user's intent; similarly
#'   \code{\link{clusterMany}} does not directly take a dissimilarity matrix but
#'   only a matrix of values \code{x} (though a user can define a distance
#'   function to be applied to \code{x} in \code{\link{clusterMany}}).
#' @details Unlike \code{\link{clusterMany}}, most of the relevant arguments for
#'   the actual clustering algorithms in \code{clusterSingle} are passed to the
#'   relevant steps via the arguments \code{mainClusterArgs},
#'   \code{subsampleArgs}, and \code{seqArgs}. These arguments should be
#'   \emph{named} lists with parameters that match the corresponding functions:
#'   \code{\link{mainClustering}},\code{\link{subsampleClustering}}, and
#'   \code{\link{seqCluster}}. These three functions are not meant to be called
#'   by the user, but rather accessed via calls to \code{clusterSingle}. But the
#'   user can look at the help files of those functions for more information 
#'   regarding the parameters that they take.
#' @details Only certain combinations of parameters are possible for certain
#'   choices of \code{sequential} and \code{subsample}. These restrictions are
#'   documented below. 
#'   \itemize{ 
#'       \item{\code{clusterFunction} for
#'   \code{mainClusterArgs}: }{The choice of \code{subsample=TRUE} also controls
#'   what algorithm type of clustering functions can be used in the
#'   mainClustering step. When \code{subsample=TRUE}, then resulting
#'   co-clustering matrix  from subsampling is converted to a dissimilarity
#'   (specificaly 1-coclustering values) and is passed to \code{diss} of
#'   \code{\link{mainClustering}}. For this reason, the \code{ClusterFunction}
#'   object given to \code{\link{mainClustering}} via the argument
#'   \code{mainClusterArgs} must take input of the form of a dissimilarity. When
#'   \code{subsample=FALSE} and \code{sequential=TRUE}, the
#'   \code{clusterFunction} passed in \code{clusterArgs} element of
#'   \code{mainClusterArgs} must define a \code{ClusterFunction} object with
#'   \code{algorithmType} 'K'.  When \code{subsample=FALSE} and
#'   \code{sequential=FALSE}, then there are no restrictions on the
#'   \code{ClusterFunction} and that clustering is applied directly to the input
#'   data. } 
#'   \item{\code{clusterFunction}  for \code{subsampleArgs}: }{If the
#'   \code{ClusterFunction} object given to the \code{clusterArgs} of
#'   \code{subsamplingArgs} is missing the algorithm will use the default for
#'   \code{\link{subsampleClustering}} (currently "pam"). If
#'   \code{sequential=TRUE}, this \code{ClusterFunction} object must be of type
#'   'K'. } 
#'   \item{Setting \code{k} for subsampling: }{If \code{subsample=TRUE}
#'   and \code{sequential=TRUE}, the current K of the sequential iteration
#'   determines the 'k' argument passed to \code{\link{subsampleClustering}}  so
#'   setting 'k=' in the list given to the subsampleArgs will not do anything
#'   and will produce a warning to that effect (see documentation of
#'   \code{\link{seqCluster}}).} 
#'   \item{Setting \code{k} for mainClustering step:
#'   }{If \code{sequential=TRUE} then the user should not set \code{k} in the
#'   \code{clusterArgs} argument of \code{mainClusterArgs} because it must be
#'   set by the sequential code, which has a iterative reseting of the
#'   parameters. Specifically if \code{subsample=FALSE}, then the sequential
#'   method iterates over choices of \code{k} to cluster the input data. And if
#'   \code{subsample=TRUE}, then the \code{k} in the clustering of
#'   mainClustering step (assuming the clustering function is of type 'K') will
#'   use the \code{k} used in the subsampling step to make sure that the
#'   \code{k} used in the mainClustering step is reasonable. } 
#'   \item{Setting
#'   \code{findBestK} in \code{mainClusterArgs}: }{If \code{sequential=TRUE} and
#'   \code{subsample=FALSE}, the user should not set 'findBestK=TRUE' in
#'   \code{mainClusterArgs}. This is because in this case the sequential method
#'   changes \code{k}; an error message will be given if this combination of
#'   options are set. However, if \code{sequential=TRUE} and
#'   \code{subsample=TRUE}, then passing either 'findBestK=TRUE' or
#'   'findBestK=FALSE' via \code{mainClusterArgs} will function as expected
#'   (assuming the \code{clusterFunction} argument passed to
#'   \code{mainClusterArgs} is of type 'K'). In particular, the sequential step
#'   will set the number of clusters \code{k} for clustering of each subsample.
#'   If findBestK=FALSE, that same \code{k} will be used for mainClustering step
#'   that clusters the resulting co-occurance matrix after subsampling. If
#'   findBestK=TRUE, then \code{\link{mainClustering}} will search for best k.
#'   Note that the default 'kRange' over which \code{\link{mainClustering}}
#'   searches when findBestK=TRUE depends on the input value of \code{k} which
#'   is set by the sequential method if \code{sequential=TRUE}), see above. The
#'   user can change \code{kRange} to not depend on \code{k} and to be fixed
#'   across all of the sequential steps by setting \code{kRange} explicitly in
#'   the \code{mainClusterArgs} list.} }
#' @return A \code{\link{ClusterExperiment}} object if
#'   \code{inputType} is of type "X".
#' @return If input was not of type "X", then the result is a list with values
#'   \itemize{ 
#'        \item{clustering: }{The vector of clustering results}
#'        \item{clusterInfo: }{A list with information about the parameters run in
#'   the clustering} 
#'        \item{coClusterMatrix: }{(only if \code{saveSubsamplingMatrix=TRUE}, NxB set of clusterings obtained after B subsamples.} 
#'   }
#' @details To provide a distance matrix via the argument \code{distFunction},
#'   the function must be defined to take the distance of the rows of a matrix
#'   (internally, the function will call \code{distFunction(t(x))}. This is to
#'   be compatible with the input for the \code{dist} function. \code{as.matrix}
#'   will be performed on the output of \code{distFunction}, so if the object
#'   returned has a \code{as.matrix} method that will convert the output into a
#'   symmetric matrix of distances, this is fine (for example the class
#'   \code{dist} for objects returned by \code{dist} have such a method). If
#'   \code{distFunction=NA}, then a default distance will be calculated based on
#'   the type of clustering algorithm of \code{clusterFunction}. For type "K"
#'   the default is to take \code{dist} as the distance function. For type "01",
#'   the default is to take the (1-cor(x))/2.
#'
#' @seealso \code{\link{clusterMany}} to compare multiple choices of parameters,
#'   and \code{\link{mainClustering}},\code{\link{subsampleClustering}}, and
#'   \code{\link{seqCluster}} for the underlying functions called by
#'   \code{clusterSingle}.
#'
#' @name clusterSingle
#'
#' @examples
#' data(simData)
#'
#' \dontrun{
#' #following code takes some time.
#' #use clusterSingle to do sequential clustering
#' #(same as example in seqCluster only using clusterSingle ...)
#' set.seed(44261)
#' clustSeqHier_v2 <- clusterSingle(simData,
#'      sequential=TRUE, subsample=TRUE, 
#'      subsampleArgs=list(resamp.n=100, samp.p=0.7,
#'      clusterFunction="kmeans", clusterArgs=list(nstart=10)),
#'      seqArgs=list(beta=0.8, k0=5), mainClusterArgs=list(minSize=5,
#'      clusterFunction="hierarchical01",clusterArgs=list(alpha=0.1)))
#' }
#'
#' #use clusterSingle to do just clustering k=3 with no subsampling
#' clustObject <- clusterSingle(simData,
#'     subsample=FALSE, sequential=FALSE,
#'     mainClusterArgs=list(clusterFunction="pam", clusterArgs=list(k=3)))
#' #compare to standard pam
#' pamOut<-cluster::pam(t(simData),k=3,cluster.only=TRUE)
#' all(pamOut==primaryCluster(clustObject))
#' @aliases clusterSingle,SummarizedExperiment-method
#' @rdname clusterSingle
#' @export
setMethod(
    f = "clusterSingle",
    signature = signature(inputMatrix = "SummarizedExperiment" ),
    definition = function(inputMatrix, ...) {
        clusterSingle(as(inputMatrix,"SingleCellExperiment"),...)
    }
)

#' @rdname clusterSingle
#' @export
setMethod(
    f = "clusterSingle",
    signature = signature(inputMatrix = "ClusterExperiment"),
    definition = function(inputMatrix, ...) {
        if(any(c("transFun","isCount") %in% names(list(...))))
            stop("The internally saved transformation function of a ClusterExperiment object must be used when given as input and setting 'transFun' or 'isCount' for a 'ClusterExperiment' is not allowed.")
        outval <- clusterSingle(as(inputMatrix,"SingleCellExperiment"),transFun=transformation(inputMatrix),...)
        retval<-addClusterings(inputMatrix,outval)
        #make most recent clustering the primary cluster
        primaryClusterIndex(retval)<-nClusterings(retval)
        if(!is.null(outval@coClustering)) retval@coClustering<-outval@coClustering
        #make sure save the calculated information
        retval<-.addBackSEInfo(newObj=retval,oldObj=outval)
        return(retval)
    }
)
#' @rdname clusterSingle
#' @param whichAssay numeric or character specifying which assay to use. See
#'   \code{\link[SummarizedExperiment]{assay}} for details.
#' @export
setMethod(
    f = "clusterSingle",
    signature = signature(inputMatrix = "SingleCellExperiment"),
    definition = function(inputMatrix, reduceMethod="none",
                          nDims=defaultNDims(inputMatrix,reduceMethod),
                          whichAssay=1, ...) {
        inputArgs<-list(...)
        isDimReduced<- anyValidReducedDims(inputMatrix) && isReducedDims(inputMatrix,reduceMethod)
        isFilter<-anyValidFilterStats(inputMatrix) && isFilterStats(inputMatrix,reduceMethod)
        if(isDimReduced & isFilter) stop("reduceMethod matches both reducedDimNames and filtering statistic")
        if(reduceMethod=="none" || (!isDimReduced && !isFilter)){
            #go to matrix version using assay(x) and will calculate reduceMethod etc.
            outval<-clusterSingle(assay(inputMatrix, whichAssay),
                                  reduceMethod=reduceMethod,nDims=nDims,...)
            #add back in the SingleCellExperiment stuff lost
            retval<-.addBackSEInfo(newObj=outval,oldObj=inputMatrix)
            #but now need the filter/reducedDim
            if(reduceMethod!="none"){
                if(isFilterStats(outval,reduceMethod)) filterStats(retval)<-filterStats(outval)
                if(isReducedDims(outval,reduceMethod)) reducedDims(retval)<-reducedDims(outval)
            }
        }
        else{
            if(isDimReduced){
                #don't transform PCA!
                if(any(names(inputArgs)%in%"transFun") )
                    inputArgs<-inputArgs[!names(inputArgs)%in%"transFun"]
                if(any(names(inputArgs)%in%"isCount"))
                    inputArgs<-inputArgs[!names(inputArgs)%in%"isCount"]
                if(is.na(nDims)) nDims<-defaultNDims(inputMatrix,reduceMethod)
                outval<-do.call("clusterSingle",c(list(inputMatrix=(t(reducedDim(inputMatrix,type=reduceMethod)[,seq_len(nDims)])),reduceMethod="none",transFun=function(x){x},isCount=FALSE),inputArgs))
            }
            if(isFilter){
                #Need to think how can pass options to filterData...
                if(is.na(nDims)) nDims<-defaultNDims(inputMatrix,reduceMethod)
                outval<-clusterSingle(filterData(inputMatrix,filterStats=reduceMethod,percentile=nDims),reduceMethod="none",...)			#do transform filtered data...
            }
            #add back in the SingleCellExperiment stuff lost
            retval<-.addBackSEInfo(newObj=outval,oldObj=inputMatrix)
            
        }
        return(retval)
    }
)


#' @rdname clusterSingle
#' @export
#' @param saveSubsamplingMatrix logical. If TRUE, the co-clustering matrix
#'   resulting from subsampling is returned in the coClustering slot (and
#'   replaces any existing coClustering object in the slot \code{coClustering}
#'   if input object is a \code{ClusterExperiment} object.)
#' @param makeMissingDiss logical. Whether to calculate necessary distance 
#'   matrices needed when input is not "diss". If TRUE, then when a clustering 
#'   function calls for a inputType "diss", but the given matrix is of type "X",
#'   the function will calculate a distance function. A dissimilarity matrix
#'   will also be calculated if a post-processing argument like \code{findBestK}
#'   or \code{removeSil} is chosen, since these rely on calcualting silhouette
#'   widths from distances.
setMethod(
    f = "clusterSingle",
    signature = signature(inputMatrix = "matrixOrHDF5OrNULL"),
    definition = function(inputMatrix, inputType="X", 
                          subsample=FALSE, sequential=FALSE, distFunction=NA,
                          mainClusterArgs=NULL, subsampleArgs=NULL, seqArgs=NULL,
                          isCount=FALSE,transFun=NULL, 
                          reduceMethod="none",
                          nDims=defaultNDims(inputMatrix, reduceMethod),
                          makeMissingDiss=if(ncol(inputMatrix)<1000) TRUE else FALSE,
                          clusterLabel="clusterSingle",
                          saveSubsamplingMatrix=FALSE, 
                          checkDiss=FALSE, warnings=TRUE) {
                             
        origInputType<-inputType
        if(saveSubsamplingMatrix & !subsample){
            warning("Setting saveSubsamplingMatrix=TRUE has no effect if subsample=FALSE")
            saveSubsamplingMatrix<-FALSE
        }
        doDiss<-FALSE
        if(is.function(distFunction) || !is.na(distFunction)){
            if(inputType!="diss"){
                inputType<-"diss"
                doDiss<-TRUE
            }
            else{
                stop("Cannot provide argument distFunction for an inputMatrix that is already a dissimilarity (inputType='diss')")
            }
        }
        ##########
        ## Check arguments and set defaults as needed
        ## Note, some checks are duplicative of internal functions, 
        ## but better here, because don't want to find error after 
        ## already done extensive calculation...
        ##########
        checkOut<-.checkArgs(inputType=inputType, subsample=subsample, sequential=sequential, main=TRUE, mainClusterArgs=mainClusterArgs, subsampleArgs=subsampleArgs, seqArgs=seqArgs,allowMakeDiss=makeMissingDiss & !doDiss,warn=warnings)
        if(is.character(checkOut)) stop(checkOut)
        mainClusterArgs<-checkOut$mainClusterArgs
        subsampleArgs<-checkOut$subsampleArgs
        ## if makeMissingDiss=TRUE, then will tell whether to create diss from X with euclidean distance
        doDissPost<-checkOut$doDissPost
        if(!doDiss){
            doDiss<-checkOut$doDiss
        } 
        
        ##########
        ## Handle dimensionality reduction:
        ##########
        ###Don't do this until after do the checks, because takes some time.
        transObj<-NULL
        if(origInputType == "X"){
            origX<-inputMatrix # Need this to make CE object later!
            N <- dim(inputMatrix)[2] #ngenes x nsamples
            ##########
            ##transformation to data x that will be input to clustering
            ##########
            transFun<-.makeTransFun(transFun=transFun,isCount=isCount) #need this later to build clusterExperiment object
            reduceMethod<-match.arg(reduceMethod,c("none",
                                   listBuiltInReducedDims(), 
                                   listBuiltInFilterStats())) #because this is matrix method, will always have to be a built in value.
            if(length(nDims)>1 || length(reduceMethod)>1) {
                stop("clusterSingle only handles one choice of dimensions or reduceMethod. If you want to compare multiple choices, try clusterMany")
            }
            if(!is.na(nDims) & reduceMethod=="none") {
                if(warnings) warning("specifying nDims has no effect if reduceMethod==`none`")
            }
            if(reduceMethod=="none"){
                inputMatrix<-transformData(inputMatrix,transFun=transFun)
            }
            else if(reduceMethod%in%listBuiltInReducedDims()){
                transObj<-makeReducedDims(inputMatrix,reducedDims=reduceMethod, maxDims=nDims, transFun=transFun,isCount=isCount)
                inputMatrix<-t(reducedDim(transObj,type=reduceMethod))
            }
            else if(reduceMethod %in% listBuiltInFilterStats()){
                transObj<-makeFilterStats(inputMatrix,filterStat=reduceMethod, transFun=transFun,isCount=isCount)
                inputMatrix<-transformData(filterData(transObj, filterStats=reduceMethod, percentile=nDims), transFun=transFun, isCount=isCount)
            }
            else stop("invalid value for reduceMethod -- not in built-in filter or reducedDim method")
        }
        else{
            if(any(reduceMethod!="none")) stop("'reduceMethod' cannot be given if 'inputType' argument is not of type 'X'.")
            N<-nrow(inputMatrix)
        }
        
        
        #Make dissimilarity AFTER transforming data
        
        cf<-if(subsample) subsampleArgs[["clusterFunction"]] else mainClusterArgs[["clusterFunction"]]
        if(doDiss){
            mess<-"Making nxn dissimilarity matrix"
            if(!is.function(distFunction) && is.character(distFunction)){
                mess<-paste(mess,sprintf("(with distance function %s)",distFunction))
            }
            else if(!is.function(distFunction) && is.na(distFunction)) mess<-paste(mess,"(with default distance function, determined by algorithm type of clustering function)")
            else mess<-paste(mess,"(with user defined distance function)")
            if(warnings) .mynote(mess)
            inputMatrix<-.makeDiss(inputMatrix,
                distFunction=distFunction,
                checkDiss=FALSE, algType=algorithmType(cf))
            inputType<-"diss"
        }
        else if(doDissPost & inputType!="diss"){
            mess<-"Making nxn dissimilarity matrix in order to do post-processing (e.g. arguments findBestK=TRUE or removeSil=TRUE)."
            if(warnings) .mynote(mess)
            cfPost<- mainClusterArgs[["clusterFunction"]]
            mainClusterArgs[["diss"]]<-.makeDiss(inputMatrix,
                distFunction=distFunction,
                checkDiss=FALSE, algType=algorithmType(cfPost))
            if(checkDiss) .checkDissFunction(mainClusterArgs[["diss"]], algType = algorithmType(cfPost))
        }
        
        if(inputType=="diss" & checkDiss){
            .checkDissFunction(inputMatrix, algType = algorithmType(cf))
        }
        ##########
        ## Start running clustering
        ##########
        if(sequential){
            outlist <- do.call("seqCluster",
                               c(list(inputMatrix=inputMatrix,
                                    inputType=inputType, subsample=subsample,
                                      subsampleArgs=subsampleArgs,
                                      mainClusterArgs=mainClusterArgs),
                                      seqArgs))
        }
        else{
            ##########
            ##.clusterWrapper just deciphers choices and makes clustering.
            ##########
            finalClusterList <- .clusterWrapper(inputMatrix=inputMatrix,
                    subsample=subsample,
                    subsampleArgs=subsampleArgs,
                    mainClusterArgs=mainClusterArgs)
            outlist <- list("clustering"= .clusterListToVector(finalClusterList$result, N), coClusterMatrix=t(finalClusterList$inputMatrix))
            
        }
        clInfo<-list(list(clusterInfo = outlist$clusterInfo,
                          whyStop = outlist$whyStop,
                          subsample = subsample,
                          sequential = sequential,
                          mainClusterArgs = mainClusterArgs,
                          subsampleArgs = subsampleArgs,
                          seqArgs = seqArgs,
                          reduceMethod=reduceMethod,
                          nDims=nDims
        ))
        ##########
        ## Convert to ClusterExperiment Object
        ##########
        if(origInputType == "X"){ 
            retval<-.convertOutListToCE(
                xMatrix=origX,
                clustering=outlist$clustering,
                clusterInfo=clInfo,
                coClusterMatrix=outlist$coClusterMatrix,
                transFun=transFun,
                clusterLabel=clusterLabel,
                sequential=sequential, 
                subsample=subsample, 
                saveSubsamplingMatrix=saveSubsamplingMatrix, 
                existingCE=transObj)
            return(retval)
        }
        else{
            out<-list(clustering=outlist$clustering, 
				clusterInfo=clInfo)
            if(saveSubsamplingMatrix) 
                out<-c(out,list(coClusterMatrix=outlist$coClusterMatrix))
            return(out)
        }
        
    }
)
# Do this so clear how to transform diss version of output into CE 
# (for reuse in clusterMany...)
.convertOutListToCE<-function(xMatrix,
    clustering,clusterInfo, coClusterMatrix, 
    clusterLabel,sequential, 
    subsample, transFun,
    saveSubsamplingMatrix, existingCE){
    retval <- ClusterExperiment(xMatrix, clustering,
                                transformation=transFun,
                                clusterInfo=clusterInfo, 
                                clusterTypes="clusterSingle",
                                checkTransformAndAssay=FALSE)
    clusterLabels(retval)<-clusterLabel
    if(!is.null(coClusterMatrix) & !sequential & subsample & saveSubsamplingMatrix) {
        #will convert to sparse matrix:
		coClustering(retval) <- coClusterMatrix
        ch<-.checkCoClustering(retval)
        if(!is.logical(ch)) stop(ch)
    }
    if(!is.null(existingCE)){
        #add in the reduceMethod stuff
        retval<-.addBackSEInfo(newObj=retval,oldObj=existingCE)
    }
    return(retval)
}
#wrapper that calls the clusterSampling and mainClustering routines in reasonable order.
#called by both seqCluster and clusterSingle
#clusterFunction assumed to be defined in mainClusterArgs AND subsampleArgs
.clusterWrapper <- function(inputMatrix,  subsample, mainClusterArgs, subsampleArgs)
{
    if(subsample){
        #Returns NxB matrix
        inputMatrix<-t(do.call("subsampleClustering",
			c(list(inputMatrix=inputMatrix), 
			subsampleArgs)))
        mainClusterArgs[["inputType"]]<-"cat"
    }    
    #Takes as input BxN matrix...
    resList<-do.call("mainClustering",
		c(list(inputMatrix=inputMatrix, 
			format="list", returnData=TRUE),
		mainClusterArgs))
    return(resList)
}







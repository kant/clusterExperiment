#' @name plotReducedDims
#' @title Plot 2-dimensionsal representation with clusters
#' @description Plot a 2-dimensional representation of the data, color-code by a
#'   clustering.
#' @param object a ClusterExperiment object
#' @param reducedDim What dimensionality reduction method to use. Should match
#'   either a value in \code{reducedDimNames(object)} or one of the built-in
#'   functions of \code{\link{listBuiltInReducedDims}()}
#' @param whichDims vector of length 2 giving the indices of which dimensions to
#'   show. The first value goes on the x-axis and the second on the y-axis.
#' @param clusterLegend matrix with three columns and colnames
#'   'clusterIds','name', and 'color' that give the color and name of the
#'   clusters in whichCluster. If NULL, pulls the information from
#'   \code{object}.
#' @param legend either logical, indicating whether to plot legend, or character
#'   giving the location of the legend (passed to \code{\link{legend}})
#' @param xlab Label for x axis
#' @param ylab Label for y axis
#' @param unassignedColor If not NULL, should be character value giving the
#'   color for unassigned (-1) samples (overrides \code{clusterLegend}) default.
#' @param missingColor If not NULL, should be character value giving the color
#'   for missing (-2) samples (overrides \code{clusterLegend}) default.
#' @param plotUnassigned logical as to whether unassigned (either -1 or -2
#'   cluster values) should be plotted.
#' @param pch the point type, passed to \code{plot.default}
#' @param legendTitle character value giving title for the legend. If NULL, uses
#'   the clusterLabels value for clustering.
#' @param nColLegend The number of columns in legend. If missing, picks number 
#'   of columns internally. 
#' @param ... arguments passed to \code{\link{plot.default}}
#' @inheritParams getClusterIndex
#' @details If \code{plotUnassigned=TRUE}, and the color for -1 or -2 is set to
#'   "white", will be coerced to "lightgrey" regardless of user input to
#'   \code{missingColor} and \code{unassignedColor}. If \code{plotUnassigned=FALSE},
#'   the samples with -1/-2 will not be plotted, nor will the category show up in the
#'   legend.
#' @details If the requested \code{reducedDim} method has not been created yet,
#'   the function will call \code{\link{makeReducedDims}} on the FIRST assay of
#'   \code{x}. The results of this method will be saved as part of the object
#'   and returned INVISIBLY (meaning if you don't save the output of the
#'   plotting command, the results will vanish). To pick another assay, you
#'   should call `makeReducedDims` directly and specify the assay.
#' @seealso \code{\link{plot.default}}, \code{\link{makeReducedDims}}, \code{\link{listBuiltInReducedDims}()}
#' @rdname plotReducedDims
#' @return A plot is created. Nothing is returned.
#' @examples
#' #clustering using pam: try using different dimensions of pca and different k
#' data(simData)
#'
#' cl <- clusterMany(simData, nReducedDims=c(5, 10, 50), reducedDim="PCA",
#' clusterFunction="pam", ks=2:4, findBestK=c(TRUE,FALSE),
#' removeSil=c(TRUE,FALSE), makeMissingDiss=TRUE)
#'
#' plotReducedDims(cl,legend="bottomright")
#' @export
#' @aliases plotReducedDims plotReducedDims,ClusterExperiment-method
setMethod(
  f = "plotReducedDims",
  signature = signature(object = "ClusterExperiment"),
  definition = function(object, whichCluster="primary",
                        reducedDim="PCA",whichDims=c(1,2),plotUnassigned=TRUE,legend=TRUE,legendTitle="",nColLegend=6,
                        clusterLegend=NULL,unassignedColor=NULL,missingColor=NULL,pch=19,xlab=NULL,ylab=NULL,...)
  {
	whichCluster<-getSingleClusterIndex(object,whichCluster,passedArgs=list(...))
    cluster<-clusterMatrix(object)[,whichCluster]
    if("col" %in% names(list(...))) stop("plotting parameter 'col' may not be passed to plot.default. Colors must be set via 'clusterLegend' argument.")
    if(is.null(clusterLegend)){
      clusterLegend<-clusterLegend(object)[[whichCluster]]
    }
    else{
      if(is.null(dim(clusterLegend)) || ncol(clusterLegend)!=3 || !all(c("clusterIds","name","color") %in% colnames(clusterLegend))) stop("clusterLegend must be a matrix with three columns and names 'clusterIds','name', and 'color'")
      if(!all(as.character(unique(cluster)) %in% clusterLegend[,"clusterIds"])) stop("'clusterIds' in 'clusterLegend' do not match clustering values")
    }
    clColor<-clusterLegend[,"color"]
    names(clColor)<-clusterLegend[,"name"]
    wh1<-which(clusterLegend[,"clusterIds"]=="-1")
    wh2<-which(clusterLegend[,"clusterIds"]=="-2")
    if(!is.null(unassignedColor) && is.character(unassignedColor)){
      if(length(wh1)>0) clColor[wh1]<-unassignedColor
    }
    if(!is.null(missingColor) && is.character(missingColor)){
      if(length(wh2)>0) clColor[wh2]<-missingColor
    }
    if(length(wh1)>0){
      if(plotUnassigned && clColor[wh1]=="white") clColor[wh1]<-"lightgrey"
      else if(!plotUnassigned) clColor[wh1]<-NA
      names(clColor)[wh1]<-"Unassigned"
      clusterLegend[wh1,"name"]<-"Unassigned"
      clColor<-c(clColor[-wh1],clColor[wh1])
    }
    if(length(wh2)>0){
      if(plotUnassigned && clColor[wh2]=="white") clColor[wh2]<-"lightgrey"
      else if(!plotUnassigned) clColor[wh2]<-NA
      names(clColor)[wh2]<-"Missing"
      clusterLegend[wh2,"name"]<-"Missing"
      clColor<-c(clColor[-wh2],clColor[wh2])
    }
    
    clFactor<-factor(as.character(cluster),levels=clusterLegend[,"clusterIds"], labels=clusterLegend[,"name"])
    
    #################
    ####Dim reduction stuff:
    #################
    if(length(whichDims)<2)
      stop("whichDims must be a vector of length at least 2 giving the which dimensions of the dimensionality reduction to plot")
    redoDim<-FALSE
    if(!reducedDim %in% reducedDimNames(object) & reducedDim %in% listBuiltInReducedDims()) redoDim<-TRUE
    if(reducedDim %in% reducedDimNames(object)){
      #check if ask for higher dim than available
      if(max(whichDims)>NROW(object) || max(whichDims)>NCOL(object)) stop("Invalid value for whichDims: larger than row or column")
      if(max(whichDims)>ncol(reducedDim(object,type=reducedDim))) redoDim<-TRUE
    }
    
    if(redoDim){
     object<-makeReducedDims(object,reducedDims=reducedDim,maxDims=max(whichDims),whichAssay=1)
		 warning(paste("'makeReducedDims' is being called because requested method",reducedDim,"has not been created yet for this object. 'makeReducedDims' will be run on the FIRST assay; for a different assay call 'makeReducedDims' directly."))	
    }
    if(reducedDim %in% reducedDimNames(object)){
      
      dat<-reducedDim(object,type=reducedDim)[,whichDims]
    }
    else stop("'reducedDim' does not match saved dimensionality reduction nor built in methods.")
    
    if(length(whichDims)==2){
      if(is.null(ylab)) ylab<-paste("Dimension",whichDims[2])
      if(is.null(xlab)) xlab<-paste("Dimension",whichDims[1])
      
      graphics::plot(dat,col=clColor[as.character(clFactor)],pch=pch,xlab=xlab,ylab=ylab,...)
      
      doLegend<-FALSE
      
      if(is.logical(legend)) {
        if(legend) {
          doLegend<-TRUE
          legend<-"topright"
        }
      } else{
        if(is.character(legend)) doLegend<-TRUE
        else stop("legend must either be logical or character value.")
      }
      
      if(doLegend){
        if(!plotUnassigned){
          wh1<-which(names(clColor)=="Unassigned")
          wh2<-which(names(clColor)=="Missing")
          if(length(wh1)>0) clColor<-clColor[-wh1]
          if(length(wh2)>0) clColor<-clColor[-wh2]
        }
        if(is.null(legendTitle)) legendTitle<-clusterLabels(object)[whichCluster]
			if(missing(nColLegend)){
				nPerColLegend<-6
				nColLegend<-length(clColor) %/% nPerColLegend					
				if(length(clColor)%% nPerColLegend > 0) nColLegend<-nColLegend+1
			}
			graphics::legend(x=legend, legend=names(clColor), fill=clColor,title=legendTitle,ncol=nColLegend)
      }
      
    }
    else if(length(whichDims)>2){
      colnames(dat)<-paste("Dim.",whichDims,sep="")
      graphics::pairs(data.frame(dat),col=clColor[as.character(clFactor)],pch=pch,...)
    }
    
    invisible(object)
    
  })

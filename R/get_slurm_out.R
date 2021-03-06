#' Reads the output of a function calculated on the Slurm cluster 
#'
#' This function reads all function output files (one by cluster node used) from 
#' the specified Slurm job and returns the result in a single data frame
#' (if "table" format selected) or list (if "raw" format selected). It doesn't 
#' record any messages (including warnings or errors) output to the R console
#' during the computation; these can be consulted by invoking 
#' \code{\link{print_job_status}}.
#' 
#' The \code{outtype} option is only relevant for jobs submitted with 
#' \code{slurm_apply}. Jobs sent with \code{slurm_call} only return a single
#' object, and setting \code{outtype = "table"} creates an error in that case.
#' 
#' @param slr_job A \code{slurm_job} object or the path to the slurm job folder.
#' @param outtype Can be "table" or "raw", see "Value" below for details.
#' @param wait Specify whether to block until \code{slr_job} completes.
#' @return If \code{outtype = "table"}: A data frame with one column by 
#'   return value of the function passed to \code{slurm_apply}, where 
#'   each row is the output of the corresponding row in the params data frame 
#'   passed to \code{slurm_apply}.
#'   
#'   If \code{outtype = "raw"}: A list where each element is the output 
#'   of the function passed to \code{slurm_apply} for the corresponding
#'   row in the params data frame passed to \code{slurm_apply}.
#' @seealso \code{\link{slurm_apply}}, \code{\link{slurm_call}}
#' @export
get_slurm_out <- function(slr_job, outtype = "raw", wait = TRUE) {
 
	if(class(slr_job)=="character")
	{
		job_folder <- slr_job
		slr_job_file <- file.path(slr_job,"slurm_job.Rdata")
		tmpdir <- slr_job
		if(file.exists(slr_job_file)) load(slr_job_file) else stop("slr_job must be a path to the slurm job directory...")
	} else
	{
		job_folder <- getwd()
		tmpdir <- file.path(job_folder,paste0("_rslurm_", slr_job$jobname))
	}

    # Check arguments
    if (!(class(slr_job) == "slurm_job")) {
        stop("slr_job must be a slurm_job")
    }
    outtypes <- c("table", "raw")
    if (!(outtype %in% outtypes)) {
        stop(paste("outtype should be one of:", paste(outtypes, collapse = ', ')))
    }

    # Wait for slr_job using Slurm dependency
    if (wait) {
        wait_for_job(slr_job)
    }
    
    res_files <- file.path(job_folder,paste0("results_", 0:(slr_job$nodes - 1), ".RDS"))

	missing_files <- res_files[!sapply(res_files,file.exists)]
	
    if (length(missing_files) > 0) {
        missing_list <- paste(missing_files, collapse = ", ")
        warning(paste("The following files are missing:", missing_list))
    }
    res_files <- res_files[sapply(res_files,file.exists)]
    if (length(res_files) == 0) return(NA)
    
    slurm_out <- lapply(res_files, readRDS)
    slurm_out <- do.call(c, slurm_out)
    
    if (outtype == "table") {
        slurm_out <- as.data.frame(do.call(rbind, slurm_out))
    }
    slurm_out
}

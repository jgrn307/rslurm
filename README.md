|                |                 |
|----------------|-----------------|
| rslurm-package | R Documentation |

rslurm: Submit R calculations to a SLURM cluster
------------------------------------------------

### Description

This package automates the process of sending simple function calls or parallel calculations to a cluster using the SLURM workload manager.

### Overview

This package includes two core functions used to send computations to a SLURM cluster. While `slurm_call` executes a function using a single set of parameters (passed as a list), `slurm_apply` evaluates the function in parallel for multiple sets of parameters grouped in a data frame. `slurm_apply` automatically splits the parameter sets into equal-size chunks, each chunk to be processed by a separate cluster node. It uses functions from the `parallel` package to parallelize computations within each node.

The output of `slurm_apply` or `slurm_call` is a `slurm_job` object that serves as an input to the other functions in the package: `print_job_status`, `cancel_slurm`, `get_slurm_out` and `cleanup_files`.

For bug reports or questions about this package, contact Ian Carroll(icarroll@sesync.org).

### Function Specification

To be compatible with `slurm_apply`, a function may accept any number of single value parameters. The names of these parameters must match the column names of the `params` data frame supplied. There are no restrictions on the types of parameters passed as a list to `slurm_call`.

If the function passed to `slurm_call` or `slurm_apply` requires knowledge of any R objects (data, custom helper functions) besides `params`, a character vector corresponding to their names should be passed to the optional `add_objects` argument.

When parallelizing a function, since any error will interrupt all calculations for the current node, it may be useful to wrap expressions which may generate errors into a `try` or `tryCatch` function. This will ensure the computation continues with the next parameter set after reporting the error.

### Output Format

The default output format for `get_slurm_out` (`outtype = "raw"`) is a list where each element is the return value of one function call. If the function passed to `slurm_apply` produces a vector output, you may use `outtype = "table"` to collect the output in a single data frame, with one row by function call.

### Examples

    ## Not run: 
    # Create a data frame of mean/sd values for normal distributions 
    pars <- data.frame(par_m = seq(-10, 10, length.out = 1000), 
                       par_sd = seq(0.1, 10, length.out = 1000))
                       
    # Create a function to parallelize
    ftest <- function(par_m, par_sd) {
     samp <- rnorm(10^7, par_m, par_sd)
     c(s_m = mean(samp), s_sd = sd(samp))
    }

    sjob1 <- slurm_apply(ftest, pars)
    print_job_status(sjob1)
    res <- get_slurm_out(sjob1, "table")
    all.equal(pars, res) # Confirm correct output
    cleanup_files(sjob1)

    ## End(Not run)


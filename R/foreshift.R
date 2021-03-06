#' Shift demand to the future
#' 
#'\tabular{rrrrr}{
#'   21.0 \tab 6 \tab 160 \tab 110 \tab 3.90\cr
#'   21.0 \tab 6 \tab 160 \tab 110 \tab 3.90\cr
#'   22.8 \tab 4 \tab 108 \tab  93 \tab 3.85\cr
#'   21.4 \tab 6 \tab 258 \tab 110 \tab 3.08\cr
#'   18.7 \tab 8 \tab 360 \tab 175 \tab 3.15
#' }
#'
#' @param input_mtx list of flexible matrices
#' @param flex_step list of flexibility steps
#' @param cap list of cap per object
#' @param input_vct list of input vectorized
#' @param fit formula to calulate the fit of the flexible demand
#'
#' @return object 
#' \describe{
#'   \item{demand fixed}{First item}
#'   \item{demand flex}{Second item}
#'   \item{fit curve initial}{Second item}
#'   \item{fit curve final}{Second item}   
#' }
#' @export
#' @examples
#' 1+1
foreshift <- function(input_mtx,
                      flex_step,
                      cap = NULL,
                      input_vct,
                      fit = ~ 1*.demand
){
  
  # You can also pass the formula as a character
  if (is.character(fit)) fit <- as.formula(fit)

  # Make all the input a list of matrices
  # that can be made a cube ("stacked")
  format_mtx_steps <- function(matrices, steps) {
    listify <- function(input) {
      if (is.list(input)) {return(input)}
      list(input)
    }

    matrices <- listify(matrices)
    steps <- listify(steps)

    mapply(formatFlexSteps,
           matrices,
           steps,
           MoreArgs = list(max_step = max(sapply(steps, max))),
           SIMPLIFY = FALSE
    )
  }
  mtx_list <- format_mtx_steps(input_mtx, flex_step)


  # .demand is a keywork in the fit formula, as it is
  # .demand_fixed passed into input_vct

  if (".demand_fixed" %in% names(input_vct)) {
    input_vct[[".demand"]] <- input_vct[[".demand_fixed"]]
  } else {
    input_vct[[".demand"]] <- rep(0, nrow(mtx_list[[1]]))
  }

  # .cap_flex and .cap_demand. Both are important.
  # if (!(".cap_flex" %in% names(input_vct))) {
  #   input_vct[[".cap_flex"]] <- rep(0, nrow(mtx_list[[1]]))
  # }

  # if (!(".cap_demand" %in% names(input_vct))) {
  #   input_vct[[".cap_demand"]] <- rep(0, nrow(mtx_list[[1]]))
  # }
  
  # the list input_vct is instead an environment
  env_fit <- list2env(input_vct, parent = safe_env)
  ## input verification
  # stopifnot(
  #   # not all the variables for the fit formula are passed
  #   # to the input_vct list
  #   all(all.vars(fit) %in% names(env_fit)),
  #   # not all the variables in the fit environment have
  #   # the same length as the matrix passed
  #   all(sapply(names(env_fit),
  #              function(x){
  #                length(env_fit[[x]]) == nrow(input_mtx)
  #                })
  #       ),
  #   # the length of the flex_step does not match the column
  #   # of the flex demand
  #   ncol(input_mtx) == length(flex_step)
  #   )
  ##
  
  # aux_demand <- ~ 1*.demand

  call_fit <- fit[[2]]
  env_aux = new.env(parent = safe_env)
  call_aux <- (~ 1*.demand)[[2]]
  
  ## process cap: the NULL become zero
  
  cap_charge <- vapply(cap, function(x){ifelse(is.null(x), 0, x)}, numeric(1))
  
  sol <- foreShiftCpp(mtx_list = mtx_list,
                      cap_charge = cap_charge,
                      env_fit = env_fit,
                      call_fit = call_fit,
                      env_aux = env_aux,
                      call_aux = call_aux)
  
  sol
  }

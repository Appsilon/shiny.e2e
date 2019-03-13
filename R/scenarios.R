#' Edit shiny environment file
#'
#' @description While testing local shiny app, you may want to run it on separate environment.
#'    The function opens the file responsible for setting up environment - you can include here
#'    required options and environment variables that are used during run_scenario function run.
#' @param config_dir Relative path to structure config file (config.yaml) directory.
#' @export
edit_test_env <- function(config_dir = getOption("config_dir", default = default_config_dir)) {
  test_env_path <- yaml::read_yaml(glue::glue("{config_dir}/{config_name}"))$test_env
  file.edit(test_env_path)
}

#' Define scenario basing on template
#'
#' @param label Scenario id.
#' @param config_dir Relative path to structure config file (config.yaml) directory.
#' @param url URL to application on which tests should be performed.
#' @param onBeforeScriptcookiePath,referenceUrl,readyEvent,readySelector,delay,hideSelectors,removeSelectors,onReadyScript,keyPressSelectors,hoverSelector,hoverSelectors,clickSelector,clickSelectors,postInteractionWait,scrollToSelector,selectors,selectorExpansion,misMatchThreshold,requireSameDimensions
#'    Other parameters defining scenario. Please check https://github.com/garris/BackstopJS for details.
#' @export
define_scenario <- function(label, config_dir = getOption("config_dir", default = default_config_dir),
                            onBeforeScript = NULL,
                            cookiePath = NULL, referenceUrl = NULL, readyEvent = NULL, readySelector = NULL,
                            delay = 1000, hideSelectors = NULL, removeSelectors = list(), onReadyScript = NULL,
                            keyPressSelectors = NULL, hoverSelector = NULL, hoverSelectors = NULL,
                            clickSelector = NULL, clickSelectors = NULL, postInteractionWait = NULL,
                            scrollToSelector = NULL, selectors = list("document"),
                            selectorExpansion = NULL, misMatchThreshold = 0.2, requireSameDimensions = NULL) {

  params <- as.list(environment()) %>%
    purrr::keep(~ !is.null(.))
  params$config_dir <- NULL

  config <- yaml::read_yaml(glue::glue("{config_dir}/{config_name}"))

  if (is.null(onReadyScript)) {
    params$onReadyScript <- glue::glue("{label}.js")
  }
  # (todo) Check if label currently exists
  scenarios_list <- get_scenarios(config_dir)
  if (length(scenarios_list) == 0) {
    scenarios_list <- list(params)
  } else {
    scenarios_list <- append(scenarios_list, list(params))
  }
  write_scenarios(scenarios_list, config_dir)

  make_engine_script(label, config_dir)
}

make_engine_script <- function(label, config_dir = getOption("config_dir", default = default_config_dir)) {
  config <- yaml::read_yaml(glue::glue("{config_dir}/{config_name}"))
  scenario_path <- glue::glue("{config$dir}/engine_scripts/{label}.js")
  file.copy(system.file("scenario_template.js", package = "shiny.e2e"), scenario_path)
  file.edit(scenario_path)
}

get_scenarios <- function(config_dir) {
  jsonlite::fromJSON(glue::glue("{config_dir}/{scenarios_list_file}"), simplifyVector = FALSE)
}

write_scenarios <- function(scenarios_list, config_dir) {
  jsonlite::write_json(scenarios_list, glue::glue("{config_dir}/{scenarios_list_file}"), simplifyVector = FALSE, auto_unbox = TRUE)
}

#' Edit scenario
#'
#' @param label Scenario id.
#' @param config_dir Relative path to structure config file (config.yaml) directory.
#' @export
edit_scenario <- function(label, config_dir = getOption("config_dir", default = default_config_dir)) {
  config <- jsonlite::fromJSON(config_dir)
  file.edit(glue::glue("{config$dir}/engine_scripts/{label}.js"))
}

#' Perform test or create reference screenshot
#'
#' @param label Scenario id. If NULL then all defined scenarios are used.
#' @param action "test" for performing test (default), "reference" for creating reference screenshot
#' @param app_path Relative path for Shiny App directory (used only for scenarios testing local app)
#' @param port Port in which local Shiny App should be run.
#' @param app_url External url of the Shiny App
#' @param config_dir Relative path to structure config file (config.yaml) directory.
#' @param dosplay_report If TRUE, test report will be opened.
#' @param run_time Time in seconds needed for application run.
#' @param viewports,asyncCaptureLimit,engineFlags,engineOptions,report,debug
#'    Parameters specifying browser and test environment. Check https://github.com/garris/BackstopJS for details.
#' @export
run_scenarios <- function(label = NULL,
                          action = "test",
                          app_path = "app.R",
                          port = default_port,
                          config_dir = getOption("config_dir", default = default_config_dir),
                          display_report = FALSE, run_time = 30,
                          viewports = list(list(name = "mac_screen", width = 1920, height = 1080)),
                          asyncCaptureLimit = 5,
                          engineFlags = list(), engine = "puppeteer",
                          engineOptions = list(
                            ignoreHTTPSErrors = TRUE,
                            headless = TRUE,
                            args = list("--no-sandbox", "--disable-setuid-sandbox")
                          ),
                          report = list("CI"), debug = FALSE) {
  params <- as.list(environment()) %>%
    purrr::keep(~ !is.null(.))

  config = yaml::read_yaml(glue::glue("{config_dir}/{config_name}"))
  paths = list(
    bitmaps_reference = glue::glue("{config$dir}/reference_screenshots"),
    bitmaps_test = glue::glue("{config$dir}/test_screenshots"),
    engine_scripts = glue::glue("{config$dir}/engine_scripts"),
    html_report = glue::glue("{config$dir}/report/html_report"),
    ci_report = glue::glue("{config$dir}/report/ci_report")
  )

  scenarios <- jsonlite::fromJSON(glue::glue("{config$dir}/{scenarios_list_file}"), simplifyVector = FALSE)

  path_is_local <- function(path) {
    is.null(httr::parse_url(path)$hostname)
  }

  if (path_is_local(app_path)) {
    app_url <- glue::glue("http://{ getOption('shiny.host', '127.0.0.1') }:{ port }")
  } else {
    app_url <- app_path
  }

  add_url <- function(x, url) {
    x$url <- url
    x
  }
  scenarios <- purrr::modify(scenarios, add_url, url = app_url)


  if (!is.null(label)) {
    scenarios <- scenarios %>%
      purrr::keep(~ .$label %in% label)
    params$label <- NULL
  }
  params$paths <- paths
  params$config_dir <- NULL
  params$scenarios <- scenarios
  params$id <- config$id
  params$action <- NULL
  params$app_path <- NULL

  source_env <- ""
  if (file.exists(config$test_env)) {
    source_env <- glue::glue("source('{config$test_env}');")
  }

  if (path_is_local(app_path)) {
    message(glue::glue("Running app locally on port: {port}"))
    pid_file <- tempfile("pid")
    file.create(pid_file)
    system(
      sprintf("Rscript -e \"%s shiny::runApp('%s', port = %s)\" & echo $! > %s", source_env, app_path, port, pid_file),
      wait = FALSE)
    pid <- readLines(pid_file)
    message(glue::glue("Shiny process PID: {pid}"))
    message("Give application time to run..")
    Sys.sleep(run_time)
  }

  reference_filter = ""
  if (action == "reference" && (length(label) == 1)) {
    reference_filter <- glue::glue("--filter={label}")
  }

  writeLines(sprintf("module.exports = %s", jsonlite::toJSON(params, pretty = TRUE, auto_unbox = TRUE)),
             con = glue::glue("{config$dir}/config.js"))
  system(glue::glue("backstop {action} --configPath={config$dir}/config.js {reference_filter}"), wait = TRUE)
  if (path_is_local(app_path)) {
    system(sprintf("kill -9 %s", pid))
  }

  if (display_report && action == "test") {
    open_report(config$dir)
  }

}
#' Open test report
#'
#' @param config_dir Relative path to structure config file (config.yaml) directory.
#' @export
open_report <- function(config_dir) {
  if (R.version$os == "msys") {
    start_browser <- "start"
  } else {
    start_browser <- "xdg-open"
  }

  system(glue::glue("{start_browser} {config_dir}/report/html_report/index.html"))
}

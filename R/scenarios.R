#' @export
edit_test_env <- function(config_dir = getOption("config_dir", default = default_config_dir)) {
  test_env_path <- yaml::read_yaml(glue::glue("{config_dir}/{config_name}"))$test_env
  file.edit('test_env_path')
}

#' @export
define_scenario <- function(label, config_dir = getOption("config_dir", default = default_config_dir),
                            url = glue::glue("http://127.0.0.1:{default_port}"), onBeforeScript = NULL,
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
  file.copy(system.file("scenario_template.js", package = "end2end"), scenario_path)
  file.edit(scenario_path)
}

get_scenarios <- function(config_dir) {
  jsonlite::fromJSON(glue::glue("{config_dir}/{scenarios_list_file}"), simplifyVector = FALSE)
}

write_scenarios <- function(scenarios_list, config_dir) {
  jsonlite::write_json(scenarios_list, glue::glue("{config_dir}/{scenarios_list_file}"), simplifyVector = FALSE, auto_unbox = TRUE)
}

#' @export
edit_scenario <- function(label, config_dir = getOption("config_dir", default = default_config_dir)) {
  config <- jsonlite::fromJSON(config_dir)
  file.edit(glue::glue("{config$dir}/engine_scripts/{label}.js"))
}

#' @export
run_scenarios <- function(label = NULL, action = "test", config_dir = getOption("config_dir", default = default_config_dir),
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

  scenarios <- jsonlite::fromJSON(glue::glue("{config$dir}/{scenarios_list_file}"))

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

  pid_file <- tempfile("pid")
  file.create(pid_file)
  system(sprintf("Rscript -e \"shiny::runApp('app.R', port = 8888)\" & echo $! > %s", pid_file), wait = FALSE)
  pid <- readLines(pid_file)

  writeLines(sprintf("module.exports = %s", jsonlite::toJSON(params, pretty = TRUE, auto_unbox = TRUE)),
             con = glue::glue("{config$dir}/config.js"))
  system(glue::glue("backstop {action} --configPath={config$dir}/config.js"), wait = TRUE)
  system(sprintf("kill -9 %s", pid))
}

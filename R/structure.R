prepare_config <- function(id, dir, env_script, settings) {
  dir.create(file.path(dir, id), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, id, "engine_scripts"), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, id, "reference_screenshots"), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, id, "test_screenshots"), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, id, "report/html_report"), showWarnings = FALSE, recursive = TRUE)
  dir.create(file.path(dir, id, "report/ci_report"), showWarnings = FALSE, recursive = TRUE)
  file.copy(system.file(scenarios_list_file, package = "shiny.e2e"), file.path(dir, id, scenarios_list_file))
  if (settings) {
    file.create(file.path(dir, id, settings_script), showWarnings = FALSE)
  }
  if (env_script) {
    file.create(file.path(dir, id, test_env_script), showWarnings = FALSE)
  }
  options("config_dir" = glue::glue("{dir}/{id}"))
  yaml::write_yaml(
    x = list(id = id, dir = file.path(dir, id),
             test_env = file.path(dir, id, test_env_script), settings = file.path(dir, id, settings_script)),
    file = glue::glue("{dir}/{id}/{config_name}")
  )
}

update_action <- function(dir) {
  file.copy(system.file("action.js", package = "shiny.e2e"), dir)
}

#' Create structure for tests
#'
#' @param dir Directory in which structure should be created
#' @param id Subdirectory of dir. dir/id is the final directory for tests structure.
#' @param env_script If TRUE, then empty R script for setting local Shiny App environment is created. Not used yet.
#' @param settings If TRUE, then settings template for browser and test environment is created. Not used yet.
#' @export
make_structure <- function(dir = "tests/end2end", id = "app", env_script = FALSE,
                           settings = FALSE) {
  prepare_config(id, dir, env_script, settings)
  config = yaml::read_yaml(glue::glue("{dir}/{id}/{config_name}"))
  update_action(config$dir)
}

% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/scenarios.R
\name{edit_test_env}
\alias{edit_test_env}
\title{Edit shiny environment file}
\usage{
edit_test_env(config_dir = getOption("config_dir", default =
  default_config_dir))
}
\arguments{
\item{config_dir}{Relative path to structure config file (config.yaml) directory.}
}
\description{
While testing local shiny app, you may want to run it on separate environment.
   The function opens the file responsible for setting up environment - you can include here
   required options and environment variables that are used during run_scenario function run.
}

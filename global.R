## Load packages
library(covid19br)
library(dplyr)
library(tidyr)
library(httr)
library(lubridate)
library(knitr)
library(shiny)
library(shinyjs)
library(plotly)
library(shinythemes)
library(shinycssloaders)
library(shinyWidgets)
library(shinyBS)
library(markdown)
library(stringr)

## Load local functions
source("R/utils.R")
dir.create("cache", showWarnings = FALSE)

## Define font to be used later
f1 <- list(family = "Arial", size = 10, color = "rgb(30, 30, 30)")

## colors for observed data
blu <- 'rgb(100, 140, 240)'
dblu <- 'rgb(0, 0, 102)'
red <- 'rgb(200, 30, 30)'
dred <- 'rgb(100, 30, 30)'

##-- DATA SOURCES ----
## setup data source (Johns Hopkins)- GLOBAL
baseURL <- "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series"

allData <- loadData("time_series_covid19_confirmed_global.csv", "CumConfirmed") %>%
  inner_join(
    loadData("time_series_covid19_deaths_global.csv", "CumDeaths"),
    by = c("Province/State", "Country/Region", "date")
  ) 

allData$`Country/Region` <- recode(allData$`Country/Region`, US = "United States of America", `Korea, South` = "South Korea")

countries <- sort(unique(allData$`Country/Region`))

## Setup data source (MSaude/BR)- BRAZIL
# baseURL.BR = "https://raw.githubusercontent.com/belisards/coronabr/master/dados"
# baseURL.BR = "https://covid.saude.gov.br/assets/files/COVID19_"
baseURL.BR <- "https://raw.githubusercontent.com/covid19br/covid19br.github.io/master/dados"
# baseURL.BR <- "https://raw.githubusercontent.com/CovidLP/app_COVID19/master/R/STAN"
brData <- loadData.BR("EstadosCov19.csv")

## Setup data source - US
baseURL.US = "https://raw.githubusercontent.com/CSSEGISandData/COVID-19/master/csse_covid_19_data/csse_covid_19_time_series"

covid19_confirm <- loadData.US_cases("time_series_covid19_confirmed_US.csv", "confirmed")
covid19_deaths <- loadData.US_deaths("time_series_covid19_deaths_US.csv", "deaths")
usData <- left_join(covid19_confirm,covid19_deaths, by=c('state','date')) %>%
  rename(`Province/State`=state, CumConfirmed=confirmed, CumDeaths=deaths) %>%
  select(`Province/State`, CumConfirmed, CumDeaths, date)

##-- LOAD PREDICTION RESULTS ----
files <- readfiles.repo()
aux <- sub(pattern = '(\\_n.rds$)|(\\_d.rds$)', replacement = '', x = files)

## List of countries for SHORT TERM prediction
countries_STpred <- sort(unique(
  unlist(lapply(strsplit(aux, "_"), function(x) x[1]))))
countries_STpred_orig <- gsub("-", " ", countries_STpred)

## List of Brazil's states
statesBR_STpred <- unique(unlist(lapply(strsplit(aux, "_"), function(x) if(x[1] == "Brazil") return(x[2]))))
statesBR_STpred[is.na(statesBR_STpred)] <- "<all>"
statesBR_STpred <- sort(statesBR_STpred)

## List of countries for LONG TERM prediction
countries_LTpred_orig <- countries_STpred_orig

## List of Brazil's states - LONG TERM
statesBR_LTpred <- statesBR_STpred

##-- List of countries to hide new cases
# hide_countries_nc <- list('Australia', 'Belgium', 'Canada', 'Greece', 'Japan', 'Korea, South',
# 'Netherlands', 'Peru', 'Poland', 'Portugal', 'Spain', 'Switzerland',
# 'Uruguay', 'US')
hide_countries_nc <- list()

##-- List of countries to hide deaths
# hide_countries_d <- list('Australia', 'US')
hide_countries_d <- list()

## Read RDS files from github repository
githubURL <- "https://github.com/CovidLP/app_COVID19/raw/master/STpredictions"

##-- Date format
dt_format <- "%d/%b/%y"
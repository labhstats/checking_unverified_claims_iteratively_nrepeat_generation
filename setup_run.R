# Script to set up the R environment. Most can be done manually via Rstudio also.

#Install R packages that are used so far...

install.packages("pdftools", dependencies = TRUE)
install.packages("tidyllm", dependencies = TRUE)

require(pdftools)
require(tidyllm)

install.packages("dplyr", dependencies = TRUE)
install.packages("stringr", dependencies = TRUE)
install.packages("purrr", dependencies = TRUE)

require(dplyr)
require(stringr)
require(purrr)

##
# Start Ollama before running the next ones, if appropriate.
#
##

#Install a model of choice into the already installed and running Ollama server (default)
# https://cran.r-project.org/web/packages/tidyllm/tidyllm.pdf
#ollama_download_model("cogito:8b") 
#ollama_download_model("ministral-3:8b") 
#ollama_download_model("ministral-3:3b")
#ollama_download_model("bge-m3:567m") 

#Delete with, without going into command lines, e.g.
# ollama_delete_model("cogito:8b")

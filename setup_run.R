# Script to set up the R environment. Most can be done manually via Rstudio also :)

#Install necessary R packages

install.packages("pdftools", dependencies = TRUE)
install.packages("tidyllm", dependencies = TRUE)

require(pdftools)
require(tidyllm)

##
# Start Ollama before running the next ones.
#
##

#Install a model of choice into the already installed and running Ollama server (default)
# https://cran.r-project.org/web/packages/tidyllm/tidyllm.pdf
ollama_download_model("cogito:8b") 

#Delete with, without going into command line
# ollama_delete_model("cogito:8b")

## PS:
# Consider using models that fit your scope, resources, and that have committed to 
# and contributed to open source / weight LLMs, and which also are seemingly aligned politically.

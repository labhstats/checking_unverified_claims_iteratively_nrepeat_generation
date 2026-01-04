# app.R
# Simple Shiny app, limited options in UI (for now)

# GPT-5.1 generated... and simplified manually as guided by GPT...

library(shiny)
#library(DT) #Commented away uses?

# Your existing setup / functions --------------------------
# (Adjust paths if your filenames differ)

#Assumes that files are in same level or folder / Rproject to work.
source("checking_unverified_claims.R")       # contains checking_unverified_claims via llm()
source("iteratively_with_nrepeat_generation.R")

# ---- Wrapper around your main iterative function --------
# This is the only place that "knows" about the nested-list input format.
run_iterative_check <- function(
    claims_text,
    pdf_path,
    n_repeat = 3,
    iter_in_cuc_prompt = NA,
    iter_use_model = "cogito:8b", #Change this before running the app?
    iter_use_context = 20000,
    iter_use_temp = 0.3,
    use_custom_server_url = "http://localhost:11434",
    bool_do_embed = FALSE,
    embed_model_use = "bge-m3:567m",
    top_k_embedevidence = 2,
    chunk_size_use = 300
) {
  # Split claims into vector (one per line)
  claims_vec <- unlist(strsplit(claims_text, "\n"))
  claims_vec <- trimws(claims_vec)
  claims_vec <- claims_vec[nzchar(claims_vec)]
  
  if (length(claims_vec) == 0) {
    stop("No non-empty claims found.")
  }
  if (is.null(pdf_path) || is.na(pdf_path)) {
    stop("No valid PDF path supplied.")
  }
  
  # Build nested list structure expected by iteratively_with_nrepeat_generation()
  # Each element: list(claim = "<claim>", source_s = c(pdf_path1, pdf_path2, ...))
  # Here we use the SAME uploaded PDF for all claims.
  in_nested_list <- lapply(claims_vec, function(cl) {
    list(
      claim    = cl,
      source_s = c(pdf_path)   # could be a vector of multiple PDFs if you extend the UI
    )
  })
  
  # Call your engine
  out_list <- iteratively_with_nrepeat_generation(
    in_nested_list   = in_nested_list,
    n_repeat         = n_repeat,
    iter_in_cuc_prompt = iter_in_cuc_prompt,
    iter_use_model   = iter_use_model,
    iter_use_context = iter_use_context,
    iter_use_temp    = iter_use_temp,
    iter_in_fun_model = ollama_chat,
    iter_use_ollama_server = use_custom_server_url,
    iter_do_embed_bool = bool_do_embed,
    iter_use_embed_model = embed_model_use,
    iter_top_k_evidence = top_k_embedevidence,
    iter_use_chunk_size = chunk_size_use,
    iter_timer_bool  = TRUE
  )
  
  # out_list is a list of long character strings (one per claim).
  # For the table, we make a small data.frame with a preview column.
  raw_vec <- as.character(out_list)
  
  preview <- vapply(
    raw_vec,
    FUN = function(x) {
      # single-line preview, truncated
      x1 <- gsub("[\r\n]+", " ", x)
      if (nchar(x1) > 200) substr(x1, 1, 200) else x1
    },
    FUN.VALUE = character(1)
  )
  
  results_df <- data.frame(
    claim   = claims_vec,
    preview = preview,
    stringsAsFactors = FALSE
  )
  
  list(
    results_df = results_df,
    raw_list   = raw_vec
  )
}

# ----------------- UI ------------------------------------
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      #raw_output {
        white-space: pre-wrap;      /* wrap long lines */
        word-wrap: break-word;      /* break long words if needed */
      }
    "))
  ),
  
  titlePanel("Checking Unverified Claims (Iteratively / N-repeat Generation)"),
  
  sidebarLayout(
    sidebarPanel(
      textAreaInput(
        "claims",
        "Claims or sentences to verify (one per line, newline with Enter):",
        height = "150px",
        placeholder = "Example:\nThe intervention improved outcomes by 20%...\nThe study included 300 participants...\nPotatoes are pretty good..."
      ),
      
      fileInput(
        "pdf_file",
        "Upload source PDF, e.g. citation referenced at end of claim or sentence:",
        accept = ".pdf"
      ),
      
      numericInput(
        "n_repeat",
        "Number of repeat generations per claim (n_repeat, 1 to 20):",
        value = 1,
        min = 1,
        max = 20,
        step = 1
      ),
      
      textInput("use_model", "Model to do verification:",
                value = "ministral-3:8b",
                placeholder = "Specify available model to use..."),
      
      numericInput("use_context", "Context size (1000 - 20000), i.e. model working memory:",
                   value = 10000,
                   min = 1000,
                   max = 20000,
                   step = 1000
                   ),
      
      numericInput("use_temperature", "Temperature (0 - 2) less to more random model:",
                   value = 0.3,
                   min = 0,
                   max = 2, #Limits per tidyllm
                   step = 0.1
      ),
      
      radioButtons("embed_option", "Full source PDF context attached, or embed partial document context:",
                   choices = c("Use full (accurate, slower, and context expensive)" = "full",
                               "Use embed (faster, less accurate, and less context heavy)" = "embed"),
                   selected = "full"), #Is the embed method implemented very good? idk, but it is faster...
      
      textInput("embed_use_model", "Model for embedding:",
                value = "bge-m3:567m",
                placeholder = "Specify available embed model to use..."),
      
      numericInput("top_k", "Top k embed chunks (Use k most <similar*> of source PDF to check claim):",
                   value = 2,
                   min = 1,
                   max = 10,
                   step = 1
      ),
      
      numericInput("size_chunk", "Chunk size per k part used in embedding (10% of chunk size is overlap):",
                   value = 300,
                   min = 200,
                   max = 1000,
                   step = 100
      ),
      
      textInput("custom_server_url", "Custom Server URL (do not change if same PC is host):",
                value = "http://localhost:11434", #Default value according to Qwen2.5-coder:7b
                placeholder = "Enter your custom server URL here..."),
      
      # If you later want model / temperature controls, you can add inputs here
      # and pass them into run_iterative_check().
      
      actionButton("run", "Check unverified claim(s)", class = "btn-primary"),
      
      br(), br(),
      downloadButton("download_txt", "Download check(s) as .txt"),
      
      br(), br(),
      verbatimTextOutput("status")
    ),
    
    mainPanel(
      #h3("Results (per claim)"),
      #DTOutput("results_table"),
      #br(),
      h4("Raw explanation / evidence / verdict"),
      verbatimTextOutput("raw_output")
    )
  )
)

# ----------------- Server --------------------------------
server <- function(input, output, session) {
  
  status_text <- reactiveVal("Idle")
  results_store <- reactiveVal(NULL)  # <- new: to keep last run's results
  
  # Initial empty outputs
  output$status <- renderText(status_text())
  # output$results_table <- renderDT({
  #   datatable(data.frame(), options = list(pageLength = 5))
  # })
  output$raw_output <- renderPrint({ "No results yet." })
  
  output$download_txt <- downloadHandler(
    filename = function() {
      paste0("claim_check_results_", format(Sys.time(), "%Y%m%d_%H%M%S"), ".txt")
    },
    content = function(file) {
      res <- results_store()
      
      if (is.null(res)) {
        writeLines("No results available. Run a check first.", con = file)
        return(NULL)
      }
      
      # res is the list we returned in run_iterative_check():
      #   res$results_df (with claims)
      #   res$raw_list   (full text per claim)
      lines <- vapply(
        seq_along(res$raw_list),
        FUN = function(i) {
          paste0(
            "===== Claim ", i, " =====\n",
            #res$results_df$claim[i], "\n\n",
            res$raw_list[[i]], "\n",
            "========================================\n"
          )
        },
        FUN.VALUE = character(1)
      )
      
      writeLines(lines, con = file)
    }
  )
  
  observeEvent(input$run, {
    req(input$claims)
    req(input$pdf_file)
    
    status_text("Running verification... (make sure Ollama is already running)")
    output$status <- renderText(status_text())
    
    claims_text <- input$claims
    pdf_path    <- input$pdf_file$datapath
    n_repeat    <- input$n_repeat
    use_context <- input$use_context
    use_model <- input$use_model
    use_temperature <- input$use_temperature
    custom_server_url <- input$custom_server_url
    embed_option <- input$embed_option
    embed_use_model <- input$embed_use_model
    use_top_k <- input$top_k
    use_chunk_size <- input$size_chunk
    
    res <- NULL
    err <- NULL
    
    if(embed_option == "full"){ #Change to something sensible from a code perspective...
      embed_option = FALSE
    }else{
      embed_option = TRUE
    }
    
    tryCatch(
      {
        res <- run_iterative_check(
          claims_text       = claims_text,
          pdf_path          = pdf_path,
          n_repeat          = n_repeat,
          iter_use_context = use_context,
          iter_use_model = use_model,
          iter_use_temp = use_temperature,
          use_custom_server_url = custom_server_url,
          bool_do_embed = embed_option,
          embed_model_use = embed_use_model,
          top_k_embedevidence = use_top_k,
          chunk_size_use = use_chunk_size,
          # You can thread through custom prompt/model/temp here if you like
        )
      },
      error = function(e) {
        err <<- e
      }
    )
    
    if (!is.null(err)) {
      status_text(paste("Error during verification:", err$message))
      output$status <- renderText(status_text())
      return(NULL)
    }
    
    status_text("Done.")
    output$status <- renderText(status_text())
    
    results_store(res)
    
    # Table output: one row per claim with a short preview
    # output$results_table <- renderDT({
    #   datatable(
    #     res$results_df,
    #     options = list(pageLength = 5, scrollX = TRUE)
    #   )
    # })
    
    # Raw output: print full big strings, separated by claim
    output$raw_output <- renderPrint({
      for (i in seq_along(res$raw_list)) {
        cat("===== Claim", i, "=====\n\n")
        #cat(res$results_df$claim[i], "\n\n")
        cat(res$raw_list[[i]], "\n\n")
        cat("========================================\n\n")
      }
    })
  })
}

shinyApp(ui, server,options = list(height = 1440))

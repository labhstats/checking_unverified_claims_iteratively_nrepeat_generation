#Lowest level validate claim function

checking_unverified_claims_llm = function(in_claim,
                                          in_pdf_path,
                                          in_cuc_prompt = NA,
                                          use_model = "cogito:8b",
                                          use_context = 20000,
                                          use_temp = 0.5,
                                          in_fun_model = ollama_chat, #For different API calls via tidyllm, i.e. function as input
                                          use_ollama_server = "http://localhost:11434",
                                          do_embed_bool = FALSE,
                                          use_embed_model = "bge-m3:567m",
                                          use_chunk_size = 300,
                                          top_k_embedevidence = 2,
                                          sub_embed_batch_size = 1, #Omitted for now...
                                          timer_bool = TRUE){
  
  use_chunk_overlap = round(use_chunk_size/10, #Just do automatically...
                            digits = 0)
  
  #Packages...
  require(tidyllm)
  require(pdftools)
  
  #PDF path check...
  if(is.na(in_pdf_path)){
    pdf_na_text = "PDF path was NA..."
    print(pdf_na_text)
    
    return("missing_sources") #Not optimal...
  }
  
  if(!do_embed_bool){
    
    print("-- Do full doc context in prompt...")
    
    start_time = 0
    
    if(timer_bool){
      start_time = Sys.time()
    }
    
    # Mold the "in_claim" and "in_cuc_prompt" into "use_molded_text"
    use_molded_text = ""
    
    if(is.na(in_cuc_prompt)){
      
      use_molded_text <- paste( #Chat-GPT 5.1 Auto suggested 100% as of 2nd december 2025...
        "You are a careful research assistant that checks whether a claim is supported by the content of a document.\n\n",
        
        "You will be given one claim or sentence from the document.\n",
        "Your task is to determine how well this claim is supported by the document's content.\n\n",
        
        "Use ONLY the information contained in the document that you have access to.\n",
        "Do NOT use outside knowledge, assumptions, or prior world knowledge.\n\n",
        
        "Support categories:\n",
        " - \"fully_supported\": The main factual content of the claim is clearly stated or clearly follows from the document.\n",
        " - \"partially_supported\": Parts of the claim are supported, but important elements are missing, unclear, or implied but not stated explicitly.\n",
        " - \"not_supported\": The document does not contain information that supports the claim.\n",
        " - \"contradicted\": The document clearly states the opposite of the claim.\n\n",
        
        "In addition:\n",
        " - Identify the most relevant evidence sentence(s) from the document.\n",
        " - If no evidence exists, return an empty string for the evidence.\n\n",
        
        "Return ONLY a JSON object in the following format:\n",
        "{\n",
        "  \"explanation\": \"<brief explanation for your verdict>\"\n",
        "  \"evidence_sentence\": \"<the most relevant matching sentence or empty string>\",\n",
        "  \"verdict\": \"fully_supported | partially_supported | not_supported | contradicted\",\n",
        "}\n\n",
        
        "CLAIM TO CHECK:\n",
        in_claim," \n",
        "DOCUMENT ATTACHED: \n",
        sep = "")
      
    }else{
      
      use_molded_text = paste(in_cuc_prompt,
                              in_claim,
                              sep = "")
      
    }
    
    #Do the LLM...
    out_single_chat <- llm_message(.llm = use_molded_text,
                                   .pdf = in_pdf_path) |>
      in_fun_model(.model = use_model,
                   .num_ctx = use_context,
                   .temperature = use_temp,
                   .ollama_server = use_ollama_server)
    
    if(timer_bool){
      end_time = Sys.time()
      
      print(end_time - start_time)
    }
    
    return(out_single_chat)
    
  }else{
    
    ## EMBED run
    print("-- Do partial embedded doc context in prompt...")
    
    ## Packages
    
    library(dplyr)
    library(stringr)
    library(purrr)
    
    start_time = 0
    
    if(timer_bool){
      start_time = Sys.time()
    }
    
    #Load pdf text and collapse into one string
    
    pages <- pdf_text(in_pdf_path)
    doc <- paste(pages, collapse = "\n")
    
    # Helper functions... 
    
    approx_tokens <- function(text) {
      str_count(text, "\\S+") * 0.75
    }
    
    chunk_text <- function(text, target_tokens = use_chunk_size, overlap_tokens = use_chunk_overlap) {
      
      sentences <- str_split(text, "(?<=[.!?])\\s+", simplify = TRUE) |> as.vector()
      
      chunks <- list()
      current <- ""
      current_tokens <- 0
      
      for (s in sentences) {
        s_tokens <- approx_tokens(s)
        
        if (current_tokens + s_tokens > target_tokens) {
          chunks <- append(chunks, current)
          
          overlap_words <- tail(str_split(current, "\\s+")[[1]], overlap_tokens)
          current <- paste(overlap_words, collapse = " ")
          current_tokens <- approx_tokens(current)
        }
        
        current <- paste(current, s)
        current_tokens <- current_tokens + s_tokens
      }
      
      chunks <- append(chunks, current)
      chunks
    }
    
    # Use helper functions to chunk collapsed string of pages
    
    chunks <- chunk_text(doc)
    
    #print(length(chunks))
    
    evidence <- tibble(
      chunk_id = seq_along(chunks),
      text = chunks
    )
    
    #print(head(evidence))
    
    # Embed helper functions...
    embed_non_batch <- function(texts, embed_server, model) {
      purrr::map(texts, ~ {
        emb <- ollama_embedding(
          .input = .x,
          .model = model,
          .ollama_server = embed_server
        )
        # Extract the embedding vector
        emb$embeddings[[1]]
      })
    }
    
    
    # Use embed helper functions...
    evidence_embeddings <- embed_non_batch(
      texts = evidence$text,
      model = use_embed_model,
      embed_server = use_ollama_server
    )
    
    #print(evidence_embeddings)
    
    evidence_index <- evidence |>
      mutate(embedding = evidence_embeddings)
    
    #print(evidence_index)
    
    #Similarity helper functions...
    cosine_sim <- function(a, b) {
      sum(a * b) / (sqrt(sum(a^2)) * sqrt(sum(b^2)))
    }
    
    retrieve_evidence <- function(claim_embedding, index, k = top_k_embedevidence) {
      index |>
        mutate(similarity = map_dbl(embedding, cosine_sim, b = claim_embedding)) |>
        arrange(desc(similarity)) |>
        slice_head(n = k)
    }
    
    #Embed the claim...
    claim_embedded <- ollama_embedding(
      .input = in_claim,
      .model = use_embed_model,
      .ollama_server = use_ollama_server)
    
    #Retrieve "relevant" text and collapse into prompt ready context(?)
    
    #print(claim_embedded)
    
    claim_embedded = claim_embedded[["embeddings"]][[1]]
    
    #print(claim_embedded)
    
    retrieved <- retrieve_evidence(claim_embedding = claim_embedded, index = evidence_index)
    
    context <- paste(
      paste0("[", retrieved$chunk_id, "] ", retrieved$text),
      collapse = "\n\n"
    )
    
    
    if(timer_bool){
      end_time = Sys.time()
      
      print("Embed duration...")
      print(end_time - start_time)
    }
    
    print("Final verification based on retrieved context...")
    
    #
    # Repeat of non-chunk / embedded pipeline
    #
    
    # Mold the "in_claim" and "in_cuc_prompt" into "use_molded_text"
    use_molded_text = ""
    
    if(is.na(in_cuc_prompt)){
      
      use_molded_text <- paste( #Chat-GPT 5.1 Auto suggested 100% as of 2nd december 2025...
        "You are a careful research assistant that checks whether a claim is supported by the content of a document.\n\n",
        
        "You will be given one claim or sentence from the document.\n",
        "Your task is to determine how well this claim is supported by the document's content.\n\n",
        
        "Use ONLY the information contained in the document that you have access to.\n",
        "Do NOT use outside knowledge, assumptions, or prior world knowledge.\n\n",
        
        "Support categories:\n",
        " - \"fully_supported\": The main factual content of the claim is clearly stated or clearly follows from the document.\n",
        " - \"partially_supported\": Parts of the claim are supported, but important elements are missing, unclear, or implied but not stated explicitly.\n",
        " - \"not_supported\": The document does not contain information that supports the claim.\n",
        " - \"contradicted\": The document clearly states the opposite of the claim.\n\n",
        
        "In addition:\n",
        " - Identify the most relevant evidence sentence(s) from the document.\n",
        " - If no evidence exists, return an empty string for the evidence.\n\n",
        
        "Return ONLY a JSON object in the following format:\n",
        "{\n",
        "  \"explanation\": \"<brief explanation for your verdict>\"\n",
        "  \"evidence_sentence\": \"<the most relevant matching sentence or empty string>\",\n",
        "  \"verdict\": \"fully_supported | partially_supported | not_supported | contradicted\",\n",
        "}\n\n",
        
        "CLAIM TO CHECK:\n",
        in_claim," \n",
        "EMBEDDED CONTEXT ATTACHED: \n",
        context,
        sep = "")
      
    }else{
      
      use_molded_text = paste(in_cuc_prompt,
                              in_claim,
                              context,
                              sep = "")
      
    }
    
    #Do the LLM...
    out_single_chat <- llm_message(.llm = use_molded_text) |>
      in_fun_model(.model = use_model,
                   .num_ctx = use_context,
                   .temperature = use_temp,
                   .ollama_server = use_ollama_server)
    
    if(timer_bool){
      end_time = Sys.time()
      
      print("Total duration...")
      print(end_time - start_time)
    }
    
    return(out_single_chat)
    
  }
  
  
  
}












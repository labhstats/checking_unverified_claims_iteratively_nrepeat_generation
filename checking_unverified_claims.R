#Lowest level validate claim function

checking_unverified_claims_llm = function(in_claim,
                                          in_pdf_path,
                                          in_cuc_prompt = NA,
                                          use_model = "cogito:8b",
                                          use_context = 20000,
                                          use_temp = 0.5,
                                          in_fun_model = ollama_chat, #For different API calls via tidyllm, i.e. function as input
                                          timer_bool = TRUE){
  
  #Packages...
  require(tidyllm)
  require(pdftools)
  
  #PDF path check...
  if(is.na(in_pdf_path)){
    pdf_na_text = "PDF path was NA..."
    print(pdf_na_text)
    
    return("missing_sources") #Not optimal...
  }
  
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
                 .temperature = use_temp)
  
  if(timer_bool){
    end_time = Sys.time()
    
    print(end_time - start_time)
  }
  
  return(out_single_chat)
  
}












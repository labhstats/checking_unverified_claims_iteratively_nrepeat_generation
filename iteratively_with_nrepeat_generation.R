

iteratively_with_nrepeat_generation = function(in_nested_list, #with list of claim(s) and pdf path(s)
                                               n_repeat = 5,
                                               iter_in_cuc_prompt = NA,
                                               iter_use_model = "cogito:8b",
                                               iter_use_context = 20000,
                                               iter_use_temp = 0.5,
                                               iter_in_fun_model = ollama_chat, #For different API calls
                                               iter_timer_bool = TRUE){
  
  num_claims = length(in_nested_list)
  
  source("checking_unverified_claims.R")
  
  out_individual_claim_verdicts = lapply(in_nested_list, function(x){
    
    curr_claim = x[["claim"]]
    curr_source_s = x[["source_s"]]
    
    num_source_s = length(curr_source_s)
    
    print("--------")
    print(curr_claim)
    
    out_cuc_superglobal = paste("######################\n######################\n",
                                "Claim: ",curr_claim,"\n",
                                "######################\n######################\n",
                                sep = "")
    
    for(i in 1:num_source_s){
      
      curr_source_i = curr_source_s[i]
      print("---")
      print(curr_source_i)
      
      #Intra-source judgement
      out_cuc_i_global = ""
      
      for(n_rep in 1:n_repeat){ #Inefficient if multiple GPUs or similar avaialable?
        #Repeat per source n_repeat times
        
        print(paste(as.character(n_rep)," of ",as.character(n_repeat)),sep ="")
        
        out_cuc_in = checking_unverified_claims_llm(in_claim = curr_claim,
                                                    in_pdf_path = curr_source_i,
                                                    # From global function...
                                                    in_cuc_prompt = iter_in_cuc_prompt,
                                                    use_model = iter_use_model,
                                                    use_context = iter_use_context,
                                                    use_temp = iter_use_temp,
                                                    in_fun_model = iter_in_fun_model,
                                                    timer_bool = iter_timer_bool)
        
        out_cuc_i_global = paste(out_cuc_i_global,"\n",
                                 "Source ",as.character(num_source_s),": ", curr_source_i,"\n",
                                 "---------- Repeat Nr: ", as.character(n_rep)," of ", as.character(n_repeat), "------------\n",
                                 get_reply(out_cuc_in),"\n",
                                 "---------------------------------------------\n",
                                 sep = "")
        
      }
      
      out_cuc_superglobal = paste(out_cuc_superglobal,"\n",
                                  "---------------------------------------------\n",
                                  out_cuc_i_global,"\n",
                                  "---------------------------------------------\n",
                                  sep = "")
      
    }
    
    return(out_cuc_superglobal)
    
  })
  
  
  return(out_individual_claim_verdicts)
  
}






















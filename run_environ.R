##
## Environment for testing and running the 
## Checking Unverified Claims Iteratively with N-repeat Generation process, using no clickable UI...
##


##
# Checking lowest level, and for testing claims against a single pdf

source("checking_unverified_claims.R")

test_pdf_path = "test_case_ti2022/ti_2022.pdf" #Local test document.

out_test_1 = checking_unverified_claims_llm(in_claim = "Resilence is not important when running a hospital.",
                                            in_pdf_path = test_pdf_path,
                                            use_model = "cogito:8b",
                                            use_context = 20000,
                                            use_temp = 0.5)

# Test batch of claims --- not yet "auto generated" from text to verify itself...

# Since we only test one sentence or claim per pdf...
# We may need multiple pdfs per claim, or multiple repeat claims with a single pdf.
# Arguably, the latter is simplest, but may lack later intra-claim coherency when only one pdf is checked at the time; 
# i.e. no chunking of pdfs with iteration over chunks.

# Nested list with claim (singular) and at least one source (character vector) for verification of claim.

# Structure to use with other algorithms or LLMs:
# Sub structure: list(claim = "",source_s = c("test_case_ti2022/ti_2022.pdf"))
# Full structure:
# list(list(claim = "claim_1",source_s = c("source_folder/author_2_year_zzzz.pdf")),
#     list(claim = "claim_2",source_s = c("source_folder/author_1_year_yyyy.pdf","source_folder/author_2_year_xxxx.pdf")))

#test_batch_list is manufactured specifically to provoke, suppurt, partial support, not supported, and contradicted verdict.

test_batch_list = list(list(claim = "Resilence is not important when running a hospital.", #Contradictory.
                            source_s = c("test_case_ti2022/ti_2022.pdf")),
                       list(claim = "A study found that it be best that many school districts in Tromso are shut down and closed.", #Not relevant.
                            source_s = c("test_case_ti2022/ti_2022.pdf")),
                       list(claim = "My experiences as a physician CEO was intense and immensely interesting.", #Direct quote.
                            source_s = c("test_case_ti2022/ti_2022.pdf")),
                       list(claim = "A published paper suggests that hospitals should be run as efficient, optimised and lean as possible", #Vague partial
                            source_s = c("test_case_ti2022/ti_2022.pdf")))

# Testing batch of claims...

source("iteratively_with_nrepeat_generation.R")

out_test_list = iteratively_with_nrepeat_generation(in_nested_list = test_batch_list, #with list of claim(s) and pdf path(s)
                                                    n_repeat = 1,
                                                    iter_use_model = "cogito:8b",
                                                    iter_use_context = 20000,
                                                    iter_use_temp = 0.5,
                                                    iter_in_fun_model = ollama_chat, #For different API calls
                                                    iter_timer_bool = TRUE)

out_test_list

lapply(out_test_list,function(x) llm_message(x,.system_prompt = "")) #Easier to read...


# Saving checks of unverified claims...

source("write_txt_files.R")

output_txt_files_path = "output_test_run" #Folder name...

write_totxt(text_list = out_test_list,
            file_base_path = output_txt_files_path)






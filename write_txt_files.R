# Script for writing or exporting the list of claims into txt files, ready for use in other programs or context...

write_totxt = function(text_list,
                       file_base_path = output_txt_files_path){
  
  num_text = length(text_list)
  
  for(i in 1:num_text){
    
    use_file = paste(file_base_path,"/text_file_",as.character(i),"_",
                     Sys.Date(),".txt",
                     sep = "")
    
    print(use_file)
    
    x = text_list[[i]]
    
    writeLines(text = x, con = use_file)
    
  }
  
  print("Finished..?")
  
}


















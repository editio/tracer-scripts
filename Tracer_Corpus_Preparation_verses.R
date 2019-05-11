### --------------------------------------- ###
### Script to prepare a corpus for TRACER   ###
### --------------------------------------- ###

### April 2019 ###

### It imports vers lines. The verses in the corpus are defined with newline character \n ###

library(tidyverse)

rm(list = ls()) # Clean the data (a classic)
Sys.setlocale(locale="UTF-8") # Set the locale (just in case)

# Set the work directory in R containing the files to prepare. Each work in one .txt file.
setwd("~/Documents/tracer-scripts/pre_tracer")

# Get the list of files from the working directory.
file_list <- list.files()

# Import all files in R as data frames, delimited by line breaks.
file_list_df <- lapply(file_list,function(i){
  read_delim(i, "\n", col_names = "texto", na = c("", "NA"))
})

# Merge each data frame in the list into a single data frame.
# Every number refers to a work, following the files alphabetic order.
one_df = bind_rows(file_list_df, .id = 'obra')

  # Start >> Optional << #

      # Remove all diacritics (accents, etc.)
      one_df$texto = iconv(one_df$texto, "", "ASCII//TRANSLIT", sub = "byte") %>%
      gsub("[[:punct:]]|\\d|\"","\\1",.,perl = F)
      
      # Remove uppercase words (just in case the corpus in not clean from speakers)
      one_df$texto = gsub("^\\w[A-ZÁÍÓÚÉÑ].*","\\1",one_df$texto, perl = F)
      
      # Change the text to lowercase 
      one_df$texto = tolower(one_df$texto)
      
  # End >> Optional << #

# Trim trailing, middle, and leading white space (just for double checking after regex; read_delim() removes them when loading the files)
one_df <- data.frame(lapply(one_df, str_squish)) 

# Remove empty lines in the data frame.
one_df$texto[one_df$texto == ""] = NA
one_df = na.omit(one_df)

# Create de table according to tracer requisites:
# - adding the numeric ids, each work diferenciated by the first two digits.
# - completing until 7 digits with every row of each work.
# - adding the date column, and renaming all.

tracerdataset = one_df %>%
  mutate(x5 = str_pad(one_df$obra, 2, pad = "0", "left")) %>%  #important left!
  group_by(obra) %>% 
  mutate(x4 = sprintf(paste0("%05d"), row_number())) %>% 
  within(id <- paste(x5,x4, sep='')) %>%
  within(fecha <- "NULL") %>%
  select(id,texto,fecha,obra)

# Handle titles: extract work titles from the file names and put them in a data frame.

file_list = rowid_to_column(as.data.frame(file_list), var = "obra")
file_list$obra = as.character(file_list$obra)

# Join the titles to the main data frame by the work.
tracerdataset = left_join(tracerdataset, file_list, "obra")

# Remove "obra". It is not needed it
tracerdataset$obra <- NULL

# Remove punctuation and extension from file name.
tracerdataset$file_list = gsub("\\.txt$|[[:punct:]]",'\\1', tracerdataset$file_list, perl = F)

# Save the data frame to a txt file (columns separated by tabs).
write.table(tracerdataset, 
            file = "../merged_tracer/tracerdataset.txt", # txt for Tracer
            sep="\t", # tab delimiter
            col.names=FALSE, # remove colnames
            row.names = FALSE, # remove rownames
            quote = FALSE # not quotation marks in variables. 
)

## END of CORPUS PREPARATION ###

# Table with titles and ids
library(DT)

tableids = datatable(file_list, filter = 'top') %>%
  saveWidget('tableids.html')

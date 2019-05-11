
### --------------------------------------- ###
### Script to prepare a corpus for TRACER   ###
### --------------------------------------- ###

### March 2019 ###

library(tidyverse)
library(tokenizers)
library(rowr)

rm(list = ls()) # Clean the data (a classic)
Sys.setlocale(locale="UTF-8") # Set the locale (just in case)

# Set the local directory where you keep the indididual files in txt (one file per work).
setwd("~/Documents/tracer-scripts/pre_tracer")

# Get file list from the working directory
file_list <- list.files()

# Import all files in R as data frames.
file_list_df <- lapply(file_list,function(i){
    read_file(i)
  })

# The function from library(tokenizers)
df_tokens = tokenize_sentences(file_list_df, lowercase = F, strip_punct = F)

# The function cbind.fill() for NAs from library(rowr)
one_df = do.call(cbind.fill, c(df_tokens, fill = NA)) 

names(one_df) <- seq_along(one_df)

one_df = gather(one_df, obra, texto)

## From here, the same script than in corpus preparation verses. ##

            ### Start > Optional < ###
            
            # Remove all diacritics (accents, etc.). Redundant with tokenize_sentences(lowercase = F ...)
            one_df$texto = iconv(one_df$texto, "", "ASCII//TRANSLIT", sub = "byte") %>%
              gsub("[[:punct:]]|\\d|\"","\\1",.,perl = F)
            
            # Remove uppercase words (just in case, for speakers)
            one_df$texto = gsub("^\\w[A-ZÁÍÓÚÉÑ].*","\\1",one_df$texto, perl = F)
            
            # All lowercase. Redundant with tokenize_sentences(lowercase = F ...)
            one_df$texto = tolower(one_df$texto)
            
            ### End > Optional < ###

# Trim trailing, middle, and leading white space (just double check, read_delim() removes them)
one_df <- data.frame(lapply(one_df, str_squish)) 

# Remove empty lines in the data frame.
one_df$texto[one_df$texto == ""] = NA
one_df = na.omit(one_df)

# Create de table according to tracer requisites.

tracerdataset = one_df %>%
  mutate(x5 = str_pad(one_df$obra, 2, pad = "0", "left")) %>%  #important left!
  group_by(obra) %>% 
  mutate(x4 = sprintf(paste0("%05d"), row_number())) %>% 
  within(id <- paste(x5,x4, sep='')) %>%
  within(fecha <- "NULL") %>%
  select(id,texto,fecha,obra)

# Handle titles: extract titles and put them in a data frame.

file_list = rowid_to_column(as.data.frame(file_list), var = "obra")
file_list$obra = as.character(file_list$obra)

# Join them by id.
tracerdataset = left_join(tracerdataset, file_list, "obra")

# Remove obra. Not needed it
tracerdataset$obra <- NULL

# Remove punctuation and extension from file name.
tracerdataset$file_list = gsub("\\.txt$|[[:punct:]]",'\\1', tracerdataset$file_list, perl = F)

write.table(tracerdataset, 
            file = "../merged_tracer/tracerdataset.txt", # txt for Tracer
            sep="\t", # tab delimiter
            col.names=FALSE, # remove colnames
            row.names = FALSE, # remove rownames
            quote = FALSE # not quotation marks in variables. 
)

## END of CORPUS PREPARATION ###
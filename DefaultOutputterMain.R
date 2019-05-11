# Visualising results in a tabular format

library(tidyverse)

df = read.csv("tracerdataset-tracerdataset.score.expanded.csv", header = F, "\t")

# "The .score file lists results bidirectionally and thus redundantly". Remove duplicates.

df = df %>% 
filter(row_number() %% 2 == 0)

# Variable V7: True means matches within the same work. Not interested in this. 

df <- subset(df, df$V7 != "true")   

# Full match. 
df$total = ifelse(df$V5 == df$V6, "TRUE", "FALSE")
# Some words. 
df$parcial = df$V6 %in% df$V5

# df$total is almost the same as score = 1 (df$V4). E.g. "luego vamos" vs "vamos luego":  score = 1, but df$total == false.

# df$V7 = NULL # not needed.


# Keeps just the 2 first digits to reduce the comparation to works (not lines)

df$V1 = str_pad(df$V1, 7, pad = "0", "left") # 7 is maximum
df$V2 = str_pad(df$V2, 7, pad = "0", "left")

df$V1 = substr(df$V1,1,2)
df$V2 = substr(df$V2,1,2)

# Subsets of works. Atention! the first work gets removed from V1 after removing duplicates.

obra_02_vs_all <- subset(df, df$V1 %in% df$V1[df$V1 == "02"])

obra_02_vs_obra_01 <- subset(df, df$V1 %in% df$V1[df$V1 == "02"] & df$V2 %in% df$V2[df$V2 == "01"] )

# Save to disk

write.table(df, 
            file = "tracer_scores_teatro.csv",
            sep="\t", # separado por tabulador.
            col.names=T, 
            row.names =FALSE,
            quote = FALSE
)
#################################################################################################
##############################     HEATMAP CORRELATION TEMPLATE    ##############################
#################################################################################################

### N.B. -- PAIRWISE COMPLETE OBSERVATIONS ARE USED:
# "Pairwise Complete" is the exclusion of individuals with missing data for the 2 variables which 
# are being compared as opposed to the exclusion of individuals with any missing data for the 
# variables compared in the heatmap

### Required packages

library(ggplot2); library(Hmisc); library(tidyr)

#################################################################################################
##### STEP '0': DATA INPUT AND FORMATTING PRIOR TO CLEANING AND PROCESSING
#################################################################################################

### a) CHANGE file directory - GO TO: SESSION > SET WORKING DIRECTORY > CHOOSE DIRECTORY

setwd("~/Desktop/PBCAR")   ### OR CHANGE FILE DIRECTORY HERE

### b) SELECT NAME of file to read (data are in wide format)

hmap.df <- read.csv("Data_File.csv") ### READS in a .csv file

### c) SELECT only the names of the variables you want to analyze and ORDER:
### ORDER will be from left-to-right for x axis & bottom-to-top for y axis

heatmap.items <- c("Variable_3","Variable_4","Variable_1","Variable_2","Variable_5")

### d) RENAME variables (if desired):

item.rename <- c("Var3", "Var4","Var1","Var2","Var5")

#################################################################################################

# SELECTS only the variables to be analyzed
hmap.df <- hmap.df[c(heatmap.items)]

# ASSIGNS the new names to the data frame
colnames(hmap.df) <- item.rename

#################################################################################################
##### STEP 1: CREATION OF THE CORRELATION MATRIX
#################################################################################################

### type = "pearson" or "spearman"
correlation.matrix <- rcorr(as.matrix(hmap.df), type = "pearson")

### Change number of decimal points (default 2)
corr.matrix <- round(as.matrix(correlation.matrix[["r"]]), 2)

### Isolate Upper Triangle Function
get_upper_tri <- function(x){
  x[lower.tri(x)] <- NA
  return(x)
}

### Create upper triangle
upper.tri.corr <- get_upper_tri(corr.matrix)

### LONG format of matrix
melted.corr.matrix <- reshape2::melt(upper.tri.corr, na.rm = TRUE)

##### ----------  OPTIONAL: WRITE a .csv with the correlation coefficients

write.csv(corr.matrix, "heatmap_coefficients.csv")

#################################################################################################
##### STEP 2: CREATION OF THE P-VALUE MATRIX
#################################################################################################

corr.p.values <- as.matrix(correlation.matrix[["P"]])
upper.tri.p <- get_upper_tri(corr.p.values)

melted.corr.pval <- as.data.frame(reshape2::melt(upper.tri.p, na.rm = TRUE))
melted.corr.pval$pval <- melted.corr.pval$value

### DETERMINE whether the p-value is below the alpha threshold of significance or not

alpha <- 0.005

melted.corr.pval$pval_sign <- ifelse(melted.corr.pval$pval<alpha,"Sign.",NA)
melted.corr.pval$pval_sign <- factor(melted.corr.pval$pval_sign, levels = c("Sign.",NA))
melted.corr.pval <- melted.corr.pval[c("Var1","Var2","pval_sign")]

### MERGE p-values with the correlation coefficients
melted.corr <- merge(melted.corr.matrix, melted.corr.pval,by = c("Var1","Var2"), all.x = T)

##### ----------  OPTIONAL: WRITE a .csv with the p-values of significance

write.csv(corr.p.values,"heatmap_pvalues.csv")

#################################################################################################
##### STEP 3: HEATMAP CREATION
#################################################################################################

(heatmap.plot <- ggplot(data = melted.corr, aes(Var2, Var1, fill = value)) +
  geom_tile(color = "white") +
  scale_fill_gradient2(low = "midnightblue", high = "maroon4", mid = "grey90", 
                       midpoint = 0, limit = c(-1,1), space = "Lab", 
                       name="Pearson\nCorrelation") +
  scale_y_discrete(position = "right") +
  theme_minimal() + coord_fixed())

### ADD correlation coefficients to the heat map with significance (based on the alpha set in Step 3)
### Colour of coefficients will be black for significant, and a light grey for non-significant

(heatmap.plot <- heatmap.plot + 
  geom_text(aes(Var2, Var1, label = value, colour = pval_sign), size = 5, show.legend = F) +
    scale_colour_manual(values = c("black","grey100")))

### MAKE final adjustments to plot

(heatmap.plot <- heatmap.plot +
    ggtitle("Heatmap Plot") + # add a title to the heatmap plot
    theme(axis.title.x = element_blank(), # remove x-axis title
          axis.title.y = element_blank(), # remove y-axis title
          panel.grid.major = element_blank(), # remove grid lines
          panel.border = element_blank(), # remove plot border
          plot.title = element_text(size = 30, face = "bold", hjust = 0.5), # customize plot title
          legend.title = element_text(face = "bold",size = 15, hjust = 0.5), # customize legend title
          legend.direction = "horizontal", # make legend horizontal
          legend.position = c(0.2, 0.8), # change legend position
          axis.text = element_text(face = "bold", size = 15)) + # customize axis text
    guides(fill = guide_colorbar(barwidth = 10, barheight = 1, title.position = "top"))) # change legend position

#################################################################################################
##### STEP 4: NUMBER OF PAIRED OBSERVATIONS
#################################################################################################

corr.pair.numbers <- correlation.matrix[["n"]]

##### ----------  OPTIONAL: WRITE a .csv file with the number of observations for each correlation pair

write.csv(corr.pair.numbers, "heatmap_nvalues.csv")

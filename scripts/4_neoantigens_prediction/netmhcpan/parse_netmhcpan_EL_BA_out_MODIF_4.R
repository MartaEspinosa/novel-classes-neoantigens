#!/usr/bin/env Rscript
#Júlia Perera
#30/11/2021
#Script to generate nice table from NetMHCpan output

# Run like this:
#Rscript parse_netmhcpan_EL_BA_out.R FILE.xls

args = commandArgs(trailingOnly=TRUE)

# test if there is at least one argument: if not, return an error
if (length(args)<1) {
  stop("Please provide an .xls file with output of netMHCpan", call.=FALSE)
}

# Read arguments
INfile <- args[1]

################################################
### Load libraries and prepare styles
################################################

library("openxlsx")

## create and add a style to the title
main_title <- createStyle(fontSize = 11, fontColour = "black", halign ="left",textDecoration = "bold")
## create and add a style to the first_header
first_header <- createStyle(
  fontSize = 11, fontColour = "black", halign = "left",textDecoration = "bold",
  border = "TopBottom", borderColour = "black",borderStyle = "thick"
)
## create and add a style to the first_header
second_header <- createStyle(
  fontSize = 11, fontColour = "black", halign = "left",textDecoration = "bold",
  border = "TopBottom", borderColour = "black",borderStyle = "medium"
)

################################################
### Read input
################################################

#Although extension is xls, it is a tabular file
df=read.delim2(INfile,check.names = F)

#df=openxlsx::readWorkbook("upeptides200604_Navarra.netMHCpan.EL_BA.12representative.xlsx")
#df=openxlsx::readWorkbook("upeptides200604_Navarra.netMHC4_2.xlsx")

# Extract HLA alleles names
HLA=colnames(df)
HLA=gsub("X.*","",HLA)
HLA=HLA[!grepl("Core",df[1,])]

#R emove repeated columns with "core" sequence
colnames(df)=df[1,]
df=df[-1,]
df=df[,!grepl("^core|^icore",colnames(df))]

#Convert to numeric for posterior conditional formating
df[,grep("Rank",colnames(df))]=as.data.frame(sapply(df[,grep("Rank",colnames(df))], as.numeric))

# Add number of binders for BA
df$NB_BA=rowSums(df[,grep("BA_Rank",colnames(df))]<2)
df$NB=as.numeric(df$NB)


#Put summary at the beggining
df=df[,c(1:3,21:22,4:20)]


#Create header vectors
HLA=HLA[HLA!=""]
header=c(rep("",5),as.vector(t(cbind(HLA,rep("",length(HLA)),rep("",length(HLA)),rep("",length(HLA))))))
header2=gsub("\\..*","",colnames(df))
colnames(df)=NULL

################################################
### Write output
################################################

# Creating workbook
wb <- createWorkbook()
# Create a new sheet to contain the plot
sheet <-addWorksheet(wb,  "netMHCpan")

# Write title in worksheet
writeData(wb, 1, x = "NetMHCpan-4.1 results", startRow = 1, startCol = 1)
addStyle(wb = wb, sheet = 1, rows = 1, cols = 1, style = main_title)

#Write legend
writeData(wb, 1, x = "NB: Number of binders (EL predictions). % Rank<2 (weak binder) or <0.5% (strong binder)", 
          startRow = 3, startCol = 1,colNames = F)
writeData(wb, 1, x = "NB_BA: Number of binders (BA predictions). % Rank<10 (weak binder) or <2% (strong binder)", 
          startRow = 4, startCol = 1,colNames = F)
writeData(wb, 1, x = "EL-Score: Eluted ligand prediction score (ie. the likelihood of a peptide being an MHC ligand)",
          startRow = 5, startCol = 1,colNames = F)
writeData(wb, 1, x ="% Rank of eluted ligand prediction score. %Rank is a transformation that normalizes prediction scores across different MHC molecules and enables inter-specific MHC binding prediction comparisons. %Rank of a query sequence is computed by comparing its prediction score to a distribution of prediction scores for the MHC in question, estimated from a set of random natural peptides.", startRow = 6, startCol = 1,colNames = F)
writeData(wb, 1, x ="BA-score: Predicted binding affinity in log-scale", startRow = 7, startCol = 1,colNames = F)
writeData(wb, 1, x ="BA_Rank: % Rank of predicted affinity compared to a set of random natural peptides. This measure is not affected by inherent bias of certain molecules towards higher or lower mean predicted affinities", startRow = 8, startCol = 1,colNames = F)


# Write colnames HLA
writeData(wb, 1, x = matrix(header,nrow=1), startRow = 10, startCol = 1,colNames = F)
addStyle(wb = wb, sheet = 1, rows = 10, cols = 1:length(header), style = first_header)
# write colnames
writeData(wb, 1, x = matrix(header2,nrow=1), startRow = 11, startCol = 1,colNames = F)
addStyle(wb = wb, sheet = 1, rows = 11, cols = 1:length(header), style = first_header)


# Write dataset
writeData(wb, 1, x = df, startRow = 12, colNames = FALSE, withFilter = FALSE)
#addStyle(wb = wb, sheet = 1, rows = 10, cols = 1:length(header), style = second_header)

conditionalFormatting( wb,
                       sheet = 1,
                       cols = grep("Rank",header2),
                       rows = 12:(nrow(df)+12),
                       rule = c(0,2),
                       style = createStyle(bgFill = "moccasin"),
                       type = "between"
)
#Save file with the same name as input but changing extension to xlsx
saveWorkbook(wb, gsub(tools::file_ext(INfile),"xlsx",INfile),overwrite = T)




#' @title Formatting the \code{\link{phyloseq-class}} Object advanced
#' @description Format the phyloseq object to add the best taxonomy in phyloseq object (tax_table and otu_table).
#' @details Most commonly it is observed that the taxonomy file has classification until a given taxonomic level.
#'          row.names for both tax_table and otu_table have best hit, until maximun genus level (species classification with short amplicons is a myth)is made available. This code is a
#'          slight modification of the code from  \pkg{ampvis} \code{\link{phyloseq-class}}.
#'          Here, we directly take the phyloseq object as input and make the necessary formatting.
#'
#' @param x \code{\link{phyloseq-class}} object
#' @return  \code{\link{phyloseq-class}} object.
#' @import tidyr
#' @import dplyr
#' @import microbiome
#' @import phyloseq
#' @export
#' @examples
#' \dontrun{
#' # Example data
#' library(microbiome)
#' library(microbiomeUtilities)
#' library(tibble)
#' data("zackular2014")
#' p0 <- zackular2014
#' p0.f <- format_to_besthit(p0)
#' }
#' @keywords utilities

format_to_besthit <- function(x) {
  Domain <- Phylum <- Class <- Order <- Family <- Genus <-
    Species <- tax <- tax.merge <-
    best_hit <- y <- NULL

  # First harmonise the colnames in tax_table

  if (ncol(tax_table(x)) == 6) {
    colnames(tax_table(x)) <-
      c("Domain", "Phylum", "Class", "Order", "Family", "Genus")
  } else if (ncol(tax_table(x)) == 7) {
    colnames(tax_table(x)) <-
      c(
        "Domain",
        "Phylum",
        "Class",
        "Order",
        "Family",
        "Genus",
        "Species"
      )
  } else {
    stop("Taxonomic levels should be either 6 (untill genus) or 7 (until species) level")
  }

  # replace NAs with taxonomic abbrevations

  tax_table(x)[, 1][is.na(tax_table(x)[, 1])] <-
    paste0(tolower(substring("kingdom", 1, 1)), "__")

  tax_table(x)[, 2][is.na(tax_table(x)[, 2])] <-
    paste0(tolower(substring("Phylum", 1, 1)), "__")

  tax_table(x)[, 3][is.na(tax_table(x)[, 3])] <-
    paste0(tolower(substring("Class", 1, 1)), "__")

  tax_table(x)[, 4][is.na(tax_table(x)[, 4])] <-
    paste0(tolower(substring("Order", 1, 1)), "__")

  tax_table(x)[, 5][is.na(tax_table(x)[, 5])] <-
    paste0(tolower(substring("Family", 1, 1)), "__")

  tax_table(x)[, 6][is.na(tax_table(x)[, 6])] <-
    paste0(tolower(substring("Genus", 1, 1)), "__")

  if (ncol(tax_table(x)) == 7) {
    tax_table(x)[, 7][is.na(tax_table(x)[, 7])] <-
      paste0(tolower(substring("Species", 1, 1)), "__")
  }


  # get the taxonomy table for making changes

  y <- as.data.frame(x@tax_table)
  # head(y)

  y$Domain <- gsub("k__", "", y$Domain)
  y$Phylum <- gsub("p__", "", y$Phylum)
  y$Class <- gsub("c__", "", y$Class)
  y$Order <- gsub("o__", "", y$Order)
  y$Family <- gsub("f__", "", y$Family)
  y$Genus <- gsub("g__", "", y$Genus)

  if (ncol(tax_table(x)) == 7) {
    y$Species <- gsub("s__", "", y$Species)
  }



  if (ncol(tax_table(x)) == 6) {
    tax <-
      mutate(y, Domain, Domain = ifelse(Domain == "", "Unclassified", Domain)) %>%
      mutate(Phylum,
        Phylum = ifelse(Phylum == "", paste("k__", Domain, "", sep = ""), Phylum)
      ) %>%
      mutate(Class, Class = ifelse(Class == "", ifelse(
        grepl("__", Phylum),
        Phylum,
        paste("c__",
          Phylum, "",
          sep = ""
        )
      ), Class)) %>%
      mutate(Order, Order = ifelse(Order ==
        "", ifelse(
        grepl("__", Class), Class, paste("c__", Class, "", sep = "")
      ), Order)) %>%
      mutate(Family, Family = ifelse(Family == "", ifelse(
        grepl("__", Order), Order, paste("o__",
          Order, "",
          sep = ""
        )
      ), Family)) %>%
      mutate(Genus, Genus = ifelse(Genus ==
        "", ifelse(
        grepl("__", Family),
        Family,
        paste("f__", Family, "", sep = "")
      ),
      Genus
      ))
  } else if (ncol(tax_table(x)) == 7) {
    tax <-
      mutate(y, Domain, Domain = ifelse(Domain == "", "Unclassified", Domain)) %>%
      mutate(Phylum,
        Phylum = ifelse(Phylum == "", paste("k__", Domain, "", sep = ""), Phylum)
      ) %>%
      mutate(Class, Class = ifelse(Class == "", ifelse(
        grepl("__", Phylum),
        Phylum,
        paste("c__",
          Phylum, "",
          sep = ""
        )
      ), Class)) %>%
      mutate(Order, Order = ifelse(Order ==
        "", ifelse(
        grepl("__", Class), Class, paste("c__", Class, "", sep = "")
      ), Order)) %>%
      mutate(Family, Family = ifelse(Family == "", ifelse(
        grepl("__", Order), Order, paste("o__",
          Order, "",
          sep = ""
        )
      ), Family)) %>%
      mutate(Genus, Genus = ifelse(Genus ==
        "", ifelse(
        grepl("__", Family),
        Family,
        paste("f__", Family, "", sep = "")
      ),
      Genus
      )) %>%
      mutate(Species, Species = ifelse(Species == "", ifelse(
        grepl("__", Genus), Genus,
        paste("g__", Genus, "", sep = "")
      ), Species))
  }

  # we have un formatted taxonomy in y. and new in tax.
  # Lets start repalcing one column at a time.

  rownames(tax) <- rownames(y)

  #
  rownames(tax) <- paste("OTU-", rownames(tax), sep = "")

  tax$col1 <- tax$Genus

  tax$col2 <- rownames(tax)

  tax.merge <- tidyr::unite(tax,
    best_hit,
    c("col2", "col1"),
    sep = ":",
    remove = TRUE
  )

  rownames(tax.merge) <- tax.merge$best_hit

  otu.1 <- as.data.frame.matrix(abundances(x))
  rownames(otu.1) <- tax.merge$best_hit

  OTU <- otu_table(as.matrix(otu.1),
    taxa_are_rows = TRUE
  )

  TAX <- tax_table(as.matrix(tax.merge))

  sampledata <- sample_data(meta(x))

  p.new <- merge_phyloseq(
    OTU,
    TAX,
    sampledata
  )

  return(p.new)
}

## pisa2022
## international dataset: CY08MSP_STU_QQQ.sav
## hk sub dataset: pisa2022hk5907.sav
## Part 2: Analysis
## install and load package
## import dataset, recode country-specific items
## extracting, recoding, setting correlation type
## efa, parallel analysis, vss analysis
## re-build new variables dataset
## Claude-3.7-Sonnet
## LAM Wai Ip
## 5 June 2025

#==========
#==========

# Set working directory
#setwd("C:/Users/jwila/OneDrive/Documents/PISA2022Data/data_preparation")

#==========
#==========

# Install required packages if not already installed
if (!requireNamespace("haven", quietly = TRUE)) install.packages("haven")
if (!requireNamespace("psych", quietly = TRUE)) install.packages("psych")
if (!requireNamespace("polycor", quietly = TRUE)) install.packages("polycor")
if (!requireNamespace("dplyr", quietly = TRUE)) install.packages("dplyr")
if (!requireNamespace("readr", quietly = TRUE)) install.packages("readr")
if (!requireNamespace("tidyr", quietly = TRUE)) install.packages("tidyr")
if (!requireNamespace("ggplot2", quietly = TRUE)) install.packages("ggplot2")
if (!requireNamespace("lubridate", quietly = TRUE)) install.packages("lubridate")

# Load the packages if not already loaded
if (!require(haven))     {library(haven)}      # For reading SPSS files
if (!require(psych))     {library(psych)}      # For factor analysis
if (!require(polycor))   {library(polycor)}    # For tetrachoric correlations
if (!require(dplyr))     {library(dplyr)}      # For data manipulation
if (!require(readr))     {library(readr)}      # For reading and writing CSV files
if (!require(tidyr))     {library(tidyr)}      # For data cleaning
if (!require(ggplot2))   {library(ggplot2)}    # For visualisation 
if (!require(lubridate)) {library(lubridate)}

#==========
#==========

# Convert the 'recode_value' column into a list of vectors
input_items$recode_value <- lapply(input_items$recode_value, function(x) {
  # Handle empty values
  if (is.na(x) || x == "") {
    return(c()) # Return an empty vector for empty values
  } else {
    # Split by comma and trim whitespace
    split_values <- trimws(unlist(strsplit(as.character(x), ",")))
    
    # Handle NA values and convert to numeric
    result <- sapply(split_values, function(val) {
      if (val == "NA") {
        return(NA)
      } else {
        return(as.numeric(val))
      }
    })
    
    return(result)
  }
})

# Create the item_parameters data frame
item_parameters <- data.frame(
  target_item_id = input_items$target_item_id,
  target_item_name = input_items$target_item_name,
  cor_mat_type = input_items$cor_mat_type,
  recode_value = I(input_items$recode_value), # Use I() to preserve list structure
  stringsAsFactors = FALSE
)

# Print the resulting data frame to verify
#print(item_parameters)

#==========
#==========

## Adding timestamps to output RDS files, 
## prevents overwriting previous results, and 
## easier to track different analysis runs.
## One timestamp per R session, 
## so all analyses done in that session share the same output file.

# Create a single timestamp for the entire session
if (!exists("session_timestamp")) {
  session_timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  cat("Session timestamp:", session_timestamp, "\n")
}

# Create output directory
# output_dir <- "pisa_results"
if (!dir.exists(output_dir)) {
  dir.create(output_dir)
  cat("Created output directory:", output_dir, "\n")
}

# Define the output file path with the session timestamp
output_rds_path <- file.path(output_dir, paste0("output_", session_timestamp, ".rds"))


#==========
#==========

# Check if the data is already loaded; if not, read the SPSS file
# Replace the path with the actual location of your file

# Define the file data and path for pisa2022hk input from SPSS
#file_spss_path <- "pisa2022hk5907.sav"
#file_r_data <- "pisa2022hk"
#file_r_path <- "pisa2022hk.rds"

if (!exists(file_r_data)) {
  
  # Check if the file exists
  if (file.exists(file_r_path)) {
    
    # If file exists, read it
    pisa2022hk <- readRDS(file_r_path)
    cat("PISA HK data already exists. Loaded existing data from:", file_r_path, "\n")
    
  } else {
    
    # If file doesn't exist, run transformation code
    cat("PISA data not found. Creating data from SPSS file...\n")
    
    pisa2022hk <- read_spss(file_spss_path)
    
    # Define a single recoding rule
    recode_rule <- c("3440001" = 1, "3440002" = 2, "3440003" = 3, "3440004" = 4, "3440005" = 5)
    
    # Helper function to recode a column
    recode_column <- function(column_data) {
      case_when(
        column_data %in% names(recode_rule) ~ as.numeric(recode_rule[column_data]),
        TRUE ~ NA_real_  # Return NA for unmatched values
      )
    }
    
    # Apply the recoding to columns with the specified naming pattern
    pisa2022hk <- pisa2022hk %>%
      mutate(across(
        .cols = matches(paste0("^", item_prefix, "\\d{3}D\\d{2}[A-Z]{2}$")),  # Dynamic pattern based on prefix
        .fns = ~ recode_column(.),                                            # Apply the single recoding rule
        .names = "{sub('D', 'Q', .col)}"                                      # Rename columns by replacing "D" with "Q"
      ))    
  
    saveRDS(pisa2022hk, file=file_r_path)
    cat("Loading from SPSS complete. Data saved to:", file_r_path, "\n")
    
}}

# Check the dimensions of the dataset
# View the first few rows and column names
# dim(pisa2022hk)
# head(pisa2022hk)
# names(pisa2022hk)

#==========
#==========

# Define the file data and path for pisa2022hk_transformed output
#file_csv_data <- "pisa2022hk_transformed"
#file_csv_path <- "pisa2022hk_transformed.csv"
file_csv_path <- file.path(output_dir, paste0(file_csv_data,".csv"))

# Check if data exists
if (!exists(file_csv_data)) {

# Check if the file exists
if (file.exists(file_csv_path)) {
  
  # If file exists, read it
  pisa2022hk_transformed <- read.csv(file_csv_path)
  cat("PISA transformed file already exists. Loaded existing data from:", file_csv_path, "\n")

  } else {
  
    # If file doesn't exist, run transformation code
  cat("PISA transformed file not found. Creating transformed data...\n")
  
  # Create a new dataframe with the specified columns
  # First including ST003D02T and ST003D03T to calculate age
  temp_df <- pisa2022hk %>%
    select(CNTSTUID, LANGTEST_COG, ST001D01T, ST004D01T, ST003D02T, ST003D03T)
  
  # Clean month and year data and calculate age using system date
  temp_df <- temp_df %>%
    mutate(
      # Recode LANGTEST_COG: 313 to 1 (English), 316 to 2 (Chinese)
      LANGTEST_COG = case_when(
        LANGTEST_COG == 313 ~ 1,  # English
        LANGTEST_COG == 316 ~ 2,  # Chinese
        TRUE ~ as.numeric(NA)     # Any other values set to NA
      ),
      
      # Clean month data - only valid months (1-12) are kept
      month_clean = case_when(
        ST003D02T >= 1 & ST003D02T <= 12 ~ ST003D02T,
        TRUE ~ as.numeric(NA)
      ),
      
      # Clean year data - only valid years are kept
      year_clean = case_when(
        ST003D03T >= 2000 & ST003D03T <= 2009 ~ ST003D03T,
        TRUE ~ as.numeric(NA)
      ),
      
      # Create birth date (using 15th of the month for simplicity)
      birth_date = case_when(
        !is.na(month_clean) & !is.na(year_clean) ~ 
          make_date(year = year_clean, month = month_clean, day = 15),
        TRUE ~ NA_Date_
      ),
      
      # PISA 2022 reference date
      ref_date = as.Date("2022-04-15"),
      
      # Calculate exact age in years
      age = case_when(
        !is.na(birth_date) ~ time_length(interval(birth_date, ref_date), "years"),
        TRUE ~ as.numeric(NA)
      )
    )
  
  # Create final dataframe with renamed columns
  pisa2022hk_transformed <- temp_df %>%
    select(
      id = CNTSTUID,
      test_lang = LANGTEST_COG, 
      grade = ST001D01T, 
      gender = ST004D01T, 
      age
    )
  
  # Save the reduced dataframe as a CSV file
  write.csv(pisa2022hk_transformed, file_csv_path, row.names = FALSE)
  cat("Transformation complete. Data saved to:", file_csv_path, "\n")
}}

# Now pisa2022hk_transformed is available for use either way
cat("Transformed dataset dimensions:", dim(pisa2022hk_transformed)[1], "rows by", 
    dim(pisa2022hk_transformed)[2], "columns\n")

#==========
#==========

# Function for part2 to calculate appropriate correlation matrix based on data type
get_correlation_matrix <- function(data, type = "auto") {
  # Calculate correlation matrix based on type
  type <- tolower(type)  # Convert type to lowercase for case-insensitive comparison
  
  # Auto-detect data type if not specified
  if (type == "auto") {
    # Check if data is binary (only contains 0/1 or 1/2)
    unique_values <- unique(unlist(lapply(data, function(x) unique(x[!is.na(x)]))))
    if (length(unique_values) <= 2 && 
        (all(unique_values %in% c(0, 1)) || all(unique_values %in% c(1, 2)))) {
      type <- "tetra"
    } else {
      type <- "poly"
    }
    cat("Auto-detected correlation type:", type, "\n")
  }
  
  # Function to determine correlation matrix type and compute the correlation
  if (type %in% c("tetra", "nominal", "categorical", "binary", "yes/no", "y/n", "yn", "2")) {
    cor_mat_type <<- "tetra"  # Update global variable
    result <- tetrachoric(data)
  } else if (type %in% c("poly", "ordinal", "likert", "order", "rank", "3")) {
    cor_mat_type <<- "poly"  # Update global variable
    result <- polychoric(data)
  } else if (type %in% c("pearson", "scale", "interval", "ratio", "continuous", "0")) {
    cor_mat_type <<- "pearson"  # Update global variable
    result <- list(rho = cor(data, use = "pairwise.complete.obs"))
  } else if (type %in% c("spearman",  "1")) {   
    cor_mat_type <<- "spearman"  # Update global variable
    result <- list(rho = cor(data, use = "pairwise.complete.obs", method = "spearman"))
  } else {
    stop("Invalid correlation type. Use 'tetra', 'binary'; 'poly', 'likert', 'ordinal'; or 'pearson', 'interval'")
  }
  
  return(result)
}

#==========
#==========

# Function to create factor solution based on number of factors
create_factor_solution <- function(target_item, target_item_id, 
                                   correlation_matrix, cor_mat_type,
                                   method_name) {
  
  cor_mat <- correlation_matrix$rho
  
  method_name <- toupper(method_name)  # Convert type to lowercase for case-insensitive comparison
  
  cat("\n=== ", method_name, " Solution ===\n\n")
  
  if (method_name == "KAISER") {
    
    #==========
    
    # Using eigenvalues > 1 criterion (Kaiser criterion)
    eigenvalues <- eigen(cor_mat)$values
    cat("Eigenvalues:", eigenvalues, "\n")
    
    # Count factors with eigenvalues > 1

    num_factors <- ifelse(is.na(sum(eigenvalues > 1)), 
                          1, 
                          max(1, sum(eigenvalues > 1))
                          )                         
                          
    cat("Number of factors with eigenvalues > 1 is", num_factors, "\n")
    
    #==========
    
  } else if (method_name == "PA") {
    
    # setting fa="fa" or fa="pc"
    pa_result <- fa.parallel(cor_mat, 
                             n.obs=nrow(target_item),
                             fa=fa, 
                             main=paste0("Parallel Analysis Scree Plot for item ",
                                         target_item_id, 
                                         " (n=", nrow(target_item), ", ",
                                         cor_mat_type, " correlations)"
                             ))
    
    num_factors <- ifelse(is.na(pa_result$nfact), 
                          1, 
                          max(1, pa_result$nfact)
                          )
    cat("Number of factors with PA:", num_factors, "\n")
    
    #==========
    
    cat("\nAdjusting number of factors with PA:\n")
    
    # 1. Number of factors suggested by straight parallel analysis
    num_factors_pa_simple <- sum(pa_result$fa.values > pa_result$fa.sim)
    
    # 2. Calculate differences between actual and simulated eigenvalues
    eigen_diff <- pa_result$fa.values - pa_result$fa.sim
    min_diff_threshold <- 0.10
    num_factors_pa_meaningful <- sum(eigen_diff > min_diff_threshold)
    
    # 3. Calculate proportion of variance explained by each factor
    eigen_sum <- sum(pa_result$fa.values[pa_result$fa.values > 0])  # Sum of positive eigenvalues
    variance_explained <- pa_result$fa.values / eigen_sum
    min_variance_threshold <- 0.05
    num_factors_pa_substantial <- sum(variance_explained > min_variance_threshold)
    
    # 4. Another approach: implement a minimum absolute eigenvalue threshold
    min_eigen <- 0.2
    num_factors_pa_min_eigen <- sum(pa_result$fa.values > min_eigen & 
                                      pa_result$fa.values > pa_result$fa.sim)
    
    # 5. Custom approach - add a small buffer to the simulated eigenvalues
    buffer <- 0.05  # Adjust this value based on your data
    custom_sim_values <- pa_result$fa.sim + buffer
    num_factors_pa_custom <- sum(pa_result$fa.values > custom_sim_values)
    
    # 6. Run parallel analysis with a stricter criterion (e.g., 99th percentile)
    cat("Strict (99.9%) ")
    pa_strict <- fa.parallel(correlation_matrix$rho, 
                             n.obs=nrow(target_item), 
                             fa="fa", 
                             quant=0.999,  # Use 99th percentile instead of default
                             main="Strict Parallel Analysis (99th percentile)",
                             plot = FALSE)
    num_factors_pa_strict <- sum(pa_strict$fa.values > pa_strict$fa.sim)
    
    # 7. Alternatively, you can create a completely custom criterion
    min_ratio <- 1.2  # Actual must be at least 20% larger than simulated
    num_factors_pa_ratio <- sum((pa_result$fa.values / pa_result$fa.sim) > min_ratio & 
                                  pa_result$fa.values > 0)
    
    # Create a data frame with methods and their conceptual strengths
    num_factors_pa_df <- data.frame(
      method = c(
        "Simple PA",
        "Meaningful difference (>0.1)",
        "Substantial variance (>5%)",
        "Minimum eigenvalue (>0.2)",
        "Custom buffer (>sim+0.05)",
        "Strict PA (99.9%)",
        "Ratio criterion (>1.2x)"
      ),
      nfactors = c(
        num_factors_pa_simple,       # Original PA suggestion (3)
        num_factors_pa_meaningful,   # Minimum difference criterion (1)
        num_factors_pa_substantial,  # Variance explained criterion (1)
        num_factors_pa_min_eigen,    # Minimum eigenvalue criterion (1)
        num_factors_pa_custom,       # Custom buffer approach (1)
        num_factors_pa_strict,       # Stricter percentile PA (3)
        num_factors_pa_ratio         # Minimum ratio criterion (3)
      ),
      # Weights based on methodological considerations
      weight = c(1.0, 2.0, 2.5, 2.0, 1.0, 0.5, 1.5)
    )
    
    # Display the methods, their suggestions, and weights
    print(num_factors_pa_df)

    #==========
    
    
  } else {
    
    stop("Invalid method. Use 'kaiser' or 'pa'.")
    
  } 
  
  cat("\nRunning EFA with", num_factors, "factors as suggested by", method_name, "\n")
  
  # Run EFA  
  efa_result  <- fa(cor_mat,
                    nfactors=num_factors,
                    rotate="varimax",
                    fm="minres")
  
  # Show rotated factor loadings with a cleaner format
  print("Rotated Factor Loadings (Varimax Rotation):")
  print(efa_result$loadings, cutoff=0.3, sort=TRUE)
  
  # Visualize the factor structure
  fa.diagram(efa_result,
             main=paste0(method_name, ": EFA for item ",
                         target_item_id,
                         " (n=", nrow(target_item), ", ",
                         cor_mat_type, " correlations)"
             ))
  
  # Also check variance explained by each factor
  cat("\n")
  print("Variance Explained by Each Factor:")
  print(efa_result$Vaccounted)

  #==========
  
  # Convert to dataframe
  loadings_df <- as.data.frame(efa_result$loadings[]) 

  # Store the original row names (item names) before any transformation
  item_names <- rownames(loadings_df) 
  
  # Rename the columns as requested
  colnames(loadings_df) <- paste0(target_item_name, "_F", 1:ncol(loadings_df)) 

  # 1. Set values below cutoff threshold (0.3) to 0
  binary_df <- loadings_df %>%
    mutate(across(everything(), ~ifelse(. < 0.3, 0, .)))
  
  # Create a new column for item names to preserve them
  binary_df$item_name <- item_names
  
  # 2. For each row, set the highest value to 1 and others to 0
  binary_df <- binary_df %>%
    rowwise() %>%
    mutate(across(-item_name, ~ifelse(. == max(c_across(-item_name)) & . > 0, 1, 0))) %>%
    ungroup()
  
   # Create a list of items that load on each factor
  factor_items <- list()
  for(col in 1:(ncol(binary_df)-1)) { # -1 because we added the item_name column
    factor_name <- colnames(binary_df)[col]
    # Use the item_name column instead of rownames
    factor_items[[factor_name]] <- binary_df$item_name[binary_df[, col] == 1]
  }
  
  # Calculate factor reliabilities
  reliability <- list()
  for(factor in names(factor_items)) {
    items <- factor_items[[factor]]
    if(length(items) > 1) {
      # Need at least 2 items for reliability
      alpha_result <- psych::alpha(target_item[, items])
      reliability[[factor]] <- alpha_result$total$raw_alpha
    } else if(length(items) == 1) {
      reliability[[factor]] <- NA  # Can't calculate alpha for single item
    } else {
      reliability[[factor]] <- NA  # No items
    }
  }
  
  cat("\nFactor structure:\n")
  print(binary_df)
  
  cat("\nItems for each factor:\n")
  for(f in names(factor_items)) {
    cat(f, ": ", paste(factor_items[[f]], collapse=", "), 
        ifelse(is.na(reliability[[f]]), 
               " (single item)", 
               paste0(" (alpha = ", round(reliability[[f]], 3), ")")), 
        "\n")
  }
  
  return(list(
    efa_result = efa_result,
    binary_df = binary_df,
    num_factors = num_factors, 
    factor_items = factor_items,
    reliability = reliability
  ))

}

#==========
#==========

# Initialize an empty list for output
output_list <- list()

# Loop through each item and run the analysis
for (i in 1:nrow(item_parameters)) {
  # Dynamically set parameters
  target_item_id <- item_parameters$target_item_id[i]
  target_item_name <- item_parameters$target_item_name[i]  # Get the meaningful name
  recode_value <- item_parameters$recode_value[[i]]
  cor_mat_type <- item_parameters$cor_mat_type[i]
  
  cat("\n#### Analysis on item", target_item_id, "Begins ####\n")
  #cat(format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

  # Print progress
  cat("\n#### Analysis on item", target_item_id, "(", target_item_name, ") Begins ####\n")
  
  
#==========
#==========
  
  # Make output_dir available to the script
  #assign("output_dir", output_dir, envir = .GlobalEnv)
  
#==========
#==========
  
  # Create PDF file to capture plots
  pdf_file <- file.path(output_dir, paste0(target_item_id, "_plots.pdf"))
  cat("Creating PDF file:", pdf_file, "\n")
  pdf(pdf_file, width = 10, height = 8)
  
  # Run the external script while capturing console output
  #console_output <- capture.output(source("pisa2022hk5907_II_analysis_v6.R"))
  
  # Start capturing console output
  console_output <- capture.output({
    
#==========
#==========
  
    # Extract target international item, convert to numeric
    target_item <- pisa2022hk %>% 
      select(starts_with(paste0(target_item_id, "Q"))) %>%
      mutate(across(everything(), ~as.numeric(.)))
    
    # Apply recoding if needed
    if(length(recode_value) > 0) {
      cat("  Applying recoding with values:", paste(recode_value, collapse=", "), "\n")
      target_item <- target_item %>%
        mutate(across(
          everything(),
          ~{
            ifelse(. >= 1 & . <= length(recode_value), 
                   recode_value[.], 
                   as.numeric(NA))
          }
        ))
    } else {
      cat("  No recoding needed for this item\n")
    }
    
    # Get the number of columns to determine which case we're handling
    n_cols <- ncol(target_item)
  
    # Case 1: Single item
    if(n_cols == 1) {  
      cat("  Processing as a single item\n")
      
      
      # Extract the value
      result_value <- target_item[[1]]
      
      # Report statistics
      cat("  Summary statistics:\n")
      cat("    Mean:", round(mean(result_value, na.rm = TRUE), 2), "\n")
      cat("    SD:", round(sd(result_value, na.rm = TRUE), 2), "\n")
      cat("    Missing values:", sum(is.na(result_value)), "out of", length(result_value), "\n")
      
      # Create a data frame with the new variable
      new_composites <- data.frame(temp = result_value)
      names(new_composites) <- target_item_name
      
      # Extract the values
      item_values <- as.numeric(target_item[[1]])
      
      # Create data frame for plotting
      plot_data <- data.frame(value = item_values)
      
      # Box plot with violin
      p <- ggplot(plot_data, aes(x = "", y = value)) +
        geom_violin(fill = "skyblue", alpha = 0.5) +
        geom_boxplot(width = 0.1, fill = "white", alpha = 0.7) +
        stat_summary(fun = mean, geom = "point", shape = 23, size = 3, fill = "red") +
        labs(
          title = paste("Distribution for", target_item_name),
          subtitle = paste("Mean =", round(mean(item_values, na.rm = TRUE), 2),
                           ", Median =", round(median(item_values, na.rm = TRUE), 2)),
          x = "",
          y = "Value"
        ) +
        theme_minimal()
      
      print(p)
      
      
      correlation_matrix <- NULL
      kaiser_solution <- NULL
      pa_solution <- NULL
      vss_result <- NULL
      

      # Case 2: Two items - calculate correlation and mean
    } else if(n_cols == 2) {
      cat("  Processing as a two-item measure\n")
      
      
      # Calculate correlation coefficient
      correlation_matrix <- cor(target_item[[1]], target_item[[2]], 
                            use = "pairwise.complete.obs", 
                            method = cor_mat_type)
      
      # Create a likert visualization
      likert_data <- target_item %>%
        pivot_longer(everything(), names_to = "item", values_to = "response") %>%
        mutate(response_factor = factor(response))
      
      likert_plot <- ggplot(likert_data, aes(y = item, fill = response_factor)) +
        geom_bar(position = "fill") +
        scale_x_continuous(labels = scales::percent) +
        scale_fill_brewer(palette = "RdYlBu") +
        labs(
          title = paste("Response patterns for", target_item_name),
          x = "Percentage",
          y = "Item",
          fill = "Response"
        ) +
        theme_minimal()
      
      print(likert_plot)

      # Create a heatmap showing frequency of response combinations
      item_combinations <- table(target_item[[1]], target_item[[2]], useNA = "ifany")
      item_heatmap <- ggplot(as.data.frame(as.table(item_combinations)), 
                             aes(x = Var1, y = Var2, fill = Freq)) +
        geom_tile() +
        geom_text(aes(label = Freq), color = "white") +
        scale_fill_gradient(low = "skyblue", high = "darkblue") +
        labs(
          title = paste("Response combinations for", target_item_name),
          x = names(target_item)[1],
          y = names(target_item)[2],
          fill = "Frequency"
        ) +
        theme_minimal()
      
      print(item_heatmap)
      
           
      kaiser_solution <- NULL
      pa_solution <- NULL
      vss_result <- NULL
      
      # Calculate mean score
      result_value <- rowMeans(target_item, na.rm = TRUE)
      
      # Report statistics
      cat("  Two-item correlation by", cor_mat_type, round(correlation_matrix, 3), "\n")
      cat("  Summary statistics (mean score):\n")
      cat("    Mean:", round(mean(result_value, na.rm = TRUE), 2), "\n")
      cat("    SD:", round(sd(result_value, na.rm = TRUE), 2), "\n")
      cat("    Missing values:", sum(is.na(result_value)), "out of", length(result_value), "\n")
      
      # Create a data frame with the new variable
      new_composites <- data.frame(temp = result_value)
      names(new_composites) <- target_item_name
      
    
      # Case 3: Multiple items (3+) - conduct factor analysis
    } else {
      cat("  Processing as a multi-item scale with", n_cols, "items\n")
      
    
    
  # Use cor_mat_type variable in the function call
  # type = tetra (binary), poly (ordinal), pearson (interval)
  correlation_matrix <- get_correlation_matrix(target_item, type = cor_mat_type)
  
#==========
#==========

# Create both solutions
kaiser_solution <- create_factor_solution(target_item, target_item_id,
                                     correlation_matrix, cor_mat_type,
                                     "kaiser")

pa_solution <- create_factor_solution(target_item, target_item_id,
                                 correlation_matrix, cor_mat_type,
                                 "pa")

#==========

# Additional helpful visualization: VSS plot to help determine number of factors
vss_result <- VSS(correlation_matrix$rho, 
                  n=5,  # Maximum number of factors to extract
                  rotate="varimax", 
                  n.obs=nrow(target_item),  # Actual number of observations
                  title=paste0("VSS Analysis for item ",
                               target_item_id, 
                               " (n=", nrow(target_item), ", ",
                               cor_mat_type, " correlations)"
                  ))
cat("\n=== Very Simple Structure (VSS) ===\n\n")
#print(vss_result)
vss_result$vss.stats[grep("^cfit", names(vss_result$vss.stats))] %>%
  as.data.frame() %>%
  print()

# when thinking vss, assuming vars are on left and factors right, listed horizontally 
# row depth=how many factor, column=how many link can eavh variable have.
# column from left to right is from converging (ie simple) to much diverging (ie much complex)

#==========

# Print timestamp at the end
#cat("\nAnalysis on",  target_item_id, "completed:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

#==========
#==========

# Re-building new variables based on results of analysis on construct by efa

cat("\nAssuming Kaiser Solution (eigenvalues > 1), but not PA, is taken.\n")

n_factors <- kaiser_solution$num_factors
binary_df <- kaiser_solution$binary_df
factor_items <- kaiser_solution$factor_items

# For each factor, calculate the mean of its items
for(factor_name in names(factor_items)) {
  items <- factor_items[[factor_name]]
  
  if(length(items) > 0) {
    target_item <- target_item %>%
      mutate(!!factor_name := rowMeans(select(., all_of(items)), na.rm = TRUE))
  } else {
    target_item <- target_item %>%
      mutate(!!factor_name := NA_real_)
  }
}

# Print the results
# cat("\nFactor structure:\n")
# print(binary_df %>% select(-item_name)) # Hide item_name for cleaner output
# cat("\nItems for each factor:\n")
# print(factor_items)
# cat("\nFirst few rows of result with factor scores:\n")
# print(head(target_item))
# View(target_item)

#==========
#==========

# Get just the new composite variables
new_composites <- target_item %>%
  select(all_of(names(factor_items)))

}

# Print the first few rows of the new composites to verify
#cat("New composite variables created:\n")
#print(head(new_composites))

# Now add these composites to the full dataset
# Assuming that pisahk2022 and target_item have the same number of rows
# and are in the same order
# Alternatively, if you need to use a joining key:
# Assuming there's an ID column called "student_id" in both datasets
# pisahk2022 <- pisahk2022 %>%
#    left_join(new_composites, by = "student_id")
# Check if any columns in new_composites already exist in pisa2022hk_transformed
duplicate_cols <- intersect(names(pisa2022hk_transformed), names(new_composites))

if (length(duplicate_cols) > 0) {
  cat("\nWarning: The following columns already exist and will be overwritten:", 
      paste(duplicate_cols, collapse=", "), "\n")
  
  # Remove duplicate columns from original dataframe before binding
  pisa2022hk_transformed <- pisa2022hk_transformed %>%
    select(-all_of(duplicate_cols))
}

# Now bind columns
pisa2022hk_transformed <- pisa2022hk_transformed %>%
  bind_cols(new_composites)

# Save the updated dataset to CSV
write.csv(pisa2022hk_transformed, file_csv_path, row.names = FALSE)

cat("\nUpdated", target_item_id, "on dataset and saved to", file_csv_path )
cat(" with dimensions", dim(pisa2022hk_transformed)[1], "rows by", 
    dim(pisa2022hk_transformed)[2], "columns")
#cat(" at ", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")

#==========
#==========

# End of capture.output block
})

# Close the PDF device
dev.off()
cat("Saved plots to", pdf_file, "\n")

#==========
#==========

# Store results in the output list - using your exact structure
# with added error checking to avoid errors if variables don't exist
output_list[[target_item_id]] <- list(
  cor_mat = if(exists("correlation_matrix")) correlation_matrix else NULL,
  kaiser_solution = if(exists("kaiser_solution")) kaiser_solution else NULL,
  pa_solution = if(exists("pa_solution")) pa_solution else NULL,
  vss_result = if(exists("vss_result")) vss_result else NULL,
  console_log = console_output
)

# Save the current state after each item
saveRDS(output_list, output_rds_path)

cat("Completed analysis for", target_item_id, 
    "- Saved plots to", pdf_file, "\n")

# Only remove specific analysis result variables
rm(list = c("correlation_matrix", "kaiser_solution", "pa_solution", "vss_result", "console_output"))

}

#==========
#==========

# Create a summary file
summary_file <- file.path(output_dir, "analysis_summary.txt")
cat("PISA Analysis Summary\n\n", file = summary_file)
cat("Items analyzed:", length(output_list), "\n\n", file = summary_file, append = TRUE)

# Add basic information about each analysis to the summary
for (item_id in names(output_list)) {
  cat("Item:", item_id, "\n", file = summary_file, append = TRUE)
  
  # Add info about available results
  if (!is.null(output_list[[item_id]]$kaiser_solution)) {
    cat("  Kaiser solution available\n", file = summary_file, append = TRUE)
  }
  
  if (!is.null(output_list[[item_id]]$pa_solution)) {
    cat("  Parallel analysis solution available\n", file = summary_file, append = TRUE)
  }
  
  if (!is.null(output_list[[item_id]]$vss_result)) {
    cat("  VSS result available\n", file = summary_file, append = TRUE)
  }
  
  cat("\n", file = summary_file, append = TRUE)
}

cat("\nAnalysis complete! All results saved to", output_dir, "\n")
cat("- Plots saved as individual PDF files\n")
cat("- All results stored in output.rds\n")
cat("- Summary saved to analysis_summary.txt\n")

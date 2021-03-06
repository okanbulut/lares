####################################################################
# Study the distribution of a targets variable and another variable
# Similar to the funModeling::corrplot function
plot_distr <- function(data, target, values, 
                       top = 10, breaks = 10, 
                       abc = FALSE,
                       na.rm = FALSE, 
                       print_table = FALSE,
                       save = FALSE, subdir = NA) {
  
  require(ggplot2)
  require(gridExtra)
  require(dplyr)
  
  targets <- data[[target]]
  value <- data[[values]]
  
  targets_name <- colnames(data[target[1]])
  variable_name <- colnames(data[values[1]])
  
  if (length(targets) != length(value)) {
    message("The targets and value vectors should be the same length.")
    stop(message(paste("Currently, targets has",length(targets),"rows and value has",length(value))))
  }
  
  if (length(unique(targets)) > 9) {
    stop("You should use a targets variable with max 9 different value!")
  }
  
  if (is.numeric(value)) {
    value <- cut(value, quantile(value, prob = seq(0, 1, length = breaks), type = 7, na.rm = T))
  }
  
  if (length(unique(value)) > top) {
    top <- ifelse(breaks > top, breaks, top)
    value <- lares::categ_reducer(value, top = top)
  }
  
  df <- data.frame(targets = targets, value = value)
  
  if (na.rm == TRUE) {
    df <- df[complete.cases(df), ]
  }
  
  freqs <- df %>% group_by(value, targets) %>% 
    tally() %>% arrange(desc(n)) %>% 
    mutate(p = round(100*n/sum(n),2)) %>% ungroup() %>%
    mutate(row = row_number(),
           order = ifelse(grepl("\\(|\\)", value), 
                          as.numeric(as.character(substr(gsub(",.*", "", value), 2, 100))), row))
  if (abc == TRUE) {
    freqs <- freqs %>% mutate(order = rank(as.character(value)))
  }
  
  distr <- df %>% group_by(targets) %>% 
    tally() %>% arrange(desc(n)) %>% 
    mutate(p = round(100*n/sum(n),2), pcum=cumsum(p))
  
  count <- ggplot(freqs, aes(x=reorder(as.character(value), order), y=n, fill=targets, label=n, ymax=max(n)*1.1)) + 
    geom_col(position = "dodge") +
    geom_text(check_overlap = TRUE, position = position_dodge(0.9), size=3, vjust = -0.15) +
    scale_fill_brewer(palette = "Blues") + theme_minimal() + 
    labs(x = "", y = "Counter") + 
    theme(legend.position="top", legend.title=element_blank())
  
  if (length(unique(value)) >= 10) {
    count <- count + theme(axis.text.x = element_text(angle = 45, hjust=1))
  }
  
  prop <- ggplot(freqs, aes(x=reorder(as.character(value), -order), y=p/100, fill=targets, label=p)) + 
    geom_col(position = "fill") +
    geom_hline(yintercept = distr$pcum[1:(nrow(distr)-1)]/100, colour = "purple", linetype = "dotted", alpha = 0.8) +
    geom_text(check_overlap = TRUE, position = position_stack(vjust = 0.5), size = 3.2) +
    scale_fill_brewer(palette = "Blues") + 
    theme_minimal() + coord_flip() + 
    labs(x = "Proportions", y = "") + guides(fill=FALSE) + 
    labs(caption = paste("Variables:", targets_name, "vs.", variable_name))
  
  if (length(unique(value)) > top) {
    count <- count + labs(caption = paste("Showing the", top, "most frequent values"))
  }
  
  if (print_table == TRUE) {
    print(freqs %>% select(-order))
  }
  
  if (save == TRUE) {
    
    file_name <- paste0("viz_distr_", targets_name, ".vs.", variable_name, ".png")
    
    if (!is.na(subdir)) {
      dir.create(file.path(getwd(), subdir))
      file_name <- paste(subdir, file_name, sep="/")
    }
    
    png(file_name, height = 1500, width = 2000, res = 300)
    grid.arrange(count, prop, ncol = 1, nrow = 2)
    dev.off()
  }
  
  # Plot the result
  return(grid.arrange(count, prop, ncol = 1, nrow = 2))
  
}

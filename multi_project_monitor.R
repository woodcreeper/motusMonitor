#!/usr/bin/env Rscript
# Multi-Project Motus Monitor
# Monitors multiple Motus projects and sends notifications for new detections

library(motus)
library(dplyr)
library(lubridate)

# Set timezone to UTC (CRITICAL)
Sys.setenv(TZ = "UTC")

# ========== CONFIGURATION ==========
# Projects are read from motus_config.env
config_file <- "motus_config.env"
if (file.exists(config_file)) {
  source_lines <- readLines(config_file)
  projects_line <- grep("^PROJECTS=", source_lines, value = TRUE)
  if (length(projects_line) > 0) {
    projects_str <- sub("^PROJECTS=", "", projects_line)
    projects_str <- gsub(" ", "", projects_str)  # Remove spaces
    PROJECTS <- as.integer(unlist(strsplit(projects_str, ",")))
    cat("Loaded", length(PROJECTS), "projects from config:", paste(PROJECTS, collapse=", "), "\n")
  } else {
    stop("PROJECTS not found in motus_config.env. Please configure it.")
  }
} else {
  stop("Configuration file 'motus_config.env' not found.\nPlease copy motus_config.env.example to motus_config.env and configure it.")
}

# Base directory for all project data
BASE_DIR <- "~/Dropbox/motusMonitor/motus_data_multi"

# Notification method
NOTIFICATION_METHOD <- "desktop"  # Options: "desktop", "email", "slack", "log_only"

# Email settings (if using email)
EMAIL_TO <- "your.email@gmail.com"
EMAIL_FROM <- "your.email@gmail.com"

# ========== FUNCTIONS ==========
log_message <- function(message, level = "INFO", project = NULL) {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  prefix <- if (!is.null(project)) paste0("[Project ", project, "] ") else ""
  log_entry <- paste0("[", timestamp, "] ", level, ": ", prefix, message)
  cat(log_entry, "\n")
}

send_desktop_notification <- function(title, message) {
  tryCatch({
    if (Sys.info()["sysname"] == "Darwin") {
      # macOS
      escaped_msg <- gsub('"', '\\"', message)
      escaped_title <- gsub('"', '\\"', title)
      cmd <- sprintf('osascript -e \'display notification "%s" with title "%s"\'', 
                     escaped_msg, escaped_title)
      system(cmd)
      log_message("Desktop notification sent")
    }
  }, error = function(e) {
    log_message(paste("Notification error:", e$message), "WARN")
  })
}

check_and_download <- function(project_num) {
  log_message("Checking for new data", project = project_num)
  
  # Create project-specific directory
  project_dir <- file.path(path.expand(BASE_DIR), paste0("project_", project_num))
  if (!dir.exists(project_dir)) {
    dir.create(project_dir, recursive = TRUE)
    log_message("Created directory", project = project_num)
  }
  
  tryCatch({
    # Check for new data
    db_file <- file.path(project_dir, paste0("project-", project_num, ".motus"))
    db_exists <- file.exists(db_file)
    
    if (db_exists) {
      new_data <- tellme(projRecv = project_num, dir = project_dir)
      log_message(paste("Check complete - Hits:", new_data$numHits, 
                        "Runs:", new_data$numRuns), 
                  project = project_num)
    } else {
      log_message("Database doesn't exist yet - skipping", "WARN", project = project_num)
      return(NULL)
    }
    
    # If there's new data, download it
    if (new_data$numHits > 0 || new_data$numRuns > 0) {
      log_message("New data found! Downloading...", project = project_num)
      
      sql_motus <- tagme(projRecv = project_num, 
                         dir = project_dir, 
                         update = TRUE)
      
      log_message("Download complete", project = project_num)
      
      # Get recent detections (last 24 hours)
      tbl_alltags <- tbl(sql_motus, "alltags")
      day_ago <- as.numeric(Sys.time()) - 86400
      
      recent <- tbl_alltags %>%
        filter(ts >= day_ago) %>%
        collect() %>%
        mutate(time = as_datetime(ts))
      
      if (nrow(recent) > 0) {
        log_message(paste("Found", nrow(recent), "recent detections (last 24h)"), 
                    project = project_num)
        
        # Summarize
        summary <- recent %>%
          group_by(motusTagID, speciesEN) %>%
          summarise(
            detections = n(),
            receivers = n_distinct(recv),
            .groups = "drop"
          ) %>%
          arrange(desc(detections))
        
        # Send notification
        if (NOTIFICATION_METHOD == "desktop") {
          title <- paste("Motus Alert: Project", project_num)
          
          if (nrow(summary) == 1) {
            msg <- sprintf("%d detections of tag %d (%s) on %d receiver(s)", 
                           summary$detections[1], 
                           summary$motusTagID[1],
                           ifelse(is.na(summary$speciesEN[1]), "Unknown", summary$speciesEN[1]),
                           summary$receivers[1])
          } else {
            msg <- sprintf("%d new detections across %d tags", 
                           nrow(recent), 
                           nrow(summary))
          }
          
          send_desktop_notification(title, msg)
        }
        
        # Save summary
        summary_file <- file.path(project_dir, 
                                  sprintf("summary_%s.csv", 
                                          format(Sys.time(), "%Y%m%d_%H%M%S")))
        write.csv(summary, summary_file, row.names = FALSE)
        log_message(paste("Saved summary to:", basename(summary_file)), project = project_num)
        
        return(list(
          project = project_num,
          new_hits = new_data$numHits,
          recent_detections = nrow(recent),
          unique_tags = nrow(summary)
        ))
      } else {
        log_message("New data downloaded but no recent detections", project = project_num)
        return(list(project = project_num, new_hits = new_data$numHits, recent_detections = 0))
      }
      
    } else {
      log_message("No new data available", project = project_num)
      return(NULL)
    }
    
  }, error = function(e) {
    log_message(paste("Error:", e$message), "ERROR", project = project_num)
    return(NULL)
  })
}

# ========== MAIN EXECUTION ==========
log_message("===================================================")
log_message("   MULTI-PROJECT MOTUS MONITOR STARTED")
log_message("===================================================")
log_message(paste("Monitoring", length(PROJECTS), "project(s):", paste(PROJECTS, collapse = ", ")))

# Expand BASE_DIR path
BASE_DIR <- path.expand(BASE_DIR)
if (!dir.exists(BASE_DIR)) {
  dir.create(BASE_DIR, recursive = TRUE)
  log_message(paste("Created base directory:", BASE_DIR))
}

# Check each project
results <- list()
for (proj in PROJECTS) {
  log_message("")
  result <- check_and_download(proj)
  if (!is.null(result)) {
    results <- append(results, list(result))
  }
}

# Summary
log_message("")
log_message("===================================================")
if (length(results) > 0) {
  log_message(paste("SUMMARY: Found new data for", length(results), "project(s)"))
  for (r in results) {
    if (r$recent_detections > 0) {
      log_message(sprintf("  Project %d: %d recent detections, %d unique tags", 
                          r$project, r$recent_detections, r$unique_tags))
    }
  }
} else {
  log_message("SUMMARY: No new data for any monitored projects")
}
log_message("===================================================")

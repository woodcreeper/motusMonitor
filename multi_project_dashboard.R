# Multi-Project Dashboard
# Quick morning overview of all monitored Motus projects

library(motus)
library(dplyr)
library(lubridate)

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

# ========== FUNCTIONS ==========
get_project_summary <- function(project_num, days_back = 7) {
  project_dir <- file.path(path.expand(BASE_DIR), paste0("project_", project_num))
  db_file <- file.path(project_dir, paste0("project-", project_num, ".motus"))
  
  if (!file.exists(db_file)) {
    return(list(
      project = project_num,
      exists = FALSE,
      error = "Database not found"
    ))
  }
  
  tryCatch({
    # Load database
    sql_motus <- tagme(project_num, dir = project_dir, update = FALSE)
    tbl_alltags <- tbl(sql_motus, "alltags")
    
    # Get recent data
    cutoff <- as.numeric(Sys.time()) - (days_back * 86400)
    
    recent <- tbl_alltags %>%
      filter(ts >= cutoff) %>%
      collect() %>%
      mutate(time = as_datetime(ts))
    
    if (nrow(recent) == 0) {
      return(list(
        project = project_num,
        exists = TRUE,
        recent_detections = 0,
        tags = 0,
        receivers = 0,
        species = 0
      ))
    }
    
    # Summaries
    by_species <- recent %>%
      group_by(speciesEN) %>%
      summarise(detections = n(), .groups = "drop") %>%
      arrange(desc(detections))
    
    by_tag <- recent %>%
      group_by(motusTagID, speciesEN) %>%
      summarise(detections = n(), .groups = "drop") %>%
      arrange(desc(detections))
    
    by_receiver <- recent %>%
      group_by(recvDeployName) %>%
      summarise(detections = n(), .groups = "drop") %>%
      arrange(desc(detections))
    
    return(list(
      project = project_num,
      exists = TRUE,
      recent_detections = nrow(recent),
      tags = n_distinct(recent$motusTagID),
      receivers = n_distinct(recent$recv),
      species = n_distinct(recent$speciesEN),
      first_detection = min(recent$time),
      last_detection = max(recent$time),
      by_species = by_species,
      by_tag = by_tag,
      by_receiver = by_receiver,
      raw_data = recent
    ))
    
  }, error = function(e) {
    return(list(
      project = project_num,
      exists = TRUE,
      error = e$message
    ))
  })
}

# ========== MAIN DASHBOARD ==========
cat("\n")
cat("══════════════════════════════════════════════════════════\n")
cat("         MULTI-PROJECT MOTUS DASHBOARD\n")
cat("══════════════════════════════════════════════════════════\n\n")
cat("📅", format(Sys.time(), "%A, %B %d, %Y - %H:%M:%S UTC"), "\n")
cat("📊 Monitoring", length(PROJECTS), "project(s):", paste(PROJECTS, collapse = ", "), "\n\n")

# Collect data for all projects
cat("⏳ Loading data for all projects...\n\n")
all_summaries <- list()
for (proj in PROJECTS) {
  summary <- get_project_summary(proj, days_back = 7)
  all_summaries[[as.character(proj)]] <- summary
  
  # Quick status
  if (!summary$exists) {
    cat(sprintf("  ❌ Project %d: Database not found\n", proj))
  } else if (!is.null(summary$error)) {
    cat(sprintf("  ⚠️  Project %d: Error - %s\n", proj, summary$error))
  } else if (summary$recent_detections == 0) {
    cat(sprintf("  ℹ️  Project %d: No detections in last 7 days\n", proj))
  } else {
    cat(sprintf("  ✅ Project %d: %s detections, %d tags\n", 
                proj, format(summary$recent_detections, big.mark = ","), summary$tags))
  }
}

cat("\n")
cat("══════════════════════════════════════════════════════════\n")
cat("  📊 COMBINED SUMMARY (Last 7 Days)\n")
cat("══════════════════════════════════════════════════════════\n\n")

# Combined statistics
total_detections <- sum(sapply(all_summaries, function(s) {
  if (s$exists && is.null(s$error)) s$recent_detections else 0
}))

total_tags <- sum(sapply(all_summaries, function(s) {
  if (s$exists && is.null(s$error)) s$tags else 0
}))

total_receivers <- sum(sapply(all_summaries, function(s) {
  if (s$exists && is.null(s$error)) s$receivers else 0
}))

active_projects <- sum(sapply(all_summaries, function(s) {
  s$exists && is.null(s$error) && s$recent_detections > 0
}))

cat("  Total detections:", format(total_detections, big.mark = ","), "\n")
cat("  Active projects:", active_projects, "of", length(PROJECTS), "\n")
cat("  Unique tags detected:", total_tags, "\n")
cat("  Unique receivers:", total_receivers, "\n\n")

# Individual project details
cat("══════════════════════════════════════════════════════════\n")
cat("  📋 PROJECT DETAILS\n")
cat("══════════════════════════════════════════════════════════\n\n")

for (proj_name in names(all_summaries)) {
  summary <- all_summaries[[proj_name]]
  
  if (!summary$exists || !is.null(summary$error) || summary$recent_detections == 0) {
    next  # Skip projects with no data
  }
  
  cat("─────────────────────────────────────────────────────────\n")
  cat(sprintf("  PROJECT %d\n", summary$project))
  cat("─────────────────────────────────────────────────────────\n\n")
  
  cat(sprintf("  Recent Activity:\n"))
  cat(sprintf("    Detections: %s\n", format(summary$recent_detections, big.mark = ",")))
  cat(sprintf("    Tags: %d\n", summary$tags))
  cat(sprintf("    Receivers: %d\n", summary$receivers))
  cat(sprintf("    Species: %d\n", summary$species))
  cat(sprintf("    Date range: %s to %s\n\n", 
              format(summary$first_detection, "%Y-%m-%d"),
              format(summary$last_detection, "%Y-%m-%d")))
  
  # Top species
  if (nrow(summary$by_species) > 0) {
    cat("  🦅 Top Species:\n")
    top_species <- head(summary$by_species, 5)
    for (i in 1:nrow(top_species)) {
      species_name <- ifelse(is.na(top_species$speciesEN[i]), "Unknown", top_species$speciesEN[i])
      cat(sprintf("    %d. %s: %s detections\n", 
                  i, species_name, format(top_species$detections[i], big.mark = ",")))
    }
    cat("\n")
  }
  
  # Top tags
  if (nrow(summary$by_tag) > 0) {
    cat("  🏷️  Top Tags:\n")
    top_tags <- head(summary$by_tag, 5)
    for (i in 1:nrow(top_tags)) {
      species_name <- ifelse(is.na(top_tags$speciesEN[i]), "Unknown", top_tags$speciesEN[i])
      cat(sprintf("    %d. Tag %d (%s): %s detections\n", 
                  i, top_tags$motusTagID[i], species_name, 
                  format(top_tags$detections[i], big.mark = ",")))
    }
    cat("\n")
  }
  
  # Top receivers
  if (nrow(summary$by_receiver) > 0) {
    cat("  📡 Top Receivers:\n")
    top_receivers <- head(summary$by_receiver, 5)
    for (i in 1:nrow(top_receivers)) {
      receiver_name <- ifelse(is.na(top_receivers$recvDeployName[i]), "Unknown", 
                              top_receivers$recvDeployName[i])
      cat(sprintf("    %d. %s: %s detections\n", 
                  i, receiver_name, format(top_receivers$detections[i], big.mark = ",")))
    }
    cat("\n")
  }
}

# Today's activity across all projects
cat("══════════════════════════════════════════════════════════\n")
cat("  🎯 TODAY'S ACTIVITY\n")
cat("══════════════════════════════════════════════════════════\n\n")

today_start <- as.numeric(as.POSIXct(Sys.Date()))
today_total <- 0

for (proj_name in names(all_summaries)) {
  summary <- all_summaries[[proj_name]]
  
  if (!summary$exists || !is.null(summary$error)) next
  
  if (exists("raw_data", summary)) {
    today_data <- summary$raw_data %>%
      filter(ts >= today_start)
    
    if (nrow(today_data) > 0) {
      cat(sprintf("  Project %d: %s detections (%d tags)\n",
                  summary$project,
                  format(nrow(today_data), big.mark = ","),
                  n_distinct(today_data$motusTagID)))
      today_total <- today_total + nrow(today_data)
    }
  }
}

if (today_total == 0) {
  cat("  No detections yet today\n")
} else {
  cat(sprintf("\n  Total today: %s detections\n", format(today_total, big.mark = ",")))
}

cat("\n")
cat("══════════════════════════════════════════════════════════\n")
cat("  ✅ DASHBOARD COMPLETE\n")
cat("══════════════════════════════════════════════════════════\n\n")

cat("💡 Quick Actions:\n")
cat("  • Check for updates: source('multi_project_monitor.R')\n")
cat("  • View logs: readLines('multi_project.log') %>% tail(30)\n")
cat("  • Update databases: Manually run monitor script\n\n")

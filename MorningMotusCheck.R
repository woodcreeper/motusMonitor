# Morning Motus Check
# Complete overview: check for updates + view dashboard

cat("\n🦅 GOOD MORNING - MOTUS CHECK\n")
cat("══════════════════════════════════════\n\n")

# Step 1: Check for updates
cat("Step 1: Checking for new data...\n")
cat("──────────────────────────────────────\n")
source("~/Dropbox/motusMonitor/multi_project_monitor.R")

cat("\n\n")

# Step 2: Show dashboard
cat("Step 2: Loading dashboard...\n")
cat("──────────────────────────────────────\n\n")
source("~/Dropbox/motusMonitor/multi_project_dashboard.R")

cat("\n☕ Have a great day!\n\n")
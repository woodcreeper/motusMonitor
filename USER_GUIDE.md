# Motus Monitor - Complete User Guide

Comprehensive guide for setting up and using the Motus Multi-Project Monitor.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Configuration](#configuration)
4. [First-Time Setup](#first-time-setup)
5. [Daily Usage](#daily-usage)
6. [Advanced Features](#advanced-features)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements

- **Operating System:** macOS 12+ or Linux
- **R Version:** 4.0 or higher
- **Disk Space:** Depends on project size
  - Small projects: 100MB - 1GB
  - Large projects: 1GB - 20GB+
- **Internet Connection:** Required for initial downloads and updates

### Required Accounts

- **Motus Account:** Active account at https://motus.org
- **Project Access:** Permission to access your project data
- **Email Account (optional):** For Gmail notifications, create an app password

### Software Installation

**Install R:**
- Download from https://www.r-project.org/
- macOS: Use the .pkg installer
- Linux: Use your package manager

**Install RStudio (recommended):**
- Download from https://posit.co/download/rstudio-desktop/
- Not required but makes things easier

---

## Installation

### Step 1: Download the Monitor

**Option A: Using Git**
```bash
cd ~/Dropbox
git clone https://github.com/woodcreeper/motusMonitor.git
```

**Option B: Manual Download**
1. Download ZIP from GitHub
2. Extract to `~/Dropbox/motusMonitor`

### Step 2: Install R Packages

Open R or RStudio and run:
```r
# Set timezone (important!)
Sys.setenv(TZ = "UTC")

# Install CRAN packages
install.packages(c("dplyr", "lubridate", "DBI", "RSQLite", "httr", "jsonlite"))

# Install motus from Birds Canada R-Universe
install.packages("motus", 
                 repos = c(birdscanada = "https://birdscanada.r-universe.dev",
                          CRAN = "https://cloud.r-project.org"))
```

**Verify installation:**
```r
library(motus)
packageVersion("motus")  # Should be 6.0.0 or higher
```

---

## Configuration

### Step 1: Create Your Config File
```bash
cd ~/Dropbox/motusMonitor
cp motus_config.env.example motus_config.env
```

### Step 2: Edit Configuration
```bash
nano motus_config.env
```

**Minimal configuration:**
```bash
# Your project numbers (comma-separated)
PROJECTS=675,676,677

# Notification method
NOTIFICATION_METHOD=desktop
```

**For email notifications, also set:**
```bash
EMAIL_TO=your.email@gmail.com
EMAIL_FROM=your.email@gmail.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
```

**Then set credentials as environment variables:**
```bash
nano ~/.zshrc  # or ~/.bashrc on Linux

# Add these lines:
export SMTP_USER="your.email@gmail.com"
export SMTP_PASSWORD="your_gmail_app_password"

# Save and reload
source ~/.zshrc
```

### Step 3: Update Script Files

**Edit `multi_project_monitor.R` line 11:**
```r
PROJECTS <- c(675, 676, 677)  # Your project numbers
```

**Edit `multi_project_dashboard.R` line 8:**
```r
PROJECTS <- c(675, 676, 677)  # Same project numbers
```

---

## First-Time Setup

### Step 1: Authenticate with Motus

The first time you access Motus data, you'll need to authenticate.

**In RStudio:**
```r
library(motus)
Sys.setenv(TZ = "UTC")

# This will prompt for username/password
tagme(675, new = TRUE, dir = "~/Dropbox/motusMonitor/motus_data_multi/project_675")
```

**Enter:**
- Username: Your Motus username
- Password: Your Motus password

Credentials are stored securely in your system keychain.

### Step 2: Download Project Databases

**Check project sizes first (optional):**
```r
# See how big each project is before downloading
for (proj in c(675, 676, 677)) {
  info <- tellme(projRecv = proj, new = TRUE)
  cat(sprintf("Project %d: %.1f MB\n", proj, info$numBytes / 1024^2))
}
```

**Download each project:**
```r
# Project 675
tagme(675, new = TRUE, dir = "~/Dropbox/motusMonitor/motus_data_multi/project_675")

# Project 676
tagme(676, new = TRUE, dir = "~/Dropbox/motusMonitor/motus_data_multi/project_676")

# Project 677
tagme(677, new = TRUE, dir = "~/Dropbox/motusMonitor/motus_data_multi/project_677")
```

**Important notes:**
- Downloads can take minutes to hours for large projects
- You can pause (Ctrl+C) and resume later
- Use `update = TRUE` to resume:
```r
  tagme(675, update = TRUE, dir = "...")
```

### Step 3: Test the System
```r
# Test monitoring script
source("multi_project_monitor.R")

# Should see:
# [timestamp] INFO: Checking for new data...
# [timestamp] INFO: No new data available (or shows new data)

# Test dashboard
source("multi_project_dashboard.R")

# Should display summary of all projects
```

### Step 4: Set Up Automation

**macOS/Linux - Using Cron:**
```bash
# Open crontab editor
crontab -e

# Add this line (press 'i' to insert)
0 * * * * /Library/Frameworks/R.framework/Resources/bin/Rscript ~/Dropbox/motusMonitor/multi_project_monitor.R >> ~/Dropbox/motusMonitor/multi_project.log 2>&1

# Save: Esc, :wq, Enter
```

**Verify:**
```bash
crontab -l  # Should show your cron job
```

**Enable permissions (macOS):**
- System Settings > Privacy & Security > Full Disk Access
- Add `/usr/sbin/cron`

---

## Daily Usage

### Morning Routine

**Simple one-command check:**
```r
source("MorningMotusCheck.R")
```

**What you'll see:**
1. New data check for all projects
2. Download summary if new data found
3. Complete dashboard with:
   - Combined statistics
   - Per-project breakdowns
   - Top species, tags, receivers
   - Today's activity

### View Recent Activity

**Last 30 log entries:**
```bash
tail -30 ~/Dropbox/motusMonitor/multi_project.log
```

**Live monitoring:**
```bash
tail -f ~/Dropbox/motusMonitor/multi_project.log
```

### Check Detection Summaries

Detailed CSV summaries are saved for each detection event:
```bash
ls ~/Dropbox/motusMonitor/motus_data_multi/project_675/summary_*.csv
```

Open in Excel, Numbers, or read in R:
```r
summary <- read.csv("motus_data_multi/project_675/summary_20251113_024325.csv")
```

---

## Advanced Features

### Custom Queries

**Track specific tag:**
```r
library(motus)
library(dplyr)
Sys.setenv(TZ = "UTC")

sql_motus <- tagme(675, update = FALSE, 
                   dir = "~/Dropbox/motusMonitor/motus_data_multi/project_675")
tbl_alltags <- tbl(sql_motus, "alltags")

# Get tag journey
tag_data <- tbl_alltags %>%
  filter(motusTagID == 101339) %>%
  collect() %>%
  mutate(time = as_datetime(ts)) %>%
  arrange(ts)

# Receiver path
tag_data %>%
  group_by(recvDeployName, recvDeployLat, recvDeployLon) %>%
  summarise(
    first = min(time),
    last = max(time),
    hits = n()
  )
```

**Species migration analysis:**
```r
# Get all Veery detections
veery <- tbl_alltags %>%
  filter(speciesEN == "Veery") %>%
  collect() %>%
  mutate(time = as_datetime(ts))

# Daily summary
veery %>%
  mutate(date = as.Date(time)) %>%
  group_by(date) %>%
  summarise(detections = n(), tags = n_distinct(motusTagID))
```

### Update Metadata

If species names show as "Unknown":
```r
# Force metadata refresh
tagme(675, forceMeta = TRUE, dir = "...")
```

### Export Data
```r
# Export recent detections
recent <- tbl_alltags %>%
  filter(ts >= as.numeric(Sys.time() - 7*86400)) %>%
  collect()

write.csv(recent, "recent_detections.csv", row.names = FALSE)
```

---

## Troubleshooting

### Common Issues

**Problem: "Database doesn't exist yet"**
- **Solution:** Run `tagme(PROJECT_NUM, new = TRUE, ...)` to create initial database

**Problem: "Please enter login name"**
- **Solution:** First-time authentication required. Enter Motus credentials.
- **Note:** Only asked once; credentials stored in system keychain

**Problem: Desktop notifications not appearing**
- **Check:** System Settings > Notifications > Terminal (enable all options)
- **Test:** `osascript -e 'display notification "Test" with title "Test"'`
- **Alternative:** Install terminal-notifier: `brew install terminal-notifier`

**Problem: Cron job not running**
- **Check cron list:** `crontab -l`
- **Check permissions:** System Settings > Privacy > Full Disk Access > cron
- **View log:** `tail -f ~/Dropbox/motusMonitor/multi_project.log`

**Problem: "Error in connection" or network issues**
- **Solution:** Check internet connection
- **Solution:** Try again later (Motus servers may be busy)
- **Solution:** Use `update = TRUE` to resume interrupted downloads

**Problem: Very slow queries on large database**
- **Solution:** Always filter before collecting:
```r
  # Good (fast)
  data <- tbl_alltags %>% filter(speciesEN == "Veery") %>% collect()
  
  # Bad (slow/crashes)
  data <- tbl_alltags %>% collect()  # Don't do this!
```

### Getting Help

**Motus-specific questions:**
- Motus documentation: https://motuswts.github.io/motus/
- Motus support: https://motus.org/data/support
- Motus forum: https://motus.org/forum

**This monitoring system:**
- GitHub issues: https://github.com/woodcreeper/motusMonitor/issues

---

## Appendix: Gmail App Password Setup

For email notifications with Gmail:

1. Go to https://myaccount.google.com/security
2. Enable "2-Step Verification" if not already enabled
3. Go to https://myaccount.google.com/apppasswords
4. Select app: "Mail"
5. Select device: "Mac" or "Other"
6. Click "Generate"
7. Copy the 16-character password
8. Use this as `SMTP_PASSWORD` (without spaces)

---

## Appendix: Cron Schedule Examples
```bash
# Every hour at :00
0 * * * * [command]

# Every 2 hours
0 */2 * * * [command]

# Every day at 8 AM
0 8 * * * [command]

# Every Monday at 9 AM
0 9 * * 1 [command]

# Every 30 minutes
*/30 * * * * [command]
```

---

## Version History

**1.0.0** - November 2025
- Initial release
- Multi-project monitoring
- Desktop/email/Slack notifications
- Automated dashboard

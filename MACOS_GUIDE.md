# Motus Monitor - macOS Silicon Mac Setup Guide

## 🍎 Optimized for Apple Silicon MacBook Pro + RStudio

This guide is specifically for macOS (Apple Silicon M1/M2/M3) users running RStudio.

---

## Prerequisites Check

### 1. Verify Your R Installation

Open RStudio and run:
```r
# Check R version (should be 4.0+)
R.version.string

# Check if you're running native ARM64 R (recommended for M1/M2/M3)
R.version$arch
# Should show "aarch64" for native Apple Silicon
```

**Important for Apple Silicon:** 
- Use the **native ARM64 version** of R from CRAN (not Intel/x86_64)
- Download from: https://cran.r-project.org/bin/macosx/
- Look for "R-x.x.x-arm64.pkg"

### 2. Verify RStudio
- RStudio Desktop should be version 2022.07.0 or newer for best Apple Silicon support
- Check: RStudio > About RStudio

---

## 📥 Installation - Using RStudio

### Step 1: Download Files

1. Download all 8 files from the outputs to a folder, e.g.:
   ```
   ~/Documents/motus-monitor/
   ```

2. In RStudio, set this as your working directory:
   ```r
   setwd("~/Documents/motus-monitor")
   ```

### Step 2: Install R Packages (in RStudio)

**Option A: Run the setup portions in RStudio Console**

```r
# Install required packages
packages <- c("motus", "dplyr", "lubridate", "DBI", "RSQLite", "httr", "jsonlite")

# Install motus from Birds Canada R-Universe
install.packages("motus", 
                repos = c(birdscanada = "https://birdscanada.r-universe.dev",
                         CRAN = "https://cloud.r-project.org"))

# Install other packages from CRAN
install.packages(c("dplyr", "lubridate", "DBI", "RSQLite", "httr", "jsonlite"))

# Verify installation
library(motus)
library(dplyr)
library(lubridate)
```

**Option B: Run the bash setup script from Terminal**

Open Terminal (Applications > Utilities > Terminal):
```bash
cd ~/Documents/motus-monitor
bash setup.sh
```

### Step 3: Configure Your Project

Edit `motus_config.env` in RStudio:
- File > Open File > motus_config.env

Change these lines:
```bash
PROJECT_NUMBER=176  # Change to YOUR project number
NOTIFICATION_METHOD=desktop  # macOS desktop notifications work great!
DATA_DIR=./motus_data
```

Save the file.

### Step 4: First Test Run (in RStudio)

Run the test script:
```r
# Make sure you're in the right directory
setwd("~/Documents/motus-monitor")

# Source the test script
source("test_setup.R")
```

### Step 5: Run the Monitor (in RStudio)

```r
# Run the main monitoring script
source("motus_monitor.R")
```

**First-time authentication:**
- You'll be prompted for your Motus username and password
- RStudio will show the prompts in the Console
- Credentials are securely stored by the R keyring package

---

## 🔔 macOS Desktop Notifications

macOS has **excellent** built-in notification support!

### Setup for Desktop Notifications

1. **Edit motus_config.env:**
   ```bash
   NOTIFICATION_METHOD=desktop
   ```

2. **Grant Terminal Notification Permission:**
   - System Settings > Notifications > Terminal
   - Enable "Allow Notifications"

3. **The notifications will appear in your Notification Center!**
   - You'll see banner notifications when tags are detected
   - They'll appear in the top-right corner
   - History is saved in Notification Center

### Example Desktop Notification:
```
┌─────────────────────────────────────┐
│  Motus Alert: New Tag Detections    │
├─────────────────────────────────────┤
│  Tag ID: 23316 (Red Knot)          │
│  156 hits across 2 receivers        │
│  See log for details                │
└─────────────────────────────────────┘
```

---

## ⏰ Scheduling - macOS Options

### Option 1: Cron (Simple, Works Great)

Open Terminal:
```bash
# Open crontab editor
crontab -e
```

Press `i` to enter insert mode, then add one of these lines:

**Check every hour:**
```bash
0 * * * * /Library/Frameworks/R.framework/Resources/bin/Rscript ~/Documents/motus-monitor/motus_monitor.R >> ~/Documents/motus-monitor/motus_data/cron.log 2>&1
```

**Check every 6 hours:**
```bash
0 */6 * * * /Library/Frameworks/R.framework/Resources/bin/Rscript ~/Documents/motus-monitor/motus_monitor.R >> ~/Documents/motus-monitor/motus_data/cron.log 2>&1
```

**Check daily at 8 AM:**
```bash
0 8 * * * /Library/Frameworks/R.framework/Resources/bin/Rscript ~/Documents/motus-monitor/motus_monitor.R >> ~/Documents/motus-monitor/motus_data/cron.log 2>&1
```

Press `Esc`, then type `:wq` and press `Enter` to save.

**Find your Rscript path:**
```bash
which Rscript
# Typically: /Library/Frameworks/R.framework/Resources/bin/Rscript
# Or if using Homebrew: /opt/homebrew/bin/Rscript
```

### Option 2: Launchd (macOS Native, More Reliable)

Launchd is macOS's native scheduling system and is more reliable than cron.

**Create a plist file:**
```bash
nano ~/Library/LaunchAgents/com.motus.monitor.plist
```

**Paste this content (adjust paths):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.motus.monitor</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>/Library/Frameworks/R.framework/Resources/bin/Rscript</string>
        <string>/Users/YOUR_USERNAME/Documents/motus-monitor/motus_monitor.R</string>
    </array>
    
    <key>StartInterval</key>
    <integer>3600</integer>  <!-- 3600 seconds = 1 hour -->
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/Documents/motus-monitor/motus_data/launchd.log</string>
    
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/Documents/motus-monitor/motus_data/launchd_error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/Library/Frameworks/R.framework/Resources/bin</string>
    </dict>
</dict>
</plist>
```

**Replace YOUR_USERNAME** with your actual username:
```bash
echo $USER  # This shows your username
```

**Load the launch agent:**
```bash
launchctl load ~/Library/LaunchAgents/com.motus.monitor.plist
```

**Useful launchd commands:**
```bash
# Start immediately
launchctl start com.motus.monitor

# Stop
launchctl stop com.motus.monitor

# Unload (disable)
launchctl unload ~/Library/LaunchAgents/com.motus.monitor.plist

# Check if running
launchctl list | grep motus
```

---

## 🎨 RStudio Workflow

### Daily RStudio Workflow

**1. Quick Check:**
```r
setwd("~/Documents/motus-monitor")

# View recent log entries
log_file <- "motus_data/motus_monitor.log"
cat(tail(readLines(log_file), 20), sep = "\n")
```

**2. Manual Check:**
```r
# Run a manual check
source("motus_monitor.R")
```

**3. Query Your Data:**
```r
library(motus)
library(dplyr)
library(lubridate)

# Load your database
sql_motus <- tagme(YOUR_PROJECT_NUMBER, 
                   dir = "./motus_data", 
                   update = FALSE)

# View all tags in your project
tbl_alltags <- tbl(sql_motus, "alltags")
tbl_alltags %>% 
  select(motusTagID, speciesEN, fullID) %>% 
  distinct() %>% 
  collect()

# Get recent detections (last 24 hours)
recent <- tbl_alltags %>%
  filter(ts >= (as.numeric(Sys.time()) - 86400)) %>%
  collect() %>%
  mutate(time = as_datetime(ts))

# Summary by receiver
recent %>%
  group_by(recvDeployName, speciesEN) %>%
  summarise(
    num_detections = n(),
    first_det = min(time),
    last_det = max(time)
  )
```

**4. Visualization:**
```r
library(ggplot2)

# Plot detections over time
recent %>%
  ggplot(aes(x = time, y = recvDeployLat, color = speciesEN)) +
  geom_point(alpha = 0.6, size = 3) +
  labs(title = "Tag Detections by Location",
       x = "Time (UTC)",
       y = "Latitude",
       color = "Species") +
  theme_minimal()
```

### RStudio Project Setup (Recommended)

Create an RStudio Project for better organization:

1. File > New Project > Existing Directory
2. Choose your `motus-monitor` folder
3. This creates a `.Rproj` file

Benefits:
- Automatic working directory management
- Better file organization
- Git integration (optional)
- Easier to reopen

---

## 🔧 Apple Silicon Specific Notes

### Potential Issues & Solutions

**1. Package Installation Fails:**

If you get compilation errors:
```r
# Install Xcode Command Line Tools first
# In Terminal:
xcode-select --install

# Then install packages with source compilation if needed
install.packages("packagename", type = "source")
```

**2. RSQLite Installation Issues:**

```r
# If RSQLite fails to install
install.packages("RSQLite", type = "source")

# Or use binary
install.packages("RSQLite", type = "mac.binary")
```

**3. Check Architecture:**

```r
# Verify you're running native ARM64
.Platform$r_arch
# Should show "aarch64" or "arm64"

# If it shows "x86_64", you're running Intel R via Rosetta
# Consider reinstalling native ARM64 R
```

**4. Homebrew R Users:**

If you installed R via Homebrew:
```bash
# Rscript location will be:
/opt/homebrew/bin/Rscript

# Use this in cron/launchd instead
```

---

## 📁 Recommended Directory Structure

```
~/Documents/motus-monitor/
│
├── motus_monitor.R           # Main script
├── motus_config.env          # Your configuration
├── setup.sh                  # Setup script
├── test_setup.R              # Test script
│
├── README.md                 # Documentation
├── QUICKSTART.md
├── CRON_SETUP_GUIDE.md
├── ARCHITECTURE.md
├── MACOS_GUIDE.md           # This file
│
├── motus-monitor.Rproj      # RStudio project (optional)
│
└── motus_data/              # Created automatically
    ├── project-XXX.motus    # Your database
    ├── motus_monitor.log
    ├── cron.log (or launchd.log)
    ├── last_check.rds
    └── detection_summary_*.csv
```

---

## 🔐 Credentials Management on Mac

### Motus Credentials

The `motus` package uses the system keyring to store credentials securely:

```r
# First time you run tagme(), you'll be prompted
library(motus)
sql_motus <- tagme(YOUR_PROJECT_NUMBER, new = TRUE)
# Enter username: your_motus_username
# Enter password: ********

# Credentials are stored in macOS Keychain
# You can view/edit them in:
# Applications > Utilities > Keychain Access
# Search for "motus"
```

### Email/Slack Credentials

For security, use environment variables in your `~/.zshrc` or `~/.bash_profile`:

```bash
# Edit your shell profile
nano ~/.zshrc  # If using zsh (default on modern macOS)
# or
nano ~/.bash_profile  # If using bash

# Add these lines:
export SMTP_USER="your.email@gmail.com"
export SMTP_PASSWORD="your_app_password"
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK"

# Save and reload
source ~/.zshrc
```

---

## 🧪 Testing Your Setup

### Complete Test in RStudio:

```r
# Set working directory
setwd("~/Documents/motus-monitor")

# Test 1: Check packages
packages <- c("motus", "dplyr", "lubridate", "DBI", "RSQLite")
for (pkg in packages) {
  if (require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat(paste("✓", pkg, "OK\n"))
  } else {
    cat(paste("✗", pkg, "MISSING\n"))
  }
}

# Test 2: Check Motus connection
library(motus)
Sys.setenv(TZ = "UTC")  # Always set this!

# Try to get sample project info
result <- tellme(projRecv = 176, new = TRUE)
print(result)

# Test 3: Test notification (if using desktop)
system('osascript -e \'display notification "Motus monitor test" with title "Test Alert"\'')
```

---

## 📊 Monitoring from RStudio

### Create a Quick Dashboard Script:

Save this as `dashboard.R`:

```r
# Motus Monitor Dashboard
# Run this in RStudio to see your monitoring status

library(motus)
library(dplyr)
library(lubridate)

# Configuration
PROJECT_NUM <- 176  # Change to your project
DATA_DIR <- "./motus_data"

cat("\n")
cat("═══════════════════════════════════════\n")
cat("     MOTUS MONITOR DASHBOARD\n")
cat("═══════════════════════════════════════\n\n")

# Check if database exists
db_file <- file.path(DATA_DIR, paste0("project-", PROJECT_NUM, ".motus"))

if (!file.exists(db_file)) {
  cat("❌ Database not found. Run motus_monitor.R first.\n\n")
  quit()
}

# Database info
file_info <- file.info(db_file)
file_size <- round(file_info$size / 1024 / 1024, 2)
cat(paste("📁 Database:", db_file, "\n"))
cat(paste("💾 Size:", file_size, "MB\n"))
cat(paste("📅 Last modified:", format(file_info$mtime, "%Y-%m-%d %H:%M:%S"), "\n\n"))

# Load database
sql_motus <- tagme(PROJECT_NUM, dir = DATA_DIR, update = FALSE)

# Get detection summary
tbl_alltags <- tbl(sql_motus, "alltags")

total_detections <- tbl_alltags %>% 
  summarise(n = n()) %>% 
  pull(n)

cat(paste("📡 Total detections:", format(total_detections, big.mark = ","), "\n\n"))

# Recent detections (last 7 days)
week_ago <- as.numeric(Sys.time()) - (7 * 24 * 3600)

recent <- tbl_alltags %>%
  filter(ts >= week_ago) %>%
  collect() %>%
  mutate(time = as_datetime(ts))

cat("═══════════════════════════════════════\n")
cat("  RECENT ACTIVITY (Last 7 Days)\n")
cat("═══════════════════════════════════════\n\n")

if (nrow(recent) > 0) {
  # By tag
  by_tag <- recent %>%
    group_by(motusTagID, speciesEN, fullID) %>%
    summarise(
      detections = n(),
      receivers = n_distinct(recv),
      .groups = "drop"
    ) %>%
    arrange(desc(detections))
  
  cat("🏷️  By Tag:\n")
  print(by_tag, n = 10)
  cat("\n")
  
  # By receiver
  by_receiver <- recent %>%
    group_by(recvDeployName) %>%
    summarise(
      detections = n(),
      tags = n_distinct(motusTagID),
      .groups = "drop"
    ) %>%
    arrange(desc(detections))
  
  cat("📡 By Receiver:\n")
  print(by_receiver, n = 10)
  cat("\n")
  
  # Timeline
  cat("📅 Daily Timeline:\n")
  daily <- recent %>%
    mutate(date = as.Date(time)) %>%
    group_by(date) %>%
    summarise(detections = n(), .groups = "drop") %>%
    arrange(date)
  print(daily)
  
} else {
  cat("No detections in the last 7 days.\n")
}

cat("\n")
cat("═══════════════════════════════════════\n\n")

# Last check time
last_check_file <- file.path(DATA_DIR, "last_check.rds")
if (file.exists(last_check_file)) {
  last_check <- readRDS(last_check_file)
  cat(paste("⏱️  Last automated check:", format(last_check, "%Y-%m-%d %H:%M:%S UTC"), "\n"))
  time_since <- difftime(Sys.time(), last_check, units = "hours")
  cat(paste("   (", round(time_since, 1), "hours ago)\n"))
}

cat("\n")
```

Run it anytime:
```r
source("dashboard.R")
```

---

## 🎯 Quick Commands Cheat Sheet

### In RStudio:

```r
# Set working directory
setwd("~/Documents/motus-monitor")

# Run monitor
source("motus_monitor.R")

# View dashboard
source("dashboard.R")

# Check logs
readLines("motus_data/motus_monitor.log") %>% tail(20)

# Check for new data (without downloading)
library(motus)
tellme(YOUR_PROJECT_NUMBER, dir = "./motus_data")

# Update database
sql_motus <- tagme(YOUR_PROJECT_NUMBER, dir = "./motus_data")
```

### In Terminal:

```bash
# Navigate to project
cd ~/Documents/motus-monitor

# Run monitor
Rscript motus_monitor.R

# View live log
tail -f motus_data/motus_monitor.log

# Check cron jobs
crontab -l

# Edit cron jobs
crontab -e

# Check launchd status
launchctl list | grep motus
```

---

## 💡 Pro Tips for Mac Users

1. **Use RStudio Projects** - Much easier to manage working directories

2. **Desktop Notifications** - Work beautifully on Mac, use them!

3. **Spotlight Search** - Your log files are indexed, searchable

4. **Quick Look** - Press Space on .csv files to preview summaries

5. **Terminal in RStudio** - Tools > Terminal > New Terminal (convenient!)

6. **Keyboard Shortcuts**:
   - `Cmd + Enter` - Run current line/selection
   - `Cmd + Shift + S` - Source file
   - `Cmd + Shift + M` - Insert pipe operator `%>%`

7. **Auto-save** - Enable in RStudio > Preferences > General

8. **Git Integration** - Consider version controlling your config and custom scripts

---

## 🆘 Troubleshooting macOS-Specific Issues

### "Operation not permitted" errors:

Give Terminal/RStudio full disk access:
1. System Settings > Privacy & Security > Full Disk Access
2. Add Terminal and/or RStudio
3. Restart the application

### Cron jobs not running:

```bash
# Check if cron has permissions
# System Settings > Privacy & Security > Full Disk Access
# Add /usr/sbin/cron

# Or use launchd instead (recommended)
```

### Desktop notifications not appearing:

```bash
# System Settings > Notifications
# Find "Terminal" or "Script Editor"
# Enable notifications
# Set alert style to "Banners" or "Alerts"
```

### R packages failing to compile:

```bash
# Install Xcode Command Line Tools
xcode-select --install

# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install dependencies
brew install openssl libgit2
```

---

## 📞 Getting Help

- **RStudio Community**: https://community.rstudio.com/
- **Motus Support**: motus@birdscanada.org
- **R Installation**: https://cran.r-project.org/bin/macosx/
- **This Documentation**: README.md, ARCHITECTURE.md

---

**You're all set up for macOS!** 🍎🦅

Your Silicon Mac is perfect for this workflow - fast, efficient, and with great notification support. Enjoy automated Motus monitoring!

# Motus Monitor - Quick Start Guide

Get your Motus tag detection monitor up and running in 5 minutes!

## 📦 What You Downloaded

- **motus_monitor.R** - Main monitoring script
- **motus_config.env** - Configuration file  
- **setup.sh** - Automated setup script
- **test_setup.R** - Test your installation
- **README.md** - Complete documentation
- **CRON_SETUP_GUIDE.md** - Scheduling guide

## ⚡ Quick Start (3 Steps)

### Step 1: Run Setup (2 minutes)

**Linux/Mac:**
```bash
cd /path/to/downloaded/files
bash setup.sh
```

**Windows:**
Open R or RStudio and run:
```r
setwd("C:/path/to/downloaded/files")
source("setup.R")
```

This will:
- Install required R packages
- Create data directory
- Test your installation

### Step 2: Configure (1 minute)

Edit `motus_config.env`:
```bash
# Change this to YOUR project number!
PROJECT_NUMBER=176  # Replace 176 with your actual project

# Choose notification method
NOTIFICATION_METHOD=log_only  # Start with this for testing
```

### Step 3: Test Run (2 minutes)

```bash
./motus_monitor.R
```

You'll be prompted for your Motus credentials. Check the log:
```bash
cat motus_data/motus_monitor.log
```

## ✅ Verify It's Working

Run the test script:
```bash
./test_setup.R
```

You should see:
```
✓ All tests passed!
```

## 🔔 Set Up Notifications (Optional)

### Email
```bash
# Edit motus_config.env:
NOTIFICATION_METHOD=email
EMAIL_TO=your-email@example.com

# For Gmail, create App Password:
# Google Account > Security > 2-Step Verification > App Passwords

export SMTP_USER="your.email@gmail.com"
export SMTP_PASSWORD="your_app_password"
```

### Slack
```bash
# Create webhook: https://api.slack.com/messaging/webhooks
export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"

# Edit motus_config.env:
NOTIFICATION_METHOD=slack
```

### Desktop (Linux/Mac)
```bash
# Install notify-send (Linux):
sudo apt-get install libnotify-bin

# Edit motus_config.env:
NOTIFICATION_METHOD=desktop
```

## ⏰ Automate with Cron

### Quick Cron Setup

```bash
# Edit crontab
crontab -e

# Add one of these lines:
# Check every hour:
0 * * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1

# Check every 6 hours:
0 */6 * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1

# Check daily at 8 AM:
0 8 * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
```

Get full path:
```bash
realpath motus_monitor.R
```

## 📊 View Your Data

### Check Logs
```bash
# Monitor log (real-time)
tail -f motus_data/motus_monitor.log

# Cron log
tail -f motus_data/cron.log

# View last 20 lines
tail -20 motus_data/motus_monitor.log
```

### View Detection Summaries
```bash
# CSV files are auto-generated
ls motus_data/detection_summary_*.csv

# View in terminal
cat motus_data/detection_summary_20251111_150000.csv
```

### Query in R
```r
library(motus)
library(dplyr)

# Load your database
sql_motus <- tagme(YOUR_PROJECT_NUMBER, dir = "./motus_data", update = FALSE)

# View recent detections
tbl_alltags <- tbl(sql_motus, "alltags")
recent <- tbl_alltags %>%
  filter(ts >= (as.numeric(Sys.time()) - 86400)) %>%  # Last 24 hours
  collect()

# Summary by tag
summary <- recent %>%
  group_by(motusTagID, speciesEN) %>%
  summarise(num_detections = n(), num_receivers = n_distinct(recv))
```

## 🔧 Common Issues

### "Permission denied"
```bash
chmod +x motus_monitor.R setup.sh test_setup.R
```

### "motus package not found"
```r
install.packages("motus", 
  repos = c(birdscanada = "https://birdscanada.r-universe.dev",
           CRAN = "https://cloud.r-project.org"))
```

### "Can't connect to Motus"
- Check internet connection
- Verify Motus credentials
- Try: https://motus.org (make sure site is up)

### Cron not running
```bash
# Check cron service
sudo systemctl status cron

# View cron jobs
crontab -l

# Check system logs
grep CRON /var/log/syslog
```

## 📚 Next Steps

1. **Customize Detection Window**: Edit `hours_back` in motus_monitor.R
2. **Filter by Species**: Modify queries to only alert for specific species
3. **Multiple Projects**: Create separate configs for each project
4. **Advanced Scheduling**: See CRON_SETUP_GUIDE.md
5. **Integration**: Export CSVs to Google Sheets, dashboards, etc.

## 🆘 Need Help?

- **Full Documentation**: See README.md
- **Cron Setup**: See CRON_SETUP_GUIDE.md
- **Motus Support**: motus@birdscanada.org
- **Test Script**: Run `./test_setup.R` to diagnose issues

## 💡 Pro Tips

1. **Start Simple**: Use `NOTIFICATION_METHOD=log_only` first
2. **Test Manually**: Run `./motus_monitor.R` a few times before setting up cron
3. **Check Logs Often**: The log file is your friend!
4. **Backup Data**: The .motus files are your local database - back them up!
5. **Update Regularly**: Keep R packages up-to-date

## 🎯 Quick Commands Cheat Sheet

```bash
# Test installation
./test_setup.R

# Run monitor manually
./motus_monitor.R

# View live log
tail -f motus_data/motus_monitor.log

# Edit config
nano motus_config.env

# Edit cron jobs
crontab -e

# View cron jobs
crontab -l

# Check database
ls -lh motus_data/*.motus
```

---

**You're all set!** 🦅

Your monitor will now automatically check for tag detections and notify you when your animals are detected. Happy tracking!

# Motus Automated Tag Detection Monitor

Automated monitoring system for Birds Canada Motus Wildlife Tracking System tag detections. Get instant notifications when your tagged animals are detected by receiver stations in the Motus network!

## 🚀 Features

- **Automated Checking**: Periodically polls the Motus server for new tag detections
- **Smart Notifications**: Get alerted via email, Slack, or desktop notifications
- **Detailed Summaries**: Receive detection summaries with tag IDs, species, locations, and timestamps
- **Efficient**: Only downloads new data, stores locally in SQLite format
- **Flexible Scheduling**: Run hourly, daily, or on any custom schedule
- **Comprehensive Logging**: Track all checks and detections with detailed logs

## 📋 Prerequisites

- **R** (version 4.0 or higher)
- **Motus account** with project registered at https://motus.org
- **Operating System**: Linux, macOS, or Windows
- **Internet connection** for downloading detection data

## 🔧 Quick Start

### 1. Clone or Download

Download all files to a directory on your computer:
```bash
mkdir motus-monitor
cd motus-monitor
# Copy all files here
```

### 2. Run Setup

**Linux/Mac:**
```bash
chmod +x setup.sh
./setup.sh
```

**Windows:**
```powershell
# Run R and execute:
source("setup.R")
```

### 3. Configure

Edit `motus_config.env` with your settings:
```bash
PROJECT_NUMBER=176  # Replace with YOUR project number
NOTIFICATION_METHOD=email  # or slack, desktop, log_only
```

### 4. Test

Run manually to test:
```bash
./motus_monitor.R
```

Check the log:
```bash
cat motus_data/motus_monitor.log
```

### 5. Schedule (Optional)

The setup script will offer to configure automatic scheduling. Or see [CRON_SETUP_GUIDE.md](CRON_SETUP_GUIDE.md) for manual setup.

## 📁 Files Included

```
motus-monitor/
├── motus_monitor.R          # Main monitoring script
├── motus_config.env          # Configuration file
├── setup.sh                  # Setup script (Linux/Mac)
├── CRON_SETUP_GUIDE.md       # Detailed scheduling guide
├── README.md                 # This file
└── motus_data/               # Created automatically
    ├── project-XXX.motus     # Your detection database
    ├── motus_monitor.log     # Monitoring log
    ├── last_check.rds        # Last check timestamp
    ├── detection_summary_*.csv  # Detection summaries
    └── cron.log              # Cron execution log
```

## ⚙️ Configuration Options

Edit `motus_config.env`:

### Essential Settings

```bash
# Your Motus project number (REQUIRED)
PROJECT_NUMBER=176

# Where to store data files
DATA_DIR=./motus_data

# Notification method
NOTIFICATION_METHOD=log_only  # Options: email, slack, desktop, log_only
```

### Email Notifications

```bash
NOTIFICATION_METHOD=email
EMAIL_TO=your-email@example.com
EMAIL_FROM=motus-monitor@yourdomain.com
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587

# Set these as environment variables:
export SMTP_USER=your.email@gmail.com
export SMTP_PASSWORD=your_app_password
```

For Gmail, you need to:
1. Enable 2-factor authentication
2. Create an App Password (Google Account > Security > App Passwords)

### Slack Notifications

```bash
NOTIFICATION_METHOD=slack

# Create webhook at: https://api.slack.com/messaging/webhooks
export SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

### Desktop Notifications

```bash
NOTIFICATION_METHOD=desktop
```

Requires:
- Linux: `libnotify-bin` (`sudo apt-get install libnotify-bin`)
- macOS: Built-in (no additional software needed)

## 🔔 How Notifications Work

When new tag detections are found, you'll receive a notification with:

- **Tag ID** and full tag identifier
- **Species** name
- **Number of detections** (hits)
- **Number of receivers** that detected the tag
- **Time range** of detections (first and last)
- **Receiver locations** where tag was detected
- **Timestamp** of the check

Example notification:
```
🦅 NEW MOTUS TAG DETECTIONS 🦅

Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tag ID: 23316 (#123:6.1@166.38)
Species: Red Knot
Detections: 156 hits across 2 receiver(s)
Time range: 2025-11-10 08:23 to 2025-11-11 14:17 UTC
Receivers: Station A, Station B

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: 1 tag(s) with 156 total detections
Check time: 2025-11-11 15:00:00 UTC
```

## 📊 Working with the Data

### View Database in R

```r
library(motus)
library(dplyr)

# Load your database
sql_motus <- tagme(176, dir = "./motus_data", update = FALSE)

# View all detections
tbl_alltags <- tbl(sql_motus, "alltags")

# Get recent detections as dataframe
recent <- tbl_alltags %>%
  filter(ts >= (as.numeric(Sys.time()) - 86400)) %>%  # Last 24 hours
  collect() %>%
  as.data.frame()

# View detection summary
summary <- recent %>%
  group_by(motusTagID, speciesEN) %>%
  summarise(
    num_detections = n(),
    num_receivers = n_distinct(recv)
  )
```

### Export Data

Detection summaries are automatically saved as CSV files in the `motus_data/` directory with timestamps:
```
detection_summary_20251111_150000.csv
```

## 🕐 Scheduling Options

### Recommended Schedules

**Frequent monitoring (active field season):**
```bash
# Every hour
0 * * * * /path/to/motus_monitor.R
```

**Regular monitoring:**
```bash
# Every 6 hours
0 */6 * * * /path/to/motus_monitor.R
```

**Daily monitoring:**
```bash
# Once per day at 8 AM
0 8 * * * /path/to/motus_monitor.R
```

**Weekday monitoring:**
```bash
# Monday-Friday at 9 AM
0 9 * * 1-5 /path/to/motus_monitor.R
```

See [CRON_SETUP_GUIDE.md](CRON_SETUP_GUIDE.md) for detailed scheduling instructions.

## 📝 Logs and Monitoring

### View Logs

```bash
# Main monitoring log
tail -f motus_data/motus_monitor.log

# Cron execution log (if using cron)
tail -f motus_data/cron.log

# View last 50 lines
tail -50 motus_data/motus_monitor.log

# Search for specific tag
grep "motusTagID: 23316" motus_data/motus_monitor.log

# Search for errors
grep ERROR motus_data/motus_monitor.log
```

### Log Format

```
[2025-11-11 15:00:00] INFO: === Motus Monitor Started ===
[2025-11-11 15:00:01] INFO: Checking for new data for project 176
[2025-11-11 15:00:05] INFO: New data check complete: Hits: 156 | Runs: 12 | Batches: 2
[2025-11-11 15:00:06] INFO: New data available! Hits: 156 Runs: 12
[2025-11-11 15:00:07] INFO: Downloading new data...
[2025-11-11 15:00:45] INFO: Data download complete
[2025-11-11 15:00:46] INFO: Retrieving detections from last 24 hours
[2025-11-11 15:00:47] INFO: Found 156 recent detections
[2025-11-11 15:00:48] INFO: Sending email notification
[2025-11-11 15:00:50] INFO: Email sent successfully
[2025-11-11 15:00:50] INFO: === Motus Monitor Completed ===
```

## 🔍 Troubleshooting

### Script Won't Run

**Check permissions:**
```bash
ls -l motus_monitor.R
# Should show: -rwxr-xr-x

# If not:
chmod +x motus_monitor.R
```

**Check R path in script:**
```bash
which R
# Update first line of motus_monitor.R if needed
```

### No Data Found

**Verify project number:**
```bash
# In R:
library(motus)
sql_motus <- tagme(YOUR_PROJECT_NUMBER, new = TRUE)
# Enter your Motus credentials when prompted
```

**Check authentication:**
- Ensure you're using correct Motus username/password
- Verify you have access to the project

### Cron Not Running

**Check cron status:**
```bash
# Linux
sudo systemctl status cron

# Mac
sudo launchctl list | grep cron
```

**Check cron logs:**
```bash
grep CRON /var/log/syslog
# or
tail -f motus_data/cron.log
```

**Test manually:**
```bash
/full/path/to/motus_monitor.R
```

### Notifications Not Working

**Email:**
- Verify SMTP credentials
- Check spam folder
- Test SMTP server connection
- For Gmail: ensure App Password is created

**Slack:**
- Verify webhook URL
- Check webhook is active in Slack settings
- Test webhook with curl:
```bash
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test message"}' \
  YOUR_WEBHOOK_URL
```

**Desktop:**
- Ensure notify-send is installed (Linux)
- Check notification permissions (macOS)

## 🔐 Security Best Practices

1. **Don't commit credentials**: Never put passwords in git repositories
2. **Use environment variables**: Store sensitive data in environment variables
```bash
export SMTP_PASSWORD=your_password
export SLACK_WEBHOOK_URL=your_webhook
```

3. **Restrict file permissions**:
```bash
chmod 600 motus_config.env
```

4. **Use SSH keys**: For running on remote servers, use SSH key authentication

## 🆘 Getting Help

### Motus Support
- **Email**: motus@birdscanada.org
- **Documentation**: https://motuswts.github.io/motus/
- **Motus Website**: https://motus.org

### R Package Issues
- **GitHub**: https://github.com/MotusWTS/motus/issues

### Script Issues
- Check logs first: `cat motus_data/motus_monitor.log`
- Review [CRON_SETUP_GUIDE.md](CRON_SETUP_GUIDE.md)
- Test script manually to see errors: `./motus_monitor.R`

## 📚 Additional Resources

- [Motus R Book](https://motuswts.github.io/motus/)
- [Motus API Documentation](https://motus.org/api/)
- [Cron Setup Guide](CRON_SETUP_GUIDE.md) (included)
- [R for Data Science](https://r4ds.had.co.nz/)

## 🔄 Updates and Maintenance

### Update R Packages
```r
# Update motus and dependencies
install.packages("motus", 
                repos = c(birdscanada = "https://birdscanada.r-universe.dev",
                         CRAN = "https://cloud.r-project.org"))
```

### Update Database
Database is automatically updated each time the script runs. To force metadata update:
```r
library(motus)
sql_motus <- tagme(YOUR_PROJECT_NUMBER, forceMeta = TRUE)
```

## 📈 Advanced Usage

### Custom Queries

You can modify `motus_monitor.R` to add custom queries. For example, to only get notifications for a specific species:

```r
# In get_recent_detections function, add:
recent_detections <- tbl_alltags %>%
  filter(ts >= cutoff_time, speciesEN == "Red Knot") %>%
  # ... rest of the query
```

### Multiple Projects

To monitor multiple projects, create separate config files and schedule separate cron jobs:

```bash
# Project 176
0 * * * * /path/to/motus_monitor.R --config=config_project176.env

# Project 177
0 * * * * /path/to/motus_monitor.R --config=config_project177.env
```

### Integration with Other Tools

The CSV summaries can be:
- Imported into Excel or Google Sheets
- Used in automated reports
- Uploaded to cloud storage
- Integrated with custom dashboards

## 📄 License

This monitoring system is provided as-is for use with the Motus Wildlife Tracking System. Please ensure you comply with Motus data sharing policies and your institution's data management requirements.

## 🙏 Acknowledgments

- **Birds Canada** for developing and maintaining the Motus system
- **Motus R Package developers** for the excellent R interface
- All contributors to the Motus network

---

**Happy Tracking!** 🦅

For questions or issues specific to this monitoring script, please review the troubleshooting section above. For Motus-specific questions, contact motus@birdscanada.org.

# Setting Up Cron Jobs for Motus Monitor

This guide will help you set up automated checking of your Motus tags using cron (Linux/Mac) or Task Scheduler (Windows).

## Linux / macOS - Using Cron

### Quick Setup
Run the setup script which will guide you through the process:
```bash
bash setup.sh
```

### Manual Setup

1. **Make the script executable:**
   ```bash
   chmod +x motus_monitor.R
   ```

2. **Edit your crontab:**
   ```bash
   crontab -e
   ```

3. **Add one of these lines** (choose based on how often you want to check):

   **Every hour:**
   ```
   0 * * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
   ```

   **Every 2 hours:**
   ```
   0 */2 * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
   ```

   **Every 6 hours:**
   ```
   0 */6 * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
   ```

   **Once per day at 8 AM:**
   ```
   0 8 * * * /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
   ```

   **Every weekday at 9 AM:**
   ```
   0 9 * * 1-5 /full/path/to/motus_monitor.R >> /full/path/to/motus_data/cron.log 2>&1
   ```

4. **Get the full path** to your script:
   ```bash
   realpath motus_monitor.R
   ```

5. **Verify your cron job:**
   ```bash
   crontab -l
   ```

### Cron Schedule Format
```
* * * * * command
│ │ │ │ │
│ │ │ │ └─── Day of week (0-7, Sunday = 0 or 7)
│ │ │ └───── Month (1-12)
│ │ └─────── Day of month (1-31)
│ └───────── Hour (0-23)
└─────────── Minute (0-59)
```

### Useful Cron Commands
```bash
# View your cron jobs
crontab -l

# Edit your cron jobs
crontab -e

# Remove all your cron jobs
crontab -r

# View cron log
tail -f motus_data/cron.log

# View monitor log
tail -f motus_data/motus_monitor.log
```

---

## Windows - Using Task Scheduler

### Using the GUI

1. **Open Task Scheduler:**
   - Press `Win + R`
   - Type `taskschd.msc`
   - Press Enter

2. **Create a New Task:**
   - Click "Create Basic Task" in the right panel
   - Name: "Motus Monitor"
   - Description: "Automated Motus tag detection monitoring"

3. **Set Trigger:**
   - Choose when to run (Daily, Weekly, etc.)
   - Set your preferred time

4. **Set Action:**
   - Action: "Start a program"
   - Program: `C:\Program Files\R\R-4.x.x\bin\Rscript.exe`
   - Arguments: `"C:\full\path\to\motus_monitor.R"`
   - Start in: `C:\full\path\to\script\directory`

5. **Finish and Test:**
   - Click Finish
   - Right-click the task and select "Run" to test

### Using PowerShell

Create a scheduled task with PowerShell:

```powershell
$action = New-ScheduledTaskAction -Execute "Rscript.exe" -Argument "C:\path\to\motus_monitor.R"
$trigger = New-ScheduledTaskTrigger -Daily -At "8:00AM"
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERNAME" -LogonType S4U
$settings = New-ScheduledTaskSettingsSet -StartWhenAvailable

Register-ScheduledTask -TaskName "Motus Monitor" -Action $action -Trigger $trigger -Principal $principal -Settings $settings
```

---

## Docker (Advanced)

If you prefer to run this in a Docker container:

1. **Create a Dockerfile:**
   ```dockerfile
   FROM rocker/r-ver:latest
   
   RUN apt-get update && apt-get install -y \
       libcurl4-openssl-dev \
       libssl-dev \
       libxml2-dev \
       cron
   
   RUN R -e "install.packages(c('motus', 'dplyr', 'lubridate', 'DBI', 'RSQLite', 'httr', 'jsonlite'), repos='https://cloud.r-project.org')"
   
   COPY motus_monitor.R /app/
   COPY motus_config.env /app/
   
   WORKDIR /app
   
   RUN chmod +x motus_monitor.R
   
   # Add cron job
   RUN echo "0 * * * * /app/motus_monitor.R" > /etc/cron.d/motus-cron
   RUN chmod 0644 /etc/cron.d/motus-cron
   RUN crontab /etc/cron.d/motus-cron
   
   CMD ["cron", "-f"]
   ```

2. **Build and run:**
   ```bash
   docker build -t motus-monitor .
   docker run -d -v $(pwd)/motus_data:/app/motus_data motus-monitor
   ```

---

## Troubleshooting

### Cron Job Not Running?

1. **Check if cron is running:**
   ```bash
   sudo systemctl status cron
   # or
   sudo service cron status
   ```

2. **Check the cron log:**
   ```bash
   grep CRON /var/log/syslog
   ```

3. **Check script permissions:**
   ```bash
   ls -l motus_monitor.R
   # Should show: -rwxr-xr-x
   ```

4. **Test the script manually:**
   ```bash
   ./motus_monitor.R
   # Check for any errors
   ```

### Path Issues in Cron

Cron runs with a minimal environment. Always use full paths:

```bash
# Bad
0 * * * * motus_monitor.R

# Good
0 * * * * /home/username/projects/motus/motus_monitor.R
```

### R Package Not Found in Cron

Add R library path to your crontab:

```bash
# Add at the top of your crontab
R_LIBS_USER=/home/username/R/library

0 * * * * /home/username/projects/motus/motus_monitor.R
```

---

## Notification Setup

### Email Notifications

For email notifications, you'll need to configure SMTP. For Gmail:

1. **Enable 2-factor authentication** on your Google account

2. **Create an App Password:**
   - Go to Google Account settings
   - Security > 2-Step Verification > App passwords
   - Generate a password for "Mail"

3. **Set environment variables:**
   ```bash
   export SMTP_USER="your.email@gmail.com"
   export SMTP_PASSWORD="your_app_password"
   ```

4. **Update motus_config.env:**
   ```bash
   NOTIFICATION_METHOD=email
   EMAIL_TO=your.email@gmail.com
   SMTP_SERVER=smtp.gmail.com
   SMTP_PORT=587
   ```

### Slack Notifications

1. **Create a Slack Incoming Webhook:**
   - Go to https://api.slack.com/messaging/webhooks
   - Create a new webhook for your channel
   - Copy the webhook URL

2. **Set the environment variable:**
   ```bash
   export SLACK_WEBHOOK_URL="https://hooks.slack.com/services/YOUR/WEBHOOK/URL"
   ```

3. **Update motus_config.env:**
   ```bash
   NOTIFICATION_METHOD=slack
   ```

### Desktop Notifications (Linux)

Install notify-send:
```bash
# Ubuntu/Debian
sudo apt-get install libnotify-bin

# Fedora/RHEL
sudo yum install libnotify
```

Update config:
```bash
NOTIFICATION_METHOD=desktop
```

---

## Monitoring Your Monitor

### View Recent Logs
```bash
# Last 20 lines of monitor log
tail -20 motus_data/motus_monitor.log

# Follow log in real-time
tail -f motus_data/motus_monitor.log

# Search for errors
grep ERROR motus_data/motus_monitor.log
```

### Check Data Directory
```bash
ls -lh motus_data/
# You should see:
# - project-XXX.motus (your database)
# - motus_monitor.log (log file)
# - last_check.rds (timestamp of last check)
# - detection_summary_*.csv (summary files)
```

### Test Notifications
Modify the script temporarily to always send notifications, or manually trigger it with recent data.

---

## Advanced: Running on a Server

For 24/7 monitoring on a remote server:

1. **Set up SSH key authentication** to your server

2. **Clone or copy** the scripts to your server

3. **Run setup** on the server

4. **Configure systemd** (alternative to cron) for better logging:

Create `/etc/systemd/system/motus-monitor.timer`:
```ini
[Unit]
Description=Motus Monitor Timer

[Timer]
OnBootSec=5min
OnUnitActiveSec=1h
Unit=motus-monitor.service

[Install]
WantedBy=timers.target
```

Create `/etc/systemd/system/motus-monitor.service`:
```ini
[Unit]
Description=Motus Monitor Service

[Service]
Type=oneshot
ExecStart=/path/to/motus_monitor.R
User=yourusername
WorkingDirectory=/path/to/script/directory
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable motus-monitor.timer
sudo systemctl start motus-monitor.timer
```

Check status:
```bash
systemctl status motus-monitor.timer
systemctl list-timers
```

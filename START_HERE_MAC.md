# 🍎 START HERE - Mac Users with RStudio

**Welcome!** You're all set to automate your Motus tag monitoring on your Silicon MacBook Pro.

---

## ⚡ Quick Start (Choose Your Path)

### Path A: RStudio Console (Easiest)

1. **Open RStudio**

2. **Set your working directory:**
   ```r
   setwd("~/Documents/motus-monitor")  # or wherever you saved the files
   ```

3. **Run the setup:**
   ```r
   source("rstudio_setup.R")
   ```
   
4. **Follow the prompts** - that's it!

---

### Path B: Terminal (Alternative)

1. **Open Terminal** (Applications > Utilities > Terminal)

2. **Navigate to your files:**
   ```bash
   cd ~/Documents/motus-monitor
   ```

3. **Run setup:**
   ```bash
   bash setup.sh
   ```

---

## 🎯 After Setup

### 1. Configure Your Project

**In RStudio:**
- File > Open File > `motus_config.env`
- Change this line:
  ```
  PROJECT_NUMBER=176
  ```
  to YOUR actual Motus project number

- Save the file (Cmd+S)

### 2. First Test Run

**In RStudio Console:**
```r
source("motus_monitor.R")
```

**What happens:**
- You'll be prompted for Motus username/password (once only)
- Script downloads your detection data
- Creates database in `motus_data/` folder
- Logs everything

**Check the log:**
```r
readLines("motus_data/motus_monitor.log") %>% tail(20)
```

### 3. View Your Dashboard

**In RStudio Console:**
```r
source("dashboard.R")
```

**You'll see:**
- Total detections
- Recent activity (last 7 days)
- Today's detections
- Summary by tag/receiver/species
- Monitoring status

---

## 🔔 Set Up Notifications

### Desktop Notifications (Recommended for Mac!)

1. **Edit config file:**
   - Open `motus_config.env`
   - Change:
     ```
     NOTIFICATION_METHOD=desktop
     ```

2. **Enable Terminal notifications:**
   - System Settings > Notifications > Terminal
   - Turn on "Allow Notifications"

3. **Test it:**
   ```r
   source("motus_monitor.R")
   ```
   If new detections are found, you'll get a macOS notification! 🎉

---

## ⏰ Automate It (Run Every Hour)

### Option 1: Cron (Simplest)

**In Terminal:**
```bash
crontab -e
```

**Press `i`, then paste this line (replace paths):**
```bash
0 * * * * /Library/Frameworks/R.framework/Resources/bin/Rscript ~/Documents/motus-monitor/motus_monitor.R >> ~/Documents/motus-monitor/motus_data/cron.log 2>&1
```

**Press Esc, type `:wq`, press Enter**

**To find your Rscript path:**
```bash
which Rscript
```

### Option 2: Launchd (macOS Native)

See **MACOS_GUIDE.md** section "Scheduling - macOS Options" for detailed launchd setup.

---

## 📊 Daily Workflow in RStudio

**Create a keyboard shortcut or save these:**

```r
# Set timezone (do this once per session)
Sys.setenv(TZ = "UTC")

# Quick check for new data
library(motus)
tellme(YOUR_PROJECT_NUMBER, dir = "./motus_data")

# Update database
source("motus_monitor.R")

# View dashboard
source("dashboard.R")

# Check recent logs
readLines("motus_data/motus_monitor.log") %>% tail(30)

# Query your data
sql_motus <- tagme(YOUR_PROJECT_NUMBER, dir = "./motus_data", update = FALSE)
tbl_alltags <- tbl(sql_motus, "alltags")
```

---

## 📁 Your Files

```
~/Documents/motus-monitor/
│
├── START_HERE_MAC.md        ⭐ This file
├── MACOS_GUIDE.md            Complete Mac guide
├── README.md                 Full documentation
├── QUICKSTART.md             Quick reference
│
├── rstudio_setup.R          ⚡ Run this first in RStudio
├── motus_monitor.R           Main monitoring script
├── dashboard.R              📊 View your detections
├── motus_config.env         ⚙️ Your settings
│
└── motus_data/               📁 Created automatically
    ├── project-XXX.motus     Your detection database
    ├── motus_monitor.log     Activity log
    └── detection_summary_*.csv  Summaries
```

---

## 🎓 What You Can Do

### In RStudio:

**Basic:**
- Check for new detections: `source("motus_monitor.R")`
- View dashboard: `source("dashboard.R")`
- Read logs: `readLines("motus_data/motus_monitor.log")`

**Advanced:**
- Query database with dplyr
- Create visualizations with ggplot2
- Export data to CSV/Excel
- Build custom analyses
- Generate reports

**Example queries:**
```r
library(motus)
library(dplyr)

# Load database
sql_motus <- tagme(176, dir = "./motus_data", update = FALSE)
tbl_alltags <- tbl(sql_motus, "alltags")

# Get today's detections
today <- tbl_alltags %>%
  filter(ts >= as.numeric(as.POSIXct(Sys.Date()))) %>%
  collect()

# Summary by species
tbl_alltags %>%
  group_by(speciesEN) %>%
  summarise(detections = n(), tags = n_distinct(motusTagID)) %>%
  collect()

# Map recent detections
library(ggplot2)
recent <- tbl_alltags %>%
  filter(ts >= as.numeric(Sys.time() - 86400*7)) %>%
  collect()

ggplot(recent, aes(x = recvDeployLon, y = recvDeployLat, 
                   color = speciesEN, size = sig)) +
  geom_point(alpha = 0.6) +
  theme_minimal() +
  labs(title = "Detections - Last 7 Days")
```

---

## 🆘 Quick Troubleshooting

### "Cannot find motus package"
```r
install.packages("motus", 
  repos = c(birdscanada = "https://birdscanada.r-universe.dev",
           CRAN = "https://cloud.r-project.org"))
```

### "Permission denied"
```bash
chmod +x *.R *.sh
```

### "Cron not working"
- Check: System Settings > Privacy & Security > Full Disk Access
- Add: /usr/sbin/cron
- Or use launchd instead

### "Can't connect to Motus"
- Check internet connection
- Verify credentials at https://motus.org
- Try manual download: `tagme(YOUR_PROJECT, new = TRUE)`

### Notifications not appearing
- System Settings > Notifications > Terminal
- Enable notifications
- Set style to "Banners"

---

## 🎯 Common Tasks

| Task | Command |
|------|---------|
| **First setup** | `source("rstudio_setup.R")` |
| **Check for new data** | `source("motus_monitor.R")` |
| **View dashboard** | `source("dashboard.R")` |
| **Read logs** | `readLines("motus_data/motus_monitor.log")` |
| **Edit cron** | In Terminal: `crontab -e` |
| **Test notification** | In Terminal: `osascript -e 'display notification "Test" with title "Motus"'` |

---

## 📚 Documentation Map

**Start here:** ← You are here
↓
**MACOS_GUIDE.md** - Complete macOS setup with launchd, notifications, etc.
↓
**README.md** - Full feature documentation
↓
**ARCHITECTURE.md** - How everything works under the hood

**Quick Reference:** QUICKSTART.md
**Scheduling Details:** CRON_SETUP_GUIDE.md

---

## 💡 Pro Tips

1. **Create an RStudio Project** (File > New Project) for this folder
2. **Use desktop notifications** - they're perfect on Mac!
3. **Check your dashboard daily** - just run `source("dashboard.R")`
4. **Keep R packages updated** - `update.packages()`
5. **Back up your .motus database** - it's valuable!

---

## ✅ Success Checklist

- [ ] Ran `source("rstudio_setup.R")`
- [ ] Changed `PROJECT_NUMBER` in `motus_config.env`
- [ ] Successfully ran `source("motus_monitor.R")`
- [ ] Entered Motus credentials
- [ ] Database created in `motus_data/`
- [ ] Dashboard shows data: `source("dashboard.R")`
- [ ] Configured notification method
- [ ] Set up cron or launchd (optional but recommended)
- [ ] Tested notifications

---

## 🎉 You're Done!

Your Motus tag monitoring is now automated. Your Mac will:
- Check for new detections automatically
- Download only new data (efficient!)
- Send you notifications when tags are detected
- Log everything for review
- Store data locally for analysis

**Next time you open RStudio:**
1. Open the project (if you created one)
2. Run `source("dashboard.R")` to see what's new
3. That's it!

---

## 🚀 Going Further

**Want to customize?**
- Edit detection time window in `motus_monitor.R`
- Filter by specific species
- Change notification format
- Add custom queries to dashboard
- Create visualization scripts

**Need help?**
- Motus Support: motus@birdscanada.org
- Motus R Book: https://motuswts.github.io/motus/
- Full docs: See README.md

---

**Happy tracking!** 🦅

Your tags are now being monitored 24/7. You'll get notifications whenever they're detected anywhere in the Motus network!

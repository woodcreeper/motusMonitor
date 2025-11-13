# Motus Monitor - System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    MOTUS MONITOR SYSTEM                      │
└─────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│  Cron Job    │────────▶│  R Script    │────────▶│ Notifications │
│  (Scheduler) │         │  (Monitor)   │         │ (Email/Slack) │
└──────────────┘         └──────────────┘         └──────────────┘
       │                        │                         │
       │                        │                         │
       ▼                        ▼                         ▼
  Every hour            Motus API/DB              User receives
  (or custom)           Local SQLite              alert with
                        Data processing           detection info
```

## Detailed Workflow

### 1. Scheduled Execution
```
Cron Job (or Task Scheduler)
    │
    ├─ Runs at specified intervals (e.g., hourly)
    ├─ Executes: motus_monitor.R
    ├─ Redirects output to: cron.log
    └─ Records: Execution time, exit status
```

### 2. Monitor Script Execution
```
motus_monitor.R starts
    │
    ├─ Load configuration (motus_config.env)
    │  └─ Project number, notification settings, etc.
    │
    ├─ Check for new data (tellme() function)
    │  │
    │  ├─ Connect to Motus server API
    │  ├─ Query: "Any new detections for project X?"
    │  └─ Returns: numHits, numRuns, numBatches, numGPS
    │
    ├─ IF new data exists:
    │  │
    │  ├─ Download data (tagme() function)
    │  │  ├─ Downloads to: ./motus_data/project-XXX.motus
    │  │  ├─ Format: SQLite database
    │  │  └─ Contains: detections, metadata, GPS, etc.
    │  │
    │  ├─ Query recent detections
    │  │  ├─ Calculate time window (e.g., last 24 hours)
    │  │  ├─ Query SQLite database
    │  │  └─ Extract: tag IDs, species, receivers, timestamps
    │  │
    │  ├─ Summarize detections
    │  │  ├─ Group by: tag ID, species
    │  │  ├─ Calculate: num detections, num receivers
    │  │  └─ Format: Human-readable summary
    │  │
    │  ├─ Send notification
    │  │  └─ Choose method: email, Slack, desktop, or log
    │  │
    │  └─ Save summary (CSV file)
    │     └─ Location: ./motus_data/detection_summary_*.csv
    │
    ├─ IF no new data:
    │  └─ Log: "No new data available"
    │
    └─ Save check timestamp (last_check.rds)
```

### 3. Notification Flow

```
NOTIFICATION SYSTEM
    │
    ├─ Email (SMTP)
    │  │
    │  ├─ Compose message
    │  ├─ Connect to SMTP server (e.g., smtp.gmail.com:587)
    │  ├─ Authenticate (SMTP_USER, SMTP_PASSWORD)
    │  └─ Send email to EMAIL_TO
    │
    ├─ Slack (Webhook)
    │  │
    │  ├─ Format message (markdown)
    │  ├─ POST to webhook URL
    │  └─ Message appears in Slack channel
    │
    ├─ Desktop (notify-send)
    │  │
    │  ├─ Create notification
    │  └─ Display on desktop (Linux/Mac)
    │
    └─ Log Only
       └─ Write to motus_monitor.log
```

## Data Flow Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      MOTUS NETWORK                            │
│  Receivers worldwide detecting tags, uploading to central DB  │
└───────────────────────────┬──────────────────────────────────┘
                            │
                            │ Internet
                            ▼
                    ┌───────────────┐
                    │  Motus API    │
                    │  Server       │
                    └───────┬───────┘
                            │
                            │ tellme()  "Any new data?"
                            │ tagme()   "Download new data"
                            │
                            ▼
             ┌──────────────────────────────┐
             │   Your Computer              │
             │                              │
             │  ┌────────────────────────┐  │
             │  │  motus_monitor.R       │  │
             │  │  (R Script)            │  │
             │  └───────────┬────────────┘  │
             │              │                │
             │              ▼                │
             │  ┌────────────────────────┐  │
             │  │  Local SQLite Database │  │
             │  │  project-XXX.motus     │  │
             │  │                        │  │
             │  │  Tables:               │  │
             │  │  - alltags (main view) │  │
             │  │  - hits                │  │
             │  │  - runs                │  │
             │  │  - batches             │  │
             │  │  - recvDeps (stations) │  │
             │  │  - tagDeps (tags)      │  │
             │  │  - species             │  │
             │  └───────────┬────────────┘  │
             │              │                │
             │              ▼                │
             │  ┌────────────────────────┐  │
             │  │  Query & Process       │  │
             │  │  - Filter by time      │  │
             │  │  - Group by tag        │  │
             │  │  - Summarize           │  │
             │  └───────────┬────────────┘  │
             │              │                │
             └──────────────┼────────────────┘
                            │
                            ▼
             ┌──────────────────────────────┐
             │   Outputs                     │
             │                               │
             │  - Email notification         │
             │  - Slack message              │
             │  - Desktop alert              │
             │  - Log file entry             │
             │  - CSV summary file           │
             └───────────────────────────────┘
```

## File Structure

```
your-project-directory/
│
├── motus_monitor.R          # Main script (executable)
├── motus_config.env          # Configuration file
├── setup.sh                  # Setup/installation script
├── test_setup.R              # Testing script
│
├── README.md                 # Full documentation
├── CRON_SETUP_GUIDE.md       # Cron configuration guide
├── QUICKSTART.md             # Quick start guide
│
└── motus_data/               # Data directory (created automatically)
    │
    ├── project-XXX.motus     # SQLite database (downloaded from Motus)
    │                         # Contains all tag detections
    │
    ├── motus_monitor.log     # Main log file
    │                         # Records all checks and actions
    │
    ├── cron.log              # Cron execution log
    │                         # Records when cron runs the script
    │
    ├── last_check.rds        # Timestamp of last check (R object)
    │                         # Used to calculate time window
    │
    └── detection_summary_*.csv  # Detection summaries (timestamped)
                                 # One file per detection event
```

## Component Details

### Motus API Functions

**tellme(projRecv, dir, new)**
- Purpose: Check for new data without downloading
- Returns: List with numHits, numRuns, numBatches, numGPS, numBytes
- Use case: Quick check before deciding to download

**tagme(projRecv, dir, new, update)**
- Purpose: Download/update detection database
- Returns: SQLite connection object
- Creates/updates: project-XXX.motus file
- Parameters:
  - projRecv: Project number or receiver serial
  - new: TRUE for first download
  - update: TRUE to check for new data
  - dir: Directory for database storage

### Database Structure

```
SQLite Database (project-XXX.motus)
│
├── Tables (Raw data)
│   ├── hits      - Individual tag detections
│   ├── runs      - Continuous detection sequences
│   ├── batches   - Upload batches from receivers
│   ├── tags      - Tag metadata
│   ├── tagDeps   - Tag deployment info
│   ├── recvs     - Receiver metadata
│   ├── recvDeps  - Receiver deployment info
│   └── species   - Species information
│
└── Views (Pre-joined data)
    ├── alltags     - Complete detection data (most used)
    ├── alltagsGPS  - With GPS coordinates
    └── allambigs   - Ambiguous detections
```

### Key Fields in 'alltags' View

```
Detection Information:
- hitID          - Unique hit identifier
- runID          - Run identifier
- ts             - Timestamp (seconds since 1970-01-01)
- sig            - Signal strength
- freq           - Frequency

Tag Information:
- motusTagID     - Unique Motus tag ID
- fullID         - Full tag identifier string
- speciesEN      - Species (English name)
- mfgID          - Manufacturer tag ID
- tagBI          - Burst interval

Receiver Information:
- recv           - Receiver serial number
- recvDeployName - Receiver station name
- recvDeployLat  - Receiver latitude
- recvDeployLon  - Receiver longitude
- port           - Antenna port number

Deployment Information:
- tagDeployStart - Tag deployment start time
- tagDeployLat   - Tag deployment latitude
- tagDeployLon   - Tag deployment longitude
```

## Process Flow - First Time Setup

```
1. Download files
   └─▶ Extract to directory

2. Run setup.sh
   │
   ├─▶ Check R installation
   ├─▶ Install R packages (motus, dplyr, etc.)
   ├─▶ Create data directory
   ├─▶ Test configuration
   └─▶ Offer cron setup

3. Edit motus_config.env
   │
   ├─▶ Set PROJECT_NUMBER
   ├─▶ Choose NOTIFICATION_METHOD
   └─▶ Configure credentials (if needed)

4. Test run
   │
   ├─▶ ./motus_monitor.R
   ├─▶ Enter Motus credentials
   ├─▶ Downloads database (first time: may take time)
   └─▶ Check logs

5. Set up automation
   │
   ├─▶ crontab -e
   ├─▶ Add schedule line
   └─▶ Save and exit

6. Monitor
   │
   ├─▶ Check logs: tail -f motus_data/motus_monitor.log
   ├─▶ Review summaries: cat motus_data/detection_summary_*.csv
   └─▶ Receive notifications
```

## Process Flow - Ongoing Operation

```
Every check cycle (e.g., hourly):

1. Cron triggers script
   └─▶ Executes motus_monitor.R

2. Script loads config
   └─▶ Reads motus_config.env

3. Check last run time
   └─▶ Read last_check.rds

4. Query Motus server
   │
   ├─▶ tellme(PROJECT_NUMBER)
   └─▶ Returns data availability

5. IF new data:
   │
   ├─▶ Download: tagme(PROJECT_NUMBER, update = TRUE)
   ├─▶ Query recent detections
   ├─▶ Generate summary
   ├─▶ Send notification
   └─▶ Save CSV summary

6. IF no new data:
   └─▶ Log: "No new data"

7. Update timestamp
   └─▶ Save current time to last_check.rds

8. Script exits
   └─▶ Cron waits for next scheduled run
```

## Notification Message Format

```
🦅 NEW MOTUS TAG DETECTIONS 🦅

Summary:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Tag ID: [motusTagID] ([fullID])
Species: [speciesEN]
Detections: [X] hits across [Y] receiver(s)
Time range: [first_detection] to [last_detection] UTC
Receivers: [list of station names]

[... repeated for each tag ...]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Total: [N] tag(s) with [M] total detections
Check time: [timestamp]
```

## Error Handling

The script handles various error conditions:

```
Error Type              Action
───────────────────────────────────────────────────
Network failure         Log error, continue
Authentication failed   Log error, exit (retry next cycle)
Database locked         Wait and retry
API timeout             Log error, continue
Notification failed     Log error, but mark check complete
Invalid configuration   Log error, exit
Insufficient disk space Log error, cleanup old files
```

## Performance Considerations

**Database Size:**
- Initial download: Can be large (100MB - several GB)
- Updates: Only new data downloaded (efficient)
- Storage: Plan for database growth over time

**Check Frequency:**
- Recommended: Every 1-6 hours
- Too frequent: Unnecessary API load, no new data
- Too infrequent: May miss time-sensitive detections

**Network:**
- Requires stable internet connection
- Initial download may take 5-60 minutes
- Updates typically < 1 minute

**System Resources:**
- R process: ~50-200MB RAM during execution
- Database: Disk space proportional to detections
- CPU: Minimal (mostly I/O bound)

## Security Model

```
Credentials Storage:
├─ Motus username/password
│  └─▶ Stored by R package (secure keyring)
│
├─ SMTP credentials
│  └─▶ Environment variables (not in files)
│
└─ Slack webhook
   └─▶ Environment variables (not in files)

File Permissions:
├─ Scripts: rwxr-xr-x (755) - Executable
├─ Config: rw------- (600) - Private
└─ Data: rw-r--r-- (644) - Read for user/group
```

## Customization Points

You can customize the system at these points:

1. **Detection window** (in motus_monitor.R)
   - Modify `hours_back` parameter
   
2. **Species filter** (in motus_monitor.R)
   - Add filter: `filter(speciesEN == "Red Knot")`
   
3. **Notification format** (in motus_monitor.R)
   - Modify `format_detection_summary()`
   
4. **Check schedule** (in crontab)
   - Change cron schedule expression
   
5. **Database location** (in motus_config.env)
   - Change DATA_DIR path
   
6. **Notification method** (in motus_config.env)
   - Switch between email, Slack, desktop, log

## Troubleshooting Decision Tree

```
Script not running?
│
├─▶ Check: Is cron running? (systemctl status cron)
│   ├─ No: Start cron service
│   └─ Yes: Continue
│
├─▶ Check: Is cron job configured? (crontab -l)
│   ├─ No: Add cron job
│   └─ Yes: Continue
│
├─▶ Check: Script permissions? (ls -l motus_monitor.R)
│   ├─ Not executable: chmod +x motus_monitor.R
│   └─ Executable: Continue
│
├─▶ Check: Manual run works? (./motus_monitor.R)
│   ├─ No: Check R packages, config
│   └─ Yes: Check cron logs
│
└─▶ Check: cron.log for errors
    └─▶ Review and fix specific error
```

---

## Summary

This system provides automated, reliable monitoring of your Motus-tagged animals with:

- **Efficiency**: Only downloads new data
- **Flexibility**: Multiple notification options
- **Reliability**: Error handling and logging
- **Scalability**: Works for projects of any size
- **Transparency**: Complete logging of all operations

The modular design allows you to customize any component while maintaining overall system integrity.

#!/bin/bash
mkdir -p attendance_tracker_v1/Helpers/ attendance_tracker_v1/reports/
touch attendance_tracker_v1/attendance_checker.py attendance_tracker_v1/Helpers/assets.csv attendance_tracker_v1/Helpers/config.json attendance_tracker_v1/reports/reports.log
echo "import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    # 1. Load Config
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)
    
    # 2. Archive old reports.log if it exists
    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    # 3. Process Data
    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']
        
        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")
        
        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])
            
            # Simple Math: (Attended / Total) * 100
            attendance_pct = (attended / total_sessions) * 100
            
            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."
            
            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()" > attendance_tracker_v1/attendance_checker.py
echo "Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0" > attendance_tracker_v1/Helpers/assets.csv
echo "{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}" > attendance_tracker_v1/Helpers/config.json
echo "--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class." > attendance_tracker_v1/reports/reports.log
# Ask the user if they want to update the attendance thresholds 
read -p "Do you want to update the attendance thresholds? (y/n): " choice 
if [ "$choice" = "y" ]; then 
	# Ask for the new Warning threshold 
	read -p "Enter Warning threshold : " warning 
	warning=${warning:-75} 
	# Ask for the new Failure threshold 
	read -p "Enter Failure threshold : " failure 
	failure=${failure:-50} 
	# Update the Warning threshold 
	sed -i "s/\"warning_threshold\": [0-9]*/\"warning_threshold\": $warning/" config.json 
	# Update the Failure threshold 
	sed -i "s/\"failure_threshold\": [0-9]*/\"failure_threshold\": $failure/" config.json 
	echo "Attendance thresholds updated successfully." 
else 
	echo "Attendance thresholds were not changed." 
fi 
PROJECT_DIR="attendance_tracker_v1" 
i="$1" 
ARCHIVE_NAME="attendance_tracker_${i}_archive.tar.gz" 
# Function executed when Ctrl+C (SIGINT) is received 
handle_interrupt() { 
	echo 
	echo "Script interrupted by user (Ctrl+C)." 
	echo "Creating an archive of the current project state..." 
	# Check that the project directory still exists 
	if [ -d "$PROJECT_DIR" ]; then 
		tar -czf "$ARCHIVE_NAME" "$PROJECT_DIR" 
		echo "Archive created: $ARCHIVE_NAME" 
		rm -rf "$PROJECT_DIR" 
		echo "Incomplete project directory deleted." 
	else 
		echo "Project directory does not exist." 
	fi
	exit 1 
} 
# Catch SIGINT (Ctrl+C) and call handle_interrupt 
trap 'handle_interrupt' SIGINT 
# Create the project directory 
mkdir -p "$PROJECT_DIR" 
echo "Attendance tracker is running..." 
echo "Press Ctrl+C to cancel and archive the current state." 
while true; do 
	echo "Processing attendance data..." 
	sleep 2 
done
# Health Check: verify that Python 3 is installed
if python3 --version; then
	echo "SUCCESS: Python 3 is installed."
else
	echo "WARNING: Python 3 is not installed."
fi
# Check that the required application directory exists
if [ -d "attendance_tracker" ]; then
	echo "SUCCESS: Application directory structure is present."
else
	echo "WARNING: Application directory structure is missing."
fi

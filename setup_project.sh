#!/bin/bash
# Project directory and archive name
Project_dir="attendance_tracker_v1"
i="$1"
archive_name="attendance_tracker_${i}_archive.tar.gz"
handle_interrupt() {
	# Script interrupted by user (Ctrl+C).
	echo "Archiving the current project state"
	# Check that the project directory exists
	if [ -d "$Project_dir" ]; then
		tar -czf "$archive_name" "$Project_dir"
		echo "Archive created: $archive_name"
		rm -rf "$Project_dir"
		echo "Incomplete project directory deleted."
	else
		echo "Project directory does not exist."
	fi
	exit 1
}
# Catch SIGINT
trap 'handle_interrupt' SIGINT
# The required application directory and its structure
mkdir -p "$Project_dir/Helpers" "$Project_dir/reports"
# Required files
touch "$Project_dir/attendance_checker.py" "$Project_dir/Helpers/assets.csv" "$Project_dir/Helpers/config.json" "$Project_dir/reports/reports.log"
cat > "$Project_dir/attendance_checker.py" <<'PYTHON'
#!/usr/bin/python3
import csv
import json
import os
from datetime import datetime
def run_attendance_check():
	# 1. Load configuration
	with open('Helpers/config.json', 'r') as f:
		config = json.load(f)
	# 2. Archive old reports.log if it exists
	if os.path.exists('reports/reports.log'):
		timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
		os.rename(
			'reports/reports.log',
			f'reports/reports_{timestamp}.log.archive'
		)
	# 3. Process attendance data
	with open('Helpers/assets.csv', mode='r') as f, \
			open('reports/reports.log', 'w') as log:
		reader = csv.DictReader(f)
		total_sessions = config['total_sessions']
		log.write(
			f"--- Attendance Report Run: {datetime.now()} ---\n"
		)
		for row in reader:
			name = row['Names']
			email = row['Email']
			attended = int(row['Attendance Count'])
			attendance_pct = (attended / total_sessions) * 100
			message = ""
			if attendance_pct < config['thresholds']['failure']:
				message = (
					f"URGENT: {name}, your attendance is "
					f"{attendance_pct:.1f}%. You will fail this class."
				)
			elif attendance_pct < config['thresholds']['warning']:
				message = (
					f"WARNING: {name}, your attendance is "
					f"{attendance_pct:.1f}%. Please be careful."
				)
			if message:
				if config['run_mode'] == "live":
					log.write(
						f"[{datetime.now()}] ALERT SENT TO "
						f"{email}: {message}\n"
					)
					print(f"Logged alert for {name}")
				else:
					print(
						f"[DRY RUN] Email to {email}: {message}"
					)
if __name__ == "__main__":
	run_attendance_check()
PYTHON
cat > "$Project_dir/Helpers/assets.csv" <<'CSV'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSV
cat > "$Project_dir/Helpers/config.json" <<'JSON'
{
"thresholds": {
	"warning": 75,
	"failure": 50
},
"run_mode": "live",
"total_sessions": 15
}
JSON
cat > "$Project_dir/reports/reports.log" <<'LOG'
--- Attendance Report Run: 2026-02-06 18:10:01.468726 ---
[2026-02-06 18:10:01.469363] ALERT SENT TO bob@example.com: URGENT: Bob Smith, your attendance is 46.7%. You will fail this class.
[2026-02-06 18:10:01.469424] ALERT SENT TO charlie@example.com: URGENT: Charlie Davis, your attendance is 26.7%. You will fail this class.
LOG
echo "Project structure created successfully."
#Updating the attendance thresholds
read -p "Update the attendance thresholds? (y/n): " choice
if [ "$choice" = "y" ]; then
	read -p "Enter Warning threshold: " warning
	warning=${warning:-75}
	read -p "Enter Failure threshold: " failure
	failure=${failure:-50}
	# Update config.json
	sed -i "s/\"warning\": [0-9]*/\"warning\": $warning/" \
		"$Project_dir/Helpers/config.json"
	sed -i "s/\"failure\": [0-9]*/\"failure\": $failure/" \
		"$Project_dir/Helpers/config.json"
	echo "Updated successfully."
else
	echo "No changed."
fi
# Verify that Python 3 is installed
if python3 --version; then
	echo "Python is installed."
else
	echo "Python isn't installed."
fi
# Check that the required application directory exists
if [ -d "$Project_dir" ] && \
[ -d "$Project_dir/Helpers" ] && \
[ -d "$Project_dir/reports" ]; then
	echo "Required app dir structure is present."
else
	echo "Needed structure is missing."
fi
echo "Tracker running"
echo "Press Ctrl+C to stop and archive"
while true; do
    echo "Processing attendance data"
    sleep 2
done

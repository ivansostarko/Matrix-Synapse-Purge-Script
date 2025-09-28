#!/bin/bash

# Script to purge old messages and media from Matrix Synapse
# Retention period: 7 days
# Assumes PostgreSQL database and default Synapse paths

# Configuration
SYNAPSE_CONFIG="/etc/matrix-synapse/homeserver.yaml"
DB_NAME="synapse"
DB_USER="synapse_user"
MEDIA_STORE="/var/lib/matrix-synapse/media"
RETENTION_DAYS=7
RETENTION_MS=$((RETENTION_DAYS * 24 * 60 * 60 * 1000)) # Convert days to milliseconds
LOG_FILE="/var/log/matrix-synapse/purge.log"

# Ensure script runs as matrix-synapse user
if [ "$(whoami)" != "matrix-synapse" ]; then
    echo "This script must be run as the matrix-synapse user" | tee -a "$LOG_FILE"
    exit 1
fi

# Log start time
echo "Starting purge at $(date)" >> "$LOG_FILE"

# Step 1: Purge old events from the database
# Note: Synapse's purge_room requires room IDs, so we use a SQL query to find old events
# This query deletes events older than RETENTION_MS milliseconds
PSQL_CMD="psql -U $DB_USER -d $DB_NAME -c"
$PSQL_CMD "
    DELETE FROM event_json
    WHERE event_id IN (
        SELECT event_id
        FROM events
        WHERE received_ts < (EXTRACT(EPOCH FROM NOW()) * 1000 - $RETENTION_MS)
    );
" >> "$LOG_FILE" 2>&1

if [ $? -eq 0 ]; then
    echo "Successfully purged old events from database" >> "$LOG_FILE"
else
    echo "Error purging old events from database" >> "$LOG_FILE"
    exit 1
fi

# Step 2: Purge old media files
# Delete media files older than 7 days
find "$MEDIA_STORE" -type f -mtime +$RETENTION_DAYS -delete >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "Successfully purged media files older than $RETENTION_DAYS days" >> "$LOG_FILE"
else
    echo "Error purging media files" >> "$LOG_FILE"
    exit 1
fi

# Step 3: Compact the database
$PSQL_CMD "VACUUM FULL;" >> "$LOG_FILE" 2>&1
if [ $? -eq 0 ]; then
    echo "Successfully compacted database" >> "$LOG_FILE"
else
    echo "Error compacting database" >> "$LOG_FILE"
    exit 1
fi

# Log completion
echo "Purge completed at $(date)" >> "$LOG_FILE"

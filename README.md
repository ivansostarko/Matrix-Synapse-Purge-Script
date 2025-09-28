# Matrix Synapse Purge Script

This repository contains a Bash script (`purge_synapse.sh`) designed to automate the cleanup of old messages and media in a Matrix Synapse server. The script purges events and media files older than a specified retention period (default: 7 days) and compacts the PostgreSQL database to reclaim space. It is intended to be run as a daily cron job on an Ubuntu server hosting Matrix Synapse.

## Features
- **Purge Old Messages**: Deletes events older than 7 days from the Synapse database using a PostgreSQL query.
- **Purge Old Media**: Removes media files older than 7 days from the Synapse media store.
- **Database Compaction**: Runs `VACUUM FULL` to reclaim database space after purging.
- **Logging**: Outputs progress and errors to a log file for monitoring.
- **Cron Automation**: Configured to run daily via a cron job.

## Prerequisites
- **Matrix Synapse**: Installed and running on an Ubuntu server.
- **PostgreSQL**: Synapse database configured with PostgreSQL.
- **User Permissions**: Script must run as the `matrix-synapse` user (or the user running Synapse).
- **Access**: The Synapse user must have permissions to access the database and media store.

## Installation
1. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/matrix-synapse-purge.git
   cd matrix-synapse-purge
   ```

2. **Copy the Script**:
   Move the script to a suitable location, e.g., `/usr/local/bin/`:
   ```bash
   sudo cp purge_synapse.sh /usr/local/bin/purge_synapse.sh
   sudo chmod +x /usr/local/bin/purge_synapse.sh
   ```

3. **Configure the Script**:
   Edit `purge_synapse.sh` to match your Synapse setup:
   - `DB_NAME`: Your Synapse database name (e.g., `synapse`).
   - `DB_USER`: PostgreSQL user for Synapse (e.g., `synapse_user`).
   - `MEDIA_STORE`: Path to the Synapse media store (e.g., `/var/lib/matrix-synapse/media`).
   - `SYNAPSE_CONFIG`: Path to `homeserver.yaml` (e.g., `/etc/matrix-synapse/homeserver.yaml`).
   - `RETENTION_DAYS`: Retention period in days (default: `7`).

4. **Set Up Logging**:
   Create a log file and set permissions:
   ```bash
   sudo touch /var/log/matrix-synapse/purge.log
   sudo chown matrix-synapse:matrix-synapse /var/log/matrix-synapse/purge.log
   ```

5. **Set Up Cron Job**:
   Add a cron job to run the script daily at 2 AM:
   ```bash
   sudo -u matrix-synapse crontab -e
   ```
   Add the following line:
   ```
   0 2 * * * /bin/bash /usr/local/bin/purge_synapse.sh
   ```

## Usage
- **Test the Script**:
   Run the script manually to verify it works:
   ```bash
   sudo -u matrix-synapse /bin/bash /usr/local/bin/purge_synapse.sh
   ```
   Check the log file (`/var/log/matrix-synapse/purge.log`) for output and errors.

- **Monitor Results**:
   - Verify purged data by checking the database size:
     ```bash
     psql -U synapse_user -d synapse -c "SELECT pg_database_size('synapse');"
     ```
   - Check the media store size:
     ```bash
     du -sh /var/lib/matrix-synapse/media
     ```

## Configuration Notes
- **Database Credentials**: Ensure the `DB_USER` has `DELETE` and `VACUUM` permissions. Configure PostgreSQL authentication (e.g., via `.pgpass`) if needed.
- **Media Store Path**: Verify the `media_store_path` in `homeserver.yaml` and update `MEDIA_STORE` accordingly.
- **Retention Period**: Modify `RETENTION_DAYS` to change the retention period.
- **Database Compaction**: The `VACUUM FULL` command may lock the database, causing temporary downtime. For large deployments, consider using `VACUUM` without `FULL` or schedule during low-traffic periods.

## Warnings
- **Data Loss**: The script permanently deletes messages and media older than the retention period. Test in a non-production environment first.
- **Backup**: Ensure you have backups of your database and media store before running the script.
- **Permissions**: The script must run as the `matrix-synapse` user to avoid permission issues.

## Contributing
Contributions are welcome! Please submit a pull request or open an issue for bugs, improvements, or feature requests.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

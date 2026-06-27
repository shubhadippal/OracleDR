#!/bin/bash

set -euo pipefail

LOGFILE=/var/log/dr_asm_dismount.log

log()
{
    echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
}

log "==========================================="
log "Starting ASM Diskgroup Dismount"
log "==========================================="

DB_STATUS=$(su - oracle -c "srvctl status database -d oracledr")

echo "$DB_STATUS" | tee -a "$LOGFILE"

if echo "$DB_STATUS" | grep -Eq "Instance .* is running"; then
    log "ERROR: Database is still running."
    exit 1
fi

log "Database is stopped."

NODES=$(su - grid -c "olsnodes")

for NODE in $NODES
do
    log "-------------------------------------------"
    log "Processing $NODE"
    log "-------------------------------------------"

    ssh root@$NODE /usr/local/bin/dr_asm_dismount_local.sh | tee -a "$LOGFILE"

done

log "Completed."

#!/bin/bash
#
# Script : dr_asm_dismount_allnodes.sh
# Purpose: Dismount HUR replicated ASM disk groups on ALL RAC nodes
#          while leaving OCR mounted.
#
# Run as : root
#

set -euo pipefail

LOGFILE="/var/log/dr_asm_dismount.log"

log() {
    echo "[$(date '+%F %T')] $*" | tee -a "$LOGFILE"
}

if [[ $(id -u) -ne 0 ]]; then
    echo "Run as root."
    exit 1
fi

log "======================================================="
log "Starting ASM diskgroup dismount on all RAC nodes"
log "======================================================="

##########################################################
# Verify database is stopped
##########################################################

DB_STATUS=$(su - oracle -c "srvctl status database -d oracledr")

echo "$DB_STATUS" | tee -a "$LOGFILE"

if echo "$DB_STATUS" | grep -Eq "Instance .* is running"; then
    log "ERROR: Database is still running."
    exit 1
fi

log "Database is stopped."

##########################################################
# Discover RAC nodes
##########################################################

NODES=$(su - grid -c "olsnodes")

log "Cluster nodes:"
echo "$NODES" | tee -a "$LOGFILE"

##########################################################
# Dismount on every node
##########################################################

for NODE in $NODES
do
    log "-------------------------------------------------------"
    log "Processing node: $NODE"
    log "-------------------------------------------------------"

    ssh -o BatchMode=yes root@$NODE "su - grid -c '
sqlplus -s / as sysasm <<EOF

set pages 100
set lines 200
set serveroutput on

prompt
prompt ==== BEFORE ====
select name,state
from v\\\$asm_diskgroup
order by name;

begin
    for dg in (
        select name
        from v\\\$asm_diskgroup
        where name in (''DATA'',''REDO'',''FRA'',''TEMP'')
          and state like ''MOUNTED%''
    )
    loop
        execute immediate ''alter diskgroup ''||dg.name||'' dismount'';
        dbms_output.put_line(''Dismounted ''||dg.name);
    end loop;
end;
/

prompt
prompt ==== AFTER ====
select name,state
from v\\\$asm_diskgroup
order by name;

exit
EOF
'" | tee -a "$LOGFILE"

done

log "======================================================="
log "Completed successfully."
log "======================================================="

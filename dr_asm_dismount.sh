#!/bin/bash
#
# Script Name : dr_asm_dismount.sh
# Purpose     : Dismount HUR replicated ASM disk groups
#               (DATA, REDO, FRA, TEMP) while keeping OCR mounted.
#
# Run as      : root
#

set -euo pipefail

LOGFILE="/var/log/dr_asm_dismount.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: This script must be run as root."
    exit 1
fi

log "========================================================="
log "Starting ASM disk group dismount"
log "========================================================="

############################################################
# Verify database is stopped
############################################################

DB_STATUS=$(su - oracle -c "srvctl status database -d oracledr 2>/dev/null")

DB_STATUS=$(su - oracle -c "srvctl status database -d oracledr 2>/dev/null")

if echo "$DB_STATUS" | grep -q "is running"; then
    log "Stop the database before dismounting ASM disk groups."
    echo "$DB_STATUS" | tee -a "$LOGFILE"
    exit 1
fi

log "Database is stopped."

############################################################
# Dismount ASM Diskgroups
############################################################

su - grid -c "
export PATH=\$ORACLE_HOME/bin:\$PATH

sqlplus -s / as sysasm <<EOF

set pages 100
set lines 200
set serveroutput on

prompt
prompt ==========================================
prompt ASM Diskgroups Before Dismount
prompt ==========================================

select name,state
from v\\\$asm_diskgroup
order by name;

begin
    for dg in (
        select name
        from v\\\$asm_diskgroup
        where state like 'MOUNTED%'
          and name in ('DATA','REDO','FRA','TEMP')
    )
    loop
        execute immediate 'alter diskgroup '||dg.name||' dismount';
        dbms_output.put_line('Dismounted Diskgroup : '||dg.name);
    end loop;
end;
/

prompt
prompt ==========================================
prompt ASM Diskgroups After Dismount
prompt ==========================================

select name,state
from v\\\$asm_diskgroup
order by name;

exit
EOF
" | tee -a "$LOGFILE"

log "Completed successfully."
log "========================================================="

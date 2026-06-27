#!/bin/bash
#
# Script Name : dr_storage_rescan.sh
# Purpose     : Rescan SCSI, reload multipath, reload udev,
#               verify multipath devices and mount ASM disk groups.
#
# Run as      : root
#

set -euo pipefail

LOGFILE="/var/log/dr_storage_rescan.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Run this script as root."
    exit 1
fi

log "========================================================="
log "Starting storage rescan and ASM diskgroup mount"
log "========================================================="

###########################################################
# Scan all SCSI hosts
###########################################################

log "Scanning SCSI hosts..."

for host in /sys/class/scsi_host/host*; do
    log "Scanning ${host##*/}"
    echo "- - -" > "$host/scan"
done

###########################################################
# Wait for new devices
###########################################################

sleep 5

###########################################################
# Restart multipath
###########################################################

log "Restarting multipathd..."

systemctl restart multipathd

###########################################################
# Reload udev
###########################################################

log "Reloading udev rules..."

udevadm control --reload-rules
udevadm trigger --type=devices --action=change
udevadm settle

###########################################################
# Reload multipath maps
###########################################################

log "Reloading multipath maps..."

multipath -r

sleep 3

###########################################################
# Display multipath devices
###########################################################

log "Current multipath devices"

multipath -ll | tee -a "$LOGFILE"

###########################################################
# Mount ASM diskgroups
###########################################################

log "Mounting ASM disk groups..."

su - grid -c "
export PATH=\$ORACLE_HOME/bin:\$PATH

sqlplus -s / as sysasm <<EOF

set lines 200
set pages 100
set serveroutput on

prompt
prompt ============================
prompt ASM Diskgroups Before Mount
prompt ============================

select name,
       state,
       type,
       total_mb,
       free_mb
from v\\\$asm_diskgroup
order by name;

begin
    for dg in (
        select name
        from v\\\$asm_diskgroup
        where state='DISMOUNTED'
    )
    loop
        execute immediate 'alter diskgroup '||dg.name||' mount';
        dbms_output.put_line('Mounted Diskgroup : '||dg.name);
    end loop;
end;
/

prompt
prompt ============================
prompt ASM Diskgroups After Mount
prompt ============================

select name,
       state,
       type,
       total_mb,
       free_mb
from v\\\$asm_diskgroup
order by name;

exit
EOF
" | tee -a "$LOGFILE"

###########################################################
# Completed
###########################################################

log "Completed successfully."
log "========================================================="

#!/bin/bash

LOGFILE="/tmp/emp_activity_$(date '+%Y%m%d_%H%M%S').log"

while true
do
    clear
    {
        echo "=============================================================="
        echo "EMP_ACTIVITY Monitor - $(date '+%Y-%m-%d %H:%M:%S')"
        echo "=============================================================="
        sqlplus -s hr_user/HrUser\#123@PROD_SVC <<EOF
SET PAGESIZE 100
SET LINESIZE 200
SET FEEDBACK OFF
COLUMN EVENT_TIME FORMAT A20
COLUMN DETAILS FORMAT A120
SELECT *
FROM (
    SELECT ID,
           TO_CHAR(EVENT_TIME,'DD-MON-YY HH24:MI:SS') EVENT_TIME,
           DETAILS
    FROM EMP_ACTIVITY
    ORDER BY ID DESC
)
WHERE ROWNUM <= 40;
EXIT
EOF
    } | tee -a "$LOGFILE"

    sleep 1
done

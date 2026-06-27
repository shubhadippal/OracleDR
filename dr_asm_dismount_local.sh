#!/bin/bash
#
# Dismount ASM diskgroups on LOCAL node only.
#

su - grid -c "sqlplus -s / as sysasm <<EOF

set pages 100
set lines 200
set serveroutput on

prompt
prompt ======================================
prompt ASM Diskgroups Before Dismount
prompt ======================================

select name,state
from v\\\$asm_diskgroup
order by name;

begin
    for dg in (
        select name
        from v\\\$asm_diskgroup
        where state='MOUNTED'
          and name in ('DATA','REDO','FRA','TEMP')
    )
    loop
        execute immediate 'alter diskgroup '||dg.name||' dismount';
        dbms_output.put_line('Dismounted : '||dg.name);
    end loop;
end;
/

prompt
prompt ======================================
prompt ASM Diskgroups After Dismount
prompt ======================================

select name,state
from v\\\$asm_diskgroup
order by name;

exit
EOF
"

BEGIN
  DBMS_SCHEDULER.CREATE_JOB (
    job_name        => 'EMP_ACTIVITY_JOB',
    job_type        => 'PLSQL_BLOCK',
    job_action      => q'[
      DECLARE
          v_inst    VARCHAR2(30);
          v_host    VARCHAR2(64);
          v_site    VARCHAR2(10);
          v_dbname  VARCHAR2(30);
      BEGIN
          SELECT instance_name, host_name
          INTO   v_inst, v_host
          FROM   v$instance;

          SELECT name
          INTO   v_dbname
          FROM   v$database;

          IF LOWER(v_host) LIKE 'prod-%' THEN
              v_site := 'PROD';
          ELSIF LOWER(v_host) LIKE 'dr-%' THEN
              v_site := 'DR';
          ELSIF LOWER(v_host) LIKE 'dev-%' THEN
              v_site := 'DEV';
          ELSE
              v_site := 'UNKNOWN';
          END IF;

          INSERT INTO emp_activity
          (
              id,
              event_time,
              details
          )
          VALUES
          (
              EMP_ACTIVITY_SEQ.NEXTVAL,
              SYSTIMESTAMP,
              '1 row inserted at ' || v_site ||
              ' on database ' || v_dbname ||
              ', instance ' || v_inst
          );

          COMMIT;
      END;
    ]',
    start_date      => SYSTIMESTAMP,
    repeat_interval => 'FREQ=SECONDLY;INTERVAL=10',
    enabled         => TRUE,
    comments        => 'HUR replication test - insert row every 10 seconds'
  );
END;
/

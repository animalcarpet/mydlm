#! /bin/bash

mysql < ../schema/mydlm.sql
mysql < ../data/standard_data.sql
mysql < ../routines/mydlm_routines.sql
mysql < ../routines/mydlm_events.sql

mysql -e 'SELECT @@GLOBAL.event_scheduler';
mysql -e 'SET GLOBAL event_scheduler = ON;';

echo "Run CALL `mydlm`.`import_schemata` to auto-populate the `schemata` table"
echo "Run CALL `mydlm`.`import_tables('schema_name')` to auto-populate tables"


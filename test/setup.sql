-- NB With the exception of routines, this shouldn't update
-- an existing installation

SOURCE ../schema/mydlm.sql
SOURCE ../routines/mydlm_routines.sql
SOURCE ../data/standard_data.sql

DROP DATABASE IF EXISTS `test_mydlm_1`;
CREATE DATABASE `test_mydlm_1`;
DROP DATABASE IF EXISTS `test_mydlm_2`;
CREATE DATABASE `test_mydlm_2`;
DROP DATABASE IF EXISTS `test_mydlm_3`;

USE `test_mydlm_1`
CREATE TABLE `table_1` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_1` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_2` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_2` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_3` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_3` ADD INDEX `ts_idx` (`ts`);


USE `test_mydlm_2`
CREATE TABLE `table_1` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_1` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_2` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_2` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_3` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_3` ADD INDEX `ts_idx` (`ts`);

USE `mydlm`

-- insert_schema
SET @rtn = NULL;
CALL mydlm.insert_schema('test_mydlm_1',@rtn);
SELECT tap.eq(@rtn,1,'insert_schema() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_schema('test_mydlm_1',@rtn);
SELECT tap.eq(@rtn,NULL,'insert_schema() with duplicate name should fail');
SET @rtn = NULL;
CALL mydlm.insert_schema('test_mydlm_2',@rtn);
SELECT tap.eq(@rtn,1,'insert_schema() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_schema('test_mydlm_3',@rtn);
SELECT tap.eq(@rtn,0,'insert_schema() non-existent db should return 0');

SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'test_mydlm_1') = ('test_mydlm_1'),
  TRUE,'record should exist');
SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'test_mydlm_2') = ('test_mydlm_2'),
  TRUE,'record should exist');
SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'test_mydlm_3') = ('test_mydlm_3'),
  FALSE,'record should not exist');

-- insert_table
SET @rtn = NULL;
CALL mydlm.insert_table('test_mydlm_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,1,'insert_table() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_table('test_mydlm_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,NULL,'insert_table() with duplicate name should fail');
SET @rtn = NULL;
CALL mydlm.insert_table('test_mydlm_1','table_4',0,0,7,'ts',@rtn);
SELECT tap.eq(@rtn,0,'insert_table() non-existent table should return 0');

SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'test_mydlm_1' AND table_name = 'table_1')
    = ('table_1',1,1,365,'ts'), TRUE,'record should exist');

-- record does not exist so NULL
SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'test_mydlm_1' AND table_name = 'table_4')
    = ('table_4',0,0,7,'ts'), NULL,'record should not exist');

-- will not match so false
SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'test_mydlm_1' AND table_name = 'table_1')
    = ('table_1',1,1,7,'ts'),FALSE,'record should not match');

-- jobs

SET @rtn = NULL;
CALL mydlm.insert_job('test_mydlm_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,1,'insert_table() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_table('test_mydlm_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,NULL,'insert_table() with duplicate name should fail');
SET @rtn = NULL;
CALL mydlm.insert_table('test_mydlm_1','table_4',0,0,7,'ts',@rtn);
SELECT tap.eq(@rtn,0,'insert_table() non-existent table should return 0');

SET @table_id = (SELECT table_id
 FROM mydlm.tables t
 JOIN mydlm.schemata s USING(schema_id)
 WHERE schema_name = 'test_mydlm_1'
 AND table_name = 'table_1');

SET @rtn = NULL;
CALL mydlm.insert_job('test1 Ad hoc', 7, @table_id,
'INSERT INTO test_mydlm_1.table_1 VALUES (1,2,NOW())',
'*','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
CALL mydlm.insert_job('test2 - DDL',5,@table_id,
'CREATE TABLE IF NOT EXISTS test_mydlm_1.summarize_table_1(
 a INT,
 b INT,
 ts TIMESTAMP NOT NULL DEFAULT NOW())',
'0,10,20,30,40,50','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
SET @dependency = (SELECT job_id
FROM mydlm.jobs
WHERE job_name = 'test2 DDl');

CALL mydlm.insert_job('test3 - Summarize',4,@table_id,
'INSERT INTO test_mydlm_1.summarize_table_1
 SELECT SUM(a), SUM(b)
 FROM test_mydlm_2.table_1 WHERE ts < ?',
'0,15,30,45','*','*','*','*',1,@dependency,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
SET @dependency = (SELECT job_id
FROM mydlm.jobs
WHERE job_name = 'test3 - Summarize');

CALL mydlm.insert_job('test4 - Prune',2,@table_id,
'DELETE FROM test_mydlm.table_1 WHERE ts < ?',
'0,15,30,45','*','*','*','*',1,@dependency,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');


-- this might not work because of secure_file_priv setting
-- select @@global.secure_file_priv;
-- and change if necessary
SET @rtn = NULL;
CALL mydlm.insert_job('test5 - Archive',3,@table_id,
'SELECT a,b,ts INTO OUTFILE "/var/lib/mysql-files/table1@@DATE@@@@TIME@@"
FROM test_mydlm_1.table_1',
'*','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');



-- NB With the exception of routines, this shouldn't update
-- an existing installation

-- SOURCE ../schema/mydlm.sql
-- SOURCE ../routines/mydlm_routines.sql
-- SOURCE ../routines/mydlm_events.sql
-- SOURCE ../data/standard_data.sql

DROP DATABASE IF EXISTS `mydlm_test_1`;
CREATE DATABASE `mydlm_test_1`;
DROP DATABASE IF EXISTS `mydlm_test_2`;
CREATE DATABASE `mydlm_test_2`;
DROP DATABASE IF EXISTS `mydlm_test_3`;

USE `mydlm_test_1`
CREATE TABLE `table_1` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_1` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_2` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_2` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_3` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_3` ADD INDEX `ts_idx` (`ts`);


USE `mydlm_test_2`
CREATE TABLE `table_1` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_1` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_2` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_2` ADD INDEX `ts_idx` (`ts`);
CREATE TABLE `table_3` ( a INT, b INT, ts TIMESTAMP NOT NULL DEFAULT NOW());
ALTER TABLE `table_3` ADD INDEX `ts_idx` (`ts`);

USE `mydlm`

SELECT 'Start Tap tests';

-- insert_schema
SET @rtn = NULL;
CALL mydlm.insert_schema('mydlm_test_1',@rtn);
SELECT tap.eq(@rtn,1,'insert_schema() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_schema('mydlm_test_1',@rtn);
SELECT tap.eq(@rtn,NULL,'insert_schema() with duplicate name should fail');
SET @rtn = NULL;
CALL mydlm.insert_schema('mydlm_test_2',@rtn);
SELECT tap.eq(@rtn,1,'insert_schema() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_schema('mydlm_test_3',@rtn);
SELECT tap.eq(@rtn,0,'insert_schema() non-existent db should return 0');

SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'mydlm_test_1') = ('mydlm_test_1'),
  TRUE,'mydlm_test_1 schema record should exist');
SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'mydlm_test_2') = ('mydlm_test_2'),
  TRUE,'mydlm_test_2 schema record should exist');
SELECT tap.eq((SELECT schema_name FROM mydlm.schemata where schema_name = 'mydlm_test_3') = ('mydlm_test_3'),
  NULL,'mydlm_test_3 schema record should not exist');

SET @schema_id = (SELECT `schema_id` FROM `mydlm`.`schemata` WHERE `schema_name` = 'mydlm_test_2');

SET @rtn = NULL;
CALL mydlm.delete_schema(@schema_id,@rtn);
SELECT tap.eq(@rtn,1,'delete_schema() should return 1');

SET @rtn = NULL;
CALL mydlm.delete_schema(@schema_id,@rtn);
SELECT tap.eq(@rtn,0,'delete_schema() should return 0 for non-existent schema');


-- insert_table
SET @rtn = NULL;
CALL mydlm.insert_table('mydlm_test_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,1,'insert_table() should succeed, returning 1');
SET @rtn = NULL;
CALL mydlm.insert_table('mydlm_test_1','table_1',1,1,365,'ts',@rtn);
SELECT tap.eq(@rtn,NULL,'insert_table() with duplicate name should fail');
SET @rtn = NULL;
CALL mydlm.insert_table('mydlm_test_1','table_4',0,0,7,'ts',@rtn);
SELECT tap.eq(@rtn,0,'insert_table() non-existent table should return 0');
SET @rtn = NULL;
CALL mydlm.insert_table('mydlm_test_1','table_2',0,0,7,'ts',@rtn);
SELECT tap.eq(@rtn,1,'insert_table() should succeed returning 1');

SET @table_id = (SELECT `table_id` FROM `mydlm`.`tables` t JOIN `mydlm`.`schemata` s
USING(`schema_id`) WHERE t.`table_name` = 'table_2' AND s.`schema_name` = 'mydlm_test_1');

SET @rtn = NULL;
CALL mydlm.delete_table(@table_id,@rtn);
SELECT tap.eq(@rtn,1,'delete_table() should succeed returning 1');

SELECT tap.eq((SELECT COUNT(*) FROM `mydlm`.`tables` WHERE `table_id` = @table_id),
  0,'table record should not exist');

SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'mydlm_test_1' AND table_name = 'table_1')
    <=> ('table_1',1,1,365,'ts'), TRUE,'table record should exist');

-- record does not exist so NULL
SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'mydlm_test_1' AND table_name = 'table_4')
    <=> ('table_4',0,0,7,'ts'), FALSE,'table record should not exist');

-- will not match so false
SELECT tap.eq((SELECT table_name,personal,financial,retain_days,retain_key
  FROM mydlm.tables JOIN mydlm.schemata USING(schema_id)
  WHERE schema_name = 'mydlm_test_1' AND table_name = 'table_1')
    <=> ('table_1',1,1,7,'ts'),FALSE,'record should not match');

-- jobs
SET @table_id = (SELECT table_id
 FROM mydlm.tables t
 JOIN mydlm.schemata s USING(schema_id)
 WHERE schema_name = 'mydlm_test_1'
 AND table_name = 'table_1');

SET @rtn = NULL;
CALL mydlm.insert_job('mydlm_test1 Ad hoc', 7, @table_id,
'INSERT INTO mydlm_test_1.table_1 VALUES (1,2,NOW())',
'*','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
CALL mydlm.insert_job('mydlm_test2 - DDL',5,@table_id,
'CREATE TABLE IF NOT EXISTS mydlm_test_1.summarize_table_1(
 a INT,
 b INT,
 ts TIMESTAMP NOT NULL DEFAULT NOW())',
'0,10,20,30,40,50','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
SET @dependency = (SELECT job_id
FROM mydlm.jobs
WHERE job_name = 'mydlm_test2 DDl');

CALL mydlm.insert_job('mydlm_test3 - Summarize',4,@table_id,
'INSERT INTO mydlm_test_1.summarize_table_1
 SELECT SUM(a), SUM(b)
 FROM mydlm_test_2.table_1 WHERE ts < ?',
'0,15,30,45','*','*','*','*',1,@dependency,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
SET @dependency = (SELECT job_id
FROM mydlm.jobs
WHERE job_name = 'mydlm_test3 - Summarize');

CALL mydlm.insert_job('mydlm_test4 - Prune',2,@table_id,
'DELETE FROM mydlm_test_1.table_1 WHERE ts < ?',
'0,15,30,45','*','*','*','*',1,@dependency,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

-- this might not work because of secure_file_priv setting
-- select @@global.secure_file_priv;
-- and change if necessary
SET @rtn = NULL;
CALL mydlm.insert_job('mydlm_test5 - Archive',3,@table_id,
'SELECT a,b,ts INTO OUTFILE "/var/lib/mysql-files/table1@@DATE@@@@TIME@@"
FROM mydlm_test_1.table_1',
'*','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @rtn = NULL;
CALL mydlm.insert_job('MYDLMTESTDELETEME',3,@table_id,
'SELECT 1',
'*','*','*','*','*',1,null,@rtn);
SELECT tap.eq(@rtn,1,'insert_job() should succeed');

SET @job_id = (SELECT job_id FROM `mydlm`.`jobs` WHERE `job_name` = 'MYDLMTESTDELETEME');

SET @rtn = NULL;
CALL mydlm.delete_job(@job_id,@rtn);
SELECT tap.eq(@rtn,1,'delete_job() should return 1');




-- get single object
-- NB null safe equality check
SET @job_id = (SELECT job_id FROM jobs WHERE job_name = 'mydlm_test1 Ad hoc');

SELECT tap.eq((SELECT job_id,job_name,job_type_id,query,mi,hr,dm,mn,dw,active,depends
  FROM mydlm.jobs WHERE job_id = @job_id)
    <=> (@job_id,'mydlm_test1 Ad hoc',7,'INSERT INTO mydlm_test_1.table_1 VALUES (1,2,NOW())','*','*','*','*','*',1,NULL),
    TRUE,'Retrieved job record should match entered values');

-- test queue and dequeue
SET @rtn = NULL;
CALL mydlm.queue_job(@job_id,'2000-01-01 00:00:01',@rtn);
SELECT tap.eq(@rtn, 2, 'queue_job() should succeed');

SELECT tap.eq((SELECT COUNT(`job_id`)
  FROM mydlm.queue WHERE job_id = @job_id) <=> 1,
  TRUE,'Should be count of one for job in the queue');

SELECT tap.eq((SELECT COUNT(`job_id`)
  FROM mydlm.history WHERE job_id = @job_id) <=> 1,
  TRUE,'Should be count of one for job in history');


-- should return 2, 1 for queue and 1 for history
SET @rtn = NULL;
CALL mydlm.dequeue_job(@job_id,'2000-01-01 00:00:01',@rtn);
SELECT tap.eq(@rtn,2,'dequeue_job() should succeed');

SELECT tap.eq((SELECT COUNT(`job_id`)
  FROM mydlm.queue WHERE job_id = @job_id) <=> 0,
  TRUE, 'Should be zero count in queue for job');

-- put the job back on the queue
SET @rtn = NULL;
CALL mydlm.queue_job(@job_id,'2000-01-01 00:00:01',@rtn);
SELECT tap.eq(@rtn, 2, 'queue_job() should succeed');


SELECT tap.eq((SELECT COUNT(`job_id`)
  FROM mydlm.queue WHERE job_id = @job_id) <=> 1,
  TRUE,'Should be count of one for job in the queue');

SET @rtn = NULL;
CALL mydlm.delete_history(@job_id,'2000-01-01 00:00:01',@rtn);
SELECT tap.eq(@rtn <=> 1,
  TRUE, 'delete_history() should return 1');

SET @rtn = NULL;
CALL mydlm.delete_queue(@job_id,'2000-01-01 00:00:01',@rtn);
SELECT tap.eq(@rtn <=> 1,
  TRUE, 'delete_queue() should return 1');

-- suspend and reactivate
SET @rtn = NULL;
CALL mydlm.suspend_job(@job_id,@rtn);
SELECT tap.eq(@rtn,1,'suspend_job() should succeed');

SELECT tap.eq((SELECT job_id,active
  FROM mydlm.jobs WHERE job_id = @job_id)
    <=> (@job_id,-1),TRUE,'Suspended job should have active state = -1');

SET @rtn = NULL;
CALL mydlm.reactivate_job(@job_id,@rtn);
SELECT tap.eq(@rtn,1,'reactivate_job() should succeed');

SELECT tap.eq((SELECT job_id,active
  FROM mydlm.jobs WHERE job_id = @job_id)
    <=> (@job_id,1),TRUE,'Reactivated job should have active state = 1');





-- tidy up records
SET FOREIGN_KEY_CHECKS = 0;
DELETE FROM `mydlm`.`schemata` WHERE `schema_name` LIKE 'mydlm_test%';
DELETE FROM `mydlm`.`tables` WHERE `table_name` LIKE 'mydlm_test%';
DELETE h FROM `mydlm`.`history` h JOIN `mydlm`.`jobs` j WHERE j.`job_name` LIKE 'mydlm_test%';
DELETE FROM `mydlm`.`jobs` WHERE `job_name` LIKE 'mydlm_test%';
SET FOREIGN_KEY_CHECKS = 1;

DROP DATABASE IF EXISTS `mydlm_test_1`;
DROP DATABASE IF EXISTS `mydlm_test_2`;
DROP DATABASE IF EXISTS `mydlm_test_3`;

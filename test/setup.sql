DROP DATABASE IF EXISTS `test_mydlm_1`;
CREATE DATABASE `test_mydlm_1`;

USE `test_mydlm_1`

CREATE TABLE `table_1` ( a INT );
CREATE TABLE `table_2` ( a INT );
CREATE TABLE `table_3` ( a INT );

DROP DATABASE IF EXISTS `test_mydlm_2`;
CREATE DATABASE `test_mydlm_2`;

USE `test_mydlm_2`

CREATE TABLE `table_1` ( a INT );
CREATE TABLE `table_2` ( a INT );
CREATE TABLE `table_3` ( a INT );

DROP DATABASE IF EXISTS `mydlm`;
SOURCE ../schema/mydlm.sql
SOURCE ../routines/mydlm_routines.sql
SOURCE ../data/standard_data.sql


USE `mydlm`

-- DATABASES
INSERT INTO `job_types` (`job_type_id`,`job_type_name`)
VALUES (1,'Prune'),(2,'Archive'),(3,'Summarize'),(4,'One-off');

INSERT INTO `schemata` VALUES (1,'test_mydlm_1',null);
INSERT INTO `schemata` VALUES (2,'test_mydlm_2',null);

-- TABLES
INSERT INTO `tables` VALUES (1,1,'table_1',1,1,null);
INSERT INTO `tables` VALUES (2,1,'table_2',0,0,null);
INSERT INTO `tables` VALUES (3,1,'table_3',0,1,null);
INSERT INTO `tables` VALUES (4,2,'table_1',1,1,null);
INSERT INTO `tables` VALUES (5,2,'table_2',0,0,null);
INSERT INTO `tables` VALUES (6,2,'table_3',0,1,null);

-- JOBS

INSERT INTO `jobs` VALUES (1,1,1,null,'test 1 no depends create table','create table IF NOT EXISTS test.archive_@@YEAR@@(a int) ENGINE Innodb;','*','*','*','*','*',1,null,0);






-- QUEUE
INSERT INTO queue values (1,'2019-01-01 00:00:00');
INSERT INTO queue values (2,'2019-01-01 00:00:00');
INSERT INTO queue values (3,'2019-01-01 00:00:00');
INSERT INTO queue values (1,'2019-01-01 00:01:00');
INSERT INTO queue values (1,'2019-01-01 00:02:00');


DROP DATABASE IF EXISTS `test_mydlm_1`;
CREATE DATABASE `test_mydlm_1`;

USE `test_mydlm_1`

CREATE TABLE `table_1` ( a INT );
CREATE TABLE `table_2` ( a INT );
CREATE TABLE `table_3` ( a INT );

DROP DATABASE IF EXISTS `test_mydlm_1`;
CREATE DATABASE `test_mydlm_1`;

USE `test_mydlm_2`

CREATE TABLE `table_1` ( a INT );
CREATE TABLE `table_2` ( a INT );
CREATE TABLE `table_3` ( a INT );


USE `mydlm`
TRUNCATE `history`
TRUNCATE `queue`;
TRUNCATE `jobs`;
TRUNCATE `tables`;
TRUNCATE `schemata`;
TRUNCATE `job_types`;

-- DATABASES
INSERT INTO `job_types` (`job_type_id`,`job_type_name`)
VALUES (1,'Prune'),(2,'Archive'),(3,'Summarize'),(4,'One-off');

INSERT INTO `schemata` VALUES (1,'test_mydlm_1');
INSERT INTO `schemata` VALUES (2,'test_mydlm_2');

-- TABLES
INSERT INTO `tables` VALUES (1,1,'table_1',1,1);
INSERT INTO `tables` VALUES (2,1,'table_2',0,0);
INSERT INTO `tables` VALUES (3,1,'table_2',0,1);
INSERT INTO `tables` VALUES (1,2,'table_1',1,1);
INSERT INTO `tables` VALUES (2,2,'table_2',0,0);
INSERT INTO `tables` VALUES (3,2,'table_2',0,1);

-- JOBS
INSERT INTO `jobs` VALUES (1,1,1,null,'test 1 no depends','','SELECT 1','',0,0,'*','*','*','*','*',1,null);
INSERT INTO `jobs` VALUES (2,1,2,1,'test 2 no depends 1','','SELECT 1','',0,0,'0,15,30,45','*','*','*','*',1,null);
INSERT INTO `jobs` VALUES (3,1,3,null,'test 3 no depends','','SELECT 1','',0,0,'0','10','*','*','*',1,null);
INSERT INTO `jobs` VALUES (4,1,1,null,'test 4 no depends','','SELECT 1','',0,0,'0','2','*','*','*',1,null);
INSERT INTO `jobs` VALUES (5,1,1,2,'test 5 depends 15 past the hour','','SELECT 1','',0,0,'15','*','*','*','*',1,null);
INSERT INTO `jobs` VALUES (6,1,1,null,'test 6 no depends happy xmas','','SELECT "HAPPY CHRISTMAS"','',0,0,'0','0','25','12','*',1,null);
INSERT INTO `jobs` VALUES (7,1,1,null,'test 7 no depends','','SELECT 1','',0,0,'0','19','*','*','*',1,null);
INSERT INTO `jobs` VALUES (8,1,1,null,'test 8 no depends','','SELECT 1','',0,0,'0','20','*','*','*',1,null);

-- QUEUE
INSERT INTO queue values (1,'2019-01-01 00:00:00');
INSERT INTO queue values (2,'2019-01-01 00:00:00');
INSERT INTO queue values (3,'2019-01-01 00:00:00');
INSERT INTO queue values (1,'2019-01-01 00:01:00');
INSERT INTO queue values (1,'2019-01-01 00:02:00');


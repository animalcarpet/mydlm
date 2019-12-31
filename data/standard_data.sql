/*
mydlm 
=====
Copyright: Paul Campbell <animalcarpet@gmail.com>
Licence: GPL
*/

-- populate lookup tables

USE mydlm

INSERT INTO `job_types` (`job_type_id`,`job_type_name`)
VALUES (1,'Prune'),(2,'Archive'),(3,'Summarize'),(4,'DDL'),(5,'Update'),(6,'One-off';

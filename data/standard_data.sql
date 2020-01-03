/*
mydlm 
=====
Copyright: Paul Campbell <animalcarpet@gmail.com>
Licence: GPL
*/

-- populate lookup tables

USE mydlm

INSERT INTO `job_types` (`job_type_id`,`job_type_name`)
VALUES (1,'One-off'),
       (2,'Prune'),
       (3,'Archive'),
       (4,'Summarize'),
       (5,'DDL'),
       (6,'Update'),
       (7,'Ad hoc');

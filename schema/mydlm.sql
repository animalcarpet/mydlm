-- A utility to manage data lifetime
CREATE DATABASE IF NOT EXISTS `mydlm`;
USE `mydlm`


CREATE TABlE IF NOT EXISTS `control` (
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP, 
  `run` TINYINT UNSIGNED NOT NULL DEFAULT 1,
   PRIMARY KEY(`created`,`run`)
) ENGINE Innodb CHARACTER SET utf8 COLLATE utf8_bin
  COMMENT 'Master switch to enable/disable run';


CREATE TABLE IF NOT EXISTS `schemata` (
  `schema_id` SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schema_name` VARCHAR(64) NOT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`schema_id`),
  UNIQUE KEY `schema_name_unq` (`schema_name`)
) ENGINE Innodb CHARACTER SET utf8 COLLATE utf8_bin
  COMMENT 'Record each database under management';


CREATE TABLE IF NOT EXISTS `tables` (
  `table_id` MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT,
  `schema_id` SMALLINT UNSIGNED NOT NULL,
  `table_name` VARCHAR(64) NOT NULL,
  `personal` TINYINT UNSIGNED NOT NULL DEFAULT '0', 
  `financial` TINYINT UNSIGNED NOT NULL DEFAULT '0', 
  `retain_days` SMALLINT UNSIGNED NOT NULL DEFAULT '0',
  `retain_key` VARCHAR(64),
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`table_id`),
  UNIQUE KEY `schema_id_table_name_unq` (`schema_id`,`table_name`),
  CONSTRAINT `schema_id_fk` FOREIGN KEY (`schema_id`) REFERENCES `schemata`(`schema_id`) ON DELETE RESTRICT
) ENGINE Innodb CHARACTER SET utf8 COLLATE utf8_bin
  COMMENT 'Record each table under management';


CREATE TABLE IF NOT EXISTS `job_types` (
 `job_type_id` TINYINT UNSIGNED NOT NULL AUTO_INCREMENT,
 `job_type_name` VARCHAR(12) NOT NULL,
 PRIMARY KEY (`job_type_id`),
 UNIQUE KEY `job_type_name_unq` (`job_type_name`)
) ENGINE Innodb CHARACTER SET utf8
  COMMENT 'The type of task to be performed';


-- The self-referencing FK is a bit strange here.
-- We want to make sure we don't delete dependent
-- jobs via a cascade, but the FK prevents any
-- deletion of records. We suspend FK checks for a
-- delete to get around this issue. The other option
-- would be to store dependent ids in a separate
-- table, but I didn't feel I needed more than 1
-- dependency for a table.

CREATE TABLE  IF NOT EXISTS `jobs` (
  `job_id` INTEGER UNSIGNED NOT NULL AUTO_INCREMENT,
  `table_id` MEDIUMINT UNSIGNED NOT NULL, 
  `job_type_id` TINYINT UNSIGNED NOT NULL,
  `depends` INTEGER UNSIGNED,
  `job_name` VARCHAR(64) NOT NULL,
  `query` TEXT NOT NULL,
  `mi` CHAR(33) NOT NULL DEFAULT '*',
  `hr` CHAR(33) NOT NULL DEFAULT '*',
  `dm` CHAR(33) NOT NULL DEFAULT '*',
  `mn` CHAR(33) NOT NULL DEFAULT '*',
  `dw` CHAR(33) NOT NULL DEFAULT '*',
  `active` TINYINT NOT NULL DEFAULT '0',
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(`job_id`),
  KEY `cron_idx` (`mi`,`hr`,`dm`,`mn`,`dw`,`active`),
  KEY `job_type_id_idx` (`job_type_id`),
  KEY `table_id_idx` (`table_id`),
  KEY `depends_idx` (`depends`),
  CONSTRAINT `table_id_fk` FOREIGN KEY  (`table_id`) REFERENCES `tables`(`table_id`) ON DELETE CASCADE,
  CONSTRAINT `depends_fk` FOREIGN KEY (`depends`) REFERENCES `jobs`(`job_id`) ON DELETE RESTRICT
) ENGINE Innodb CHARACTER SET utf8
  COMMENT 'The definition and schedule of each DLM task';


CREATE TABLE IF NOT EXISTS `queue` (
  `job_id` INTEGER UNSIGNED NOT NULL,
  `runtime` DATETIME NOT NULL,
  `semaphore` TINYINT UNSIGNED NOT NULL DEFAULT 0,
  PRIMARY KEY (`job_id`,`runtime`),
  KEY `runtime_job_id_idx` (`runtime`,`job_id`),
  KEY `semaphore_idx` (`semaphore`)
) ENGINE Innodb CHARACTER SET utf8
  COMMENT 'Queue the jobs till successfully completed';


CREATE TABLE IF NOT EXISTS `history` (
  `job_id` INTEGER UNSIGNED NOT NULL,
  `runtime` DATETIME NOT NULL,
  `rows_affected` INTEGER DEFAULT NULL,
  `started` DATETIME DEFAULT NULL,
  `finished` DATETIME DEFAULT NULL,
  `error` TEXT DEFAULT NULL,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`job_id`,`runtime`),
  KEY `runtime_job_id_idx` (`runtime`,`job_id`),
  CONSTRAINT FOREIGN KEY `job_id_idx` (`job_id`) REFERENCES `jobs`(`job_id`)
    ON DELETE RESTRICT
) ENGINE Innodb CHARACTER SET utf8
  COMMENT 'Outcome of each job';


CREATE TABLE IF NOT EXISTS `monitor` (
  `table_id` MEDIUMINT UNSIGNED NOT NULL,
  `table_rows` BIGINT UNSIGNED NOT NULL,
  `auto_increment` BIGINT UNSIGNED,
  `keyspace` FLOAT UNSIGNED,
  `created` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`table_id`,`created`),
  CONSTRAINT FOREIGN KEY `tables_id_fk` (table_id) REFERENCES `tables`(`table_id`)
    ON DELETE CASCADE
) ENGINE Innodb CHARACTER SET utf8
  COMMENT 'Monitor table rows and keyspace';


CREATE USER IF NOT EXISTS `dlmadmin`@`localhost` IDENTIFIED BY 'djBkdfOyebxc992hd^';

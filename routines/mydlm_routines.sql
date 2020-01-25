-- A utility to manage data lifetime

-- DATA LOADING ROUTINES
-- ******************************************************************************************
USE mydlm

DROP PROCEDURE IF EXISTS `import_schemata`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `import_schemata`(
  OUT _row_count INTEGER)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`schemata` (`schema_name`)
  SELECT `schema_name`
  FROM `information_schema`.`schemata` s
  WHERE s.`schema_name`
    NOT IN ('mysql','mydlm','information_schema','sys','performance_schema');

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `import_tables`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `import_tables`(
  _schema_name VARCHAR(64),
  _row_count SMALLINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`tables` (`table_name`,`schema_id`)
  SELECT t.`table_name`, s.`schema_id`
  FROM `information_schema`.`tables` t
  JOIN `mydlm`.`schemata` s ON (t.`table_schema` = s.`schema_name`)
  WHERE t.`table_schema` = _schema_name
  AND t.`table_type` = 'BASE TABLE';

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `import_table`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `import_table`(
  _schema_name VARCHAR(64),
  _table_name VARCHAR(64),
  _row_count SMALLINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`tables` (`table_name`,`schema_id`)
  SELECT t.`table_name`, s.`schema_id`
  FROM `information_schema`.`tables` t
  JOIN `mydlm`.`schemata` s ON (t.`table_schema` = s.`schema_name`)
  WHERE t.`table_schema` = _schema_name
  AND t.`table_name` = _table_name
  AND t.`table_type` = 'BASE TABLE';

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- RETRIEVE ALL OBJECTS OF A PARTICULAR CLASS
-- ******************************************************************************************

-- ALL SCHEMATA
DROP PROCEDURE IF EXISTS `get_schemata`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_schemata`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `schema_id`, s.`schema_name`, s.`created`
   FROM `mydlm`.`schemata` s;
END //
DELIMITER ;


-- ALL TABLES
DROP PROCEDURE IF EXISTS `get_tables`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_tables`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT t.`table_id`, t.`table_name`, `schema_id`, s.`schema_name`,
    t.`personal`, t.`financial`, t.`retain_days`, t.`retain_key`, t.`created`
   FROM `mydlm`.`tables` t
   JOIN `mydlm`.`schemata` s USING(`schema_id`);
END //
DELIMITER ;


-- ALL JOB TYPES
DROP PROCEDURE IF EXISTS `get_job_types`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_job_types`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_type_id`, `job_type_name`
   FROM `mydlm`.`job_types`;
END //
DELIMITER ;


-- ALL JOBS
DROP PROCEDURE IF EXISTS `get_jobs`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_jobs`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT j.`job_id`, j.`job_name`, j.`job_type_id`, jt.`job_type_name`,
    j.`query`, j.`mi`, j.`hr`, j.`dm`, j.`mn`, j.`dw`,j.`active`,
    j.`depends`, t.`table_id`, t.`table_name`
   FROM `mydlm`.`jobs` j
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`);
END //
DELIMITER ;


-- ALL QUEUED JOBS
DROP PROCEDURE IF EXISTS `get_queue`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_queue`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, q.`runtime`, s.`schema_name`, t.`table_name`,
    j.`job_name`, jt.`job_type_name`,`semaphore`
   FROM `mydlm`.`queue` q
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   ORDER BY q.runtime ASC, job_id ASC;
END //
DELIMITER ;


-- ALL HISTORY
DROP PROCEDURE IF EXISTS `get_history`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_history`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, h.`runtime`, s.`schema_name`, t.`table_name`,
    j.`job_name`, jt.`job_type_name`, h.`rows_affected`,
    h.`error`, h.`started`, h.`finished`, h.`created`
   FROM `mydlm`.`history` h
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   ORDER BY `runtime` ASC;
END //
DELIMITER ;


-- RETRIEVE ALL OBJECTS MATCHING PARAMETER
-- ******************************************************************************************

DROP PROCEDURE IF EXISTS `get_queue_by_runtime`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_queue_by_runtime`(
  _runtime DATETIME)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, `runtime`, s.`schema_name`, t.`table_name`, j.`job_name`,
     jt.`job_type_name`
   FROM `mydlm`.`queue` q
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE q.`runtime` = _runtime;
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `get_queue_by_job_id`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_queue_by_job_id`(
  _job_id INTEGER UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, `runtime`, s.`schema_name`, t.`table_name`, j.`job_name`,
     jt.`job_type_name`
   FROM `mydlm`.`queue` q
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE q.`job_id` = _job_id;
END //
DELIMITER ;


-- TABLES BY SCHEMA ID
DROP PROCEDURE IF EXISTS `get_tables_by_schema_id`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_tables_by_schema_id`(
  _schema_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT t.`table_id`, t.`table_name`, `schema_id`, s.`schema_name`,
    t.`personal`, t.`financial`, t.`retain_days`, t.`retain_key`, t.`created`
   FROM `mydlm`.`tables` t
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE t.`schema_id` = _schema_id;
END //
DELIMITER ;


-- TABLES BY SCHEMA NAME
DROP PROCEDURE IF EXISTS `get_tables_by_schema_name`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_tables_by_schema_name`(
  _table_schema VARCHAR(64))
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT t.`table_id`, t.`table_name`, `schema_id`, s.`schema_name`,
    t.`personal`, t.`financial`, t.`retain_days`, t.`retain_key`, t.`created`
   FROM `mydlm`.`tables` t
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE t.`table_schema` = _table_schema;
END //
DELIMITER ;


-- JOBS BY SCHEMA
DROP PROCEDURE IF EXISTS `get_jobs_by_schema_id`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_jobs_by_schema_id`(
  _schema_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT j.`job_id`, j.`job_name`, `schema_id`, s.`schema_name`,
    `table_id`, t.`table_name`,jt.job_type_id, jt.`job_type_name`,
    j.`query`, j.`mi`, j.`hr`, j.`dm`, j.`mn`, j.`dw`, j.`active`,
    j.`depends`
  FROM `mydlm`.`jobs` j
  JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
  JOIN `mydlm`.`tables` t USING(`table_id`)
  JOIN `mydlm`.`schemata` s USING(`schema_id`)
  WHERE s.`schema_id` = _schema_id;
END //
DELIMITER ;


-- JOBS BY TABLE
DROP PROCEDURE IF EXISTS `get_jobs_by_table_id`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_jobs_by_table_id`(
  _table_id MEDIUMINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT j.`job_id`, j.`job_name`, `schema_id`, s.`schema_name`,
    `table_id`, t.`table_name`,jt.job_type_id, jt.`job_type_name`,
    j.`query`, j.`mi`, j.`hr`, j.`dm`, j.`mn`, j.`dw`, j.`active`,
    j.`depends`
  FROM `mydlm`.`jobs` j
  JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
  JOIN `mydlm`.`tables` t USING(`table_id`)
  JOIN `mydlm`.`schemata` s USING(`schema_id`)
  WHERE j.`table_id` = _table_id;
END //
DELIMITER ;


-- HISTORY FOR A JOB
DROP PROCEDURE IF EXISTS `get_history_by_job_id`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_history_by_job_id`(
  _job_id INTEGER UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, h.`runtime`, j.`job_name`, jt.`job_type_name`,
    h.`rows_affected`, h.`error`, h.`started`, h.`finished`, h.`created`
   FROM `mydlm`.`history` h
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   WHERE h.`job_id` = _job_id;
END //
DELIMITER ;



-- RETRIEVE INDIVIDUAL SCHEMA OBJECTS
-- ******************************************************************************************
-- ONE SCHEMA
DROP PROCEDURE IF EXISTS `get_schema`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_schema`(
  _schema_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `schema_id`, s.`schema_name`, s.`created`
   FROM `mydlm`.`schemata` s
   WHERE s.`schema_id` = _schema_id;
END //
DELIMITER ;


-- ONE TABLE
DROP PROCEDURE IF EXISTS `get_table`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_table`(
  _table_id MEDIUMINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT t.`table_id`, t.`table_name`, `schema_id`, s.`schema_name`,
    t.`personal`, t.`financial`, t.`retain_days`, t.`retain_key`, t.`created`
   FROM `mydlm`.`tables` t
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE t.`table_id` = _table_id;
   
END //
DELIMITER ;


-- ONE JOB TYPE
DROP PROCEDURE IF EXISTS `get_job_type`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_job_type`(
  _job_type_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_type_id`, `job_type_name`
   FROM `mydlm`.`job_types`
   WHERE `job_type_id` = _job_type_id;
END //
DELIMITER ;


-- ONE JOB
DROP PROCEDURE IF EXISTS get_job; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE get_job(
  _job_id INTEGER UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT j.`job_id`, j.`job_name`, jt.job_type_id, jt.`job_type_name`,
    j.`query`, j.`mi`, j.`hr`, j.`dm`, j.`mn`, j.`dw`, j.`active`,
    j.`depends`
  FROM `mydlm`.`jobs` j
  JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
  WHERE j.`job_id` = _job_id;
END //
DELIMITER ;


-- ONE HISTORY RECORD
DROP PROCEDURE IF EXISTS `get_history_by_job_id_and_runtime`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_history_by_job_id_and_runtime`(
  _job_id INTEGER UNSIGNED,
  _runtime DATETIME)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT `job_id`, h.`runtime`, s.`schema_name`, t.`table_name`,
    j.`job_name`, jt.`job_type_name`, h.`rows_affected`,
    h.`error`, h.`started`, h.`finished`, h.`created`
   FROM `mydlm`.`history` h
   JOIN `mydlm`.`jobs` j USING(`job_id`)
   JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
   JOIN `mydlm`.`tables` t USING(`table_id`)
   JOIN `mydlm`.`schemata` s USING(`schema_id`)
   WHERE h.`job_id` = _job_id
   AND h.`runtime` = _runtime;
END //
DELIMITER ;


-- INSERT SCHEMA OBJECTS
-- ******************************************************************************************

-- check its a valid schema name
DROP PROCEDURE IF EXISTS `insert_schema`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `insert_schema`(
  IN _schema_name VARCHAR(64),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER
MODIFIES SQL DATA
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SET _row_count = NULL;
    
  INSERT INTO `mydlm`.`schemata` (`schema_name`)
  SELECT `schema_name`
  FROM `information_schema`.`schemata` 
  WHERE `schema_name` = _schema_name;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- check the table exists in the db
DROP PROCEDURE IF EXISTS `insert_table`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `insert_table`(
  IN _table_schema VARCHAR(64),
  IN _table_name VARCHAR(64),
  IN _personal TINYINT UNSIGNED,
  IN _financial TINYINT UNSIGNED,
  IN _retain_days SMALLINT UNSIGNED,
  IN _retain_key VARCHAR(64),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SET _row_count = NULL;

  INSERT INTO `mydlm`.`tables` (`schema_id`, `table_name`,
    `personal`, `financial`, `retain_days`, `retain_key`)
  SELECT s.`schema_id`, t.`table_name`, _personal, _financial,
    _retain_days, _retain_key
  FROM `information_schema`.`tables` t
  JOIN `mydlm`.`schemata` s ON(t.`table_schema` = s.`schema_name`)
  WHERE t.`table_schema` = _table_schema
  AND t.`table_name` = _table_name;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `insert_job_type`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `insert_job_type`(
  IN _job_type_name VARCHAR(12),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SET _row_count = NULL;

  INSERT INTO `mydlm`.`job_types` (`job_type_name`)
  VALUES(_job_type_name);

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `insert_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `insert_job`(
  IN _job_name VARCHAR(64),
  IN _job_type_id TINYINT UNSIGNED,
  IN _table_id MEDIUMINT UNSIGNED,
  IN _query TEXT,
  IN _mi CHAR(33),
  IN _hr CHAR(33),
  IN _dm CHAR(33),
  IN _mn CHAR(33),
  IN _dw CHAR(33),
  IN _active TINYINT,
  IN _depends INTEGER UNSIGNED,
  OUT _row_count INTEGER UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SET _row_count = NULL;

  INSERT INTO `mydlm`.`jobs` (
    `job_name`,
    `job_type_id`,
    `table_id`,
    `query`,
    `mi`,
    `hr`,
    `dm`,
    `mn`,
    `dw`,
    `active`,
    `depends`
  )
  VALUES (
    _job_name,
    _job_type_id,
    _table_id,
    _query,
    _mi,
    _hr,
    _dm,
    _mn,
    _dw,
    _active,
    _depends
  );

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- This only starts the record - it's finished by the log procedure
-- history has no auto_inc so use row_count()
DROP PROCEDURE IF EXISTS `insert_history`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `insert_history`(
  IN _job_id INTEGER UNSIGNED,
  IN _runtime DATETIME,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`history` (`job_id`,`runtime`)
  VALUES (_job_id, _runtime);

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- UPDATE SCHEMA OBJECTS
-- ******************************************************************************************

-- check its a valid schema name
DROP PROCEDURE IF EXISTS `update_schema`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `update_schema`(
  IN _schema_id TINYINT UNSIGNED,
  IN _schema_name VARCHAR(64),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`schemata`
  SET `schema_name` = 
    (SELECT i.`schema_name`
     FROM `information_schema`.`schemata` 
     JOIN `mydlm`.`schemata` s ON (i.`schema_name` = s.`schema_name`)
     WHERE s.`schema_id` = _schema_id) ;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- check the table exists in the table
DROP PROCEDURE IF EXISTS `update_table`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `update_table`(
  IN _table_id MEDIUMINT UNSIGNED,
  IN _schema_id TINYINT UNSIGNED,
  IN _table_name VARCHAR(64),
  IN _personal TINYINT UNSIGNED,
  IN _financial TINYINT UNSIGNED,
  IN _retain_days SMALLINT UNSIGNED,
  IN _retain_key VARCHAR(64),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`tables` SET
    `schema_id` =  _schema_id,
    `table_name` = _table_name,
    `personal` = _personal,
    `financial` = _financial,
    `retain_days` = _retain_days,
    `retain_key` = _retain_key
  WHERE `table_id` = _table_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `update_job_type`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `update_job_type`(
  IN _job_type_id TINYINT UNSIGNED,
  IN _job_type_name VARCHAR(12),
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`job_types` SET
    `job_type_name` = _job_type_name
  WHERE `job_type_id` = _job_type_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `update_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `update_job`(
  IN _job_id INTEGER UNSIGNED,
  IN _job_name VARCHAR(64),
  IN _job_type_id TINYINT UNSIGNED,
  IN _table_id MEDIUMINT UNSIGNED,
  IN _query TEXT,
  IN _mi CHAR(33),
  IN _hr CHAR(33),
  IN _dm CHAR(33),
  IN _mn CHAR(33),
  IN _dw CHAR(33),
  IN _active TINYINT,
  IN _depends INTEGER UNSIGNED,
  OUT _row_count INTEGER UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`jobs` SET
    `job_name` = _job_name,
    `job_type_id` = _job_type_id,
    `query` = _query,
    `mi` = _mi,
    `hr` = _hr,
    `dm` = _dm,
    `mn` = _mn,
    `dw` = _dw,
    `active` = _active,
    `depends` = _depends
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- This method is only included for the sake of completeness
-- updatin of the history record should be via the log procedure
-- which alos removes the queue record within a transaction
DROP PROCEDURE IF EXISTS `update_history`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `update_history`(
  IN _job_id INTEGER UNSIGNED,
  IN _runtime DATETIME,
  IN _rows_affected INTEGER,
  IN _started DATETIME,
  IN _finished DATETIME,
  IN _error TEXT,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`history` SET
    `rows_affected` = _rows_affected,
    `started` = _started,
    `finished` =  _finished,
    `error` = _error
  WHERE `job_id`  = _job_id
  AND `runtime` = _runtime;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- DELETE SCHEMA OBJECTS
-- ******************************************************************************************

DROP PROCEDURE IF EXISTS `delete_job_type`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `delete_job_type`(
  IN _job_type_id TINYINT UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DELETE FROM `mydlm`.`job_types`
  WHERE `job_type_id` = _job_type_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `delete_schema`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `delete_schema`(
  IN _schema_id TINYINT UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DELETE FROM `mydlm`.`schemata`
  WHERE s.`schema_id` = _schema_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `delete_table`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `delete_table`(
  IN _table_id MEDIUMINT UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DELETE FROM `mydlm`.`tables`
  WHERE `table_id` = _table_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `delete_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `delete_job`(
  IN _job_id INTEGER UNSIGNED,
  OUT _row_count INTEGER UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  SET FOREIGN_KEY_CHECKS = 0;

  DELETE FROM `mydlm`.`jobs`
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
  SET FOREIGN_KEY_CHECKS = 1;
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `delete_history`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `delete_history`(
  IN _job_id INTEGER UNSIGNED,
  IN _runtime DATETIME,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DELETE FROM `mydlm`.`history`
  WHERE `job_id`  = _job_id
  AND `runtime` = _runtime;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- OPERATIONAL
-- ******************************************************************************************

-- GET STUCK JOBS
DROP PROCEDURE IF EXISTS `get_dependent_queue_jobs`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_dependent_queue_jobs`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT q1.`job_id` 'stuck', q1.`runtime`, j1.`job_name`, jt1.`job_type_name`,
    q2.`job_id` 'depends' , q2.`runtime`, j2.`job_name`, jt2.`job_type_name`
  FROM `mydlm`.`queue` q1
  JOIN `mydlm`.`queue` q2 ON(q1.`depends` = q2.`job_id`)
  JOIN `mydml`.`jobs` j1 ON(j1.`job_id` = q1.`job_id`)
  JOIN `mydml`.`jobs` j2 ON(j2.`job_id` = q2.`job_id`)
  JOIN `mydlm`.`job_types` jt1 ON(j1.`job_type_id` = jt1.`job_type_id`)
  JOIN `mydlm`.`job_types` jt2 ON(j2.`job_type_id` = jt2.`job_type_id`);
END //
DELIMITER ;


-- PUT A JOB ON THE QUEUE
DROP PROCEDURE IF EXISTS `queue_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `queue_job`(
  _job_id INTEGER UNSIGNED,
  _runtime DATETIME)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
COMMENT 'Put a job instance on the queue'
BEGIN
  START TRANSACTION;
    INSERT INTO `mydlm`.`queue` VALUES (`_job_id`,`_runtime`);   
    INSERT INTO `mydlm`.`history` VALUES (`_job_id`,`_runtime`);   
  COMMIT;
END //
DELIMITER ;


-- On completion or error remove the schedule record and update history
DROP PROCEDURE IF EXISTS `log`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `log` (
  _job_id MEDIUMINT,
  _runtime DATETIME,
  _rows_affected INTEGER,
  _started DATETIME,
  _finished DATETIME,
  _error TEXT)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  START TRANSACTION;
    DELETE FROM `mydlm`.`queue` WHERE `job_id` = _job_id AND `runtime` = _runtime;   

    UPDATE `mydlm`.`history` SET
    `rows_affected` = _rows_affected,
    `started` = _started,
    `finished` = _finished,
    `error` = _error
    WHERE `job_id` = _job_id AND `runtime` = _runtime;   
  COMMIT;
END //
DELIMITER ;


-- CAN A JOB BE RUN
-- A job can only be cancelled if its taken out of the queue
-- We don't test for active as it might be a blocked job that
-- is a precondition for another
DROP FUNCTION IF EXISTS `is_runable`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' FUNCTION `is_runable` (
  _job_id INTEGER UNSIGNED,
  _runtime DATETIME)
RETURNS BOOLEAN
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  DECLARE rtn INTEGER UNSIGNED;
  
  SELECT COUNT(*) INTO rtn
  FROM
   (SELECT 1
    FROM `mydlm`.`queue` q
    WHERE q.`job_id` = _job_id
      AND q.runtime < _runtime
    UNION
    SELECT 1
    FROM `mydlm`.`queue` q
    JOIN `mydlm`.`jobs` j ON(q.`job_id` = j.`depends`)
    WHERE j.`job_id` = _job_id
      AND q.runtime <= _runtime
    UNION
    SELECT 1
    FROM `mydlm`.`jobs` j
    WHERE j.`job_id` = _job_id
      AND j.`active` != 1
   ) der;
  
  RETURN IF (rtn = 0 , TRUE, FALSE);  
END //
DELIMITER ;


-- POPULATE QUEUE WITH RUNNABLE JOBS 
-- This is calld from the EVENT mydlm_queue_jobs and populates
-- the queue and history tables
-- NB if both "day of month" (field 3) and "day of week" (field 5) are restricted (not "*"),
-- then one or both must match the current day.

DROP PROCEDURE IF EXISTS `queue_jobs`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `queue_jobs` ()
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  START TRANSACTION;

  INSERT INTO `mydlm`.`queue` (`job_id`,`runtime`)
  SELECT job_id, DATE_FORMAT(NOW(),'%Y-%m-%d %H:%i:00')
  FROM (
    SELECT j.`job_id`, NULL
    FROM `mydlm`.`jobs` j
    WHERE (j.`mi` = '*' OR FIND_IN_SET(MINUTE(NOW()),j.`mi`) > 0)
      AND (j.`hr` = '*' OR FIND_IN_SET(HOUR(NOW()),j.`hr`) > 0)
      AND (j.`dm` = '*' OR FIND_IN_SET(DAY(NOW()),j.`dm`) > 0)
      AND (j.`mn` = '*' OR FIND_IN_SET(MONTH(NOW()),j.`mn`) > 0)
      AND (j.`dw` = '*')
      AND (j.`active` = 1)
    UNION
    SELECT j.`job_id`, NULL
    FROM `mydlm`.`jobs` j
    WHERE (j.`mi` = '*' OR FIND_IN_SET(MINUTE(NOW()),j.`mi`) > 0)
      AND (j.`hr` = '*' OR FIND_IN_SET(HOUR(NOW()),j.`hr`) > 0)
      AND (j.`dm` = '*')
      AND (j.`mn` = '*' OR FIND_IN_SET(MONTH(NOW()),j.`mn`) > 0)
      AND (j.`dw` = '*' OR FIND_IN_SET(DAYOFWEEK(NOW()) - 1,j.`dw`) > 0)
      AND (j.`active` = 1)   
    UNION
    SELECT j.`job_id`, NULL
    FROM `mydlm`.`jobs` j
    WHERE (j.`mi` = '*' OR FIND_IN_SET(MINUTE(NOW()),j.`mi`) > 0)
      AND (j.`hr` = '*' OR FIND_IN_SET(HOUR(NOW()),j.`hr`) > 0)
      AND (FIND_IN_SET(DAY(NOW()),j.`dm`) > 0)
      AND (j.`mn` = '*' OR FIND_IN_SET(MONTH(NOW()),j.`mn`) > 0)
      AND (j.`dw` = '*' OR FIND_IN_SET(DAYOFWEEK(NOW()) - 1,j.`dw`) > 0)
      AND (j.`active` = 1)
  ) der;

  INSERT INTO `mydlm`.`history` (`job_id`,`runtime`,`created`)
  SELECT `job_id`,`runtime`, NULL
  FROM `mydlm`.`queue`
  WHERE `runtime` = DATE_FORMAT(NOW(),'%Y-%m-%d %H:%i:00');
  
  COMMIT;
END //
DELIMITER ;


/*
 ACTIVATE/DEACTIVATE mydlm via a toggle
*/
DROP PROCEDURE IF EXISTS `toggle_active`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `toggle_active` (
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`control`
    SELECT NULL, NOT `run`
    FROM `mydlm`.`control`
    ORDER BY `created` DESC LIMIT 1; 

  SET _row_count = ROW_COUNT();
END //

DELIMITER ;

/*
 Master control test for mydlm
*/
DROP FUNCTION IF EXISTS `is_active`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' FUNCTION `is_active` ()
RETURNS BOOLEAN
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  DECLARE rtn BOOLEAN;
  SELECT `run` INTO `rtn` 
  FROM `mydlm`.`control`
  ORDER BY `created` DESC
  LIMIT 1;

  RETURN `rtn`;
END //

DELIMITER ;



/* get the next runnable job. Update the semaphore,
 * and run it. When  finished, update the history and
 * delete the item from the queue and commit the work. 
 * If the job was a one-off set it to inactive.
 */
DROP PROCEDURE IF EXISTS `run_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `run_job` ()
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
main:BEGIN
  DECLARE _started DATETIME;
  DECLARE _finished DATETIME;
  DECLARE _job_id INTEGER UNSIGNED;
  DECLARE _runtime DATETIME;
  DECLARE _rows_affected INTEGER;
  DECLARE _job_type_id TINYINT UNSIGNED;
  DECLARE _query TEXT;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1
      @1 = RETURNED_SQLSTATE,
      @2 = MESSAGE_TEXT,
      @3 = MYSQL_ERRNO,
      @4 = CONSTRAINT_SCHEMA,
      @5 = CONSTRAINT_NAME,
      @6 = SCHEMA_NAME,
      @7 = TABLE_NAME,
      @8 = COLUMN_NAME,
      @9 = CURSOR_NAME;

    SET @err = CONCAT_WS(':',@1,@2,@3);

    ROLLBACK;
    CALL `mydlm`.`suspend_job`(_job_id,@discard);
    CALL `mydlm`.`log`(_job_id,_runtime,NULL,NULL,NULL,@err);
    RESIGNAL;
  END;
  
  IF (SELECT `mydlm`.`is_active`()) = FALSE THEN
    LEAVE main;
  END IF;

  SET @query = NULL;
  SET _started = SYSDATE();

  START TRANSACTION;

  -- next runnable job
  SELECT `job_id`, q.`runtime`, j.`job_type_id`,j.`query`
  INTO _job_id, _runtime, _job_type_id, @query
  FROM `mydlm`.`queue` q
  JOIN `mydlm`.`jobs` j USING(`job_id`)
  WHERE j.`active` = 1
  AND q.`semaphore` = 0 
  AND `is_runable`(`job_id`,`runtime`) = TRUE
  ORDER BY q.`runtime` ASC LIMIT 1;

  IF _job_id IS NULL THEN -- empty queue
    LEAVE main;
  END IF;

  SET @runtime = _runtime;

  UPDATE `mydlm`.`queue`
  SET `semaphore` = 1
  WHERE `job_id` = _job_id AND `runtime` = _runtime;

  -- macro replacement
  SET @query = REPLACE(@query,'@@DATE@@',DATE_FORMAT(_runtime,'%Y%m%d'));
  SET @query = REPLACE(@query,'@@YEARWEEK@@',DATE_FORMAT(_runtime,'%X%V'));
  SET @query = REPLACE(@query,'@@YEARMONTH@@',DATE_FORMAT(_runtime,'%Y%m'));
  SET @query = REPLACE(@query,'@@YEAR@@',DATE_FORMAT(_runtime,'%Y'));
  SET @query = REPLACE(@query,'@@TIME@@',DATE_FORMAT(_runtime,'%H%i%s'));

  PREPARE _stmt FROM @query;
  IF LOCATE('?', @query) > 0 THEN
    EXECUTE _stmt USING @runtime;
  ELSE
    EXECUTE _stmt;
  END IF;
  
  SET _rows_affected = ROW_COUNT();
  DEALLOCATE PREPARE _stmt;

  SET _finished = SYSDATE();

  CALL `mydlm`.`log`(_job_id,_runtime,_rows_affected,_started,_finished,NULL);

  IF _job_type_id = 1 THEN
    CALL `mydlm`.`suspend_job`(_job_id, @discard);
  END IF;

  CALL `mydlm`.`dequeue_job`(_job_id,_runtime, @discard);

  COMMIT;
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `dequeue_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `dequeue_job` (
  IN _job_id INTEGER UNSIGNED,
  IN _runtime DATETIME,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DELETE FROM `mydlm`.`queue`
  WHERE `job_id` = _job_id AND `runtime` = _runtime;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `deactivate_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `deactivate_job` (
  IN _job_id INTEGER UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`jobs`
  SET `active` = 0
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `reactivate_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `reactivate_job` (
  IN _job_id INTEGER UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`jobs`
  SET `active` = 1
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;

-- suspend on error or to temporarily stop from running
DROP PROCEDURE IF EXISTS `suspend_job`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `suspend_job` (
  IN _job_id INTEGER UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`jobs`
  SET `active` = -1
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


DROP PROCEDURE IF EXISTS `close_error`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `close_error` (
  IN  _job_id INTEGER UNSIGNED,
  OUT _row_count TINYINT UNSIGNED)
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  UPDATE `mydlm`.`jobs`
  SET `active` = 1
  WHERE `job_id` = _job_id;

  SET _row_count = ROW_COUNT();
END //
DELIMITER ;


-- THRESHOLD REACHED CHECK
DROP PROCEDURE IF EXISTS `activation_check`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `activation_check`()
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  DECLARE _schema_name VARCHAR(64);
  DECLARE _table_name VARCHAR(64);
  DECLARE _job_id INTEGER UNSIGNED;
  DECLARE _table_id MEDIUMINT UNSIGNED;
  DECLARE _retain_days SMALLINT UNSIGNED;
  DECLARE _retain_key VARCHAR(64);
  DECLARE _done BOOLEAN DEFAULT FALSE;
  
  DECLARE cur CURSOR FOR
    SELECT j.`job_id`, j.`table_id`, s.`schema_name`, t.`table_name`,
      t.`retain_days`, t.`retain_key`
    FROM `mydlm`.`jobs` j
    JOIN `mydlm`.`tables` t
    JOIN `mydlm`.`schemata` s
    WHERE j.`active` = -1;

  DECLARE CONTINUE HANDLER FOR NOT FOUND 
   SET _done = TRUE;

  OPEN cur;

  myloop:LOOP
    FETCH cur INTO _job_id, _table_id, _schema_name, _table_name,
      _retain_days, _retain_key;

    IF _done THEN
      LEAVE myloop;
    END IF;

    BEGIN
      SET @sql = 
        CONCAT('UPDATE `mydlm`.`jobs`
        SET `active` = 1
        WHERE `job_id` = ', _job_id, '
        AND `table_id = ', _table_id, '
        AND ', _retain_days, '? <= 
          (SELECT DATEDIFF(NOW(), MIN(`', _retain_key, '`)
           FROM `', _schema_name, '`.`', _table_name, '`) der');

      PREPARE stmt FROM @sql;
      EXECUTE stmt;
      DEALLOCATE PREPARE stmt;
    END;
  END LOOP;

  CLOSE cur;

END //
DELIMITER ;


-- MONITORING
-- ******************************************************************************************

-- GET ROWS PER TABLE
DROP PROCEDURE IF EXISTS `monitor_tables`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `monitor_tables`()
DETERMINISTIC
SQL SECURITY INVOKER 
MODIFIES SQL DATA
BEGIN
  INSERT INTO `mydlm`.`monitor`(`table_id`,`table_rows`,`auto_increment`,`keyspace`)
  SELECT m.`table_id`,t.`table_rows`,t.`auto_increment`,
    CASE c.`data_type`
      WHEN 'TINYINT' THEN ROUND(t.`auto_increment` /
        IF(c.`column_type` LIKE '%unsigned',255,127),2)
      WHEN 'SMALLINT' THEN ROUND(t.`auto_increment` /
        IF(c.`column_type` LIKE '%unsigned',65535,32767),2)
      WHEN 'MEDIUMINT' THEN ROUND(t.`auto_increment` /
        IF(c.column_type LIKE '%unsigned',16777215,8388607),2)
      WHEN 'INT' THEN ROUND(t.`auto_increment` /
        IF(c.`column_type` LIKE '%unsigned',4294967295,2147483647),2)
      WHEN 'BIGINT' THEN ROUND(t.auto_increment /
        IF(c.`column_type` LIKE '%unsigned',18446744073709551615,9223372036854775807),2)
      ELSE 0
    END AS 'keyspace'
  FROM `mydlm`.`tables` m
  JOIN `mydlm`.`schemata` s
    ON(m.`schema_id` = s.`schema_id`)
  JOIN `information_schema`.`tables` t
    ON(s.`schema_name` = t.`table_schema` AND m.`table_name` = t.`table_name`)
  LEFT JOIN `information_schema`.`columns` c
    ON(t.`table_schema` = c.`table_schema` AND t.`table_name` = c.`table_name`
        AND c.`extra` = 'AUTO_INCREMENT');
END //
DELIMITER ;


-- MONITOR DATA PER TABLE
DROP PROCEDURE IF EXISTS get_monitor_data_by_table; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE get_monitor_data_by_table(
  _table_id MEDIUMINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT s.`schema_name`, t.`table_name`, m.`table_rows`,
    m.`auto_increment`, m.`keyspace`, m.`created`
   FROM `mydlm`.`schemata` s
   JOIN `mydlm`.`tables` t USING (`schema_id`)
   JOIN `mydlm`.`monitor` m USING (`table_id`)
   WHERE m.`table_id` = _table_id;
END //
DELIMITER ;


-- MONITORING FOR ALL TABLES
DROP PROCEDURE IF EXISTS `get_monitor_data`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `get_monitor_data`()
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT s.`schema_name`, t.`table_name`, m.`table_rows`,
    m.`auto_increment`, m.`keyspace`, m.`created`
   FROM `mydlm`.`schemata` s
   JOIN `mydlm`.`tables` t USING (`schema_id`)
   JOIN `mydlm`.`monitor` m USING (`table_id`);
END //
DELIMITER ;


-- MONITORING AGAINST THRESHOLD
DROP PROCEDURE IF EXISTS `keyspace_alert`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `keyspace_alert`(
  _threshold TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
  SELECT s.`schema_name`, t.`table_name`, m.`table_rows`,
    m.`auto_increment`, m.`keyspace`, m.`created`
   FROM `mydlm`.`schemata` s
   JOIN `mydlm`.`tables` t USING (`schema_id`)
   JOIN `mydlm`.`monitor` m USING (`table_id`)
   WHERE m.`keyspace` > _threshold;
END //
DELIMITER ;


-- GROWTH (daily weekly 4 weekly)

DROP PROCEDURE IF EXISTS `keyspace_growth`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `keyspace_growth`(
  _table_id MEDIUMINT UNSIGNED,
  _days SMALLINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
SELECT m2.mdate AS 'Sample 1',m1.mdate 'Sample 2 ',m2.autoinc AS 'Keys sample 1',
  m1.autoinc AS 'Keys sample 2',(m1.autoinc - m2.autoinc) AS 'Growth'
FROM
  (SELECT DATE(`created`) AS 'mdate', `table_id`,
    MAX(`auto_increment`) AS 'autoinc'
   FROM `mydlm`.`monitor`
   WHERE `table_id` = _table_id
   GROUP BY 1,2) m1
LEFT JOIN
  (SELECT DATE(`created`) AS 'mdate', `table_id`,
    MAX(`auto_increment`) AS 'autoinc'
   FROM `mydlm`.`monitor`
   WHERE `table_id` = _table_id
   GROUP BY 1,2) m2
ON  (m1.`table_id` = m2.`table_id` AND m1.`mdate` = DATE_ADD(m2.`mdate`, INTERVAL _days DAY));

END //
DELIMITER ;

-- ORDER KEY GROWTH
DROP PROCEDURE IF EXISTS `fastest_growth`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `fastest_growth`(
  _days SMALLINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
SELECT s.`schema_name`, t.`table_name`, m2.mdate AS 'Sample 1',
  m1.mdate 'Sample 2 ',m2.autoinc AS 'Keys sample 1',
  m1.autoinc AS 'Keys sample 2',(m1.autoinc - m2.autoinc) AS 'Growth'
FROM `mydlm`.`tables` t
JOIN `mydlm`.`schemata` s USING(`schema_id`)
JOIN  
 (SELECT DATE(`created`) AS 'mdate', `table_id`,
    MAX(`auto_increment`) AS 'autoinc'
   FROM `mydlm`.`monitor`
   GROUP BY 1,2) m1 ON (m1.`table_id` = t.`table_id` AND m1.`autoinc` IS NOT NULL)
JOIN
  (SELECT DATE(`created`) AS 'mdate', `table_id`,
    MAX(`auto_increment`) AS 'autoinc'
   FROM `mydlm`.`monitor`
   GROUP BY 1,2) m2
ON  (m1.`table_id` = m2.`table_id` AND m1.`mdate` = DATE_ADD(m2.`mdate`, INTERVAL _days DAY))
GROUP BY 1,2,3,4,5,6
ORDER BY 7 DESC;
END //
DELIMITER ;

-- HISTORY BY JOB TYPE
DROP PROCEDURE IF EXISTS `history_by_job_type`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `history_by_job_type`(
  _table_id MEDIUMINT UNSIGNED,
  _job_type_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
SELECT h.`runtime`,jt.`job_type_name`,h.`rows_affected`, h.`started`, h.`finished`
FROM `mydlm`.`history` h
JOIN `mydlm`.`jobs` j USING(`job_id`)
JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
WHERE j.`table_id` = _table_id
AND j.`job_type_id` = _job_type_id;
END //
DELIMITER ;

-- HISTORY BY JOB TYPE/PERIOD
DROP PROCEDURE IF EXISTS `history_summary_by_period`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `history_summary_by_period`(
  _table_id MEDIUMINT UNSIGNED,
  _job_type_id TINYINT UNSIGNED,
  _interval CHAR(5))
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
-- takes day,week,month,year buckets
SELECT CASE _interval
  WHEN 'day' THEN DATE(h.`runtime`)
  WHEN 'week' THEN YEARWEEK(h.`runtime`)
  WHEN 'month' THEN EXTRACT(YEAR_MONTH FROM h.`runtime`)
  WHEN 'year' THEN YEAR(h.`runtime`) END,
  jt.`job_type_name`, SUM(h.`rows_affected`)
FROM `mydlm`.`history` h
JOIN `mydlm`.`jobs` j USING(`job_id`)
JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
WHERE j.`table_id` = _table_id
AND j.`job_type_id` = _job_type_id
GROUP BY 1,2;
END //
DELIMITER ;


-- HISTORY EXECUTION TIME
DROP PROCEDURE IF EXISTS `history_execution_time`; 
DELIMITER //
CREATE DEFINER='dlmadmin'@'localhost' PROCEDURE `history_execution_time`(
  _table_id MEDIUMINT UNSIGNED,
  _job_type_id TINYINT UNSIGNED)
SQL SECURITY INVOKER 
READS SQL DATA
BEGIN
-- takes day,week,month,year buckets
SELECT h.`job_id`, h.`runtime`, j.`job_name`, jt.`job_type_name`,
h.`rows_affected`, TIMEDIFF(h.`started`, h.`finished`)
FROM `mydlm`.`history` h
JOIN `mydlm`.`jobs` j USING(`job_id`)
JOIN `mydlm`.`job_types` jt USING(`job_type_id`)
WHERE j.`table_id` = _table_id
AND j.`job_type_id` = _job_type_id;
END //
DELIMITER ;

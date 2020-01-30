-- POPULATE THE RUN QUEUE

DROP EVENT IF EXISTS `mydlm`.`mydlm_queue_jobs`;
DELIMITER //
CREATE EVENT `mydlm`.`mydlm_queue_jobs`
ON SCHEDULE EVERY 1 MINUTE
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Populate the mydlm job queue'
DO
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    RESIGNAL SET MESSAGE_TEXT = 'Event Handler error- queue';
  END;

  CALL `mydlm`.`queue_jobs`;
END //

DELIMITER ;

-- RUN THE JOB PROCESS
DROP EVENT IF EXISTS `mydlm`.`mydlm_run_job`;
DELIMITER //
CREATE EVENT `mydlm`.`mydlm_run_job`
ON SCHEDULE EVERY 20 SECOND
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Execute first mydlm job on the run queue'
DO
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    RESIGNAL SET MESSAGE_TEXT = 'Event Handler error - run';
  END;

  CALL `mydlm`.`run_job`;
END //

DELIMITER ;


-- RUN THE ACTIVATION CHECK PROCESS
DROP EVENT IF EXISTS `mydlm`.`mydlm_activation_check`;
DELIMITER //
CREATE EVENT `mydlm`.`mydlm_activation_check`
ON SCHEDULE EVERY 1 DAY
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Have jobs reached the point when the retntion policy kicks in'
DO
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    RESIGNAL SET MESSAGE_TEXT = 'Event Handler error - activation';
  END;

  CALL `mydlm`.`activation_check`;
END //

DELIMITER ;


-- RUN THE TABLE STATS CHECK PROCESS
-- RUN AT 3AM 
DROP EVENT IF EXISTS `mydlm`.`mydlm_table_stats`;
DELIMITER //
CREATE EVENT `mydlm`.`mydlm_table_stats`
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 3 HOUR)
ON COMPLETION PRESERVE
ENABLE
COMMENT 'Gather stats on table growth'
DO
BEGIN
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    RESIGNAL SET MESSAGE_TEXT = 'Event Handler error - table stats';
  END;

  CALL `mydlm`.`monitor_tables`(@rtn);
  -- CALL `mydlm`.`monitor_tables_slow`(@rtn);

  SELECT @rtn;
END //

DELIMITER ;

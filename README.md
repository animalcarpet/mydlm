# mydlm

## General
A Data Lifetime Management (DLM) tool for MySQL.

Note: This code is not yet production ready. I'll be adding a suite of tests and some
additional monitoring reports before it reaches that state.

mydlm is intended as a tool for managing the summarization, pruning or archiving of
data in MySQL, in fact any repeated task for the proper stewardship of data over time
within your MySQL databases. At present, the codebase only covers the backend tasks
and is implemented as MySQL stored procedures and events. mydlm can be run entirely through
these backend process, however, much of the administration and the monitoring would
be considerably easier with a suitable front interface calling and consuming these
procedures.

Data is managed by jobs that define the type, dependencies, payload and schedule for
running and monitoring DLM tasks. A job may have as its payload any single SQL
statement. More complex tasks can be defined either as a stored procedure
or as a series of dependent jobs. Jobs can be dependent on the completion of other jobs and
are always dependent on those with the same definition, this ensures that they always
run in sequence and that only one instance of that particular task can can be running
at a given time. So, an archiving task might be dependent on a DDL task to create
the table the data will be archived to, and a subsequent deletion might be dependent on
the archiving task being completed.

A table may have multiple jobs associated with it. These jobs may cover any one
or all the defined types i.e. summarisation, archiving, pruning, DDL, updates
and even one-off tasks. While it will normally be the case that a table will only have
one job per type associated with it, it is possible to have multiple jobs of any
given type.

### Control table
DLM processes can be toggled on/off individually or all processing started/stopped via
a control table. This table also records the time of these transitions.


### Schema and Table Definition
DLM tasks, jobs in our parlance, are defined against Schema and Tables records.
For schemata, this is solely for the purpose of organising the records. Table definitions,
on the other hand, contain meta-data that define the retention policy for records
in the table.

A table record comprises:
* The table identifier
* The identifier of the related schema record
* The table name
* Whether the table contains financial or personal data
* The retention period
* The key that will be used to select records for DLM processes

The retention data is used to ensure that the DLM procedures are only
activated once the data within the table has aged by the appropriate amount, this
allows the job to be set up some time in advance when the table is first
created and when you might be weeks, months or even years from the need to run DLM
processes against the data.

### Job Types
The following types are currectly defined. Only the One-off type has a effect on
the way the job will be run - they deactivate themselves after they are run
* Summarisation
* Archiving
* Pruning
* DDL task
* Updating
* One-Off


### Job Definition
A job record includes
* The table identifier
* A name for the job
* The type of operation
* The query (a definition of the statement to run)
* The schedule for running the policy expressed in a cron-like format
* The specification of any dependency which must be successfully completed before running the job

### Statement definition
mydlm makes no assumption, nor imposes any restriction, on the statements that can be 
run for a job aside from it being a single statement.  Each statement should contain all the
logic for selecting, summarising, deleting or other task that is required. Most DLM tasks will
depend on a date, or component of a date for selecting records. For efficiency and to prevent
locking, selection of records should always be an indexed column or columns.  In addition, 
it is preferable that the queued runtime for the job is used in the selection of records 
rather than the use of functions such as NOW() or CURRENT_TIMESTAMP -  this will make it 
possible for the jobs to be have exactly the same effect on the data irrespective of when
they are run - for example if an issue prevents the job from running or the scheduler
is temporarily suspended.

mydlm contains simple macro substitution which allows components of the schedule
date to be used when constructing a statement to execute.

The defined macros can be used anyhere within a statement and are always defined in reference to 
the job runtime value rather than the current datetime. The macros can be categorised into those
which extract a date part from the runtime of a job and those that define the start of a period
relative to the job's runtime value. When using the latter category you can define a period between
two macros, so the previous month would be defined as

```
`datetime` >= @@LASTMONTH@@ AND `datetime` < @@THISMONTH@@ 
```

which would be equivalent to 

```
`datetime` >= DATE_FORMAT(DATE_SUB(@runtime, INTERVAL 1 MONTH),'%Y-%m-01 00:00:00') AND 
`datetime` < DATE_FORMAT(@runtime,'%Y-%m-01 00:00:00') 
```

Those macros defining periods always align with the very start of the period (e.g. midnight on the
1st of the month, midnight on the 1st of January etc.).

Date Part
* @@RUNTIME@@ 
* @@DATE@@ (@@TODAY@@)
* @@YEARWEEK@@
* @@YEARMONTH@@
* @@YEAR@@
* @@MONTH@@
* @@TIME@@
* @@HOUR@@
* @@MINUTE@@

Period Definition
* @@LASTYEAR@@
* @@NEXTYEAR@@
* @@LASTMONTH@@
* @@NEXTMONTH@@
* @@LASTWEEK@@
* @@NEXTWEEK@@
* @@YESTERDAY@@
* @@TOMORROW@@

#### Example Use 

Macros can be inserted in any part of a statement where a date of part of one can be used. The 
`job_run`() procedure retrieves the statements as strings from the database and does any macro 
replacement before it PREPARES and EXECUTES statement.
 
Remember to ensure that the record selection criteria is sargeable - i.e. use functions
on the parameter being tested and not on the indexed column.  

 
Delete records from last week
DELETE FROM table1 WHERE datecol >= DATE_SUB(@@DATE@@, INTERVAL 2 WEEK) 
  AND datecol < DATE_SUB(@@DATE@@, INTERVAL 1 WEEK); 


Archive records from previous year
CREATE TABLE `archive`.`table1_@@YEAR@@` AS
  SELECT * FROM table1 
  WHERE tscol >= @@YEAR@@ -1 
  AND tscol < @@YEAR@@;  


Drop a partition
DROP PARTITION IF EXISTS `table1`@@MONTH@@



### Schedule Definition
As mentioned above, mydlm uses a cron-like format for scheduling tasks. There are two reasons 
I have chosen this method: 

1. cron is a well understood format
2. The event scheduler syntax is complex and difficult to get to grips with

So, defining an event in MySQL to recur at 3:25am every day requires

```
ON SCHEDULE EVERY 1 DAY
STARTS (TIMESTAMP(CURRENT_DATE) + INTERVAL 1 DAY + INTERVAL 3 HOUR + INTERVAL 25 MINUTE)
ON COMPLETION PRESERVE
```
 
While cron will define the same with

```
25 3 * * * *
```

Like cron, jobs are scheduled to minute resolution and the cron expression consists of 5 parts 
signifying minutes, hours, day of month, month, and day of week. Note that, unlike cron, mydlm can
also be used for scheduling one-off tasks with the job specification suspended after it is first run.

mydlm recognises the following values within fields

* All fields   - \* (any value)
* minutes      - 0 to 59
* hours        - 0 to 23
* day of month - 1 to 31
* month        - 1 to 12
* day of week  - 0 to 6 (where Sunday = 0)

mydlm supports cron's ability to define comma-separated lists of values in each part, it does not
support hyphen-separated range style definition.

So,

```
0,15,30,45 * * * *
```
defines a schedule that runs every hour, on the hour and every 15 minutes thereafter.

However, the cron expression

```
30 5-10 * * *
```
would not be recognised by mydlm.

Instead, you would need 

```
30 5,6,7,8,9,10 * * *
```

### Running the jobs
A database EVENT (`mydlm_queue_jobs`) runs on the server to populate a job queue with 
the job identifier (`job_id`) and scheduled time (`runtime`) for each task that is due to 
start within the next minute.A separate EVENT (`mydlm_run_job`) pulls a runable job off 
the front of the queue, locks it with a semaphore, runs it and logs details of its execution. 
In this context 'runable' means a job that isn't locked by a semaphore, isn't in an error
state or where the job hasn't been suspended.


#### Example cron schedules

```
0 12 1 * *        = noon on the first of each month 
0,30 * * * *      = every half hour
15 15 * * 1       = a quarter past three in the after noon every Monday
0 20 1 1 *        = eight in the evening on the first of January
```

### Dependencies
Many DLM tasks will have natural dependencies. For example, You may wish to summarise
some data before deleting or archiving it. Such tasks should be scheduled to run in
the proper sequence and with sufficient time between them to ensure they run to completion.
mydlm allows for these dependencies to be explicitly stated and will check that required
tasks are completed successfully before allowing a dependent task to run.

### Job Status
Job status is indicated by a single variable that takes three states

* active 
* inactive
* suspended

* active - indicates the job is active with the DLM process.  
* inactive - indicates that the job applies to data that still hasn't aged sufficiently for DLM
processes to be necessary..
* suspended - indicates that the job has an uncleared error condition or has been temporarily stopped. 

### Logging
The `history` table records the
* Job identifier
* Scheduled time
* Start and finish times
* Number of rows affected (if any)
* Any error message generated when run

Certain operations in MySQL will return -1 for the number of rows affected, e.g. DDL
statements, so the `rows_affected` value should always be used in conjunction with
the `job_type` when calculating the number of rows that have been subject to DML
processes.

### Monitoring
As well as managing the data within the table, mydlm also provides routines to monitor
the number of rows in the table, the use of auto_increment keys, growth in the number
of records over different time periods and will also to track the fastest growing tables.

Statistics are gathered using a daily EVENT `mydlm_table_stats`. This
EVENT will then call a procedure `mydlm`.`monitor_stats` to populate the `monitor` table. 

The `mydlm_table_stats` event has been defined to run once a day at 3am. This can be 
changed to any time or interval you wish by dropping the current event and changing its
definition. The important thing here is to ensure that the interval is regular so that
the growth rate can be compared in a consistent fashion. If hourly rates are required
you could use the following definition.

```
ON SCHEDULE EVERY 1 HOUR
ON COMPLETION PRESERVE
```

Row counts are estimates from `information_schema`.`tables` as counting actual rows
can be too slow for very large tables. MYISAM tables will return a precise count of 
the rows, INNODB tables might be out by several percent in the same manner as index
statistics that the optimizer uses for deciding the optimal way to run queries. The point 
of this feature is to get an overall impression of the growth in the number of rows, 
the precise figure is usually of secondary importance. If precise counts are desired 
there is an alternate version of the stats gathering procedure `monitor_tables_slow`
which will count rows in each monitored table individually - Note this procedure 
could be very slow on larger systems. Only tables that have been imported into
the system will be monitored, if a DLM process has been defined for a table it will
be included within monitoring without additional work, other tables can be included
without a DLM process if required.


### Events
mydlm uses MySQL's EVENTS to automate the selection and running of jobs.

The queuing EVENT runs every minute, this corresponds with the way that a cron process
will initiate tasks against a predefined schedule.

The job runner EVENT should run at a frequency that is capable of keeping pace with
the queue. The EVENT will check for a runnable job, this is a very fast check against
a table with very few rows. The frequency for this EVENT can be adjusted up or down
as appropriate.

The activation check EVENT tests to see whether a job should be considered 'active'
because the data has aged sufficiently to have reached its data retention threshold.
It dose this by testing a timestamp of the oldest record. If the threshold has
passed the job is set 'active' and will be queued to run against the defined schedule.


### Replication Setup
mydlm can be used in replication environments where the replication format is set to
either ROW or MIXED. Install the pacage on the master and the schema, procedures and
evevents will replicate to the slaves. The events will be naturally set to 'SLAVESIDE
DISABLED' so the events will only run on the master. Note, you cannot use mydlm with 
STATEMENT based replication and you will get an error when you try to import the 
procedures because some of them are non-deterministic because of the use of time and 
date functions.

Failover to a slave will require the EVENTS be set to either 'DISABLED' or
'SLAVESIDE DISABLED' on the old master server and the same EVENTS set to 'ENABLED'
on the new master.
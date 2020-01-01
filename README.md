# mydlm

## General
A Data Lifetime Management (DLM) tool for MySQL.

mydlm is intended as a tool for managing the summarization, pruning or archiving of
data in MySQL, in fact any repeated task to ensure the proper stewardship of data over time
within your MySQL databases. At present, the codebase only covers the backend tasks
and is implemented as MySQL stored procedures. mydlm could be run entirely as a back end
process, however, much of the administration of processes and the monitoring would
be considerably easier with a suitable frontend interface calling and consuming those
procedures.

Data is managed by jobs that define the type, dependencies, payload and schedule for
running and monitoring DLM tasks. A job may have as its payload any single statement
SQL. More complex tasks can be defined either as a stored procedure
or as a series of dependent jobs. Jobs can be dependent on the completion of another jobs or
even themself (i.e. you can ensure that only one instance of that particular task can
run at a given time). So, an archiving task might be dependent on a DDL task to create
the table the data will be archived to, and a subsequent deletion might be dependent on
the archiving task being completed.

A table may have multiple jobs associated with it. These jobs may cover any one
or all the defined types i.e. summarisation, archiving, pruning, DDL, updates
and even one-off tasks. While it will normally be the case that a table will only have
one job per type associated with it, it is possible to have multiple jobs of any
given type.


### Schema and Table Definition
DLM tasks, jobs in our parlance, are defined against Schema and Tables records.
For schemata, this is entirely for organisating the records. Table definitions,
on the other hand, contain meta-data that define the retention policy for records
in the table.

A table record comprises
The table identifier
The identifier of the related schema record
The table name
Whether the table contains financial or personal data
The retention period for  records
The key that will be used to select records for DLM processes
A timestamp for when the record was created.

The retention data is used to ensure that the DLM procedures are only
activated once the data within the table has aged by the appropriate amount, this
allows the policy to be set up some time in advance when the table is first
created and when you might be weeks, months or even years from the need to run DLM
processes.

### Job Types
The following types are currectly supported. Only the One-off type has a effect on
the way the job will be run.
* Summarisation
* Archiving
* Pruning
* DDL task
* Updating
* One-Off




### Job Definition
A job record defines
* The table identifier
* A name for the job
* The type of operation
* The query (a definition of the statement to run)
* The schedule for running the policy expressed in a cron-like format
* The specification of a dependency which must be successfully completed before running the job

### Statement definition
mydlm makes no assumption nor imposes any restrictions on the statements that can be 
run for a job aside from it being a single statement.  Each statements should contain all the
logic for selecting, summarising, deleting or other task that is required. Most DLM tasks will
depend on a date, or component of a date for selecting records. This should be derived from the
scheduled date for the job rather than the use of functions such as NOW() or CURRENT_TIMESTAMP
- this will make it possible for processes to be run with defined date even if the scheduler for
running the jobs fails or is suspended.

mydlm contains simple macro substitution which allows components of the schedule
date to be used when constructing a statement to execute.


### Schedule Definition
As mentioned above, mydlm uses a cron-like format for scheduling tasks. Like standard cron, jobs
are scheduled to minute resolution and the cron expression consists of 5 parts signifying minutes,
hours, day of month, month, and day of week. Note, unlike cron,  mydlm can also be used for running
one-off tasks with the job specification suspended after it is first run.

mydlm recognises the following values within fields

All fields   - * (any value)
minutes      - 0 to 59
hours        - 0 to 23
day of month - 1 to 31
month        - 1 to 12
day of week  - 0 to 6 (where Sunday = 0)

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
A database EVENT runs on a master server to populate a job queue with the job identifier
(job_id) and scheduled time for each task that is due to start within the next minute.
A separate EVENT pulls jobs off the queue, locks them with a semaphore, runs the job
and logs details of its execution.

#### Example cron schedules

```
0 12 1 * *        = noon on the first of each month 
0,30 * * * *      = every half hour
15 15 * * 1       = a quarter past three in the after noon every Monday
0 20 1 1 *        = eight in the evening on the first of January
```

### Dependencies
Dependencies can be defined between jobs. You may wish to summarise some data
before archiving it. Such tasks should be scheduled to run in the proper
sequence and with sufficient time between them to ensure they run to completion.
In addition, mydlm will check that the first task within such a sequence has completed
successfully and will not run the dependent task if it hasn't.

### Job Status
Job status is indicated by a single variable that denotes three separate states

* active 
* deactivated
* suspended

*active* indicates the job applies to data that has reached the retention period for DLM.  
*deactivated* indicates that the age of the data is outside the DLM period.
*suspended* indicates that the job has either been put into a suspended state because of an error or has been temporarily stopped. 

### Logging
The `history` table records the
* Job identifier
* Scheduled time
* Start and finish times
* Records affected (if any)
* Any error message generated when run

### Monitoring
As well as managing the data within the table, mydlm also provides routines to monitor
the number of rows in the table, the use of auto_increment keys, growth in the number
of records over different periods and also to track the fastest growing tables.

Row counts are estimates from `information_schema`.`tables` as counting actual rows
would be too slow for very large tables. The point of this feature is to get an
overall impression of the number of rows, the precise figure is not that important.


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
It doe this by testing a timestamp of the oldest record. If the threshold has
passed the job is set 'active' and will be queued to run against the defined schedule.



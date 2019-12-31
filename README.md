# mydlm

## General
A Data Lifetime Management tool for MySQL.

mydlm is intended as a tool for managing the summarization, pruning or archiving of
data, in fact any repeated task to ensure the proper stewardship of data over time
within your MySQL databases. 

Table data is managed by jobs that define the type, dependencies, payload and schedule for
running deletion, archiving and summarising of records. A job may have as it's payload
any single statement SQL. More complex tasks can be defined either as a stored procedure
or as a series of dependent jobs. Jobs can be dependent on the completion of other jobs or
even themself (i.e. you can ensure that only one instance of that particular task can
run at a given time). So, an archiving task might be dependent on a DDL task to create
the table the data will be archived to and a subsequent deletion might be dependent on
the archiving task being completed.

A table may have multiple job records. These policies may cover any one or all
of the policy types i.e. summarisation, archiving or pruning and, while it will
normally be the case that a table will only have one job per type it is possible
to have multiple policies of any given type.


### Schema and Table Definition
DLM tasks, jobs in our parlance, are defined against Schema and Tables records.
For schemata, this is entirely for organisating the records. Table definitions,
on the other hand, contain meta-data that define the retention policy for records
in the table

A table record comprises
The table identifier
The identifier of the related schema record
Table name
Whether the table contains either financial or personal data
The number of days to retain records
The key that will be used to select records for DLM processes
A timestamp for when the record was created.

The retention data is used to ensure that the retention procedures are only
activated once the data within the table has aged by the appropriate amount, this
allows the policy to be set up some time in advance when the table is first
created and when you might be weeks, months or even years from running DLM
processes.


### Job Definition
A job record defines
The table identifier
A name for the job
The type of operation
  Summarisation
  Archiving
  Pruning
  DDL task
  One-Off
The query (a definition of the statement to run)
The schedule for running the policy expressed in a cron-like format
The specification of a dependency which must be successfully completed before running the job

### Statement definition
mydlm makes no assumption nor imposes any restrictions on the statements that can be 
run for a job aside from it being a single statement.  Each statements should contain all the
logic for selecting, summarising, deleting or other task that is required. Most DLM tasks will
depend on a date, or component of a date for selecting records. This should be derived from the
scheduled date for the job rather than the use of functions such as NOW() or CURRENT_TIMESTAMP
- this will make it possible for jobs to be run with defined date even if the scheduler for
running the jobs fails or is suspended.

mydlm also contains a macro substitution langauge which allows components of the scheduled
date to be used when constructing a statement to execute.

Depending on the policy type and the nature of the data the statement can be be either
extremely simple or incredibly complex.



### Schedule Definition
As mentioned above, mydlm uses a cron-like format for scheduling tasks.
Like cron, time resolution is to the nearest minute and the cron expression consists of 5 parts signifying mnutes, hours, day of month, month and day of week. Note, that mydlm is not intended for running one-off tasks unless the policy specification is deactivated after it is first run.

mydlm recognises the following values within fields

All fields   - * (any value)
minutes      - 0 to 59
hours        - 0 to 23
day of month - 1 to 31
month        - 1 to 12
day of week  - 0 to 6 (where Sunday = 0)

mydlm supports cron's ability to define comma-separated lists of values in each part, it does not support hyphen-separated range style definition.

So,
0,15,30,45 * * * *
would be recognised to indicate that the policy should run on the hour and every 15 minutes thereafter

but

30 5-10 * * *
would not be understood to indicate on the half hour between 5am and 10am

for that you would need 
30 5,6,7,8,9,10 * * *

### Running the policies
A database EVENT runs on a master server to populate a job queue with the policy number
and start time for each task that is due to start within the next minute. Once the
policy records have been selected, the same mysql thread will call a procedure
that will run the selected tasks in turn. As the tasks complete the 

#### Examples
0 12 1 * *        = noon on the first of each month 
0,30 * * * *      = every half hour
15 15 * * 1       = a quarter past three in the after noon every Monday
0 20 1 1 *        = eight in the evening on the first of January



### Dependencies
Where dependencies exist between policies, e.g. you want to summarise some data
before archiving data, the separate tasks should be scheduled to run in the proper
sequence and with sufficient time between them to ensure they run to completion.
mydlm can check that the first task within the prescribed sequence has completed
successfully and will not run the dependent task if it hasn't.




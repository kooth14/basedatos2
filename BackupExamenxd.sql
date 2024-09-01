USE msdb;
GO

-- Create the Integrity Check Job
EXEC sp_add_job @job_name = N'Integrity_Check_Job';
GO

-- Add a job step to check database integrity
EXEC sp_add_jobstep 
   @job_name = N'Integrity_Check_Job',
   @step_name = N'Check Database Integrity',
   @subsystem = N'TSQL',
   @command = N'USE [Aeropuerto]; DBCC CHECKDB ([Aeropuerto]) WITH NO_INFOMSGS;',
   @on_success_action = 1,
   @on_fail_action = 2;
GO

-- Schedule the job to run before the full backup
EXEC sp_add_jobschedule 
   @job_name = N'Integrity_Check_Job',
   @name = N'Integrity_Check_Schedule',
   @enabled = 1,
   @freq_type = 4, -- Daily
   @freq_interval = 1,
   @freq_subday_type = 1, -- Occurs once a day
   @freq_subday_interval = 0,
   @freq_relative_interval = 0,
   @freq_recurrence_factor = 1,
   @active_start_time = 230000; -- 11:00 PM
GO

-----------------------------
USE msdb;
GO

-- Create the Full Backup Job
EXEC sp_add_job @job_name = N'Full_Backup_Job';
GO

-- Add a job step to perform a full backup
EXEC sp_add_jobstep 
   @job_name = N'Full_Backup_Job',
   @step_name = N'Full Backup',
   @subsystem = N'TSQL',
   @command = N'BACKUP DATABASE [Aeropuerto] TO DISK = N''C:\Users\sevas\Documents\RiosG\Aeropuerto_Full.bak'' WITH INIT, COMPRESSION, STATS = 10;',
   @on_success_action = 1,
   @on_fail_action = 2;
GO

-- Schedule the job to run every Saturday at 11:30 PM
EXEC sp_add_jobschedule 
   @job_name = N'Full_Backup_Job',
   @name = N'Full_Backup_Schedule',
   @enabled = 1,
   @freq_type = 4, -- Weekly
   @freq_interval = 1,
   @freq_subday_type = 1, -- Occurs once a week
   @freq_subday_interval = 0,
   @freq_relative_interval = 6, -- Saturday
   @freq_recurrence_factor = 1,
   @active_start_time = 233000; -- 11:30 PM
GO
-----------------------------------

USE msdb;
GO

-- Create the Differential Backup Job
EXEC sp_add_job @job_name = N'Differential_Backup_Job';
GO

-- Add a job step to perform a differential backup
EXEC sp_add_jobstep 
   @job_name = N'Differential_Backup_Job',
   @step_name = N'Differential Backup',
   @subsystem = N'TSQL',
   @command = N'BACKUP DATABASE [Aeropuerto] TO DISK = N''C:\Users\sevas\Documents\RiosG\Aeropuerto_Diff.bak'' WITH DIFFERENTIAL, COMPRESSION, STATS = 10;',
   @on_success_action = 1,
   @on_fail_action = 2;
GO

-- Schedule the job to run every day at 11:35 PM
EXEC sp_add_jobschedule 
   @job_name = N'Differential_Backup_Job',
   @name = N'Differential_Backup_Schedule',
   @enabled = 1,
   @freq_type = 4, -- Daily
   @freq_interval = 1,
   @freq_subday_type = 1, -- Occurs once a day
   @freq_subday_interval = 0,
   @freq_relative_interval = 0,
   @freq_recurrence_factor = 1,
   @active_start_time = 233500; -- 11:35 PM
GO


---------------------
USE msdb;
GO

-- Create the Transaction Log Backup Job
EXEC sp_add_job @job_name = N'Transaction_Log_Backup_Job';
GO

-- Add a job step to perform a transaction log backup
EXEC sp_add_jobstep 
   @job_name = N'Transaction_Log_Backup_Job',
   @step_name = N'Transaction Log Backup',
   @subsystem = N'TSQL',
   @command = N'BACKUP LOG [Aeropuerto] TO DISK = N''C:\Backup\Aeropuerto_Log.trn'' WITH INIT, COMPRESSION, STATS = 10;',
   @on_success_action = 1,
   @on_fail_action = 2;
GO

-- Schedule the job to run every 30 minutes
EXEC sp_add_jobschedule 
   @job_name = N'Transaction_Log_Backup_Job',
   @name = N'Transaction_Log_Backup_Schedule',
   @enabled = 1,
   @freq_type = 4, -- Daily
   @freq_interval = 1,
   @freq_subday_type = 4, -- Occurs every 30 minutes
   @freq_subday_interval = 0,
   @freq_relative_interval = 0,
   @freq_recurrence_factor = 1,
   @active_start_time = 0; -- Midnight
GO
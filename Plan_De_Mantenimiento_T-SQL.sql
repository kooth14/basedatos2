USE [msdb]
GO

/****** Object:  Job [Plan de mantenimiento T-SQL]    Script Date: 22/04/2024 07:05:56 p. m. ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [Database Maintenance]    Script Date: 22/04/2024 07:05:56 p. m. ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Database Maintenance' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Database Maintenance'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Plan de mantenimiento T-SQL', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=3, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Plan de mantenimiento de base de datos usando Transact-SQL SERVER', 
		@category_name=N'Database Maintenance', 
		@owner_login_name=N'DESKTOP-ECARTI7\Ervin', 
		@notify_email_operator_name=N'ervin', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Database Integrity]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Database Integrity', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master];
GO
DBCC CHECKDB(N''AdventureWorks2019'')  WITH  PHYSICAL_ONLY', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reoganizar Indices]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Reoganizar Indices', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [AdventureWorks2019]
GO
ALTER INDEX ALL ON [HumanResources].[Employee] REORGANIZE  WITH ( LOB_COMPACTION = ON )
GO

USE [AdventureWorks2019]
GO
ALTER INDEX ALL ON [Person].[Person] REORGANIZE  WITH ( LOB_COMPACTION = ON )
GO


USE [AdventureWorks2019]
GO
ALTER INDEX ALL ON [Sales].[Store] REORGANIZE  WITH ( LOB_COMPACTION = ON )
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Reconstruir Indices]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Reconstruir Indices', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=5, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'Use AdventureWorks2019
SET NOCOUNT ON
DECLARE @Objectid INT, @Indexid INT,@schemaname VARCHAR(100),@tablename VARCHAR(300),@ixname VARCHAR(500),@avg_fragment float,@command VARCHAR(4000)
DECLARE AWS_Cusrsor CURSOR FOR
SELECT A.object_id,A.index_id,QUOTENAME(SS.NAME) AS schemaname,QUOTENAME(OBJECT_NAME(B.object_id,B.database_id))as tablename ,QUOTENAME(A.name) AS ixname,B.avg_fragmentation_in_percent AS avg_fragment FROM sys.indexes A inner join sys.dm_db_index_physical_stats(DB_ID(),NULL,NULL,NULL,''LIMITED'') AS B
ON A.object_id=B.object_id and A.index_id=B.index_id
INNER JOIN SYS.OBJECTS OS ON A.object_id=OS.object_id
INNER JOIN sys.schemas SS ON OS.schema_id=SS.schema_id
WHERE B.avg_fragmentation_in_percent>30  AND A.index_id>0 AND A.IS_DISABLED<>1
ORDER BY tablename,ixname
OPEN AWS_Cusrsor
FETCH NEXT FROM AWS_Cusrsor INTO @Objectid,@Indexid,@schemaname,@tablename,@ixname,@avg_fragment
WHILE @@FETCH_STATUS=0
BEGIN
IF @avg_fragment>=30.0
BEGIN
SET @command=N''ALTER INDEX ''+@ixname+N'' ON ''+@schemaname+N''.''+ @tablename+N'' REBUILD ''+N'' WITH (ONLINE = ON)'';
--Can add following line for index reorganization. Else remove following line.
SET @command=N''ALTER INDEX ''+@ixname+N'' ON ''+@schemaname+N''.''+ @tablename+N'' REORGANIZE'';
END
--PRINT @command
EXEC(@command)
FETCH NEXT FROM AWS_Cusrsor INTO @Objectid,@Indexid,@schemaname,@tablename,@ixname,@avg_fragment
END
CLOSE AWS_Cusrsor
DEALLOCATE AWS_Cusrsor
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Actualizar Estadisticas]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Actualizar Estadisticas', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master];
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [dbo].[AWBuildVersion] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [dbo].[DatabaseLog] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [dbo].[ErrorLog] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[Department] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[Employee] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[EmployeeDepartmentHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[EmployeePayHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[JobCandidate] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [HumanResources].[Shift] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[Address] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[AddressType] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[BusinessEntity] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[BusinessEntityAddress] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[BusinessEntityContact] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[ContactType] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[CountryRegion] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[EmailAddress] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[Password] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[Person] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[PersonPhone] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[PhoneNumberType] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[StateProvince] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[BillOfMaterials] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[Culture] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[Document] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[Illustration] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[Location] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[Product] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductCategory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductCostHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductDescription] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductDocument] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductInventory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductListPriceHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductModel] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductModelIllustration] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductModelProductDescriptionCulture] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductPhoto] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductProductPhoto] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductReview] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ProductSubcategory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[ScrapReason] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[TransactionHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[TransactionHistoryArchive] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[UnitMeasure] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[WorkOrder] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[WorkOrderRouting] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Purchasing].[ProductVendor] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Purchasing].[PurchaseOrderDetail] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Purchasing].[PurchaseOrderHeader] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Purchasing].[ShipMethod] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Purchasing].[Vendor] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[CountryRegionCurrency] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[CreditCard] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[Currency] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[CurrencyRate] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[Customer] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[PersonCreditCard] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesOrderDetail] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesOrderHeader] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesOrderHeaderSalesReason] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesPerson] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesPersonQuotaHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesReason] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesTaxRate] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesTerritory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SalesTerritoryHistory] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[ShoppingCartItem] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SpecialOffer] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[SpecialOfferProduct] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Sales].[Store] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Person].[vStateProvinceCountryRegion] 
WITH FULLSCAN
GO
use [AdventureWorks2019]
GO
UPDATE STATISTICS [Production].[vProductAndDescription] 
WITH FULLSCAN
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Shrink Database]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Shrink Database', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master];
GO
USE [AdventureWorks2019]
GO
DBCC SHRINKDATABASE(N''AdventureWorks2019'', 10, TRUNCATEONLY)
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Backup Full]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Backup Full', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master];
GO
BACKUP DATABASE [AdventureWorks2019] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019_backup_2024_04_22_095741_1843342.bak'' WITH NOFORMAT, NOINIT,  NAME = N''AdventureWorks2019_backup_2024_04_22_095741_1843342'', SKIP, REWIND, NOUNLOAD,  STATS = 10', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [BackUp Diferencial]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'BackUp Diferencial', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'use [master];
GO
BACKUP DATABASE [AdventureWorks2019] TO  DISK = N''C:\Program Files\Microsoft SQL Server\MSSQL16.MSSQLSERVER\MSSQL\Backup\AdventureWorks2019_backup_2024_04_22_095812_9801163.bak'' WITH  DIFFERENTIAL , NOFORMAT, NOINIT,  NAME = N''AdventureWorks2019_backup_2024_04_22_095812_9801163'', SKIP, REWIND, NOUNLOAD,  STATS = 10
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Clean Up History]    Script Date: 22/04/2024 07:05:56 p. m. ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Clean Up History', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @dt datetime select @dt = cast(N''2024-03-25T09:58:35'' as datetime) exec msdb.dbo.sp_delete_backuphistory @dt
GO
EXEC msdb.dbo.sp_purge_jobhistory  @oldest_date=''2024-03-25T09:58:35''
GO
EXECUTE msdb..sp_maintplan_delete_log null,null,''2024-03-25T09:58:35''
', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Plan De Mantenimiento', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=5, 
		@freq_subday_type=8, 
		@freq_subday_interval=1, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20240422, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=115959, 
		@schedule_uid=N'd8ba86d4-0957-4f53-a26a-390a43210843'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



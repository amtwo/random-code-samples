 --Author: Andy Mallon
 --www.am2.co


 DECLARE @SchemaName sysname,
         @ObjectName sysname,
         @CompressionLevel varchar(4)='PAGE';

 --Table to hold the results 
 CREATE TABLE #Results (
     ObjectName sysname,
     SchemaName sysname,
     indexId int,
	 partition_number int,
	 size_with_current_compression_setting_KB bigint,
	 size_with_requested_compression_setting_KB bigint,
	 sample_size_with_current_compression_setting_KB bigint,
	 sample_size_with_requested_compression_setting_KB bigint);

 --What objects do you want to get the row counts for?
 --I'm just querying sys.views, but edit this query for whatever you need
 DECLARE obj_cur CURSOR FOR
     SELECT SchemaName = schema_name(o.schema_id), 
            ObjectName = o.name
     FROM sys.objects o
	 WHERE o.type = 'U';

 --Use that cursor to loop through all objects
 OPEN obj_cur;
 FETCH NEXT FROM obj_cur INTO @SchemaName, @ObjectName;
 WHILE @@FETCH_STATUS = 0
 BEGIN
     --estimate space savings
     INSERT INTO #Results
	 EXEC sp_estimate_data_compression_savings @SchemaName,@ObjectName,NULL,NULL,@CompressionLevel
     FETCH NEXT FROM obj_cur INTO @SchemaName, @ObjectName;
 END
 CLOSE obj_cur;
 DEALLOCATE obj_cur;
 
 SELECT * FROM #Results;
 DROP TABLE #Results;


USE WarehouseManagement;
GO

-- 1. СТАТИСТИКА ИСПОЛЬЗОВАНИЯ ИНДЕКСОВ
SELECT 
    OBJECT_NAME(s.object_id) AS [Таблица],
    i.name AS [Имя индекса],
    i.type_desc AS [Тип],
    s.user_seeks AS [Поисков],
    s.user_scans AS [Сканирований],
    s.user_lookups AS [Поисков в куче],
    s.user_updates AS [Обновлений],
    s.last_user_seek AS [Последний поиск],
    s.last_user_scan AS [Последнее сканирование]
FROM sys.dm_db_index_usage_stats s
INNER JOIN sys.indexes i ON s.object_id = i.object_id AND s.index_id = i.index_id
WHERE s.database_id = DB_ID()
    AND OBJECT_NAME(s.object_id) IS NOT NULL
ORDER BY s.user_seeks + s.user_scans DESC;
GO

-- 2. МЕДЛЕННЫЕ ЗАПРОСЫ 
SELECT 
    qsq.query_id,
    qsqt.query_sql_text AS [Текст запроса],
    qsp.plan_id,
    qsrs.avg_duration / 1000 AS [Среднее время (мс)],
    qsrs.avg_logical_io_reads AS [Среднее логических чтений],
    qsrs.execution_count AS [Количество выполнений],
    qsrs.last_execution_time AS [Последнее выполнение]
FROM sys.query_store_query qsq
INNER JOIN sys.query_store_query_text qsqt ON qsq.query_text_id = qsqt.query_text_id
INNER JOIN sys.query_store_plan qsp ON qsq.query_id = qsp.query_id
INNER JOIN sys.query_store_runtime_stats qsrs ON qsp.plan_id = qsrs.plan_id
WHERE qsrs.avg_duration > 1000000 
ORDER BY qsrs.avg_duration DESC;
GO

-- 3. ФРАГМЕНТАЦИЯ ИНДЕКСОВ
SELECT 
    OBJECT_NAME(ips.object_id) AS [Таблица],
    i.name AS [Имя индекса],
    ips.avg_fragmentation_in_percent AS [Фрагментация %],
    ips.page_count AS [Количество страниц],
    ips.index_type_desc AS [Тип индекса]
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    NULL, 
    NULL, 
    NULL, 
    'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
    AND ips.page_count > 1000
ORDER BY ips.avg_fragmentation_in_percent DESC;
GO

-- 4. ОПТИМИЗАЦИЯ ИНДЕКСОВ
DECLARE @TableName NVARCHAR(255);
DECLARE @IndexName NVARCHAR(255);
DECLARE @SQL NVARCHAR(1000);

DECLARE IndexCursor CURSOR FOR
SELECT 
    OBJECT_NAME(ips.object_id),
    i.name
FROM sys.dm_db_index_physical_stats(
    DB_ID(), 
    NULL, 
    NULL, 
    NULL, 
    'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 30
    AND ips.page_count > 1000
    AND i.name IS NOT NULL;

OPEN IndexCursor;
FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @SQL = 'ALTER INDEX [' + @IndexName + '] ON [' + @TableName + '] REBUILD';
    PRINT 'Выполняется: ' + @SQL;
    
    FETCH NEXT FROM IndexCursor INTO @TableName, @IndexName;
END

CLOSE IndexCursor;
DEALLOCATE IndexCursor;

PRINT 'Оптимизация индексов завершена';
GO

-- 5. МОНИТОРИНГ БЛОКИРОВОК
SELECT
    t.text AS [Текст запроса],
    s.login_name AS [Пользователь],
    s.host_name AS [Хост],
    db.name AS [База данных],
    wt.wait_type AS [Тип ожидания],
    wt.wait_duration_ms AS [Время ожидания (мс)],
    wt.resource_description AS [Ресурс]
FROM sys.dm_os_waiting_tasks wt
INNER JOIN sys.dm_exec_sessions s ON wt.session_id = s.session_id
INNER JOIN sys.dm_exec_requests r ON s.session_id = r.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
LEFT JOIN sys.databases db ON r.database_id = db.database_id
WHERE wt.wait_type NOT LIKE '%SLEEP%'
    AND wt.wait_type NOT LIKE '%IDLE%'
    AND wt.wait_duration_ms > 1000
ORDER BY wt.wait_duration_ms DESC;
GO

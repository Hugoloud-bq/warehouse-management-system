USE WarehouseManagement;
GO

-- 1. ПРОВЕРКА СВЯЗЕЙ МЕЖДУ ТАБЛИЦАМИ
SELECT 
    fk.name AS [Имя ограничения],
    OBJECT_NAME(fk.parent_object_id) AS [Таблица],
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS [Столбец],
    OBJECT_NAME(fk.referenced_object_id) AS [Связанная таблица],
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS [Связанный столбец]
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
ORDER BY [Таблица];
GO

-- 2. ПРОВЕРКА ОГРАНИЧЕНИЙ (CONSTRAINTS)
SELECT 
    tc.TABLE_NAME AS [Таблица],
    tc.CONSTRAINT_NAME AS [Ограничение],
    tc.CONSTRAINT_TYPE AS [Тип],
    cc.CHECK_CLAUSE AS [Условие]
FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
LEFT JOIN INFORMATION_SCHEMA.CHECK_CONSTRAINTS cc 
    ON tc.CONSTRAINT_NAME = cc.CONSTRAINT_NAME
WHERE tc.TABLE_NAME IN ('Products', 'Warehouse', 'Users')
ORDER BY tc.TABLE_NAME, tc.CONSTRAINT_TYPE;
GO

-- 3. АНАЛИЗ РАЗМЕРА ТАБЛИЦ
SELECT 
    t.name AS [Имя таблицы],
    p.rows AS [Количество строк],
    SUM(a.total_pages) * 8 / 1024 AS [Размер (МБ)],
    t.create_date AS [Дата создания],
    t.modify_date AS [Дата изменения]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.name NOT LIKE 'sys%'
GROUP BY t.name, p.rows, t.create_date, t.modify_date
ORDER BY [Размер (МБ)] DESC;
GO

-- 4. ПРОВЕРКА ИНДЕКСОВ
SELECT 
    OBJECT_NAME(i.object_id) AS [Таблица],
    i.name AS [Имя индекса],
    i.type_desc AS [Тип индекса],
    COUNT(*) AS [Количество столбцов],
    i.is_unique AS [Уникальный],
    i.is_primary_key AS [Первичный ключ]
FROM sys.indexes i
INNER JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
WHERE OBJECT_NAME(i.object_id) IN ('Products', 'Warehouse', 'ReceiptDocuments')
GROUP BY OBJECT_NAME(i.object_id), i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY [Таблица], [Тип индекса];
GO

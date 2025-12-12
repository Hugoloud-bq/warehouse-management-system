-- 1. СОЗДАНИЕ ПОЛНОЙ РЕЗЕРВНОЙ КОПИИ
DECLARE @BackupPath NVARCHAR(500) = 'C:\Backup\WarehouseManagement_FULL_' 
    + REPLACE(CONVERT(NVARCHAR, GETDATE(), 120), ':', '-') + '.bak';

BACKUP DATABASE WarehouseManagement
TO DISK = @BackupPath
WITH 
    NAME = 'WarehouseManagement_Full_Backup',
    DESCRIPTION = 'Полная резервная копия базы данных',
    COMPRESSION,
    STATS = 5;
GO

PRINT 'Резервная копия создана: ' + @BackupPath;
GO

-- 2. ВОССТАНОВЛЕНИЕ ИЗ РЕЗЕРВНОЙ КОПИИ
-- Внимание: Этот запрос только для демонстрации
DECLARE @RestorePath NVARCHAR(500) = 'C:\Backup\WarehouseManagement_FULL_2025-12-13.bak';

-- Сначала нужно отключить всех пользователей
ALTER DATABASE WarehouseManagement SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- Восстановление базы данных
RESTORE DATABASE WarehouseManagement
FROM DISK = @RestorePath
WITH 
    REPLACE,
    RECOVERY,
    STATS = 5;

-- Возвращаем многопользовательский режим
ALTER DATABASE WarehouseManagement SET MULTI_USER;
GO

PRINT 'База данных восстановлена из: ' + @RestorePath;
GO

-- 3. ЭКСПОРТ ДАННЫХ В CSV
-- Требуется включение xp_cmdshell
EXEC sp_configure 'xp_cmdshell', 1;
RECONFIGURE;
GO

DECLARE @ExportPath NVARCHAR(500) = 'C:\Export\';
DECLARE @Cmd NVARCHAR(2000);

-- Экспорт таблицы Products
SET @Cmd = 'bcp WarehouseManagement.dbo.Products out "' + @ExportPath + 'Products.csv" -c -t, -T -S ' + @@SERVERNAME;
EXEC xp_cmdshell @Cmd;

-- Экспорт таблицы Warehouse
SET @Cmd = 'bcp WarehouseManagement.dbo.Warehouse out "' + @ExportPath + 'Warehouse.csv" -c -t, -T -S ' + @@SERVERNAME;
EXEC xp_cmdshell @Cmd;

PRINT 'Данные экспортированы в папку: ' + @ExportPath;
GO

-- 4. АРХИВАЦИЯ СТАРЫХ ДАННЫХ
-- Создание архивной таблицы для ReceiptDocuments
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ReceiptDocuments_Archive')
BEGIN
    CREATE TABLE ReceiptDocuments_Archive (
        receipt_id INT PRIMARY KEY,
        document_number NVARCHAR(50),
        receipt_date DATE,
        total_amount DECIMAL(15,2),
        archived_date DATETIME DEFAULT GETDATE()
    );
END
GO

-- Перенос старых документов в архив (старше 1 года)
INSERT INTO ReceiptDocuments_Archive (receipt_id, document_number, receipt_date, total_amount)
SELECT receipt_id, document_number, receipt_date, total_amount
FROM ReceiptDocuments
WHERE receipt_date < DATEADD(YEAR, -1, GETDATE())
    AND status = 'completed';

-- Удаление архивных данных из основной таблицы
DELETE FROM ReceiptDocuments
WHERE receipt_date < DATEADD(YEAR, -1, GETDATE())
    AND status = 'completed';

PRINT 'Старые документы заархивированы';
GO

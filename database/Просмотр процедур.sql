USE WarehouseManagement;
GO

CREATE OR ALTER VIEW vw_CurrentStock AS
SELECT 
    p.sku AS Код,
    p.name AS Название,
    c.name AS Категория,
    SUM(w.quantity) AS Всего,
    SUM(w.reserved_quantity) AS Зарезервировано,
    SUM(w.quantity) - SUM(w.reserved_quantity) AS Доступно,
    p.unit AS Единица,
    w.rack + '-' + w.shelf + '-' + w.cell AS Ячейка
FROM Warehouse w
JOIN Products p ON w.product_id = p.product_id
JOIN Categories c ON p.category_id = c.category_id
GROUP BY p.sku, p.name, c.name, p.unit, w.rack, w.shelf, w.cell;
GO

CREATE OR ALTER VIEW vw_NeedToOrder AS
SELECT 
    p.name AS Товар,
    p.min_quantity AS МинЗапас,
    ISNULL(SUM(w.quantity), 0) AS НаСкладе,
    p.min_quantity - ISNULL(SUM(w.quantity), 0) AS Заказать
FROM Products p
LEFT JOIN Warehouse w ON p.product_id = w.product_id
GROUP BY p.product_id, p.name, p.min_quantity
HAVING ISNULL(SUM(w.quantity), 0) < p.min_quantity;
GO

CREATE OR ALTER VIEW vw_RecentReceipts AS
SELECT TOP 10
    rd.document_number AS Номер,
    rd.receipt_date AS Дата,
    m.name AS Поставщик,
    COUNT(ri.receipt_item_id) AS Позиций,
    rd.total_amount AS Сумма
FROM ReceiptDocuments rd
JOIN Manufacturers m ON rd.supplier_id = m.manufacturer_id
LEFT JOIN ReceiptItems ri ON rd.receipt_id = ri.receipt_id
WHERE rd.status = 'completed'
GROUP BY rd.document_number, rd.receipt_date, m.name, rd.total_amount
ORDER BY rd.receipt_date DESC;
GO

CREATE OR ALTER PROCEDURE sp_AddToStock
    @product_id INT,
    @quantity INT,
    @rack NVARCHAR(10),
    @shelf NVARCHAR(10),
    @cell NVARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    IF EXISTS (SELECT 1 FROM Warehouse 
               WHERE product_id = @product_id 
               AND rack = @rack AND shelf = @shelf AND cell = @cell)
    BEGIN
        UPDATE Warehouse 
        SET quantity = quantity + @quantity,
            last_restocked = GETDATE()
        WHERE product_id = @product_id 
          AND rack = @rack AND shelf = @shelf AND cell = @cell;
    END
    ELSE
    BEGIN
        INSERT INTO Warehouse (product_id, quantity, rack, shelf, cell, last_restocked)
        VALUES (@product_id, @quantity, @rack, @shelf, @cell, GETDATE());
    END
END;
GO

CREATE OR ALTER PROCEDURE sp_RemoveFromStock
    @product_id INT,
    @quantity INT,
    @reason NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @available INT;
    
    SELECT @available = SUM(quantity)
    FROM Warehouse 
    WHERE product_id = @product_id;
    
    IF @available < @quantity
    BEGIN
        RAISERROR('Недостаточно товара на складе!', 16, 1);
        RETURN;
    END
    
    UPDATE w
    SET quantity = CASE 
        WHEN w.quantity >= @quantity THEN w.quantity - @quantity
        ELSE 0
    END,
    @quantity = CASE 
        WHEN w.quantity >= @quantity THEN 0
        ELSE @quantity - w.quantity
    END
    FROM Warehouse w
    WHERE w.product_id = @product_id 
      AND w.quantity > 0
      AND @quantity > 0;
END;
GO

CREATE OR ALTER FUNCTION fn_CheckExpiry(@product_id INT)
RETURNS NVARCHAR(50)
AS
BEGIN
    DECLARE @result NVARCHAR(50);
    DECLARE @expiry_date DATE;
    
    SELECT TOP 1 @expiry_date = expiry_date
    FROM Warehouse 
    WHERE product_id = @product_id 
      AND expiry_date IS NOT NULL
    ORDER BY expiry_date;
    
    IF @expiry_date IS NULL
        SET @result = 'Без срока годности';
    ELSE IF @expiry_date < GETDATE()
        SET @result = 'ПРОСРОЧЕН';
    ELSE IF DATEDIFF(DAY, GETDATE(), @expiry_date) < 30
        SET @result = 'Скоро истечет';
    ELSE
        SET @result = 'Годен';
        
    RETURN @result;
END;
GO

CREATE OR ALTER TRIGGER tr_UpdateProductDate
ON Products
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE Products 
    SET updated_at = GETDATE()
    FROM Products p
    INNER JOIN inserted i ON p.product_id = i.product_id;
END;
GO

PRINT 'Файл 03_Views_Procedures.sql успешно загружен';
PRINT 'Доступные представления: vw_CurrentStock, vw_NeedToOrder';
GO

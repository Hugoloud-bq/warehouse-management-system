USE WarehouseManagement;
GO

-- 1. ТЕКУЩИЕ ОСТАТКИ ПО КАТЕГОРИЯМ
SELECT 
    c.name AS Категория,
    COUNT(DISTINCT p.product_id) AS КоличествоТоваров,
    SUM(w.quantity) AS ОбщееКоличество
FROM Warehouse w
JOIN Products p ON w.product_id = p.product_id
JOIN Categories c ON p.category_id = c.category_id
GROUP BY c.name
ORDER BY ОбщееКоличество DESC;
GO

-- 2. ТОВАРЫ С ИСТЕКАЮЩИМ СРОКОМ ГОДНОСТИ
SELECT 
    p.sku AS Артикул,
    p.name AS Название,
    w.expiry_date AS СрокГодности,
    DATEDIFF(DAY, GETDATE(), w.expiry_date) AS ОсталосьДней,
    w.quantity AS Количество,
    w.rack + '-' + w.shelf + '-' + w.cell AS Ячейка
FROM Warehouse w
JOIN Products p ON w.product_id = p.product_id
WHERE w.expiry_date IS NOT NULL
    AND w.expiry_date BETWEEN GETDATE() AND DATEADD(DAY, 30, GETDATE())
ORDER BY ОсталосьДней;
GO

-- 3. ПОИСК ТОВАРА ПО НАЗВАНИЮ
DECLARE @SearchTerm NVARCHAR(100) = 'Arduino';
SELECT 
    p.sku AS Артикул,
    p.name AS Название,
    c.name AS Категория,
    w.quantity AS Количество,
    w.rack + '-' + w.shelf + '-' + w.cell AS Ячейка
FROM Products p
JOIN Warehouse w ON p.product_id = w.product_id
JOIN Categories c ON p.category_id = c.category_id
WHERE p.name LIKE '%' + @SearchTerm + '%'
    OR p.sku LIKE '%' + @SearchTerm + '%'
ORDER BY w.quantity DESC;
GO

-- 4. ПРОВЕРКА ПРЕДСТАВЛЕНИЙ
SELECT TOP 5 * FROM vw_CurrentStock;
SELECT * FROM vw_NeedToOrder;
SELECT * FROM vw_RecentReceipts;
GO




USE master;
GO

IF EXISTS(SELECT name FROM sys.databases WHERE name = 'WarehouseManagement')
    DROP DATABASE WarehouseManagement;
GO

CREATE DATABASE WarehouseManagement 
COLLATE Cyrillic_General_CI_AS;
GO

USE WarehouseManagement;
GO






CREATE TABLE Users (
    user_id INT PRIMARY KEY IDENTITY(1,1),
    email NVARCHAR(255) UNIQUE NOT NULL,
    password_hash NVARCHAR(255) NOT NULL,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    phone NVARCHAR(20),
    role NVARCHAR(20) DEFAULT 'storekeeper' CHECK (role IN ('storekeeper', 'manager', 'admin', 'auditor')),
    position NVARCHAR(100), 
    department NVARCHAR(100), 
    created_at DATETIME2 DEFAULT GETDATE(),
    is_active BIT DEFAULT 1
);
GO


CREATE TABLE Categories (
    category_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(500),
    parent_category_id INT NULL,
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (parent_category_id) REFERENCES Categories(category_id)
);
GO


CREATE TABLE Manufacturers (
    manufacturer_id INT PRIMARY KEY IDENTITY(1,1),
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(500),
    contact_person NVARCHAR(100),
    phone NVARCHAR(20),
    email NVARCHAR(100),
    address NVARCHAR(500),
    is_supplier BIT DEFAULT 1, 
    created_at DATETIME2 DEFAULT GETDATE()
);
GO


CREATE TABLE Products (
    product_id INT PRIMARY KEY IDENTITY(1,1),
    sku NVARCHAR(100) UNIQUE NOT NULL, 
    name NVARCHAR(255) NOT NULL,
    description NVARCHAR(1000),
    category_id INT NOT NULL,
    manufacturer_id INT NOT NULL,
    unit NVARCHAR(20) DEFAULT 'шт.', 
    weight DECIMAL(10,3), 
    volume DECIMAL(10,3), 
    min_quantity INT DEFAULT 5, 
    max_quantity INT DEFAULT 100, 
    is_perishable BIT DEFAULT 0, 
    shelf_life_days INT, 
    created_at DATETIME2 DEFAULT GETDATE(),
    updated_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (manufacturer_id) REFERENCES Manufacturers(manufacturer_id)
);
GO


CREATE TABLE Warehouse (
    warehouse_id INT PRIMARY KEY IDENTITY(1,1),
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity >= 0),
    reserved_quantity INT DEFAULT 0 CHECK (reserved_quantity >= 0),
    rack NVARCHAR(10) NOT NULL, 
    shelf NVARCHAR(10) NOT NULL, 
    cell NVARCHAR(10) NOT NULL, 
    batch_number NVARCHAR(50), 
    production_date DATE, 
    expiry_date DATE, 
    last_inventory_date DATE, 
    last_restocked DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    UNIQUE (rack, shelf, cell) 
);
GO






CREATE TABLE ReceiptDocuments (
    receipt_id INT PRIMARY KEY IDENTITY(1,1),
    document_number NVARCHAR(50) UNIQUE NOT NULL, 
    supplier_id INT NOT NULL, 
    receipt_date DATE NOT NULL,
    invoice_number NVARCHAR(50), 
    total_amount DECIMAL(15,2) NOT NULL,
    status NVARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'completed', 'cancelled')),
    created_by INT NOT NULL, 
    confirmed_by INT, 
    completed_at DATETIME2, 
    notes NVARCHAR(1000),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (supplier_id) REFERENCES Manufacturers(manufacturer_id),
    FOREIGN KEY (created_by) REFERENCES Users(user_id),
    FOREIGN KEY (confirmed_by) REFERENCES Users(user_id)
);
GO


CREATE TABLE ReceiptItems (
    receipt_item_id INT PRIMARY KEY IDENTITY(1,1),
    receipt_id INT NOT NULL,
    product_id INT NOT NULL,
    planned_quantity INT NOT NULL CHECK (planned_quantity > 0), 
    actual_quantity INT NOT NULL CHECK (actual_quantity > 0), 
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    planned_rack NVARCHAR(10), 
    planned_shelf NVARCHAR(10),
    planned_cell NVARCHAR(10),
    actual_rack NVARCHAR(10), 
    actual_shelf NVARCHAR(10),
    actual_cell NVARCHAR(10),
    quality_status NVARCHAR(20) DEFAULT 'good' CHECK (quality_status IN ('good', 'damaged', 'expired')),
    notes NVARCHAR(500),
    FOREIGN KEY (receipt_id) REFERENCES ReceiptDocuments(receipt_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
GO


CREATE TABLE IssueDocuments (
    issue_id INT PRIMARY KEY IDENTITY(1,1),
    document_number NVARCHAR(50) UNIQUE NOT NULL,
    issue_date DATE NOT NULL,
    recipient_name NVARCHAR(255) NOT NULL, 
    recipient_department NVARCHAR(100), 
    purpose NVARCHAR(200), 
    total_amount DECIMAL(15,2),
    status NVARCHAR(20) DEFAULT 'draft' CHECK (status IN ('draft', 'confirmed', 'completed', 'cancelled')),
    created_by INT NOT NULL,
    confirmed_by INT,
    completed_at DATETIME2,
    notes NVARCHAR(1000),
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (created_by) REFERENCES Users(user_id),
    FOREIGN KEY (confirmed_by) REFERENCES Users(user_id)
);
GO


CREATE TABLE IssueItems (
    issue_item_id INT PRIMARY KEY IDENTITY(1,1),
    issue_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    taken_from_rack NVARCHAR(10), 
    taken_from_shelf NVARCHAR(10),
    taken_from_cell NVARCHAR(10),
    reason NVARCHAR(200), 
    FOREIGN KEY (issue_id) REFERENCES IssueDocuments(issue_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);
GO


CREATE TABLE InternalMovements (
    movement_id INT PRIMARY KEY IDENTITY(1,1),
    product_id INT NOT NULL,
    quantity INT NOT NULL CHECK (quantity > 0),
    from_rack NVARCHAR(10) NOT NULL,
    from_shelf NVARCHAR(10) NOT NULL,
    from_cell NVARCHAR(10) NOT NULL,
    to_rack NVARCHAR(10) NOT NULL,
    to_shelf NVARCHAR(10) NOT NULL,
    to_cell NVARCHAR(10) NOT NULL,
    reason NVARCHAR(200) CHECK (reason IN ('consolidation', 'inventory', 'expiry_date', 'other')),
    moved_by INT NOT NULL,
    moved_at DATETIME2 DEFAULT GETDATE(),
    notes NVARCHAR(500),
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (moved_by) REFERENCES Users(user_id)
);
GO


CREATE TABLE InventoryChecks (
    inventory_id INT PRIMARY KEY IDENTITY(1,1),
    inventory_number NVARCHAR(50) UNIQUE NOT NULL, 
    start_date DATE NOT NULL,
    end_date DATE,
    responsible_user INT NOT NULL, 
    status NVARCHAR(20) DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed', 'cancelled')),
    total_items INT DEFAULT 0, 
    checked_items INT DEFAULT 0, 
    discrepancies_count INT DEFAULT 0, 
    created_at DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (responsible_user) REFERENCES Users(user_id)
);
GO


CREATE TABLE InventoryResults (
    result_id INT PRIMARY KEY IDENTITY(1,1),
    inventory_id INT NOT NULL,
    product_id INT NOT NULL,
    rack NVARCHAR(10) NOT NULL,
    shelf NVARCHAR(10) NOT NULL,
    cell NVARCHAR(10) NOT NULL,
    system_quantity INT NOT NULL, 
    actual_quantity INT NOT NULL, 
    discrepancy INT, 
    discrepancy_reason NVARCHAR(200), 
    checked_by INT NOT NULL,
    checked_at DATETIME2 DEFAULT GETDATE(),
    notes NVARCHAR(500),
    FOREIGN KEY (inventory_id) REFERENCES InventoryChecks(inventory_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (checked_by) REFERENCES Users(user_id),
    UNIQUE (inventory_id, product_id, rack, shelf, cell)
);
GO




CREATE INDEX IX_Users_Email ON Users(email);
CREATE INDEX IX_Products_SKU ON Products(sku);
CREATE INDEX IX_Products_Category ON Products(category_id);
CREATE INDEX IX_Warehouse_Location ON Warehouse(rack, shelf, cell);
CREATE INDEX IX_Warehouse_Product ON Warehouse(product_id);
CREATE INDEX IX_ReceiptDocuments_Number ON ReceiptDocuments(document_number);
CREATE INDEX IX_ReceiptDocuments_Date ON ReceiptDocuments(receipt_date);
CREATE INDEX IX_ReceiptDocuments_Status ON ReceiptDocuments(status);
CREATE INDEX IX_IssueDocuments_Number ON IssueDocuments(document_number);
CREATE INDEX IX_InternalMovements_Date ON InternalMovements(moved_at);
CREATE INDEX IX_InventoryChecks_Status ON InventoryChecks(status);
GO




INSERT INTO Users (email, password_hash, first_name, last_name, role, position, department) VALUES
(N'storekeeper@company.ru', N'hash123', N'Иван', N'Петров', N'storekeeper', N'Кладовщик', N'Основной склад'),
(N'manager@company.ru', N'hash456', N'Мария', N'Сидорова', N'manager', N'Начальник склада', N'Основной склад'),
(N'admin@company.ru', N'hash789', N'Алексей', N'Иванов', N'admin', N'Системный администратор', N'ИТ-отдел');
GO

INSERT INTO Categories (name, description) VALUES
(N'Электроника', N'Электронные компоненты и устройства'),
(N'Канцтовары', N'Канцелярские принадлежности'),
(N'Хозтовары', N'Хозяйственные товары');
GO

INSERT INTO Manufacturers (name, contact_person, phone, email) VALUES
(N'ООО "ЭлектроПоставка"', N'Сергей Новиков', N'+79161234567', N'supply@electro.ru'),
(N'ИП "КанцОпт"', N'Ольга Ковалева', N'+79167654321', N'opt@kanc.ru'),
(N'Завод "МеталлДеталь"', N'Дмитрий Семенов', N'+79165554433', N'info@metall.ru');
GO

INSERT INTO Products (sku, name, category_id, manufacturer_id, unit, weight, min_quantity, max_quantity) VALUES
('ELEC-001', N'Микроконтроллер Arduino Uno', 1, 1, 'шт.', 0.025, 10, 100),
('ELEC-002', N'Резистор 10кОм', 1, 1, 'шт.', 0.001, 1000, 10000),
('KANC-001', N'Ручка шариковая синяя', 2, 2, 'шт.', 0.010, 500, 5000),
('HOZ-001', N'Перчатки резиновые', 3, 3, 'пар', 0.100, 50, 500);
GO

INSERT INTO Warehouse (product_id, quantity, rack, shelf, cell) VALUES
(1, 50, 'A', '01', '01'),
(2, 1000, 'A', '01', '02'),
(3, 1000, 'B', '01', '01'),
(4, 200, 'B', '02', '01');
GO




CREATE VIEW CurrentInventory AS
SELECT 
    p.sku,
    p.name AS product_name,
    c.name AS category,
    m.name AS supplier,
    w.rack,
    w.shelf,
    w.cell,
    w.quantity,
    w.reserved_quantity,
    w.quantity - w.reserved_quantity AS available_quantity,
    w.expiry_date,
    DATEDIFF(DAY, GETDATE(), w.expiry_date) AS days_until_expiry
FROM Products p
JOIN Categories c ON p.category_id = c.category_id
JOIN Manufacturers m ON p.manufacturer_id = m.manufacturer_id
JOIN Warehouse w ON p.product_id = w.product_id;
GO

CREATE VIEW ReceiptsSummary AS
SELECT 
    rd.document_number,
    rd.receipt_date,
    m.name AS supplier,
    COUNT(ri.receipt_item_id) AS items_count,
    SUM(ri.actual_quantity) AS total_quantity,
    rd.total_amount,
    rd.status,
    u.first_name + ' ' + u.last_name AS created_by
FROM ReceiptDocuments rd
JOIN Manufacturers m ON rd.supplier_id = m.manufacturer_id
JOIN Users u ON rd.created_by = u.user_id
LEFT JOIN ReceiptItems ri ON rd.receipt_id = ri.receipt_id
GROUP BY rd.document_number, rd.receipt_date, m.name, rd.total_amount, rd.status, u.first_name, u.last_name;
GO

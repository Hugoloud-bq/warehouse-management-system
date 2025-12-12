use WarehouseManagement;

go
delete
from ReceiptItems;


delete
from ReceiptDocuments;


delete
from Warehouse;


delete
from Products;


delete
from Manufacturers;


delete
from Categories;


delete
from Users;

go DBCC CHECKIDENT ('Users', RESEED, 0);

DBCC CHECKIDENT ('Categories', RESEED, 0);

DBCC CHECKIDENT ('Manufacturers', RESEED, 0);

DBCC CHECKIDENT ('Products', RESEED, 0);

DBCC CHECKIDENT ('Warehouse', RESEED, 0);

DBCC CHECKIDENT ('ReceiptDocuments', RESEED, 0);

DBCC CHECKIDENT ('ReceiptItems', RESEED, 0);

go print 'Добавляю пользователей...';


insert into Users (email, password_hash, first_name, last_name, phone, role, position, department)
values ('admin@sklad.ru', '123456', 'Алексей', 'Иванов', '+79161234567', 'admin', 'Администратор', 'ИТ отдел'),
       ('manager@sklad.ru', '123456', 'Мария', 'Петрова', '+79162345678', 'manager', 'Менеджер склада', 'Склад'),
       ('storekeeper@sklad.ru', '123456', 'Иван', 'Сидоров', '+79163456789', 'storekeeper', 'Кладовщик', 'Склад'),
       ('user@sklad.ru', '123456', 'Ольга', 'Кузнецова', '+79164567890', 'storekeeper', 'Кладовщик', 'Склад №2');

go print 'Добавляю категории...';


insert into Categories (name, description)
values ('Электроника', 'Электронные компоненты и устройства'),
       ('Канцтовары', 'Канцелярские принадлежности'),
       ('Хозтовары', 'Хозяйственные товары'),
       ('Инструменты', 'Ручной инструмент'),
       ('Упаковка', 'Упаковочные материалы');

go print 'Добавляю производителей...';


insert into Manufacturers (name, description, contact_person, phone, email)
values ('ООО "Электроника"', 'Поставщик электронных компонентов', 'Сергей Н.', '+79160001111', 'info@electro.ru'),
       ('ИП "КанцОпт"', 'Оптовые канцтовары', 'Ольга К.', '+79160002222', 'sales@kancopt.ru'),
       ('Завод "Металл"', 'Производитель инструментов', 'Дмитрий М.', '+79160003333', 'info@metall.ru'),
       ('ООО "УпаковкаСервис"', 'Упаковочные материалы', 'Ирина П.', '+79160004444', 'pack@upak.ru'),
       ('Фирма "Хозтовары"', 'Хозяйственные товары', 'Андрей Х.', '+79160005555', 'hoz@firma.ru');

go print 'Добавляю товары...';


insert into Products (sku, name, description, category_id, manufacturer_id, unit, weight, min_quantity, max_quantity)
values ('EL001', 'Arduino Uno', 'Плата разработки', 1, 1, 'шт.', 0.025, 10, 100),
       ('EL002', 'Резистор 10кОм', 'Углеродный резистор', 1, 1, 'шт.', 0.001, 1000, 10000),
       ('KAN001', 'Ручка синяя', 'Шариковая ручка', 2, 2, 'шт.', 0.010, 500, 5000),
       ('KAN002', 'Бумага А4', 'Офисная бумага', 2, 2, 'пачка', 2.500, 50, 500),
       ('HOZ001', 'Перчатки', 'Резиновые перчатки', 3, 5, 'пара', 0.100, 50, 500),
       ('INSTR001', 'Отвертка', 'Крестовая отвертка', 4, 3, 'шт.', 0.200, 100, 1000),
       ('UP001', 'Скотч', 'Упаковочный скотч', 5, 4, 'рулон', 0.350, 100, 1000),
       ('EL003', 'Батарейка AA', 'Щелочная батарейка', 1, 1, 'шт.', 0.023, 200, 2000),
       ('KAN003', 'Карандаш', 'Простой карандаш', 2, 2, 'шт.', 0.015, 800, 8000),
       ('HOZ002', 'Ведро', 'Пластиковое ведро', 3, 5, 'шт.', 0.800, 20, 200);

go print 'Добавляю складские остатки...';


insert into Warehouse (product_id, quantity, rack, shelf, cell)
values (1, 50, 'A', '01', '01'),
       (2, 1500, 'A', '01', '02'),
       (8, 500, 'A', '02', '01');


insert into Warehouse (product_id, quantity, rack, shelf, cell)
values (3, 1200, 'B', '01', '01'),
       (4, 150, 'B', '01', '02'),
       (9, 1000, 'B', '02', '01');


insert into Warehouse (product_id, quantity, rack, shelf, cell)
values (5, 180, 'C', '01', '01'),
       (6, 250, 'C', '01', '02'),
       (7, 400, 'C', '02', '01'),
       (10, 85, 'C', '02', '02');

go print 'Добавляю приходные документы...';


insert into ReceiptDocuments (document_number, supplier_id, receipt_date, total_amount, status, created_by, confirmed_by)
values ('ПН-001', 1, '2025-10-10', 15000.00, 'completed', 2, 1);


insert into ReceiptItems (receipt_id, product_id, planned_quantity, actual_quantity, unit_price, total_price)
values (1, 1, 20, 20, 850.00, 17000.00),
       (1, 2, 500, 500, 2.50, 1250.00);


insert into ReceiptDocuments (document_number, supplier_id, receipt_date, total_amount, status, created_by)
values ('ПН-002', 2, '2025-11-05', 8000.00, 'confirmed', 2);


insert into ReceiptItems (receipt_id, product_id, planned_quantity, actual_quantity, unit_price, total_price)
values (2, 3, 200, 200, 25.00, 5000.00),
       (2, 4, 10, 10, 300.00, 3000.00);

go print '';

print '====== ПРОВЕРКА ЗАГРУЖЕННЫХ ДАННЫХ ======';

print '';


select 'Пользователи' as Таблица,
       COUNT(*) as Количество
from Users
union all
select 'Категории',
       COUNT(*)
from Categories
union all
select 'Производители',
       COUNT(*)
from Manufacturers
union all
select 'Товары',
       COUNT(*)
from Products
union all
select 'Остатки на складе',
       COUNT(*)
from Warehouse
union all
select 'Приходные накладные',
       COUNT(*)
from ReceiptDocuments;

go print '';

print '====== ОБРАЗЦЫ ДАННЫХ ======';

print '';


select TOP 5 p.sku as Код,
           p.name as Название,
           w.quantity as Количество,
           w.rack + '-' + w.shelf + '-' + w.cell as Ячейка
from Warehouse w
join Products p on w.product_id = p.product_id
order by p.name;

go print '';

print '====== ИНСТРУКЦИЯ ======';

print '';

print 'Основные таблицы заполнены тестовыми данными.';

print 'Для проверки можно выполнить:';

print '1. SELECT * FROM Products; -- Все товары';

print '2. SELECT * FROM Warehouse; -- Остатки на складе';

print '3. SELECT * FROM vw_CurrentStock; -- Текущие остатки';

print '4. SELECT * FROM vw_NeedToOrder; -- Что нужно заказать';

print '';

print '=========================================';

print 'Тестовые данные успешно загружены!';

print '=========================================';

go

-- Лабораторна робота 3 (запити). Таблиця: products (див. products.sql)
-- Перед виконанням переконайтеся, що таблицю створено та наповнено даними.
-- UPDATE та DELETE змінюють дані; для перевірки можна обгорнути сесію в BEGIN; ... ROLLBACK;

-- 1. Проста вибірка всіх товарів, відсортованих за назвою
SELECT id, name, sku, category, price, quantity, total_value
FROM products
ORDER BY name ASC;

-- 2. П'ять найдорожчих товарів (аналог TOP через LIMIT)
SELECT id, name, price, total_value
FROM products
ORDER BY price DESC
LIMIT 5;

-- 3. Друга «сторінка» каталогу: пропустити 5 рядків, взяти наступні 5
SELECT id, name, sku, price
FROM products
ORDER BY id ASC
LIMIT 5 OFFSET 5;

-- 4. Перші три записи за зростанням ціни (стандартний синтаксис FETCH)
SELECT id, name, price
FROM products
ORDER BY price ASC
FETCH FIRST 3 ROWS ONLY;

-- 5. Пагінація через OFFSET ... FETCH NEXT (після 8-го рядка — 4 записи)
SELECT id, name, category, quantity
FROM products
ORDER BY id ASC
OFFSET 8 ROWS
FETCH NEXT 4 ROWS ONLY;

-- 6. Пошук товарів за частиною назви (шаблон LIKE)
SELECT id, name, sku, price
FROM products
WHERE name LIKE 'Товар #%'
ORDER BY id;

-- 7. Товари лише з обраних категорій (оператор IN)
SELECT id, name, category, price, quantity
FROM products
WHERE category IN ('Food', 'Clothing', 'Electronics')
ORDER BY category, name;

-- 8. Записи без текстового опису (IS NULL)
SELECT id, name, sku
FROM products
WHERE description IS NULL
ORDER BY id;

-- 9. Товари з описом у категорії Electronics (IS NOT NULL та AND)
SELECT id, name, description, price
FROM products
WHERE description IS NOT NULL
  AND category = 'Electronics'
ORDER BY price DESC;

-- 10. Нульовий залишок або дуже висока ціна (OR)
SELECT id, name, quantity, price, total_value
FROM products
WHERE quantity = 0
   OR price >= 1000
ORDER BY price DESC;

-- 11. Усі категорії, окрім General (NOT)
SELECT id, name, category
FROM products
WHERE NOT (category = 'General')
ORDER BY category, id;

-- 12. Товари в ціновому діапазоні (BETWEEN)
SELECT id, name, price, quantity, total_value
FROM products
WHERE price BETWEEN 20 AND 150
ORDER BY price ASC, id ASC;

-- 13. Складна фільтрація: комбінація IN, LIKE, BETWEEN, AND, OR, NOT
SELECT id, name, sku, category, price, quantity
FROM products
WHERE (
        category IN ('Food', 'General')
        OR name LIKE '%Pro%'
      )
  AND price BETWEEN 10 AND 50000
  AND NOT (sku LIKE 'SKU-GEN-0015')
ORDER BY total_value DESC
LIMIT 10;

-- 14. Топ-3 категорії за сумарною вартістю залишків на складі
SELECT category,
       COUNT(*) AS items_count,
       SUM(total_value) AS stock_value
FROM products
WHERE quantity > 0
  AND description IS NOT NULL
GROUP BY category
HAVING SUM(total_value) BETWEEN 100 AND 1000000
ORDER BY stock_value DESC
LIMIT 3;

-- 15. Згенеровані SKU з непарним id у діапазоні id (AND, OR, BETWEEN, ORDER BY, OFFSET, LIMIT)
SELECT id, name, sku, price
FROM products
WHERE sku LIKE 'SKU-GEN-%'
  AND (id % 2 = 1 OR quantity BETWEEN 1 AND 10)
  AND price IS NOT NULL
ORDER BY id DESC
OFFSET 2
LIMIT 6;

-- 16. Оновлення категорії для обраних id (UPDATE + IN)
UPDATE products
SET category = 'Promo'
WHERE id IN (2, 4, 6)
  AND category <> 'Promo'
RETURNING id, name, category;

-- 17. Підвищення ціни на 5% для недорогих товарів категорії Food (UPDATE + AND + BETWEEN)
UPDATE products
SET price = ROUND(price * 1.05, 2)
WHERE category = 'Food'
  AND price BETWEEN 10 AND 200
  AND quantity >= 0
RETURNING id, name, price, category;

-- 18. Скинути опис для «порожніх» залишків згенерованих позицій (UPDATE + LIKE + IS NULL + OR)
UPDATE products
SET description = 'Знято з продажу — оновлено запитом №18'
WHERE sku LIKE 'SKU-GEN-%'
  AND quantity = 0
  AND (description IS NULL OR description LIKE 'Автогенерація%')
RETURNING id, sku, description;

-- 19. Видалення тестових записів без опису в General (DELETE + IS NULL + AND + NOT)
DELETE FROM products
WHERE category = 'General'
  AND description IS NULL
  AND NOT (name LIKE '%Pro%')
  AND quantity = 0
RETURNING id, name, sku;

-- 20. Видалення дешевих згенерованих позицій, окрім назв із «Pro» (DELETE + OR + BETWEEN + NOT + LIKE)
DELETE FROM products
WHERE sku LIKE 'SKU-GEN-%'
  AND (
        price BETWEEN 0.01 AND 25
        OR name LIKE '%— 12 од.%'
      )
  AND NOT (name LIKE '%Pro%')
RETURNING id, name, price, sku;

-- Лабораторна 3. PostgreSQL програмованість для таблиці products
-- Перед запуском виконайте скрипт створення products із Lab 2.

-- 0) Безпечне перевидалення об'єктів (для повторного запуску скрипта)
DROP TRIGGER IF EXISTS trg_products_log_changes ON products;
DROP FUNCTION IF EXISTS trg_log_product_changes();
DROP VIEW IF EXISTS v_active_products;
DROP FUNCTION IF EXISTS f_get_discounted_price(INT, NUMERIC);
DROP FUNCTION IF EXISTS f_get_expensive_products(NUMERIC);
DROP TABLE IF EXISTS products_history;

-- 1) View: тільки товари, які є в наявності (quantity > 0)
CREATE VIEW v_active_products AS
SELECT
    id,
    name,
    sku,
    description,
    category,
    price,
    quantity,
    total_value
FROM products
WHERE quantity > 0;

-- 2) Скалярна функція: повертає ціну після знижки у %
CREATE OR REPLACE FUNCTION f_get_discounted_price(
    product_id INT,
    discount_percent NUMERIC
)
RETURNS NUMERIC
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
    current_price NUMERIC(12, 2);
BEGIN
    IF discount_percent < 0 OR discount_percent > 100 THEN
        RAISE EXCEPTION 'discount_percent має бути в межах [0..100], отримано: %', discount_percent;
    END IF;

    SELECT p.price
    INTO current_price
    FROM products p
    WHERE p.id = product_id;

    IF NOT FOUND THEN
        RETURN NULL;
    END IF;

    RETURN ROUND(current_price * (1 - discount_percent / 100), 2);
END;
$$;

-- 3) Таблична функція: усі колонки товарів, дорожчих за min_price
CREATE OR REPLACE FUNCTION f_get_expensive_products(min_price NUMERIC)
RETURNS TABLE (
    id INT,
    name VARCHAR,
    sku VARCHAR,
    description TEXT,
    category VARCHAR,
    price NUMERIC(12, 2),
    quantity INT,
    total_value NUMERIC(14, 2)
)
LANGUAGE sql
STABLE
AS $$
SELECT
    p.id,
    p.name,
    p.sku,
    p.description,
    p.category,
    p.price,
    p.quantity,
    p.total_value
FROM products p
WHERE p.price > min_price
ORDER BY p.price DESC, p.id ASC;
$$;

-- 4) Історія змін товарів
CREATE TABLE products_history (
    id SERIAL PRIMARY KEY,
    product_id INT NOT NULL,
    old_price NUMERIC(12, 2),
    new_price NUMERIC(12, 2),
    action_type VARCHAR(10) NOT NULL CHECK (action_type IN ('UPDATE', 'DELETE')),
    change_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- 5) Тригерна функція: логування зміни ціни (UPDATE) і видалення (DELETE)
CREATE OR REPLACE FUNCTION trg_log_product_changes()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'UPDATE' THEN
        IF OLD.price IS DISTINCT FROM NEW.price THEN
            INSERT INTO products_history (product_id, old_price, new_price, action_type, change_date)
            VALUES (OLD.id, OLD.price, NEW.price, 'UPDATE', CURRENT_TIMESTAMP);
        END IF;
        RETURN NEW;
    ELSIF TG_OP = 'DELETE' THEN
        INSERT INTO products_history (product_id, old_price, new_price, action_type, change_date)
        VALUES (OLD.id, OLD.price, NULL, 'DELETE', CURRENT_TIMESTAMP);
        RETURN OLD;
    END IF;

    RETURN NULL;
END;
$$;

-- 6) Тригер на таблиці products
CREATE TRIGGER trg_products_log_changes
AFTER UPDATE OR DELETE ON products
FOR EACH ROW
EXECUTE FUNCTION trg_log_product_changes();

-- 7) Фінальний звіт: об'єднання існуючих товарів і історії змін/видалень
SELECT
    'products' AS source_table,
    p.id AS product_id,
    p.name,
    NULL::NUMERIC(12, 2) AS old_price,
    p.price AS new_price,
    'EXISTING'::VARCHAR(10) AS action_type,
    CURRENT_TIMESTAMP AS change_date
FROM products p

UNION ALL

SELECT
    'products_history' AS source_table,
    h.product_id,
    NULL::VARCHAR AS name,
    h.old_price,
    h.new_price,
    h.action_type,
    h.change_date
FROM products_history h
ORDER BY product_id, change_date;

-- Лабораторна робота 2. Варіант: «Інформація про товари»
-- PostgreSQL

DROP TABLE IF EXISTS products;

CREATE TABLE products (
    id          SERIAL PRIMARY KEY,
    name        VARCHAR NOT NULL,
    sku         VARCHAR UNIQUE,
    description TEXT,
    category    VARCHAR DEFAULT 'General',
    price       NUMERIC(12, 2) NOT NULL
                    CHECK (price > 0),
    quantity    INT NOT NULL DEFAULT 0
                    CHECK (quantity >= 0),
    total_value NUMERIC(14, 2) GENERATED ALWAYS AS (price * quantity) STORED
);

COMMENT ON TABLE products IS 'Інформація про товари';
COMMENT ON COLUMN products.total_value IS 'Загальна вартість залишків: price * quantity';

-- Один запис, вставлений вручну
INSERT INTO products (name, sku, description, category, price, quantity)
VALUES (
    'Ноутбук Pro 15',
    'SKU-MANUAL-001',
    'Тестовий товар, доданий одним INSERT',
    'Electronics',
    45999.99,
    5
);

-- Генерація ще N записів у циклі
DO $$
DECLARE
    i   INT := 1;
    n   INT := 15;
    v_price   NUMERIC(12, 2);
    v_qty     INT;
BEGIN
    WHILE i <= n LOOP
        v_price := ROUND((12.50 + i * 7.35 + (i % 3) * 2.10)::NUMERIC, 2);
        v_qty   := (i * 3) % 41;

        INSERT INTO products (name, sku, description, category, price, quantity)
        VALUES (
            'Товар #' || i::TEXT || ' — ' || (10 + i * 2)::TEXT || ' од.',
            'SKU-GEN-' || LPAD(i::TEXT, 4, '0'),
            'Автогенерація. Ітерація ' || i::TEXT || ', ціна ≈ ' || v_price::TEXT,
            CASE (i % 4)
                WHEN 0 THEN 'Electronics'
                WHEN 1 THEN 'Food'
                WHEN 2 THEN 'Clothing'
                ELSE 'General'
            END,
            v_price,
            v_qty
        );

        i := i + 1;
    END LOOP;
END $$;

-- Перевірка (опційно)
-- SELECT id, name, sku, category, price, quantity, total_value FROM products ORDER BY id;

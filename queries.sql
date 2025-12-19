-- Общее количество покупателей
SELECT
    COUNT(*) AS customers_count
FROM customers AS c;


-- Топ-10 продавцов по выручке
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN employees AS e
    ON e.employee_id = s.sales_person_id
JOIN products AS p
    ON p.product_id = s.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name
ORDER BY
    income DESC
LIMIT 10;



-- Продавцы с ниже средней выручкой за сделку, округление вниз
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    FLOOR(AVG(s.quantity * p.price)) AS average_income
FROM sales AS s
JOIN employees AS e ON s.sales_person_id = e.employee_id
JOIN products AS p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING AVG(s.quantity * p.price) < (
    SELECT AVG(s1.quantity * p1.price)
    FROM sales AS s1
    JOIN products AS p1 ON s1.product_id = p1.product_id
)
ORDER BY average_income ASC;



-- Выручка продавцов по дням недели
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TRIM(LOWER(TO_CHAR(s.sale_date, 'Day'))) AS day_of_week,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN employees AS e
    ON e.employee_id = s.sales_person_id
JOIN products AS p
    ON p.product_id = s.product_id
GROUP BY
    e.employee_id,
    e.first_name,
    e.last_name,
    EXTRACT(DOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'Day')
ORDER BY
    CASE
        WHEN EXTRACT(DOW FROM s.sale_date) = 0 THEN 7
        ELSE EXTRACT(DOW FROM s.sale_date)
    END,
    seller;





-- Покупатели по возрастным группам
SELECT
    age_category,
    COUNT(*) AS age_count
FROM (
    SELECT
        CASE
            WHEN c.age BETWEEN 16 AND 25 THEN '16-25'
            WHEN c.age BETWEEN 26 AND 40 THEN '26-40'
            ELSE '40+'
        END AS age_category
    FROM customers AS c
) AS sub
GROUP BY age_category
ORDER BY
    CASE
        WHEN age_category = '16-25' THEN 1
        WHEN age_category = '26-40' THEN 2
        ELSE 3
    END;


-- Уникальные покупатели и выручка по месяцам
SELECT
    TO_CHAR(s.sale_date, 'YYYY-MM') AS selling_month,
    COUNT(DISTINCT s.customer_id) AS total_customers,
    FLOOR(SUM(s.quantity * p.price)) AS income
FROM sales AS s
JOIN products AS p
    ON p.product_id = s.product_id
GROUP BY
    TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY
    selling_month;



-- Покупатели с первой покупкой акционного товара
WITH first_sales AS (
    SELECT
        s.customer_id,
        s.sales_person_id,
        s.sale_date,
        ROW_NUMBER() OVER (
            PARTITION BY s.customer_id
            ORDER BY s.sale_date
        ) AS rn
    FROM sales AS s
    INNER JOIN products AS p
        ON s.product_id = p.product_id
    WHERE p.price = 0
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    fs.sale_date AS sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_sales AS fs
INNER JOIN customers AS c
    ON c.customer_id = fs.customer_id
INNER JOIN employees AS e
    ON e.employee_id = fs.sales_person_id
WHERE fs.rn = 1
ORDER BY fs.customer_id;

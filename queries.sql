-- Общее количество покупателей
SELECT
    COUNT(*) AS customers_count
FROM customers;


-- Топ-10 продавцов по выручке
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(*) AS operations,
    SUM(s.quantity * p.price) AS income
FROM employees
INNER JOIN sales AS s
    ON s.sales_person_id = employees.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.first_name,
    e.last_name,
    employees.employee_id
ORDER BY income DESC
LIMIT 10;


-- Продавцы с ниже средней выручкой за сделку
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    CAST(
        AVG(s.quantity * p.price)
        AS INTEGER
    ) AS average_income
FROM employees
INNER JOIN sales AS s
    ON s.sales_person_id = employees.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.first_name,
    e.last_name,
    employees.employee_id
HAVING AVG(s.quantity * p.price) < (
    SELECT
        AVG(s2.quantity * p2.price)
    FROM sales AS s2
    INNER JOIN products AS p2
        ON s2.product_id = p2.product_id
)
ORDER BY average_income ASC;


-- Выручка продавцов по дням недели
SELECT
    e.first_name || ' ' || e.last_name AS seller,
    LOWER(TO_CHAR(s.sale_date, 'FMDay')) AS day_of_week,
    SUM(s.quantity * p.price) AS income
FROM employees
INNER JOIN sales AS s
    ON s.sales_person_id = employees.employee_id
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    e.first_name,
    e.last_name,
    employees.employee_id,
    EXTRACT(DOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'FMDay')
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
            WHEN age BETWEEN 16 AND 25 THEN '16-25'
            WHEN age BETWEEN 26 AND 40 THEN '26-40'
            ELSE '40+'
        END AS age_category
    FROM customers
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
    SUM(s.quantity * p.price) AS income
FROM sales AS s
INNER JOIN products AS p
    ON s.product_id = p.product_id
GROUP BY
    TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month;


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
    c.first_name || ' ' || c.last_name AS customer,
    first_sales.sale_date,
    e.first_name || ' ' || e.last_name AS seller
FROM first_sales
INNER JOIN customers AS c
    ON c.customer_id = first_sales.customer_id
INNER JOIN employees AS e
    ON e.employee_id = first_sales.sales_person_id
WHERE first_sales.rn = 1
ORDER BY first_sales.customer_id;

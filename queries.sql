-- Этот запрос подсчитывает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;


-- Топ-10 продавцов по выручке
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    COUNT(s.sales_id) AS operations,
    ROUND(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
ORDER BY income DESC
LIMIT 10;



-- Продавцы с ниже средней выручкой за сделку
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    ROUND(AVG(s.quantity * p.price)) AS average_income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY e.employee_id, e.first_name, e.last_name
HAVING AVG(s.quantity * p.price) < (
    SELECT AVG(s.quantity * p.price)
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
)
ORDER BY average_income ASC;




-- Выручка продавцов по дням недели
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TO_CHAR(s.sale_date, 'FMDay') AS day_of_week,
    ROUND(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY
    e.employee_id, e.first_name, e.last_name,
    EXTRACT(DOW FROM s.sale_date),
    TO_CHAR(s.sale_date, 'FMDay')
ORDER BY
    EXTRACT(DOW FROM s.sale_date),  -- 0 = Sunday, 1 = Monday, … 6 = Saturday
    seller;



-- покупатели по возрастным группам
SELECT age_category, COUNT(*) AS age_count
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
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY TO_CHAR(s.sale_date, 'YYYY-MM')
ORDER BY selling_month ASC;



-- Покупатели с первой покупкой акционного товара
WITH first_sales AS (
    SELECT
        s.customer_id,
        s.sales_person_id,
        s.sale_date,
        ROW_NUMBER() OVER (PARTITION BY s.customer_id ORDER BY s.sale_date) AS rn
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.price = 0
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    fs.sale_date AS sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_sales fs
JOIN customers c ON c.customer_id = fs.customer_id
JOIN employees e ON e.employee_id = fs.sales_person_id
WHERE fs.rn = 1
ORDER BY fs.customer_id;


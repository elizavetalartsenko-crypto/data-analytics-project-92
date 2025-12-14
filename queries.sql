-- Этот запрос подсчитывает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;


-- Этот запрос показывает топ-10 продавцов по суммарной выручке,
-- вместе с количеством проведённых сделок.

SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.quantity) AS operations,
    s.quantity*p.price AS income
FROM sales s
JOIN employees e
ON s.sales_person_id = e.employee_id
join products as p
on s.product_id = p.product_id 
GROUP BY seller, s.quantity, p.price
ORDER BY income DESC
LIMIT 10;


-- Продавцы с ниже средней выручкой за сделку
WITH seller_avg AS (
    SELECT
        CONCAT(e.first_name, ' ', e.last_name) AS seller,
        ROUND(AVG(s.quantity * p.price)) AS average_income
    FROM sales s
    JOIN employees e ON s.sales_person_id = e.employee_id
    JOIN products p ON s.product_id = p.product_id
    GROUP BY seller
),
overall_avg AS (
    SELECT AVG(s.quantity * p.price) AS avg_all
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
)
SELECT sa.seller, sa.average_income
FROM seller_avg sa, overall_avg oa
WHERE sa.average_income < oa.avg_all
ORDER BY sa.average_income ASC;


-- Выручка продавцов по дням недели
SELECT
    CONCAT(e.first_name, ' ', e.last_name) AS seller,
    TO_CHAR(s.sale_date, 'FMDay') AS day_of_week,
    ROUND(SUM(s.quantity * p.price)) AS income
FROM sales s
JOIN employees e ON s.sales_person_id = e.employee_id
JOIN products p ON s.product_id = p.product_id
GROUP BY seller, day_of_week, EXTRACT(DOW FROM s.sale_date)
ORDER BY EXTRACT(DOW FROM s.sale_date), seller;


-- Покупатели по возрастным группам
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
GROUP BY selling_month
ORDER BY selling_month ASC;


-- Покупатели с первой покупкой акционного товара
WITH first_sales AS (
    SELECT s.customer_id, MIN(s.sale_date) AS first_sale_date
    FROM sales s
    JOIN products p ON s.product_id = p.product_id
    WHERE p.price = 0
    GROUP BY s.customer_id
)
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer,
    fs.first_sale_date AS sale_date,
    CONCAT(e.first_name, ' ', e.last_name) AS seller
FROM first_sales fs
JOIN sales s ON s.customer_id = fs.customer_id AND s.sale_date = fs.first_sale_date
JOIN customers c ON c.customer_id = fs.customer_id
JOIN employees e ON e.employee_id = s.sales_person_id
ORDER BY fs.customer_id;

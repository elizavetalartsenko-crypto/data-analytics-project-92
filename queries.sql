-- Этот запрос подсчитывает общее количество покупателей в таблице customers
SELECT COUNT(*) AS customers_count
FROM customers;


-- Этот запрос показывает топ-10 продавцов по суммарной выручке,
-- вместе с количеством проведённых сделок.

SELECT
    e.first_name || ' ' || e.last_name AS seller,
    COUNT(s.quantity) AS operations,
    ROUND(s.quantity*p.price, 0) AS income
FROM sales s
JOIN employees e
ON s.sales_person_id = e.employee_id
JOIN products AS p
ON s.product_id = p.product_id 
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
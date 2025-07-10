use vscode ;
select* from orders ;
-- find top 10 revinue genarating products in each region

select Product_id, sum(sell_price) as total_sell from orders group by product_id order by total_sell desc limit 10;

-- find top 5 selling product in each region
 
with product as (select region,product_id,sum(sell_price)as price from orders group by product_id,region)
SELECT* FROM (select*, row_number() over(partition by region order by price desc)as rn from product )a where rn<=5;
-- find month over month growth comparison for 2022 and 2023 sales eg :	jan 2022 vs jan 2023

SELECT 
  MONTH(order_date) AS month,
  SUM(CASE WHEN YEAR(order_date) = 2022 THEN sell_price ELSE 0 END) AS sales_2022,
  SUM(CASE WHEN YEAR(order_date) = 2023 THEN sell_price ELSE 0 END) AS sales_2023,
  ROUND(
    (SUM(CASE WHEN YEAR(order_date) = 2023 THEN sell_price ELSE 0 END) -
     SUM(CASE WHEN YEAR(order_date) = 2022 THEN sell_price ELSE 0 END)) /
     NULLIF(SUM(CASE WHEN YEAR(order_date) = 2022 THEN sell_price ELSE 0 END), 0)
  * 100, 2) AS growth_percentage
FROM orders
WHERE YEAR(order_date) IN (2022, 2023)
GROUP BY MONTH(order_date)
ORDER BY month;
-- for each catagory which month had highest sell

WITH monthly_sales AS (
    SELECT 
        category,
        MONTH(order_date) AS month,
        SUM(sell_price) AS total_sales
    FROM orders
    GROUP BY category, MONTH(order_date)
),
ranked_sales AS (
    SELECT *,
        ROW_NUMBER() OVER(PARTITION BY category ORDER BY total_sales DESC) AS rn
    FROM monthly_sales
)
SELECT category, month, total_sales
FROM ranked_sales
WHERE rn = 1;
-- which sub catagory had highest growth by profit in 2023 compare to 2022

WITH yearly_profit AS (
    SELECT 
        sub_category,
        YEAR(order_date) AS year,
        SUM(profit) AS total_profit
    FROM orders
    WHERE YEAR(order_date) IN (2022, 2023)
    GROUP BY sub_category, YEAR(order_date)
),
pivot_profit AS (
    SELECT 
        sub_category,
        SUM(CASE WHEN year = 2022 THEN total_profit ELSE 0 END) AS profit_2022,
        SUM(CASE WHEN year = 2023 THEN total_profit ELSE 0 END) AS profit_2023
    FROM yearly_profit
    GROUP BY sub_category
),
profit_growth AS (
    SELECT 
        sub_category,
        profit_2022,
        profit_2023,
        ROUND(
            (profit_2023 - profit_2022) / NULLIF(profit_2022, 0) * 100, 2
        ) AS growth_percent
    FROM pivot_profit
)
SELECT *
FROM profit_growth
ORDER BY growth_percent DESC
LIMIT 1;

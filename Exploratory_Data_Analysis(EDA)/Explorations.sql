----DataBase exploration

-- Explore Objects
SELECT * FROM INFORMATION_SCHEMA.TABLES


--Explore Columns
SELECT * FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME= 'dim_customer'


----Dimension Exploration

--Explore Country
SELECT DISTINCT country FROM gold.dim_customer


--Explore Major Dimensions
SELECT DISTINCT category,subcategory,product_name FROM gold.dim_products


----Date exploration


--Explore Date exploration
SELECT 
MIN(order_date) first_order_date,
MAX(order_date) AS last_order_date,
DATEDIFF(YEAR,MIN(order_date),MAX(order_date)) AS order_range
FROM gold.fact_sales

--Find youngest and oldest customer
SELECT
DATEDIFF(YEAR,MIN(birthdate),GETDATE()) AS oldest,
DATEDIFF(YEAR,MAX(birthdate),GETDATE()) AS youngest
FROM gold.dim_customer



---- Measure Exploration


--find the total sales
SELECT SUM(sales_amount) AS total_sales FROM gold.fact_sales
--items sold
SELECT SUM(quantity) AS item_sold FROM gold.fact_sales
--average selling price
SELECT AVG(price) AS average_price FROM gold.fact_sales
--Total No of orders
SELECT COUNT( DISTINCT order_number) AS total_order FROM gold.fact_sales
--Total No of products
SELECT COUNT(DISTINCT product_key ) AS total_product FROM gold.dim_products
--Total No of customers
SELECT COUNT( customer_key) AS total_customer FROM gold.dim_customer
--Total No of customer that have placed the order
SELECT COUNT(DISTINCT customer_key) AS total_customer FROM gold.dim_customer

--Generate a Report that shows all key Metrics of the Business
SELECT 'Total Sales ' AS measure_name,SUM(sales_amount) AS measure_value FROM gold.fact_sales
UNION ALL 
SELECT 'Total Quantity',SUM(quantity) AS item_sold FROM gold.fact_sales
UNION ALL
SELECT 'Average Price',AVG(price) AS average_price FROM gold.fact_sales
UNION ALL
SELECT 'Total orders' ,COUNT( DISTINCT order_number) AS total_order FROM gold.fact_sales
UNION ALL
SELECT 'Total Products',COUNT(DISTINCT product_key ) AS total_product FROM gold.dim_products
UNION ALL
SELECT 'Total Customer',COUNT( customer_key) AS total_customer FROM gold.dim_customer


---- Magnitude(comapre Measure values)

--Find total customer by Country
SELECT 
country,
COUNT(customer_key) AS total_customer
FROM gold.dim_customer
GROUP BY country
ORDER BY total_customer DESC


--Find Total customer by gender
SELECT 
gender,
COUNT(customer_key) AS total_customer
FROM gold.dim_customer
GROUP BY gender
ORDER BY total_customer DESC


--Find total Products by category
SELECT 
category,
COUNT(product_key) AS total_products
FROM gold.dim_products
GROUP BY category
ORDER BY total_products DESC


--Find avg cost of each category
SELECT 
category,
AVG(cost) AS avg_cost
FROM gold.dim_products
GROUP BY category
ORDER BY avg_cost DESC


--Total revenue generated for each cactegory
SELECT 
p.category,
SUM(f.sales_amount) AS total_cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON  p.product_key = f.product_key
GROUP BY p.category
ORDER BY total_cost DESC

--Total revenue generated from each customer
SELECT 
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON  c.customer_key = f.customer_key
GROUP BY c.customer_key,
c.first_name,
c.last_name
ORDER BY total_cost DESC

--Distribution of sold items across countries
SELECT 
c.country,
SUM(f.quantity) AS total_sold_items
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON  c.customer_key = f.customer_key
GROUP BY c.country
ORDER BY total_sold_items DESC


----Ranking Analysis

--which 5 product generate the highest revenue
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON  p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue DESC



SELECT *
FROM(
SELECT
p.product_name,
SUM(f.sales_amount) AS total_revenue,
ROW_NUMBER() OVER (ORDER BY SUM(f.sales_amount) DESC) AS rank_products
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON  p.product_key = f.product_key
GROUP BY p.product_name)t
WHERE rank_products <=5



--5 worst-performing product in terms of sales
SELECT TOP 5
p.product_name,
SUM(f.sales_amount) AS total_revenue
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON  p.product_key = f.product_key
GROUP BY p.product_name
ORDER BY total_revenue 

--Find top 10 customer generating highest revenue
SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
SUM(f.sales_amount) AS total_cost
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON  c.customer_key = f.customer_key
GROUP BY c.customer_key,
c.first_name,
c.last_name
ORDER BY total_cost DESC 


--3 customer wiht fewest order
SELECT TOP 10
c.customer_key,
c.first_name,
c.last_name,
COUNT(DISTINCT order_number ) AS total_orders
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON  c.customer_key = f.customer_key
GROUP BY c.customer_key,
c.first_name,
c.last_name
ORDER BY total_orders 


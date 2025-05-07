/*
===================================
Customer Report
==================================
purpose:
    - This report consolidates key customer metrics and behaviours

Highlights
 1.Gather essential fields such as names,ages,and transaction details
 2. segment customer into category (VIP,REGULAR,NEW) and age group.
 3. Aggregates customer-level metrics:
    --total orders
	--total sales
	--total quantity purchased
	--total products
	--lifespan(months)
4. calculate valuable kPIs:
    --months since last order
	--average order value
	--average monthly spend
===========================================
*/
IF OBJECT_ID('gold.report_customers', 'V') IS NOT NULL
    DROP VIEW gold.report_customers;
GO
CREATE VIEW gold.report_customers AS
WITH base_query AS (
--1) Base query : Retrieve core colums from tables
SELECT 
f.order_number,
f.product_key,
f.order_date,
f.sales_amount,
f.quantity,
c.customer_key,
c.customer_number,
CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
DATEDIFF(year, c.birthdate, GETDATE()) age
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON c.customer_key = f.customer_key
WHERE order_date IS NOT NULL)

,customer_aggregation AS (
SELECT 
customer_key,
customer_number,
customer_name,
age,
COUNT(DISTINCT order_number) AS total_orders,
SUM(sales_amount) AS total_sales,
SUM(quantity) AS total_quantity,
COUNT(DISTINCT product_key) AS total_products,
MAX(order_date) AS last_order_date,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
FROM base_query
GROUP BY 
  customer_key,
customer_number,
customer_name,
age)
SELECT 
customer_key,
customer_number,
customer_name,
age,
CASE WHEN age<20 THEN 'Under 20'
     WHEN age BETWEEN 20 and 29 THEN '20-29'
	 WHEN age BETWEEN 30 and 39 THEN '30-39'
	 WHEN age BETWEEN 40 and 49 THEN '40-49'
	 ELSE '50 and above'
END AS age_group,
CASE WHEN total_sales > 5000 AND lifespan>=12 THEN 'VIP'
	 WHEN total_sales <= 5000 AND lifespan >=12 THEN 'Regular'
	 ELSE 'New Customer'
END customer_segment,
last_order_date,
DATEDIFF(month,last_order_date,GETDATE()) AS recency,
total_orders,
total_sales,
--compute average order value
CASE WHEN total_orders =0 THEN 0
     ELSE total_sales/total_orders
END AS avg_order_value,
total_quantity,
total_products,
lifespan,
--compute average monthly spend
CASE WHEN lifespan=0 THEN total_sales
     ELSE total_sales/lifespan
END AS avg_monthly_spend
FROM customer_aggregation


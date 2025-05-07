
---- Sales ,Customer,quantity for year


SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
COUNT(DISTINCT customer_key) AS total_customer,
SUM(quantity) AS total_qnatity
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
ORDER BY DATETRUNC(month,order_date)


----Cumulative Analysis

--Calculate total sales for each month and running total sales



SELECT 
order_date,
total_sales,
SUM(total_sales) OVER (PARTITION BY order_date ORDER BY order_date) AS running_total_sales,
AVG(avg_price) OVER (PARTITION BY order_date ORDER BY order_date) AS moving_average_price
FROM 
(
SELECT 
DATETRUNC(month,order_date) AS order_date,
SUM(sales_amount) AS total_sales,
AVG(price) AS avg_price
FROM gold.fact_sales
WHERE order_date IS NOT NULL
GROUP BY DATETRUNC(month,order_date)
)t


----permanent Analysis

/*analyze the yearly performance of products by comparing their sales to both the 
average sales perforance of the product and the previous year sales */
 
 WITH yearly_product_sales AS (
 SELECT
 YEAR(f.order_date) AS order_year,
 p.product_name,
 SUM(f.sales_amount) AS current_sales
 FROM gold.fact_sales f
 LEFT JOIN gold.dim_products p
 ON f.product_key = p.product_key
 WHERE f.order_date IS NOT NULL
 GROUP BY 
 YEAR(f.order_date),
 p.product_name
 )
 SELECT 
order_year,
product_name,
current_sales,
AVG(current_sales)  OVER (PARTITION BY product_name) AS avg_sales,
current_sales - AVG(current_sales)  OVER (PARTITION BY product_name) AS diff_avg,
CASE WHEN current_sales - AVG(current_sales)  OVER (PARTITION BY product_name) > 0 THEN 'Above avg'
       WHEN current_sales - AVG(current_sales)  OVER (PARTITION BY product_name) < 0 THEN 'Below avg'
	   ELSE 'Avg'
END avg_change,
LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS py_sales,
current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) AS diff_py,
CASE WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) > 0 THEN 'Increase'
       WHEN current_sales - LAG(current_sales) OVER (PARTITION BY product_name ORDER BY order_year) < 0 THEN 'Decrease'
	   ELSE 'No Change'
END py_change
FROM yearly_product_sales
ORDER BY product_name, order_year


---- part-to- whole analysis

--Which category contribute to most of sales
WITH category_sales AS (
SELECT 
category,
SUM(sales_amount) total_sales
FROM gold.fact_sales f
LEFT JOIN gold.dim_products p
ON p.product_key = f.product_key
GROUP BY category)
SELECT 
category,
total_sales,
SUM(total_sales) OVER () overall_sales,
CONCAT(ROUND((CAST(total_sales AS FLOAT)/SUM(total_sales) OVER ())* 100,2),'%') AS percentage_of_total
FROM category_sales
ORDER BY total_sales DESC



---- Data Segmentation

--segment products into cost ranges and count how many products fall into each segment
WITH product_segment AS (
SELECT 
product_key,
product_name,
cost,
CASE WHEN cost < 100 THEN 'BELOW 100'
     WHEN cost BETWEEN 100 AND 500 THEN '100-500'
	 WHEN cost BETWEEN 500 AND 1000 THEN '500-1000'
	 ELSE 'Above 1000'
END cost_range
FROM gold.dim_products )

SELECT 
cost_range,
COUNT(product_key) AS total_products
FROM product_segment
GROUP BY cost_range
ORDER BY total_products DESC


/* Group customer into 3 segment 
VIP: atleast 12 month history and spending more than 5000
Regular: atleast 12 month of history but spending 5000 or less
New: lifespan less than 12 months
*/


WITH customer_spending AS (
SELECT
c.customer_key,
SUM(f.sales_amount) AS total_spending,
MIN(order_date) AS first_order,
MAX(order_date) AS last_order,
DATEDIFF(month,MIN(order_date),MAX(order_date)) AS lifespan
FROM gold.fact_sales f
LEFT JOIN gold.dim_customer c
ON f.customer_key = c.customer_key
GROUP BY c.customer_key
)
SELECT 
customer_segment,
COUNT(customer_key) AS total_customer
FROM (
	SELECT
	customer_key,
	CASE WHEN total_spending > 5000 AND lifespan>=12 THEN 'VIP'
		 WHEN total_spending <= 5000 AND lifespan >=12 THEN 'Regular'
		 ELSE 'New Customer'
	END customer_segment
	FROM customer_spending)t
GROUP BY customer_segment
ORDER BY total_customer DESC



----









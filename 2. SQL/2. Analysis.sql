-- ANALYSIS
-- Cleaned Temp Table
CREATE TEMPORARY TABLE olist_products_dataset_cleaned AS (
SELECT *,
CASE
WHEN product_category_name = 'casa_conforto_2' THEN 'casa_conforto'
WHEN product_category_name = 'eletrodomesticos_2' THEN 'eletrodomesticos'
WHEN product_category_name IS NULL THEN 'outros'
ELSE product_category_name
END AS cleaned_product_category_name
FROM olist_products_dataset
ORDER BY cleaned_product_category_name
)

-- 1. How many product categories are there?
SELECT DISTINCT(cleaned_product_category_name) AS product_category,
	   COUNT(*) AS products_in_category,
	   (SELECT COUNT(*)
	   FROM olist_products_dataset_cleaned) AS total_of_products
FROM olist_products_dataset_cleaned
GROUP BY product_category
ORDER BY products_in_category DESC
-- Olist is working with a total of 32,951 products distributed in 72 product categories.

-- 2. Which are the top 10 sold items?
SELECT DISTINCT(orders.product_id) AS product,
	   COUNT(orders.*) AS number_of_sales,
	   products.cleaned_product_category_name AS category,
	   products.product_photos_qty AS photos
FROM olist_order_items_dataset AS orders
	JOIN olist_products_dataset_cleaned AS products
	ON  orders.product_id = products.product_id
GROUP BY product, category, photos
ORDER BY number_of_sales DESC
LIMIT 10
-- On the table we can see the top ten sold products with a column for the quantity of available photos. We can see that most of the sold items have two or more photos. 
-- This hypothesis needs further investigation.

-- 3. What are the top 5 categories with most orders?
SELECT DISTINCT(products.cleaned_product_category_name) AS category,
	   COUNT(orders.*) AS number_of_sales
FROM olist_order_items_dataset AS orders
	JOIN olist_products_dataset_cleaned AS products
	ON  orders.product_id = products.product_id
GROUP BY category
ORDER BY number_of_sales DESC
LIMIT 5

-- What are the top 5 states with most clients registered?
SELECT DISTINCT (customer_state) AS states,
	   COUNT(*) AS number_of_clients
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY number_of_clients DESC
LIMIT 5

-- What are the top 5 customers with highest purchases?
SELECT DISTINCT(orders.customer_id) AS customers,
	   COUNT(DISTINCT(orders.order_id)) AS number_of_orders,
	   SUM(items.price) + SUM(items.freight_value) AS total_price
FROM olist_order_items_dataset AS items
INNER JOIN olist_orders_dataset AS orders
ON items.order_id = orders.order_id
GROUP BY customers
ORDER BY total_price DESC
LIMIT 5
-- It is recommended to confirm the accuracy of the database as the information shows there are no clients that have made more than one order between 2016 and 2020.

-- What are the top 5 states with most sales?
SELECT DISTINCT(customers.customer_state) AS states,
	   COUNT(DISTINCT(orders.order_id)) AS number_of_orders,
	   SUM(items.price) + SUM(items.freight_value) AS total_price
FROM olist_order_items_dataset AS items
INNER JOIN olist_orders_dataset AS orders
ON items.order_id = orders.order_id
INNER JOIN olist_customers_dataset AS customers
ON orders.customer_id = customers.customer_id
GROUP BY states
ORDER BY total_price DESC
LIMIT 5

-- Pivot Table with yearly sales for each state. 
CREATE EXTENSION tablefunc

SELECT *
FROM CROSSTAB (
	$$ SELECT DISTINCT(customers.customer_state) AS states,
		   EXTRACT(YEAR FROM orders.order_purchase_timestamp) AS years,
	   	   SUM(items.price) + SUM(items.freight_value) AS total_price
	FROM olist_order_items_dataset AS items
	INNER JOIN olist_orders_dataset AS orders
	ON items.order_id = orders.order_id
	INNER JOIN olist_customers_dataset AS customers
	ON orders.customer_id = customers.customer_id
	GROUP BY states, years
	ORDER BY 1,2 $$,
	$$ SELECT DISTINCT(EXTRACT(YEAR FROM order_purchase_timestamp)) AS years
	   FROM olist_orders_dataset
	   ORDER BY 1 $$
) as ct(states text, year_2016 text, year_2017 text, year_2018 text)

-- What are the average of products per order?
SELECT MAX(order_item_id) AS max_products_per_order,
	   ROUND(AVG(CAST(order_item_id AS int)),2) AS avg_products_per_order
FROM olist_order_items_dataset

-- What sellers receive the most reviews?
SELECT DISTINCT(items.seller_id2) AS sellers,
	   COUNT(reviews.review_id) AS number_of_reviews,
	   ROUND(AVG (reviews.review_score),2) AS score_avg
FROM olist_order_reviews_dataset AS reviews
INNER JOIN olist_order_items_dataset AS items
ON reviews.order_id = items.order_id
GROUP BY  sellers
ORDER BY 2 DESC

-- What percentage of the orders received a review score?
SELECT COUNT(items.order_id) AS qty_of_orders,
	   COUNT(reviews.order_id)AS qty_of_reviews,
	   COUNT(items.order_id)*100/COUNT(reviews.order_id) AS review_percentage	   
FROM olist_order_reviews_dataset AS reviews
RIGHT JOIN olist_order_items_dataset AS items
ON reviews.order_id = items.order_id
-- Checking further the information between the reviews and items tables it was possible to identify that not all reviews are attached to an order on the items table which would not allow to make an accurate calculation.

--What's the distribution of the payment types?
SELECT DISTINCT(payment_type) AS payment,
	   COUNT(payment_type) AS payments_number,
	   COUNT(payment_type)*100/
	   	(SELECT COUNT(*)
		 FROM olist_order_payments_dataset) AS payments_done_perc,
		SUM(payment_value) AS total_payment
FROM olist_order_payments_dataset
GROUP BY payment
ORDER BY 4 DESC

-- How many shipments were within the shipping limit date?
SELECT (SELECT COUNT(*) FROM olist_orders_dataset)AS number_of_total_orders,
	   COUNT(*) AS number_of_delayed_orders,
	   ROUND(COUNT(*)*100/(SELECT COUNT(*) FROM olist_orders_dataset),2) AS delayed_orders_perc,
	   ROUND((AVG(date_diff)/(-24))::decimal,2) AS avg_days_delay
FROM ( SELECT *,
	   ((DATE_PART('year', order_estimated_delivery_date)-DATE_PART('year', order_delivered_customer_date))*8760
	   +(DATE_PART('month', order_estimated_delivery_date)-DATE_PART('month', order_delivered_customer_date))*720
	   +(DATE_PART('day', order_estimated_delivery_date)-DATE_PART('day', order_delivered_customer_date))*24
	   +(DATE_PART('hour', order_estimated_delivery_date)-DATE_PART('hour', order_delivered_customer_date))
	   ) AS date_diff
	   FROM olist_orders_dataset
	   WHERE order_status = 'delivered') AS date_calculations_table
WHERE date_diff < 0
-- FIRST WE START EXPLORING THE DATA
-- How many product categories do we have?
SELECT DISTINCT(product_category_name) AS product_category,
	   COUNT(*) AS number_of_items
FROM olist_products_dataset
GROUP BY product_category
ORDER BY number_of_items DESC

-- Here we identify 74 product categories, being NULL one of them with 610 items
SELECT DISTINCT(product_category_name) AS product_category,
	   COUNT(*) AS number_of_items
FROM olist_products_dataset
GROUP BY product_category
HAVING product_category_name IS NULL
ORDER BY number_of_items DESC

-- How many orders are on the database
SELECT COUNT(DISTINCT (order_id)) AS number_of_orders
FROM olist_order_items_dataset

-- What's the time frame of the orders available
SELECT MIN(shipping_limit_date) AS min_date_available,
	   MAX (shipping_limit_date) AS max_date_available
FROM olist_order_items_dataset

-- How many sellers does the database have?
SELECT COUNT(DISTINCT(seller_id)) AS sellers
FROM olist_sellers_dataset

-- Checking length restriction on "customer_state" on different tables
SELECT DISTINCT(customer_state) AS state,
	   LENGTH(customer_state) AS characters_state
FROM olist_customers_dataset
GROUP BY state
HAVING LENGTH(customer_state) >2

SELECT DISTINCT(geolocation_state) AS state,
	   LENGTH(geolocation_state) AS characters_state
FROM olist_geolocation_dataset
GROUP BY state
HAVING LENGTH(geolocation_state) >2

SELECT DISTINCT(seller_state) AS state,
	   LENGTH(seller_state) AS characters_state
FROM olist_sellers_dataset
GROUP BY state
HAVING LENGTH(seller_state) >2

-- CLEANNING PROCESS
-- Are the product categories standardized?
SELECT DISTINCT(product_category_name) AS product_category,
	   COUNT(*) AS number_of_items,
FROM olist_products_dataset
GROUP BY product_category
ORDER BY product_category

-- The following changes are going to be made on the 'olist_products_dataset'
-- The categories 'casa_conforto' and 'casa_conforto_2' are going to be integrated.
-- The categories 'eletrodomesticos' and 'eletrodomesticos_2' are going to be integrated.
-- "NULL" values are going to be changed to 'others'

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

-- LIMITATION:  We have 3 transactions with a payment 'not_defined', however it doesn't have an effect due to the low percentage.
SELECT DISTINCT (payment_type) AS payment_types,
	   COUNT(*) AS payments,
	   ROUND(COUNT(*)*100/
	   	(SELECT COUNT(*)
		FROM olist_order_payments_dataset
		),2) AS percentage
FROM  olist_order_payments_dataset
GROUP BY payment_types
ORDER BY percentage DESC
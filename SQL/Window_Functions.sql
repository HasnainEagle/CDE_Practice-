USE BikeStores;

-- Question : 01
-- Assign a row number to each order per customer based on order_date.

SELECT customer_id,
	   order_id,
	   order_date,
	   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) Ranking
FROM sales.orders;

-- Question : 02
-- Find the latest order for each customer.

WITH Order_Per_Customer AS (
	SELECT customer_id,
		   order_id,
		   order_date,
		   ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date DESC) Latest_Order
	FROM sales.orders
)
SELECT *
FROM Order_Per_Customer
WHERE Latest_Order = 1;

-- Question : 03
-- Rank customers based on total number of orders.

WITH Customers_Orders AS (
	SELECT customer_id,
		   COUNT(order_id) Total_Orders
	FROM sales.orders
	GROUP BY customer_id
)
SELECT *,
	   DENSE_RANK() OVER(ORDER BY Total_Orders DESC) Ranking
FROM Customers_Orders;

-- Question : 04
-- Find top 3 most recent orders per store.

WITH Store_Ranking AS (
	SELECT store_id,
		   order_id,
		   order_date,
		   DENSE_RANK() OVER(PARTITION BY store_id ORDER BY order_date DESC) Ranking
	FROM sales.orders
)
SELECT *
FROM Store_Ranking
WHERE Ranking < 4;

-- Question : 05
-- Assign rank to products based on list_price within each category.

SELECT category_id,
	   product_name,
	   list_price,
	   DENSE_RANK() OVER(PARTITION BY category_id ORDER BY list_price DESC) Ranking
FROM production.products;

-- Question : 06
-- Find duplicate orders (same customer, same date) using window functions.

WITH Customer_Orders AS (
SELECT customer_id,
	   order_date,
	   order_id,
	   ROW_NUMBER() OVER(PARTITION BY customer_id,order_date ORDER BY order_date) Duplicate_Orders
FROM sales.orders
)
SELECT *
FROM Customer_Orders 
WHERE Duplicate_Orders > 1;

-- Question : 07
-- Calculate running total of orders per customer over time.

SELECT 
	customer_id,
	order_id,
	order_date,
	COUNT(*) OVER(PARTITION BY customer_id ORDER BY order_date
		       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) Running_Total 
FROM sales.orders;

-- Question : 08
-- Find previous order date for each customer.

SELECT 
	customer_id,
	order_id,
	order_date,
	LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) Previous_Date
FROM sales.orders;

-- Question : 09
-- Calculate days difference between current and previous order.

WITH Customer_Prev_Order_Date AS (
	SELECT 
		customer_id,
		order_id,
		order_date,
		LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) Previous_Date
	FROM sales.orders
)
SELECT 
	*,
	DATEDIFF(DAY,Previous_Date,order_date) Days_Difference
FROM Customer_Prev_Order_Date;

-- Question : 10
-- Find customers whose order amount increased compared to previous order.

WITH Complete_Table AS (
	SELECT
	ord.order_id,
    ord.customer_id,
    ord.order_date,
    ord_item.item_id,
    ord_item.product_id,
    ord_item.quantity,
    ord_item.list_price,
    ord_item.discount
	FROM sales.orders ord
	LEFT JOIN sales.order_items ord_item
	ON ord.order_id = ord_item.order_id
),
Customers_Order_Amount AS (
SELECT 
	customer_id,
	order_id,
	order_date,
	SUM(quantity * list_price * (1 - discount)) Order_Amount
FROM Complete_Table
GROUP BY customer_id,order_id,order_date
),
Customers_Previous_OrderAmount AS (
SELECT 
	*,
	LAG(Order_Amount) OVER(PARTITION BY customer_id ORDER BY order_date) Previous_Order_Amount
FROM Customers_Order_Amount
)
SELECT *
FROM Customers_Previous_OrderAmount
WHERE Order_Amount > Previous_Order_Amount;

-- Question : 11
-- Calculate cumulative revenue per store.

WITH Store_Raw_Data AS (
SELECT 
	store_id,
	ord.order_id,
	customer_id,
	order_date,
	quantity,
	list_price,
	discount
FROM sales.orders ord 
LEFT JOIN sales.order_items ord_item
ON ord.order_id = ord_item.order_id
),
Order_Revenue AS (
SELECT 
	store_id,
	order_id,
	order_date,
	SUM(quantity * list_price * (1-discount)) Order_Revenue
FROM Store_Raw_Data
GROUP BY store_id,order_id,order_date
)
SELECT 
	*,
	SUM(Order_Revenue) OVER(PARTITION BY store_id ORDER BY order_date) Cummulative_Revenue
FROM Order_Revenue;

-- Question : 12
-- Find highest priced product in each category.

WITH Raw_Table AS (
SELECT 
	prod.category_id,
	product_id,
	product_name,
	category_name,
	list_price
FROM production.products prod
LEFT JOIN production.categories cat
ON prod.category_id = cat.category_id
),
Product_ListPrice AS (
SELECT 
	*,
	DENSE_RANK() OVER(PARTITION BY category_id ORDER BY list_price DESC) Ranking
FROM Raw_Table
)
SELECT 
	category_id,
	category_name,
	product_name,
	list_price
FROM Product_ListPrice
WHERE Ranking = 1;

-- Question : 13
-- Find second highest priced product per category.

WITH Raw_Table AS (
SELECT 
	prod.category_id,
	product_id,
	product_name,
	category_name,
	list_price
FROM production.products prod
LEFT JOIN production.categories cat
ON prod.category_id = cat.category_id
),
Product_ListPrice AS (
SELECT 
	*,
	DENSE_RANK() OVER(PARTITION BY category_id ORDER BY list_price DESC) Ranking
FROM Raw_Table
)
SELECT 
	category_id,
	category_name,
	product_name,
	list_price
FROM Product_ListPrice
WHERE Ranking = 2;

-- Question : 14
-- Find top-selling product (by quantity) in each store.

WITH Raw_Data AS (
SELECT 
	store_id,
	ord_items.product_id,
	product_name,
	quantity
FROM sales.order_items ord_items
JOIN production.products prod
ON ord_items.product_id = prod.product_id
JOIN sales.orders ord
ON ord.order_id = ord_items.order_id
),
Store_Product_Quantity AS (
SELECT store_id,product_id,product_name,SUM(quantity) Total_Quantity
FROM Raw_Data
GROUP BY store_id,product_id,product_name
),
Product_Ranking AS (
SELECT 
	*,
	DENSE_RANK() OVER(PARTITION BY store_id ORDER BY Total_Quantity DESC) Ranking
FROM Store_Product_Quantity
)
SELECT 
	store_id,
	product_id,
	product_name,
	Total_Quantity
FROM Product_Ranking
WHERE Ranking = 1;

-- Question : 15
-- Calculate moving average of order value (last 3 orders per customer).

-- Question : 16
-- Find products whose price is above average within their category.

WITH Product_AvgPrice_Per_Category AS (
SELECT 
	*,
	AVG(list_price) OVER(PARTITION BY category_id) Average_Price
FROM production.products
)
SELECT 
	category_id,
	product_name,
	list_price,
	Average_Price
FROM Product_AvgPrice_Per_Category
WHERE list_price > Average_Price;

-- Question : 17
-- Calculate percentage contribution of each order to total store revenue.

WITH Raw_Data AS (
SELECT 
	store_id,
	ord.order_id,
	order_date,
	quantity,
	list_price,
	discount
FROM sales.orders ord 
JOIN sales.order_items ord_items
ON ord.order_id = ord_items.order_id
),
Order_Revenue AS (
SELECT 
	store_id,
	order_id,
	SUM(quantity * list_price * (1-discount)) Order_Revenue
FROM Raw_Data
GROUP BY store_id,order_id
),
Store_Revenue AS (
SELECT
	*,
	SUM(Order_Revenue) OVER(PARTITION BY store_id) Store_Revenue
FROM Order_Revenue
)
SELECT 
	*,
	(Order_Revenue/Store_Revenue) * 100 Order_Contribution
FROM Store_Revenue
ORDER BY store_id,order_id;

-- Question : 18
-- Find customers with a consistent daily ordering pattern (orders placed every month),
-- considering only customers who have placed more than one order.

WITH  RawData AS (
SELECT 
	cust.customer_id,
	order_id,
	first_name + ' ' + last_name CustomerName,
	order_date
FROM sales.orders ord
JOIN sales.customers cust
ON cust.customer_id = ord.customer_id
),
CustomerCount AS (
SELECT 
	customer_id,
	COUNT(customer_id) AS CustomerCount
FROM RawData
GROUP BY customer_id
HAVING COUNT(customer_id) > 1
),
FilteredData AS (
SELECT 
		raw_data.customer_id,
		order_id,
		CustomerName,
		order_date
FROM RawData raw_data
JOIN CustomerCount cust_count
ON raw_data.customer_id = cust_count.customer_id
),
Previous_Orders AS (
SELECT 
	*,
	LAG(order_date) OVER(PARTITION BY customer_id ORDER BY order_date) Prev_Order
FROM FilteredData
),
DATE_DIFF AS (
SELECT 
	*,
	DATEDIFF(MONTH,Prev_Order,order_date) Order_Days_Diff
FROM Previous_Orders
WHERE Prev_Order IS NOT NULL
)
SELECT 
	customer_id,
	CustomerName
FROM DATE_DIFF
GROUP BY customer_id,CustomerName
HAVING COUNT(*) = COUNT(CASE WHEN Order_Days_Diff = 1 THEN 1 END);

/*    "ANSWER VALIDATION"
SELECT 
	cust.customer_id,
	order_id,
	first_name + ' ' + last_name CustomerName,
	order_date
FROM sales.orders ord
JOIN sales.customers cust
ON cust.customer_id = ord.customer_id
WHERE cust.customer_id IN (35,109);
*/

-- Question : 19
-- Find first order and last order per customer using window functions.

/*        "My APPROACH Heavy Computation"
WITH RawData AS (
SELECT 
	cust.customer_id,
	order_id,
	first_name + ' ' + last_name CustomerName,
	order_date
FROM sales.orders ord
JOIN sales.customers cust
ON cust.customer_id = ord.customer_id
),
Fisrt_and_Last_Order AS (
SELECT 
	*,
	FIRST_VALUE(order_id) OVER(PARTITION BY customer_id ORDER BY order_date) FisrtOrder,
	LAST_VALUE(order_id) OVER(PARTITION BY customer_id ORDER BY order_date
		       ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) LastOrder
FROM RawData
),
Ranking AS (
SELECT 
	*,
	ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) Ranking
FROM Fisrt_and_Last_Order
)
SELECT
	customer_id,
	CustomerName,
	FisrtOrder,
	LastOrder
FROM Ranking
WHERE Ranking = 1;
*/

WITH OrdersWithRank AS (
    SELECT 
        cust.customer_id,
		first_name + ' ' + last_name CustomerName,
        ord.order_id,
        ord.order_date,
        MIN(ord.order_date) OVER (PARTITION BY cust.customer_id) AS first_date,
        MAX(ord.order_date) OVER (PARTITION BY cust.customer_id) AS last_date
    FROM sales.orders ord
    JOIN sales.customers cust
        ON cust.customer_id = ord.customer_id
)
SELECT 
    customer_id,
	CustomerName,
    MAX(CASE WHEN order_date = first_date THEN order_id END) AS first_order_id,
    MAX(CASE WHEN order_date = last_date THEN order_id END) AS last_order_id
FROM OrdersWithRank
GROUP BY customer_id,CustomerName
ORDER BY customer_id;

-- Question : 20
-- Identify gaps in order dates per customer

-- Question : 21
-- Find top 2 brands by total sales in each category.

-- Question : 22
-- Calculate running total of quantity sold per product.

-- Question : 23
-- Find orders where current order value > average of previous 3 orders.

-- Question : 24
-- Detect sudden spike in sales (order value > 2x previous order).

-- Question : 25
-- For each store, find top 5 customers contributing highest revenue percentage.
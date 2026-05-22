USE Interview_Prep;

-- top 3 salesman by Revenue.
WITH Raw_Data AS (
SELECT 
	name Salesman_Name,
	SUM(sale_amount) Total_Revenue
FROM Sales sal
JOIN Salesman sal_man
ON sal.salesman_id = sal_man.salesman_id
GROUP BY sal_man.salesman_id,sal_man.name
),
Rank_Customer AS (
SELECT *,
	   ROW_NUMBER() OVER(ORDER BY Total_Revenue DESC) Ranking
FROM Raw_Data
)
select 
	Salesman_Name,
	Total_Revenue
from Rank_Customer
WHERE Ranking <= 3;

-- Second Highest Salary
SELECT 
emp_id,
emp_name,
salary
FROM (
SELECT 
	emp_id,
	emp_name,
	salary,
	DENSE_RANK() OVER(ORDER BY salary DESC) Ranking
FROM Employee) x
WHERE x.Ranking = 2;

-- alternative approach
SELECT MAX(salary) Second_Highest_Salary
FROM Employee
WHERE salary < (SELECT MAX(salary) FROM Employee);

-- Employees earning more than their manager
SELECT
	emp.emp_name Emp_Name,
	mng.emp_name Manager_Name,
	emp.Salary Emp_Salary,
	mng.salary Mng_Salary
FROM Employee emp
JOIN Employee mng
ON emp.manager_id = mng.emp_id
WHERE emp.salary > mng.salary;

-- Department with highest average salary
SELECT *
FROM Department;

SELECT *
FROM Employee;

SELECT *
FROM (
SELECT department_id,AVG(salary) Average_Salary,Dense_Rank() OVER(ORDER BY AVG(salary) DESC) Ranking
FROM Employee
GROUP BY department_id
) x
WHERE x.Ranking = 1;

-- Customers who never ordered
SELECT *
FROM Customers cust
LEFT JOIN Orders ord
ON ord.customer_id = cust.customer_id
WHERE ord.customer_id IS NULL;

-- Duplicate records in a table
SELECT *
FROM (
SELECT *,
	   ROW_NUMBER() OVER(PARTITION BY order_id ORDER BY order_id) Ranking
FROM Orders) x
WHERE x.Ranking > 1;

-- Top selling product
WITH Raw_Data AS (
SELECT 
	prod.product_id,
	SUM(amount) Total_Amount
FROM Products prod
JOIN Orders ord
ON prod.product_id = ord.product_id
GROUP BY prod.product_id
),
Ranked_Products AS (
SELECT *,
	   DENSE_RANK() OVER(ORDER BY Total_Amount DESC) Ranking
FROM Raw_Data
)
SELECT 
	product_id,
	Total_Amount
FROM Ranked_Products
WHERE Ranking = 1;

-- Monthly sales trend
SELECT 
	YEAR(order_date) Order_Year,
	MONTH(order_date) Order_Month,
	SUM(amount) Sales
FROM Orders
GROUP BY MONTH(order_date),YEAR(order_date)
ORDER BY YEAR(order_date),MONTH(order_date);

-- Highest paid employee per department
WITH Ranked_Employees AS (
SELECT 
	department_id,
	emp_name,
	salary,
	DENSE_RANK() OVER(PARTITION BY department_id ORDER BY salary DESC) Ranking
FROM Employee
)
SELECT 
	department_id,
	emp_name,
	salary
FROM Ranked_Employees
WHERE Ranking = 1 ;

-- alternative approach
SELECT *
FROM Employee e
WHERE salary = (
SELECT MAX(salary) 
FROM Employee 
WHERE department_id = e.department_id
);

-- Find 3rd highest salary.
SELECT *
FROM (
SELECT 
	emp_id,
	emp_name,
	salary,
	DENSE_RANK() OVER(ORDER BY salary DESC) Ranking
FROM Employee
) x
WHERE x.Ranking = 3;

-- Customers who placed more than 5 orders**
SELECT 
	customer_id,
	COUNT(order_id) No_Of_Orders
FROM Orders
GROUP BY customer_id
HAVING COUNT(order_id) > 5;

-- Calculate Employee experience in years.
SELECT 
	emp_id,
	emp_name,
	DATEDIFF(YEAR,hire_date,CURRENT_DATE) Experience_In_Year
FROM Employee;

-- Products never sold(Find unsold products).
SELECT *
FROM Products prod
LEFT JOIN Orders ord
ON prod.product_id = ord.product_id
WHERE ord.product_id IS NULL;

-- Find departments with more than 10 employees.
SELECT 
	department_id,
	COUNT(emp_id) Employee_Count
FROM Employee
GROUP BY department_id
HAVING COUNT(emp_id) > 10;

-- 16. Find last 3 orders,Get latest 3 orders.
SELECT *
FROM (
SELECT 
	order_id,
	order_date,
	DENSE_RANK() OVER(ORDER BY order_date DESC) Ranking
FROM Orders
) x
WHERE x.Ranking <= 3;

-- 18. Highest order in each city**
SELECT *
FROM (
SELECT 
	cust.customer_id,
	city,
	order_id,
	DENSE_RANK() OVER(PARTITION BY city ORDER BY amount DESC) Ranking
FROM Customers cust
JOIN Orders ord
ON cust.customer_id = ord.customer_id
) x
WHERE x.Ranking = 1;

-- Employees hired in last 30 days,Find recent hires.
SELECT 
	emp_id,
	emp_name,
	hire_date
FROM Employee
WHERE hire_date >= DATEADD(DAY,-30,GETDATE());

-- Running total of sales,Compute cumulative sales over time.
SELECT 
	*,
	SUM(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) Cummulative_Sales
FROM Sales;

-- Moving average (last 3 days sales)
SELECT 
	*,
	AVG(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) Moving_Average_Last3Days
FROM Sales;

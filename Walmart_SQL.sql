select * from Walmart;
---------------------------------------------------------------
--DROP TABLE walmart;
--
---------------------------------------------------------------W

SELECT COUNT(*) FROM Walmart;

SELECT 
	 payment_method,
	 Count(*)
from Walmart
GROUP BY payment_method


SELECT COUNT(Distinct Branch)
from Walmart;
	
SELECT Max(quantity) from Walmart;
SELECT Min(quantity) from Walmart;

---------------------------------------------------------------
--Business Problems
--Q1.Find different payment method and number of transactions, number of qty sold.
---------------------------------------------------------------

SELECT 
	 payment_method,
	 Count(*) as no_payments,
	 Sum(quantity) as no_qty_sold
from Walmart
GROUP BY payment_method

---------------------------------------------------------------
--Q2.Identify the highest-rated category in each branch, displaying the branch, category, AVG rating
---------------------------------------------------------------

SELECT *
FROM
(
	SELECT 
		branch as Branches,
		category as Categories,
		AVG(rating) as Avg_rating,
		RANK() OVER(PARTITION BY branch ORDER BY AVG(rating) DESC) as Rank
	From Walmart
	GROUP BY 1,2
)
Where rank = 1

---------------------------------------------------------------
--Q3 Identity the busiest day for each branch base on the number of transactions
---------------------------------------------------------------

SELECT *
FROM
(SELECT
	branch,
	TO_CHAR(TO_DATE(date, 'DD/MM/YY'), 'Day') as Day_name,
	COUNT(*) as no_transactions,
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) as rank
FROM walmart
GROUP BY 1,2
)
where rank = 1


--Q4 Calculate the total quantity of items sold per payment method. List payment_method and total_qunatity.

SELECT 
	 payment_method,
	 --Count(*) as no_payments,
	 Sum(quantity) as no_qty_sold
from Walmart
GROUP BY payment_method

---------------------------------------------------------------
--Q5 
--Determine the average, minimum, and maximum rating of category for each city.
--List the city, average_rating, min_rating, and max_rating.
---------------------------------------------------------------
SELECT
	city,
	category,
	Min(rating) as Min_rating,
	Max(rating) as Max_rating,
	ROUND(AVG(rating):: NUMERIC, 2) as Avg_rating -- Added Round():: Numeric, 2 making the data cleaner 
	
FROM Walmart
GROUP BY 1, 2

---------------------------------------------------------------
-- Q6 
-- Calculate the total profit for each category by considering total_profit as
-- (Unit price * quantity * profit_margin).
-- List category and total_profit, ordered from highest to lowest profit
---------------------------------------------------------------
SELECT 
	category,
	ROUND(SUM(Total):: NUMERIC,2) as total_revenue,
	ROUND(SUM(total * profit_margin):: NUMERIC, 2) as Profit
FROM Walmart
GROUP BY 1

---------------------------------------------------------------
--Q7 
--Determine the most common payment method for each Branch. 
--Display Branch and the preferred_payment_method.
---------------------------------------------------------------
WITH CTE
AS
(
SELECT 
	branch,
	payment_method AS "Payment Method",
	COUNT(*) AS "Total trans",
	RANK() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS Rank -- added to find the rankings of total sales per payment method.
FROM Walmart
GROUP BY 1, 2
)

SELECT *
FROM CTE
WHERE Rank IN (1, 2);
---------------------------------------------------------------
--Q8
-- Categorize sales into 3 group MORNING, AFTERNOON, EVENING
-- Find out which of the shift and number of invoices
---------------------------------------------------------------
WITH CTE
AS
(
SELECT 
	branch,
CASE 
		WHEN EXTRACT (HOUR FROM (time::time)) < 12 THEN 'Morning' -- Need to use EXTRACT
		WHEN EXTRACT (HOUR FROM (time::time)) BETWEEN 12 AND 17 THEN 'Afternoon'
		ELSE 'Evening'
	END "TOD",
	COUNT(*) AS " Highest Sales",
	Rank() OVER(PARTITION BY branch ORDER BY COUNT(*) DESC) AS Rank -- added to find the rankings for the time of day.
FROM Walmart
GROUP BY 1, 2
ORDER BY 1, 3 DESC
)

SELECT * 
FROM CTE
WHERE Rank IN (1) -- add , and contine to see more rankings;

---------------------------------------------------------------
-- Q9
-- Identify 5 branch with highest decrese ratio in
-- Revenue compare to last year (current year 2023 and last year 2022)
-- Formula: (Last_rev - Current_Rev/Last_rev) * 100 = Ratio
---------------------------------------------------------------

SELECT *,
EXTRACT(YEAR FROM TO_DATE(Date, 'DD/MM/YY')) as Formatted_date
FROM walmart


--2022 Sales

WITH revenue_2022
AS
(
SELECT
	branch,
	SUM(Total) as revenue
From Walmart
WHERE EXTRACT(YEAR FROM TO_DATE(Date, 'DD/MM/YY')) = 2022 -- Postgre
-- WHERE YEAR(TO_DATE(date, 'DD'/MM/YY)) = 2022 -- MySQL
GROUP BY 1
),

revenue_2023
AS
(
SELECT
	branch,
	SUM(Total) as revenue
From Walmart
WHERE EXTRACT(YEAR FROM TO_DATE(Date, 'DD/MM/YY')) = 2023
GROUP BY 1
)

SELECT 
	LS.branch,
	LS.revenue as Last_year_revenue,
	CS.revenue as Current_Year_revenue,
	ROUND(
		(LS.revenue - CS.revenue)::NUMERIC /
		LS.revenue::Numeric* 100, 
		2) as "Rev_dec_ratio"
	FROM revenue_2022 as LS
	JOIN 
	revenue_2023 as CS
	ON LS.branch = CS.branch
WHERE LS.revenue > CS.revenue
ORDER BY 4 DESC
Limit 5;
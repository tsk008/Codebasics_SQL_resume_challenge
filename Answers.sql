1. SELECT DISTINCT market FROM gdb023.dim_customer 
WHERE region = "APAC" and customer = "Atliq Exclusive";
----------------------------------------------------------------------------------------------------------------------------------------------
2. WITH cte1 AS (
	SELECT COUNT(DISTINCT product_code) as Unique_product_2020,
		(SELECT COUNT(DISTINCT product_code) 
		FROM gdb023.fact_sales_monthly 
		WHERE fiscal_year = 2021) as Unique_product_2021
	FROM gdb023.fact_sales_monthly 
	WHERE fiscal_year = 2020)
    
SELECT cte1.*,
		ROUND(((Unique_product_2021-Unique_product_2020)/Unique_product_2020)*100,2) 
        as Percentage_change
FROM cte1;
----------------------------------------------------------------------------------------------------------------------------------------------
3. SELECT Segment,
	   COUNT(DISTINCT product_code) as Product_count 
FROM gdb023.dim_product
GROUP BY segment
ORDER BY product_count DESC;
----------------------------------------------------------------------------------------------------------------------------------------------
4. WITH cte1 AS (
		SELECT Segment,COUNT(DISTINCT product_code) as Product_count_2020
		FROM gdb023.dim_product P JOIN gdb023.fact_sales_monthly M
		USING(product_code)
		WHERE M.fiscal_year = 2020
		GROUP BY segment),
cte2 AS (
		SELECT Segment,COUNT(DISTINCT product_code) as Product_count_2021 
		FROM gdb023.dim_product P JOIN gdb023.fact_sales_monthly M
		USING(product_code)
		WHERE M.fiscal_year = 2021
		GROUP BY segment)      
SELECT 	cte1.Segment,
		cte1.Product_count_2020,
        cte2.Product_count_2021,
        (cte2.Product_count_2021-cte1.Product_count_2020) as Difference
FROM cte1 JOIN cte2 
USING (Segment)
ORDER BY Difference DESC;
----------------------------------------------------------------------------------------------------------------------------------------------
5.(SELECT	p.product_code,
		p.product,
        MAX(manufacturing_cost) as manufacturing_cost
FROM gdb023.fact_manufacturing_cost m JOIN gdb023.dim_product p
USING(product_code)
GROUP BY p.product_code
ORDER BY manufacturing_cost DESC
LIMIT 1)
UNION
(SELECT p.product_code,
		p.product,
        MIN(manufacturing_cost) as manufacturing_cost
FROM gdb023.fact_manufacturing_cost m JOIN gdb023.dim_product p
USING(product_code)
GROUP BY p.product_code
ORDER BY manufacturing_cost ASC
LIMIT 1);
----------------------------------------------------------------------------------------------------------------------------------------------
6. SELECT c.customer_code,
		c.customer,
        ROUND(AVG(d.pre_invoice_discount_pct)*100,2) as avg_discount_pct
FROM gdb023.dim_customer c JOIN gdb023.fact_pre_invoice_deductions d
USING(customer_code)
WHERE market = "India" AND d.fiscal_year = 2021
GROUP BY c.customer_code
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;
----------------------------------------------------------------------------------------------------------------------------------------------
7. SELECT s.fiscal_year,
		MONTH(s.date) as fiscal_Month,
		ROUND(SUM(s.sold_quantity*p.gross_price)/1000000,2) as Gross_sales_amt_mln
FROM fact_sales_monthly s 
JOIN fact_gross_price p
	ON s.product_code = p.product_code AND s.fiscal_year = p.fiscal_year
JOIN dim_customer c
	ON s.customer_code = c.customer_code 
GROUP BY fiscal_year,fiscal_Month
ORDER BY s.fiscal_year,fiscal_Month;
----------------------------------------------------------------------------------------------------------------------------------------------
8. SELECT CASE
		WHEN MONTH(date) IN (09,10,11) THEN "Q1"
		WHEN MONTH(date) IN (12,01,02) THEN "Q2"
		WHEN MONTH(date) IN (03,04,05) THEN "Q3"
		WHEN MONTH(date) IN (06,07,08) THEN "Q4"
	END as Quater,
        ROUND(SUM(sold_quantity)/1000000,2) as Total_sold_qty_mln
FROM gdb023.fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quater
ORDER BY Total_sold_qty_mln DESC; 
----------------------------------------------------------------------------------------------------------------------------------------------
9. WITH cte1 AS (
      SELECT c.channel,
      sum(s.sold_quantity * g.gross_price) AS gross_sales
  FROM fact_sales_monthly s 
  JOIN fact_gross_price g 
	ON s.product_code = g.product_code
  JOIN dim_customer c 
	ON s.customer_code = c.customer_code
  WHERE s.fiscal_year= 2021
  GROUP BY c.channel
  ORDER BY gross_sales DESC
)
SELECT 
  channel,
  round(gross_sales/1000000,2) AS gross_sales_mln,
  round(gross_sales/(sum(gross_sales) OVER())*100,2) AS pct 
FROM cte1 ;
----------------------------------------------------------------------------------------------------------------------------------------------
10. WITH cte1 AS (
    select division, 
    s.product_code, 
    sum(sold_quantity) AS total_sold_quantity,
    rank() OVER (partition by division order by sum(sold_quantity) desc) AS Top_3_ranks
 FROM
 fact_sales_monthly s
 JOIN dim_product p
 ON s.product_code = p.product_code
 WHERE fiscal_year = 2021
 GROUP BY product_code
)
SELECT * FROM cte1
WHERE Top_3_ranks IN (1,2,3);


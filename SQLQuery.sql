----1-INSPECTING VALUES
----*******************

SELECT * 
FROM sales_data_sample 
ORDER BY ORDERNUMBER asc

--2-CHECKING UNIQUE VALUE
--***********************

SELECT DISTINCT STATUS ----NICE ONE TO PLOT
FROM sales_data_sample

SELECT DISTINCT YEAR_ID ----
FROM sales_data_sample

SELECT DISTINCT PRODUCTLINE ----NICE TO PLOT
FROM sales_data_sample

SELECT DISTINCT COUNTRY -----NICE TO PLOT
FROM sales_data_sample

SELECT DISTINCT DEALSIZE ----NICE TO PLOT
FROM sales_data_sample

SELECT DISTINCT TERRITORY ----NICE TO PLOT
FROM sales_data_sample

-----------ANALYSIS
--------*************

--3-GROUPING SALES BY PRODUCT LINE
--********************************
 SELECT PRODUCTLINE,SUM(SALES) REVENUE
 FROM sales_data_sample
 GROUP BY PRODUCTLINE


 SELECT YEAR_ID,SUM(SALES) REVENUE
 FROM sales_data_sample 
 GROUP BY YEAR_ID
 ORDER BY 2 DESC

 SELECT DEALSIZE,SUM(SALES) REVENUE
 FROM sales_data_sample 
 GROUP BY DEALSIZE
 ORDER BY 2 DESC

--4-- WHAT WAS THE BEST MONTH FOR SALES IN A SPECIFIC YEAR?HOW MUCH EARNED THAT MONTH
--***********************************************************************************

SELECT MONTH_ID,SUM(SALES) REVENUE,COUNT(SALES)FREAQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2003
GROUP BY MONTH_ID
ORDER BY REVENUE DESC

SELECT MONTH_ID,SUM(SALES) REVENUE,COUNT(SALES)FREAQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2004
GROUP BY MONTH_ID
ORDER BY REVENUE DESC

SELECT MONTH_ID,SUM(SALES) REVENUE,COUNT(SALES)FREAQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2005
GROUP BY MONTH_ID
ORDER BY REVENUE DESC

SELECT MONTH_ID,PRODUCTLINE,SUM(SALES) REVENUE,COUNT(SALES)FREAQUENCY
FROM sales_data_sample
WHERE YEAR_ID = 2003 and MONTH_ID=11
GROUP BY MONTH_ID,PRODUCTLINE
ORDER BY REVENUE DESC

------5--WHO IS THE BEST CUSTOMER ??? 
------*******************************


DROP TABLE IF EXISTS #rfm
WITH RFM ----CTE
AS
(
	SELECT 
	CUSTOMERNAME,
	SUM(SALES) AS 'Monetary_Value',
	AVG(SALES)AS 'Averagemonetaryvalue',
	COUNT(ORDERNUMBER)AS 'Frequency',
	MAX(CONVERT(DATE,ORDERDATE)) AS'Lastorderdate',
	(SELECT MAX(CONVERT(DATE,ORDERDATE)) FROM sales_data_sample) AS 'Max order date',
	DATEDIFF(DD,MAX(CONVERT(DATE,ORDERDATE)),(SELECT MAX(CONVERT(DATE,ORDERDATE)) FROM sales_data_sample)) AS 'Recency'
	FROM sales_data_sample
	GROUP BY CUSTOMERNAME
),
rfm_c AS ----ANOTHER CTE
(
	SELECT *,
		NTILE(4) OVER (ORDER BY Recency desc) AS 'RFM_Recency', ---if we miss the 'desc' with recency output will change
		NTILE(4) OVER (ORDER BY Frequency) AS 'RFM_Frequency',
		NTILE(4) OVER (ORDER BY Monetary_Value) AS 'RFM_Monetary'
	FROM RFM 
)

SELECT 
*,[RFM_Recency]+[RFM_Monetary]+[RFM_Frequency] AS rfm_cell,
CAST([RFM_Recency] as varchar)+CAST(RFM_Frequency as varchar)+CAST(RFM_Monetary as varchar) as rfm_cell_string
INTO #rfm ---INSERTING INTO TEMP TABLE #rfm
FROM rfm_c

SELECT CUSTOMERNAME,RFM_Recency,RFM_Frequency,RFM_Monetary,
	CASE
		WHEN rfm_cell_string in(111,112,113,123,132,211,212,114,141) then 'Lost customer'
		WHEN rfm_cell_string in(133,134,143,244,334,344,144) then 'Slipping away,Cannot lose'
		WHEN rfm_cell_string in(311,411,331,421) then 'New customer'
		WHEN rfm_cell_string in(222,223,233,322) then 'Potential customer'
		WHEN rfm_cell_string in(323,333,321,422,332,432,221) then 'Active customer'
		WHEN rfm_cell_string in(433,434,443,444) then 'Loyal'
END rfm_segment		
FROM #rfm


--6--WHAT PRODUCT ARE MOST OFTEN SOLD TOGETHER?
--*********************************************

SELECT DISTINCT ORDERNUMBER,STUFF(

	(SELECT ','+ PRODUCTCODE
	FROM sales_data_sample p
	WHERE ORDERNUMBER IN
		(SELECT ORDERNUMBER ----THIS IS THE FIRST CODE IN THIS SET
		FROM (SELECT ORDERNUMBER,COUNT(*)RN
			FROM sales_data_sample
			WHERE STATUS='Shipped'
			GROUP BY ORDERNUMBER)m
		WHERE RN = 3)

    AND p.ORDERNUMBER = s.ORDERNUMBER
	FOR XML PATH(''))
	,1,1,'')

FROM sales_data_sample s
ORDER BY 2 DESC


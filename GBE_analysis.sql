--- OVERALL ANALYSIS
WITH CTE AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        MONTH(t1.Order_Date) AS Order_Month,
        DATEFROMPARTS(YEAR(t1.Order_Date), MONTH(t1.Order_Date), 1) AS Year_Month,
        t1.Order_Number AS Order_Number,
        t1.Quantity AS Quantity,
        t2.Unit_Price_USD AS Unit_Price_USD,
        t2.Unit_Cost_USD AS Unit_Cost_USD,
        t2.Category AS Category,
        t2.Subcategory AS Subcategory,
        t3.Country AS Country,
        CASE WHEN t1.StoreKey = 0 THEN 'Online' ELSE 'Offline' END AS Sales_Channel
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
), Ovr_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Order_Month,
        Year_Month,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * Unit_Price_USD * 1.00) - SUM(Quantity * Unit_Cost_USD * 1.00) AS Profit
    FROM CTE
    GROUP BY Order_Year, Order_Month, Year_Month
), Prev_Ovr_Revenue AS (
    SELECT
        *,
        LAG(Revenue) OVER (ORDER BY Order_Year) AS Prev_Revenue,
        LAG(Order_Volume) OVER (ORDER BY Order_Year) AS Prev_Order_Volume,
        LAG(Profit) OVER (ORDER BY Order_Year) AS Prev_Profit
    FROM Ovr_Seasonal_Trend
), Category_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Order_Month,
        Year_Month,
        Category,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM CTE
    GROUP BY Order_Year, Order_Month, Year_Month, Category
), Prev_Category_Revenue AS (
    SELECT
        Order_Year,
        Category,
        Revenue,
        LAG(Revenue) OVER (PARTITION BY Category ORDER BY Order_Year) AS Prev_Revenue
    FROM Category_Seasonal_Trend
), Subcategory_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Order_Month,
        Year_Month,
        Category,
        Subcategory,
        Sales_Channel,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * Unit_Price_USD * 1.00) - SUM(Quantity * Unit_Cost_USD * 1.00) AS Profit
    FROM CTE
    GROUP BY Order_Year, Order_Month, Year_Month, Category, Subcategory, Sales_Channel
), Location_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Order_Month,
        Year_Month,
        Country,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * Unit_Price_USD * 1.00) - SUM(Quantity * Unit_Cost_USD * 1.00) AS Profit
    FROM CTE
    GROUP BY Order_Year, Order_Month, Year_Month, Country
)

SELECT * FROM Subcategory_Seasonal_Trend
;

--- %YoY ANALYSIS
WITH YOY_Base AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        t1.Order_Number AS Order_Number,
        t1.Quantity AS Quantity,
        t1.StoreKey AS StoreKey,
        t2.Unit_Price_USD AS Unit_Price_USD,
        t2.Unit_Cost_USD AS Unit_Cost_USD,
        t2.Product_Name AS Product_Name,
        t2.Category AS Category,
        t2.Subcategory AS Subcategory,
        t2.Brand AS Brand,
        t3.Country AS Country,
        t3.Square_Meters AS Square_Meters
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
), Ovr_Seasonal_Trend AS (
    SELECT
        Order_Year,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * Unit_Price_USD * 1.00) - SUM(Quantity * Unit_Cost_USD * 1.00) AS Profit
    FROM YOY_Base
    GROUP BY Order_Year
), Prev_Ovr_Revenue AS (
    SELECT
        *,
        LAG(Revenue) OVER (ORDER BY Order_Year) AS Prev_Revenue,
        LAG(Order_Volume) OVER (ORDER BY Order_Year) AS Prev_Order_Volume,
        LAG(Profit) OVER (ORDER BY Order_Year) AS Prev_Profit
    FROM Ovr_Seasonal_Trend
), Category_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Category,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM YOY_Base
    -- WHERE StoreKey = 0
    GROUP BY Order_Year, Category
), Prev_Category_Revenue AS (
    SELECT
        Order_Year,
        Category,
        Revenue,
        LAG(Revenue) OVER (PARTITION BY Category ORDER BY Order_Year) AS Prev_Revenue
    FROM Category_Seasonal_Trend
), Subcategory_Seasonal_Trend AS (
    SELECT
        Order_Year,
        Category,
        Subcategory,
        Brand,
        Country,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM YOY_Base
    GROUP BY Order_Year, Category, Subcategory, Brand, Country
), Prev_Subcategory_Revenue AS (
    SELECT
        *,
        LAG(Order_Volume) OVER (PARTITION BY Subcategory ORDER BY Order_Year) AS Prev_Order_Volume,
        LAG(Revenue) OVER (PARTITION BY Subcategory ORDER BY Order_Year) AS Prev_Revenue,
        LAG(Profit) OVER (PARTITION BY Subcategory ORDER BY Order_Year) AS Prev_Profit
    FROM Subcategory_Seasonal_Trend
), Location_Seasonal_Trend AS (
    SELECT
        t1.Order_Year,
        t1.Country,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM YOY_Base t1
    GROUP BY t1.Order_Year, t1.Country
), Prev_Location_Revenue AS (
    SELECT
        Order_Year,
        Country,
        Revenue,
        LAG(Revenue) OVER (PARTITION BY Country ORDER BY Order_Year) AS Prev_Revenue
    FROM Location_Seasonal_Trend
), Brand_Revenue AS (
    SELECT
        Order_Year,
        Brand,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM YOY_Base
    GROUP BY Order_Year, Brand
), Prev_Brand_Revenue AS (
    SELECT
        *,
        LAG(Order_Volume) OVER (PARTITION BY Brand ORDER BY Order_Year) AS Prev_Order_Volume,
        LAG(Revenue) OVER (PARTITION BY Brand ORDER BY Order_Year) AS Prev_Revenue,
        LAG(Profit) OVER (PARTITION BY Brand ORDER BY Order_Year) AS Prev_Profit
    FROM Brand_Revenue
)

SELECT *,
    CASE WHEN Prev_Revenue > 0 THEN Revenue/Prev_Revenue - 1 ELSE 0 END AS YOY_Revenue_Growth,
    CASE WHEN Prev_Order_Volume > 0 THEN Order_Volume * 1.00/Prev_Order_Volume - 1 ELSE 0 END AS YOY_Order_Volume_Growth,
    CASE WHEN Prev_Profit > 0 THEN Profit/Prev_Profit - 1 ELSE 0 END AS YOY_Profit_Growth
FROM Prev_Brand_Revenue
;

--- TESTING
WITH YOY_Base AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        t1.Order_Number, t1.Quantity, t1.StoreKey,
        t2.Unit_Price_USD, t2.Unit_Cost_USD,
        t2.Category, t2.Subcategory, t2.Brand,
        t3.Country
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
),
Combined AS (
    SELECT 'Category' AS Dimension_Type, Category AS Dimension_Value, Order_Year,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM YOY_Base GROUP BY Category, Order_Year

    UNION ALL

    SELECT 'Subcategory', Subcategory, Order_Year,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM YOY_Base GROUP BY Subcategory, Order_Year

    UNION ALL

    SELECT 'Brand', Brand, Order_Year,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM YOY_Base GROUP BY Brand, Order_Year

    UNION ALL

    SELECT 'Location', Country, Order_Year,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM YOY_Base GROUP BY Country, Order_Year
)
SELECT * FROM Combined
ORDER BY Dimension_Type, Order_Year;


--- TESTING 2
WITH Base AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        MONTH(t1.Order_Date) AS Order_Month,
        DATEFROMPARTS(YEAR(t1.Order_Date), MONTH(t1.Order_Date), 1) AS Year_Month,
        t2.Category, t2.Subcategory, t2.Brand, t3.Country,
        t1.Order_Number, t1.Quantity, t2.Unit_Price_USD, t2.Unit_Cost_USD
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
),
Monthly AS (
    SELECT 'Category' AS Dimension_Type, Category AS Dimension_Value,
        Order_Year, Order_Month, Year_Month,
        COUNT(DISTINCT Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
    FROM Base GROUP BY Category, Order_Year, Order_Month, Year_Month

    UNION ALL

    SELECT 'Subcategory', Subcategory, Order_Year, Order_Month, Year_Month,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM Base GROUP BY Subcategory, Order_Year, Order_Month, Year_Month

    UNION ALL

    SELECT 'Brand', Brand, Order_Year, Order_Month, Year_Month,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM Base GROUP BY Brand, Order_Year, Order_Month, Year_Month

    UNION ALL

    SELECT 'Location', Country, Order_Year, Order_Month, Year_Month,
        COUNT(DISTINCT Order_Number),
        SUM(Quantity * Unit_Price_USD * 1.00),
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00)
    FROM Base GROUP BY Country, Order_Year, Order_Month, Year_Month
),
Yearly AS (
    SELECT Dimension_Type, Dimension_Value, Order_Year,
        SUM(Order_Volume) AS Order_Volume,
        SUM(Revenue) AS Revenue,
        SUM(Profit) AS Profit
    FROM Monthly
    GROUP BY Dimension_Type, Dimension_Value, Order_Year
),
Yearly_YoY AS (
    SELECT *,
        LAG(Revenue) OVER (
            PARTITION BY Dimension_Type, Dimension_Value ORDER BY Order_Year
        ) AS Prev_Revenue,
        LAG(Order_Volume) OVER (
            PARTITION BY Dimension_Type, Dimension_Value ORDER BY Order_Year
        ) AS Prev_Order_Volume,
        LAG(Profit) OVER (
            PARTITION BY Dimension_Type, Dimension_Value ORDER BY Order_Year
        ) AS Prev_Profit
    FROM Yearly
),
Monthly_YoY AS (
    SELECT *,
        LAG(Revenue) OVER (
            PARTITION BY Dimension_Type, Dimension_Value, Order_Month ORDER BY Order_Year
        ) AS Prev_Revenue_SamePeriod,
        LAG(Order_Volume) OVER (
            PARTITION BY Dimension_Type, Dimension_Value, Order_Month ORDER BY Order_Year
        ) AS Prev_Order_Volume_SamePeriod,
        LAG(Profit) OVER (
            PARTITION BY Dimension_Type, Dimension_Value, Order_Month ORDER BY Order_Year
        ) AS Prev_Profit_SamePeriod
    FROM Monthly
)

-- SELECT *,
--     CASE WHEN Prev_Revenue > 0 THEN Revenue / Prev_Revenue - 1 ELSE NULL END AS YOY_Revenue_Growth,
--     CASE WHEN Prev_Order_Volume > 0 THEN Order_Volume * 1.00 / Prev_Order_Volume - 1 ELSE NULL END AS YOY_Order_Volume_Growth,
--     CASE WHEN Prev_Profit > 0 THEN Profit / Prev_Profit - 1 ELSE NULL END AS YOY_Profit_Growth
-- FROM Yearly_YoY


SELECT
    Order_Year,
    Order_Month,
    Year_Month,
    COUNT(DISTINCT Order_Number) AS Order_Volume,
    SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
    SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
FROM Base
GROUP BY Order_Year, Order_Month, Year_Month
;   -- hoặc SELECT * FROM Monthly_YoY


--- OVERALL
SELECT
    YEAR(t1.Order_Date) AS Order_Year,
    MONTH(t1.Order_Date) AS Order_Month,
    DATEFROMPARTS(YEAR(t1.Order_Date), MONTH(t1.Order_Date), 1) AS Year_Month,
    COUNT(DISTINCT Order_Number) AS Order_Volume,
    SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
    SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit
FROM Base
GROUP BY Order_Year;



--- PRODUCT NAME
WITH product_name_stats AS (
    SELECT 
        YEAR(s.Order_Date) AS Order_Year,
        LEFT(p.Product_Name, LEN(p.Product_Name) - CHARINDEX(' ', REVERSE(p.Product_Name))) AS Product_Name_Clean,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue
    FROM GBE_Sales s
    JOIN GBE_Products p ON s.ProductKey = p.ProductKey  
    GROUP BY 
        YEAR(s.Order_Date),
        LEFT(p.Product_Name, LEN(p.Product_Name) - CHARINDEX(' ', REVERSE(p.Product_Name)))
),
CTE2 AS (
    SELECT *,
        LAG(Revenue) OVER (
            PARTITION BY Product_Name_Clean 
            ORDER BY Order_Year
        ) AS Prev_Revenue
    FROM product_name_stats
)
SELECT *,
    CASE WHEN Prev_Revenue > 0 THEN Revenue/Prev_Revenue - 1 ELSE 0 END AS YOY_Revenue_Growth
FROM CTE2
ORDER BY Product_Name_Clean, Order_Year
;


--- SALES CHANNEL ANALYSIS
WITH sales_channel_stats AS (
    SELECT
        YEAR(Order_Date) AS OrderYear,
        CASE WHEN t1.StoreKey = 0 THEN 'Online' ELSE 'Offline' END AS Sales_Channel,
        COUNT(DISTINCT t1.Order_Number) AS Order_Volume,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue,
        SUM(Quantity * (Unit_Price_USD - Unit_Cost_USD) * 1.00) AS Profit,
        SUM(Quantity * Unit_Price_USD * 1.00) / COUNT(DISTINCT Order_Number) AS AOV
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    GROUP BY CASE WHEN t1.StoreKey = 0 THEN 'Online' ELSE 'Offline' END, YEAR(Order_Date)
), prev_sales_channel AS (
    SELECT *,
        LAG(Revenue) OVER (PARTITION BY Sales_Channel ORDER BY OrderYear) AS Prev_Revenue,
        LAG(Order_Volume) OVER (PARTITION BY Sales_Channel ORDER BY OrderYear) AS Prev_Order_Volume,
        LAG(Profit) OVER (PARTITION BY Sales_Channel ORDER BY OrderYear) AS Prev_Profit
    FROM sales_channel_stats
)

SELECT *,
    CASE WHEN Prev_Revenue > 0 THEN Revenue/Prev_Revenue - 1 ELSE 0 END AS YoY_Revenue,
    CASE WHEN Prev_Order_Volume > 0 THEN Order_Volume * 1.00/Prev_Order_Volume - 1 ELSE 0 END AS YoY_Order_Volume,
    CASE WHEN Prev_Profit > 0 THEN Profit/Prev_Profit - 1 ELSE 0 END AS YoY_Profit
FROM prev_sales_channel
ORDER BY Sales_Channel, OrderYear
;


--- MONTHLY COHORT ANALYSIS
WITH first_purchase_month AS (
    SELECT
        t1.CustomerKey,
        MIN(DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)) AS First_Purchase_Month
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Customers t3 ON t1.CustomerKey = t3.CustomerKey
    WHERE t1.CustomerKey IS NOT NULL
    GROUP BY t1.CustomerKey
), current_purchase_stats AS (
    SELECT
        t1.CustomerKey,
        DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1) AS Purchase_Month,
        COUNT(DISTINCT t1.Order_Number) AS Order_Volume,
        SUM(Quantity) AS Quantity,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    WHERE t1.CustomerKey IS NOT NULL
    GROUP BY t1.CustomerKey, DATEFROMPARTS(YEAR(Order_Date), MONTH(Order_Date), 1)
), raw_cohort AS (
    SELECT
        t1.*,
        t2.First_Purchase_Month,
        DATEDIFF(MONTH, t2.First_Purchase_Month, t1.Purchase_Month) AS Month_Since_First_Purchase
    FROM current_purchase_stats t1
    LEFT JOIN first_purchase_month t2 ON t1.CustomerKey = t2.CustomerKey
), cohort_summary AS (
    SELECT
        First_Purchase_Month,
        Purchase_Month,
        Month_Since_First_Purchase,
        COUNT(DISTINCT CustomerKey) AS Total_Customers,
        SUM(Order_Volume) AS Total_Orders,
        SUM(Revenue) AS Total_Revenue
    FROM raw_cohort
    GROUP BY First_Purchase_Month, Purchase_Month, Month_Since_First_Purchase
)
SELECT
    t1.*,
    t2.Total_Customers AS start_value,
    t1.Total_Customers * 1.00 / t2.Total_Customers AS retention_rate
FROM cohort_summary t1
LEFT JOIN (
    SELECT *
    FROM cohort_summary
    WHERE Month_Since_First_Purchase = 0
) t2 ON t1.First_Purchase_Month = t2.First_Purchase_Month
WHERE t1.First_Purchase_Month >= '2018-01-01' AND t1.Purchase_Month <= '2018-12-31'
ORDER BY t1.First_Purchase_Month, t1.Month_Since_First_Purchase
;


--- QUARTERLY COHORT ANALYSIS
WITH first_purchase_quarter AS (
    SELECT
        t1.CustomerKey,
        MIN(DATEFROMPARTS(YEAR(Order_Date), ((DATEPART(QUARTER, Order_Date) - 1) * 3) + 1, 1)) AS First_Purchase_Quarter_Date
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Customers t3 ON t1.CustomerKey = t3.CustomerKey
    WHERE t1.CustomerKey IS NOT NULL
    GROUP BY t1.CustomerKey
), current_purchase_stats AS (
    SELECT
        t1.CustomerKey,
        DATEFROMPARTS(YEAR(Order_Date), ((DATEPART(QUARTER, Order_Date) - 1) * 3) + 1, 1) AS Purchase_Quarter_Date,
        COUNT(DISTINCT t1.Order_Number) AS Order_Volume,
        SUM(Quantity) AS Quantity,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Revenue
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    WHERE t1.CustomerKey IS NOT NULL
    GROUP BY t1.CustomerKey, DATEFROMPARTS(YEAR(Order_Date), ((DATEPART(QUARTER, Order_Date) - 1) * 3) + 1, 1)
), raw_cohort AS (
    SELECT
        t1.*,
        t2.First_Purchase_Quarter_Date,
        DATEDIFF(QUARTER, t2.First_Purchase_Quarter_Date, t1.Purchase_Quarter_Date) AS Quarter_Since_First_Purchase
    FROM current_purchase_stats t1
    LEFT JOIN first_purchase_quarter t2 ON t1.CustomerKey = t2.CustomerKey
), cohort_summary AS (
    SELECT
        First_Purchase_Quarter_Date,
        Purchase_Quarter_Date,
        Quarter_Since_First_Purchase,
        COUNT(DISTINCT CustomerKey) AS Total_Customers,
        SUM(Order_Volume) AS Total_Orders,
        SUM(Revenue) AS Total_Revenue
    FROM raw_cohort
    GROUP BY First_Purchase_Quarter_Date, Purchase_Quarter_Date, Quarter_Since_First_Purchase
)
SELECT
    CONCAT(YEAR(t1.First_Purchase_Quarter_Date), '-', 'Q', DATEPART(QUARTER, t1.First_Purchase_Quarter_Date)) AS First_Purchase_Quarter,
    CONCAT(YEAR(t1.Purchase_Quarter_Date), '-', 'Q', DATEPART(QUARTER, t1.Purchase_Quarter_Date)) AS Purchase_Quarter,
    t1.Quarter_Since_First_Purchase,
    t1.Total_Customers,
    t1.Total_Orders,
    t1.Total_Revenue,
    t2.Total_Customers AS start_value,
    t1.Total_Customers * 1.00 / t2.Total_Customers AS retention_rate
FROM cohort_summary t1
LEFT JOIN (
    SELECT *
    FROM cohort_summary
    WHERE Quarter_Since_First_Purchase = 0
) t2 ON t1.First_Purchase_Quarter_Date = t2.First_Purchase_Quarter_Date
ORDER BY t1.First_Purchase_Quarter_Date, t1.Quarter_Since_First_Purchase
;

--- RFM SEGMENTATION
WITH customer_stats_1 AS(
    SELECT
        t1.CustomerKey,
        MAX(t1.Order_Date) AS Lastest_Purchase_Date,
        COUNT(DISTINCT t1.Order_Number) AS Frequency,
        SUM(Quantity * Unit_Price_USD * 1.00) AS Monetary
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    GROUP BY t1.CustomerKey
), customer_stats_2 AS (
    SELECT
        CustomerKey,
        DATEDIFF(DAY, Lastest_Purchase_Date, (SELECT MAX(Lastest_Purchase_Date) FROM customer_stats_1)) AS Recency,
        Frequency,
        Monetary
    FROM customer_stats_1
), customer_stats_with_percentile AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY Recency DESC) AS R_pct,
        PERCENT_RANK() OVER (ORDER BY Frequency) AS F_pct,
        PERCENT_RANK() OVER (ORDER BY Monetary) AS M_pct
    FROM customer_stats_2
), customer_score AS (
    SELECT
        CustomerKey,
        Recency,
        CASE 
            WHEN R_pct <= 0.2 THEN 1
            WHEN R_pct <= 0.4 THEN 2
            WHEN R_pct <= 0.6 THEN 3
            WHEN R_pct <= 0.8 THEN 4
            ELSE 5
        END R_score,

        Frequency,
        CASE 
            WHEN F_pct <= 0.2 THEN 1
            WHEN F_pct <= 0.4 THEN 2
            WHEN F_pct <= 0.6 THEN 3
            WHEN F_pct <= 0.8 THEN 4
            ELSE 5
        END F_score,

        Monetary,
        CASE 
            WHEN M_pct <= 0.2 THEN 1
            WHEN M_pct <= 0.4 THEN 2
            WHEN M_pct <= 0.6 THEN 3
            WHEN M_pct <= 0.8 THEN 4
            ELSE 5
        END M_score
    FROM customer_stats_with_percentile
), RFM_score_final AS (
    SELECT *, CONCAT(R_score, F_score, M_score) AS RFM_Score
    FROM customer_score
)

SELECT *,
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 
            THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 
            THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2 AND M_score <= 2 
            THEN 'New Customers'
        WHEN R_score >= 3 AND F_score <= 2 
            THEN 'Promising'
        WHEN R_score = 3 AND F_score = 3 AND M_score <= 2 
            THEN 'Need Attention'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 4 
            THEN 'Cant Lose Them'
        WHEN R_score <= 2 AND F_score >= 3 
            THEN 'At Risk'
        WHEN R_score = 2 AND F_score <= 2 AND M_score <= 2 
            THEN 'About to Sleep'
        WHEN R_score = 1 AND F_score = 1 AND M_score = 1 
            THEN 'Lost'
        ELSE 'Others'
    END AS RFM_Segment
-- INTO dbo.GBE_RFM_temp
FROM RFM_score_final
ORDER BY RFM_Score DESC
;

SELECT RFM_Segment, COUNT(*) AS Customer_Count FROM GBE_RFM_temp
GROUP BY RFM_Segment

SELECT DISTINCT Country, COUNT(*) AS Customer_Count FROM GBE_Customers
GROUP BY Country
;

WITH Customer_Category AS (
    SELECT
        t1.CustomerKey,
        t2.Category,
        SUM(t1.Quantity * t2.Unit_Price_USD) AS Revenue
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    GROUP BY t1.CustomerKey, t2.Category
)
SELECT
    r.RFM_Segment,
    c.Category,
    SUM(c.Revenue) AS Revenue,
    COUNT(DISTINCT c.CustomerKey) AS Num_Customers
FROM GBE_RFM_temp r
LEFT JOIN Customer_Category c ON r.CustomerKey = c.CustomerKey
GROUP BY r.RFM_Segment, c.Category;

WITH Customer_Demo AS (
    SELECT
        CustomerKey,
        Gender,
        DATEDIFF(YEAR, Birthday, GETDATE()) AS Age,
        Country,
        State
    FROM GBE_Customers
)
SELECT
    t1.RFM_Segment,
    t2.Gender,
    t2.Country,
    CASE 
        WHEN t2.Age < 26 THEN '18-25'
        WHEN t2.Age < 36 THEN '26-35'
        WHEN t2.Age < 51 THEN '36-50'
        ELSE '50+'
    END AS Age_Group,
    COUNT(DISTINCT t1.CustomerKey) AS Num_Customers
FROM GBE_RFM_temp t1
LEFT JOIN Customer_Demo t2 ON t1.CustomerKey = t2.CustomerKey
GROUP BY t1.RFM_Segment, t2.Gender, t2.Country,
    CASE 
        WHEN t2.Age < 26 THEN '18-25'
        WHEN t2.Age < 36 THEN '26-35'
        WHEN t2.Age < 51 THEN '36-50'
        ELSE '50+'
    END
;


--- LOCATION ANALYSIS
WITH Store_Area_by_Country AS (
    SELECT
        Country,
        SUM(Square_Meters) AS Total_Sqm
    FROM GBE_Stores
    GROUP BY Country
), Sales_by_Country_Year AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        t3.Country AS Country,
        COUNT(DISTINCT t1.Order_Number) AS Order_Volume,
        SUM(t1.Quantity * t2.Unit_Price_USD * 1.00) AS Revenue,
        SUM(t1.Quantity * (t2.Unit_Price_USD - t2.Unit_Cost_USD) * 1.00) AS Profit
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
    GROUP BY YEAR(t1.Order_Date), t3.Country
)
SELECT
    s.*,
    a.Total_Sqm,
    s.Revenue / a.Total_Sqm AS Revenue_per_sqm
FROM Sales_by_Country_Year s
LEFT JOIN Store_Area_by_Country a ON s.Country = a.Country
ORDER BY s.Country, s.Order_Year;



WITH C AS (
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        t3.Country AS Country,
        COUNT(DISTINCT t1.Order_Number) AS Order_Volume,
        SUM(t1.Quantity * t2.Unit_Price_USD * 1.00) AS Revenue,
        SUM(t1.Quantity * (t2.Unit_Price_USD - t2.Unit_Cost_USD) * 1.00) AS Profit
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
    GROUP BY YEAR(t1.Order_Date), t3.Country
), D AS (
    SELECT Country, SUM(Square_Meters) AS Square_Meters
    FROM GBE_Stores
    GROUP BY Country
)
SELECT
    C.*,
    D.Square_Meters,
    C.Revenue / D.Square_Meters AS Revenue_per_sqm
FROM C
LEFT JOIN D ON C.Country = D.Country;


--- DELIVERY TIME ANALYSIS
WITH delivery_time_stats AS(
    SELECT
        YEAR(t1.Order_Date) AS Order_Year,
        DATEFROMPARTS(YEAR(t1.Order_Date), MONTH(t1.Order_Date), 1) AS Year_Month,
        t2.Category AS Category,
        t3.Country AS Country,
        DATEDIFF(DAY, t1.Order_Date, t1.Delivery_Date) * 1.00 AS Delivery_Time
    FROM GBE_Sales t1
    LEFT JOIN GBE_Products t2 ON t1.ProductKey = t2.ProductKey
    LEFT JOIN GBE_Customers t3 ON t1.CustomerKey = t3.CustomerKey
    WHERE t1.StoreKey = 0 AND t1.Delivery_Date IS NOT NULL AND t1.Delivery_Date > t1.Order_Date
)

SELECT 
    Order_Year,
    Country,
    AVG(Delivery_Time) AS Monthly_Avg_Delivery_Time,
    AVG(AVG(Delivery_Time)) OVER (PARTITION BY Order_Year) AS Yearly_Benchmark,
    (SELECT AVG(Delivery_Time) FROM delivery_time_stats) AS Overall_Avg_Delivery_Time
FROM delivery_time_stats
GROUP BY Order_Year, Country
ORDER BY Order_Year
;


--- CUSTOMER ANALYSIS
WITH First_Purchase_by_Country AS (
    SELECT
        t1.CustomerKey,
        t3.Country,
        MIN(YEAR(t1.Order_Date)) AS First_Year_in_Country
    FROM GBE_Sales t1
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
    WHERE t3.Country <> 'Online'
    GROUP BY t1.CustomerKey, t3.Country
), Customer_Type_Base AS (
    SELECT
        t1.Order_Number,
        t3.Country,
        YEAR(t1.Order_Date) AS Order_Year,
        fp.First_Year_in_Country,
        CASE 
            WHEN YEAR(t1.Order_Date) = fp.First_Year_in_Country THEN 'New'
            ELSE 'Returning'
        END AS Cust_Type
    FROM GBE_Sales t1
    LEFT JOIN GBE_Stores t3 ON t1.StoreKey = t3.StoreKey
    LEFT JOIN First_Purchase_by_Country fp 
        ON t1.CustomerKey = fp.CustomerKey AND t3.Country = fp.Country
    WHERE t3.Country <> 'Online'
), Order_Volume_by_Type AS (
    SELECT
        Country,
        Cust_Type,
        COUNT(DISTINCT Order_Number) AS Order_Volume
    FROM Customer_Type_Base
    GROUP BY Country, Cust_Type
)
SELECT
    Country,
    SUM(CASE WHEN Cust_Type = 'New' THEN Order_Volume ELSE 0 END) AS New_Orders,
    SUM(CASE WHEN Cust_Type = 'Returning' THEN Order_Volume ELSE 0 END) AS Returning_Orders,
    ROUND(
        SUM(CASE WHEN Cust_Type = 'New' THEN Order_Volume ELSE 0 END) * 100.0 
        / SUM(Order_Volume), 1
    ) AS Pct_New
FROM Order_Volume_by_Type
GROUP BY Country
ORDER BY Pct_New DESC;


SELECT TOP 1000 *
FROM GBE_Sales
;

SELECT TOP 1000 *
FROM GBE_Customers
;


SELECT TOP 1000 *
FROM GBE_Exchange_Rates
;

SELECT TOP 1000 *
FROM GBE_Products
;

SELECT TOP 1000 *
FROM GBE_Sales
;

SELECT TOP 1000 *
FROM GBE_Stores
;

SELECT DISTINCT 
    RIGHT(Product_Name, CHARINDEX(' ', REVERSE(Product_Name)) - 1) AS Last_Word
FROM GBE_Products
ORDER BY Last_Word;

SELECT
    t3.*
FROM GBE_Sales t1
LEFT JOIN GBE_Stores t2 ON t1.StoreKey = t2.StoreKey
LEFT JOIN GBE_Customers t3 ON t1.CustomerKey = t3.CustomerKey
WHERE t2.StoreKey = 0
;


SELECT DISTINCT
    Category,       
    Subcategory,
    Brand,
    LEFT(Product_Name, LEN(Product_Name) - CHARINDEX(' ', REVERSE(Product_Name))) AS Product_Name_Clean
FROM GBE_Products

SELECT LEFT(Product_Name, LEN(Product_Name) - CHARINDEX(' ', REVERSE(Product_Name))) AS Product_Name_Clean
FROM GBE_Products;
SELECT *
FROM GBE_Sales
LEFT JOIN GBE_Products ON GBE_Sales.ProductKey = GBE_Products.ProductKey
LEFT JOIN GBE_Stores ON GBE_Sales.StoreKey = GBE_Stores.StoreKey
;
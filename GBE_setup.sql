------------------------------------------------------------
-- 1) DIM_DATE — bắt buộc phải có cho mọi phân tích theo thời gian
--    (seasonal trend, YoY, delivery time trend...)
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Dim_Date AS
WITH Bounds AS (
    SELECT
        MIN(Order_Date) AS MinDate,
        MAX(COALESCE(Delivery_Date, Order_Date)) AS MaxDate
    FROM dbo.GBE_Sales
),
Seq AS (
    SELECT TOP (DATEDIFF(DAY, (SELECT MinDate FROM Bounds), (SELECT MaxDate FROM Bounds)) + 1)
        DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) - 1, (SELECT MinDate FROM Bounds)) AS [Date]
    FROM sys.all_objects a CROSS JOIN sys.all_objects b
)
SELECT
    [Date],
    YEAR([Date])                              AS [Year],
    MONTH([Date])                             AS [MonthNum],
    DATENAME(MONTH, [Date])                   AS [MonthName],
    DATEFROMPARTS(YEAR([Date]), MONTH([Date]), 1) AS [YearMonth],
    DATEPART(QUARTER, [Date])                 AS [Quarter],
    CONCAT('Q', DATEPART(QUARTER, [Date]), '-', YEAR([Date])) AS [YearQuarter],
    DATENAME(WEEKDAY, [Date])                 AS [WeekdayName]
FROM Seq;
GO

------------------------------------------------------------
-- 2) DIM_PRODUCTS
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Dim_Products AS
SELECT
    ProductKey,
    Product_Name,
    Brand,
    Color,
    Category,
    Subcategory,
    Unit_Cost_USD,
    Unit_Price_USD
FROM dbo.GBE_Products;
GO

------------------------------------------------------------
-- 3) DIM_STORES  (StoreKey = 0 -> 'Online', tự thêm 1 dòng ảo)
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Dim_Stores AS
SELECT
    StoreKey,
    Country,
    State,
    Square_Meters,
    Open_Date,
    CASE WHEN StoreKey = 0 THEN 'Online' ELSE 'Offline' END AS Store_Type
FROM dbo.GBE_Stores
UNION ALL
SELECT 0, 'Online', NULL, NULL, NULL, 'Online'
WHERE NOT EXISTS (SELECT 1 FROM dbo.GBE_Stores WHERE StoreKey = 0);
GO

------------------------------------------------------------
-- 4) DIM_CUSTOMERS — kèm Age_Group tĩnh (đã chốt theo ngày chạy view)
--    Age dùng để group, còn "tuổi chính xác" nên tính bằng DAX
--    nếu bạn cần refresh linh hoạt theo TODAY().
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Dim_Customers AS
SELECT
    CustomerKey,
    Gender,
    Name,
    City,
    State,
    Country,
    Continent,
    Birthday,
    DATEDIFF(YEAR, Birthday, GETDATE())
        - CASE WHEN DATEADD(YEAR, DATEDIFF(YEAR, Birthday, GETDATE()), Birthday) > GETDATE()
               THEN 1 ELSE 0 END AS Age,
    CASE
        WHEN DATEDIFF(YEAR, Birthday, GETDATE()) < 26 THEN '18-25'
        WHEN DATEDIFF(YEAR, Birthday, GETDATE()) < 36 THEN '26-35'
        WHEN DATEDIFF(YEAR, Birthday, GETDATE()) < 51 THEN '36-50'
        ELSE '50+'
    END AS Age_Group
FROM dbo.GBE_Customers;
GO

------------------------------------------------------------
-- 5) FACT_SALES — mức chi tiết từng dòng đơn hàng, KHÔNG group.
--    Revenue/Cost/Profit tính sẵn ở đây cho gọn, còn Order_Volume
--    (distinct order count) để Power BI tự COUNT DISTINCT bằng DAX.
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Fact_Sales AS
SELECT
    s.Order_Number,
    s.Order_Date,
    s.Delivery_Date,
    s.CustomerKey,
    s.StoreKey,
    s.ProductKey,
    s.Quantity,
    p.Unit_Price_USD,
    p.Unit_Cost_USD,
    CAST(s.Quantity * p.Unit_Price_USD AS DECIMAL(18,2)) AS Revenue,
    CAST(s.Quantity * p.Unit_Cost_USD  AS DECIMAL(18,2)) AS Cost,
    CAST(s.Quantity * (p.Unit_Price_USD - p.Unit_Cost_USD) AS DECIMAL(18,2)) AS Profit,
    CASE WHEN s.StoreKey = 0 THEN 'Online' ELSE 'Offline' END AS Sales_Channel,
    CASE WHEN s.StoreKey = 0 AND s.Delivery_Date IS NOT NULL AND s.Delivery_Date > s.Order_Date
         THEN DATEDIFF(DAY, s.Order_Date, s.Delivery_Date) END AS Delivery_Time_Days
FROM dbo.GBE_Sales s
LEFT JOIN dbo.GBE_Products p ON s.ProductKey = p.ProductKey;
GO

------------------------------------------------------------
-- 6) CUSTOMER_RFM — tính 1 lần ở mức customer, join 1-1 vào
--    Dim_Customers bên Power BI (KHÔNG group thêm gì nữa ở đây).
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Customer_RFM AS
WITH Stats1 AS (
    SELECT
        s.CustomerKey,
        MAX(s.Order_Date) AS Latest_Purchase_Date,
        COUNT(DISTINCT s.Order_Number) AS Frequency,
        SUM(s.Quantity * p.Unit_Price_USD * 1.00) AS Monetary
    FROM dbo.GBE_Sales s
    LEFT JOIN dbo.GBE_Products p ON s.ProductKey = p.ProductKey
    GROUP BY s.CustomerKey
),
Stats2 AS (
    SELECT
        CustomerKey,
        DATEDIFF(DAY, Latest_Purchase_Date, (SELECT MAX(Latest_Purchase_Date) FROM Stats1)) AS Recency,
        Frequency,
        Monetary
    FROM Stats1
),
Pct AS (
    SELECT *,
        PERCENT_RANK() OVER (ORDER BY Recency DESC) AS R_pct,
        PERCENT_RANK() OVER (ORDER BY Frequency)     AS F_pct,
        PERCENT_RANK() OVER (ORDER BY Monetary)      AS M_pct
    FROM Stats2
),
Score AS (
    SELECT
        CustomerKey, Recency, Frequency, Monetary,
        CASE WHEN R_pct<=0.2 THEN 1 WHEN R_pct<=0.4 THEN 2 WHEN R_pct<=0.6 THEN 3 WHEN R_pct<=0.8 THEN 4 ELSE 5 END AS R_score,
        CASE WHEN F_pct<=0.2 THEN 1 WHEN F_pct<=0.4 THEN 2 WHEN F_pct<=0.6 THEN 3 WHEN F_pct<=0.8 THEN 4 ELSE 5 END AS F_score,
        CASE WHEN M_pct<=0.2 THEN 1 WHEN M_pct<=0.4 THEN 2 WHEN M_pct<=0.6 THEN 3 WHEN M_pct<=0.8 THEN 4 ELSE 5 END AS M_score
    FROM Pct
)
SELECT *,
    CONCAT(R_score, F_score, M_score) AS RFM_Score,
    CASE
        WHEN R_score >= 4 AND F_score >= 4 AND M_score >= 4 THEN 'Champions'
        WHEN R_score >= 3 AND F_score >= 3 AND M_score >= 3 THEN 'Loyal Customers'
        WHEN R_score >= 4 AND F_score <= 2 AND M_score <= 2 THEN 'New Customers'
        WHEN R_score >= 3 AND F_score <= 2                  THEN 'Promising'
        WHEN R_score = 3 AND F_score = 3 AND M_score <= 2   THEN 'Need Attention'
        WHEN R_score <= 2 AND F_score >= 3 AND M_score >= 4 THEN 'Cant Lose Them'
        WHEN R_score <= 2 AND F_score >= 3                  THEN 'At Risk'
        WHEN R_score = 2 AND F_score <= 2 AND M_score <= 2  THEN 'About to Sleep'
        WHEN R_score = 1 AND F_score = 1 AND M_score = 1    THEN 'Lost'
        ELSE 'Others'
    END AS RFM_Segment
FROM Score;
GO

------------------------------------------------------------
-- 7) COHORT_RETENTION (theo tháng) — nên tính sẵn trong SQL vì
--    logic self-join theo period phức tạp, DAX sẽ rất nặng.
------------------------------------------------------------
CREATE OR ALTER VIEW dbo.vw_Cohort_Retention AS
WITH Cust_Orders AS (
    SELECT
        s.CustomerKey,
        s.Order_Number,
        DATEFROMPARTS(YEAR(s.Order_Date), (DATEPART(QUARTER, s.Order_Date) - 1) * 3 + 1, 1) AS Order_Quarter
    FROM dbo.GBE_Sales s
),
First_Purchase AS (
    SELECT CustomerKey, MIN(Order_Quarter) AS Cohort_Quarter
    FROM Cust_Orders
    GROUP BY CustomerKey
),
Cohort_Base AS (
    SELECT
        f.Cohort_Quarter,
        c.Order_Quarter,
        DATEDIFF(QUARTER, f.Cohort_Quarter, c.Order_Quarter) AS Quarter_Number,
        c.CustomerKey,
        c.Order_Number
    FROM Cust_Orders c
    JOIN First_Purchase f ON c.CustomerKey = f.CustomerKey
),
Cohort_Agg AS (
    SELECT
        Cohort_Quarter,
        Quarter_Number,
        COUNT(DISTINCT CustomerKey) AS Active_Customers,
        COUNT(DISTINCT Order_Number) AS Orders
    FROM Cohort_Base
    GROUP BY Cohort_Quarter, Quarter_Number
),
Cohort_Size AS (
    SELECT Cohort_Quarter, Active_Customers AS Cohort_Size
    FROM Cohort_Agg WHERE Quarter_Number = 0
)
SELECT
    a.Cohort_Quarter,
    YEAR(a.Cohort_Quarter) AS Cohort_Year,
    CONCAT('Q', DATEPART(QUARTER, a.Cohort_Quarter), '-', YEAR(a.Cohort_Quarter)) AS Cohort_Quarter_Label,
    a.Quarter_Number,
    a.Active_Customers,
    a.Orders,
    s.Cohort_Size,
    CAST(a.Active_Customers AS FLOAT) / s.Cohort_Size AS Retention_Rate
FROM Cohort_Agg a
JOIN Cohort_Size s ON a.Cohort_Quarter = s.Cohort_Quarter;
GO


SELECT COUNT(DISTINCT CustomerKey) AS Total_Customers FROM dbo.vw_Dim_Customers;

SELECT RFM_Segment, COUNT(*) AS Customer_Count
FROM dbo.vw_Customer_RFM
GROUP BY RFM_Segment
ORDER BY Customer_Count DESC;
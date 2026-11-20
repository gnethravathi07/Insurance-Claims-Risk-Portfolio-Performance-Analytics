-- Step 6.1 — Overall Insurance Portfolio KPIs

USE insurance_claims_analytics;

SELECT
    COUNT(*) AS Total_Policies,
    COUNT(DISTINCT Customer_ID) AS Insured_Customers,
    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium,
    ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium,
    ROUND(SUM(Coverage_Amount), 2) AS Total_Coverage_Amount,
    ROUND(AVG(Coverage_Amount), 2) AS Avg_Coverage_Amount
FROM policies;

-- Step 6.2 — Policy Distribution by Insurance Type

SELECT
    Policy_Type,
    COUNT(*) AS Total_Policies,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,
    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium,
    ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium,
    ROUND(SUM(Coverage_Amount), 2) AS Total_Coverage
FROM policies
GROUP BY Policy_Type
ORDER BY Total_Policies DESC;

-- Step 6.3 — Policy Status Distribution

SELECT
    Policy_Status,
    COUNT(*) AS Total_Policies,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,
    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium,
    ROUND(SUM(Coverage_Amount), 2) AS Total_Coverage
FROM policies
GROUP BY Policy_Status
ORDER BY Total_Policies DESC;

-- Step 6.4 — Actual Policy Coverage Status

SELECT
    CASE
        WHEN '2026-09-30' < Start_Date
            THEN 'Not Yet Started'
        WHEN '2026-09-30' > End_Date
            THEN 'Coverage Ended'
        ELSE 'Within Coverage Period'
    END AS Coverage_Status,

    COUNT(*) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,

    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium

FROM policies

GROUP BY Coverage_Status

ORDER BY Total_Policies DESC;

-- Step 6.5 — Identify Active Policies Past Expiry

SELECT
    COUNT(*) AS Active_Past_Expiry,
    ROUND(SUM(Annual_Premium), 2) AS Annual_Premium_Amount,
    ROUND(SUM(Coverage_Amount), 2) AS Coverage_Amount
FROM policies
WHERE Policy_Status = 'Active'
  AND End_Date < '2026-09-30';
  
-- Step 6.6 — Identify Expired Policies Before End Date

SELECT
    COUNT(*) AS Expired_Before_End_Date,
    ROUND(SUM(Annual_Premium), 2) AS Annual_Premium_Amount,
    ROUND(SUM(Coverage_Amount), 2) AS Coverage_Amount
FROM policies
WHERE Policy_Status = 'Expired'
  AND End_Date > '2026-09-30';
  
-- Step 6.7 — Policy Status Consistency Analysis

WITH Policy_Check AS (
    SELECT
        Policy_ID,
        Policy_Status,
        Annual_Premium,
        CASE
            WHEN Policy_Status = 'Active'
                 AND End_Date < '2026-09-30'
                THEN 'Active Past Expiry'

            WHEN Policy_Status = 'Expired'
                 AND End_Date > '2026-09-30'
                THEN 'Expired Before End Date'

            ELSE 'No Flagged Mismatch'
        END AS Validation_Status
    FROM policies
)

SELECT
    Validation_Status,
    COUNT(*) AS Total_Policies,
    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Policy_Share_Pct,
    ROUND(SUM(Annual_Premium), 2) AS Annual_Premium
FROM Policy_Check
GROUP BY Validation_Status
ORDER BY Total_Policies DESC;


-- Step 6.8 — Policy Performance by Type and Status

SELECT
    Policy_Type,

    COUNT(*) AS Total_Policies,

    SUM(CASE
        WHEN Policy_Status = 'Active' THEN 1
        ELSE 0
    END) AS Active_Policies,

    SUM(CASE
        WHEN Policy_Status = 'Expired' THEN 1
        ELSE 0
    END) AS Expired_Policies,

    SUM(CASE
        WHEN Policy_Status = 'Cancelled' THEN 1
        ELSE 0
    END) AS Cancelled_Policies,

    ROUND(
        SUM(CASE
            WHEN Policy_Status = 'Active' THEN 1
            ELSE 0
        END) * 100.0 / COUNT(*),
        2
    ) AS Active_Rate_Pct,

    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium

FROM policies

GROUP BY Policy_Type

ORDER BY Total_Policies DESC;


-- Step 6.9 — Policy Cancellation Rate Analysis

WITH Cancellation_Analysis AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Total_Policies,

        SUM(
            CASE
                WHEN Policy_Status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) AS Cancelled_Policies

    FROM policies
    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Cancelled_Policies * 100.0 / Total_Policies,
        2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Policies * 1.0 / Total_Policies DESC
    ) AS Cancellation_Rank

FROM Cancellation_Analysis
ORDER BY Cancellation_Rank;


-- Step 6.10 — Annual Premium Contribution by Policy Type

WITH Premium_Analysis AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Total_Policies,
        ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium
    FROM policies
    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,
    Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        SUM(Total_Annual_Premium) OVER (),
        2
    ) AS Premium_Contribution_Pct,

    ROUND(
        SUM(Total_Annual_Premium) OVER (
            ORDER BY Total_Annual_Premium DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        ) * 100.0 /
        SUM(Total_Annual_Premium) OVER (),
        2
    ) AS Cumulative_Premium_Pct

FROM Premium_Analysis
ORDER BY Total_Annual_Premium DESC;


-- Step 6.11 — Customer Policy Holding Analysis

WITH Customer_Policies AS (
    SELECT
        Customer_ID,
        COUNT(*) AS Policy_Count
    FROM policies
    GROUP BY Customer_ID
)

SELECT
    CASE
        WHEN Policy_Count = 1 THEN 'Single Policy'
        ELSE 'Multiple Policies'
    END AS Customer_Segment,

    COUNT(*) AS Total_Customers,

    SUM(Policy_Count) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Customer_Share_Pct

FROM Customer_Policies

GROUP BY Customer_Segment

ORDER BY Total_Customers DESC;


-- Step 6.12 — Top 10 Customers by Annual Premium

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Region,
        COUNT(p.Policy_ID) AS Total_Policies,
        ROUND(SUM(p.Annual_Premium), 2) AS Total_Annual_Premium,
        ROUND(SUM(p.Coverage_Amount), 2) AS Total_Coverage

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Region
)

SELECT
    Customer_ID,
    Region,
    Total_Policies,
    Total_Annual_Premium,
    Total_Coverage,

    DENSE_RANK() OVER (
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Customer_Portfolio

ORDER BY
    Total_Annual_Premium DESC,
    Customer_ID

LIMIT 10;


-- Step 6.13 — Regional Insurance Portfolio Performance

WITH Regional_Portfolio AS (
    SELECT
        c.Region,
        COUNT(p.Policy_ID) AS Total_Policies,
        COUNT(DISTINCT c.Customer_ID) AS Insured_Customers,

        SUM(
            CASE
                WHEN p.Policy_Status = 'Active' THEN 1
                ELSE 0
            END
        ) AS Active_Policies,

        ROUND(SUM(p.Annual_Premium), 2) AS Total_Annual_Premium

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Region
)

SELECT
    Region,
    Total_Policies,
    Insured_Customers,
    Active_Policies,

    ROUND(
        Active_Policies * 100.0 / Total_Policies,
        2
    ) AS Recorded_Active_Rate_Pct,

    Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        SUM(Total_Annual_Premium) OVER (),
        2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY Total_Annual_Premium DESC
    ) AS Regional_Rank

FROM Regional_Portfolio

ORDER BY Regional_Rank;

-- Step 6.14 — Regional Customer Insurance Penetration

WITH Customer_Coverage AS (
    SELECT
        c.Customer_ID,
        c.Region,
        COUNT(p.Policy_ID) AS Policy_Count
    FROM customers c
    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID
    GROUP BY
        c.Customer_ID,
        c.Region
)

SELECT
    Region,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE
            WHEN Policy_Count > 0 THEN 1
            ELSE 0
        END
    ) AS Insured_Customers,

    SUM(
        CASE
            WHEN Policy_Count = 0 THEN 1
            ELSE 0
        END
    ) AS Uninsured_Customers,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Count > 0 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Insurance_Penetration_Pct

FROM Customer_Coverage
GROUP BY Region
ORDER BY Insurance_Penetration_Pct DESC;


-- Step 6.15 — Insurance Portfolio by Customer Age Group

WITH Age_Portfolio AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(DISTINCT c.Customer_ID) AS Insured_Customers,
        COUNT(p.Policy_ID) AS Total_Policies,
        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Insured_Customers,
    Total_Policies,

    ROUND(Total_Annual_Premium, 2) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        SUM(Total_Annual_Premium) OVER (),
        2
    ) AS Premium_Contribution_Pct

FROM Age_Portfolio

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;
    
-- Step 6.16 — Insurance Product Preference by Age Group

WITH Age_Policy_Analysis AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        p.Policy_Type,
        COUNT(*) AS Total_Policies

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY Age_Group, p.Policy_Type
)

SELECT
    Age_Group,
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (
            PARTITION BY Age_Group
        ),
        2
    ) AS Age_Group_Policy_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Age_Group
        ORDER BY Total_Policies DESC
    ) AS Product_Rank

FROM Age_Policy_Analysis

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END,
    Product_Rank;
    
    
-- Step 6.17 — Annual Premium Trend by Policy Start Year

WITH Yearly_Premiums AS (
    SELECT
        YEAR(Start_Date) AS Policy_Year,
        COUNT(*) AS Total_Policies,
        ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium
    FROM policies
    GROUP BY YEAR(Start_Date)
),

Premium_Trend AS (
    SELECT
        Policy_Year,
        Total_Policies,
        Total_Annual_Premium,

        LAG(Total_Annual_Premium) OVER (
            ORDER BY Policy_Year
        ) AS Previous_Year_Premium

    FROM Yearly_Premiums
)

SELECT
    Policy_Year,
    Total_Policies,
    Total_Annual_Premium,
    Previous_Year_Premium,

    ROUND(
        (Total_Annual_Premium - Previous_Year_Premium)
        * 100.0 / NULLIF(Previous_Year_Premium, 0),
        2
    ) AS YoY_Change_Pct

FROM Premium_Trend
ORDER BY Policy_Year;


-- Step 6.18 — Year-over-Year Policy Count Growth

WITH Yearly_Policies AS (
    SELECT
        YEAR(Start_Date) AS Policy_Year,
        COUNT(*) AS Total_Policies
    FROM policies
    GROUP BY YEAR(Start_Date)
),

Policy_Growth AS (
    SELECT
        Policy_Year,
        Total_Policies,

        LAG(Total_Policies) OVER (
            ORDER BY Policy_Year
        ) AS Previous_Year_Policies

    FROM Yearly_Policies
)

SELECT
    Policy_Year,
    Total_Policies,
    Previous_Year_Policies,

    ROUND(
        (Total_Policies - Previous_Year_Policies)
        * 100.0 / NULLIF(Previous_Year_Policies, 0),
        2
    ) AS Policy_Growth_Pct

FROM Policy_Growth
ORDER BY Policy_Year;


-- Step 6.19 — Average Annual Premium Trend

WITH Yearly_Avg_Premium AS (
    SELECT
        YEAR(Start_Date) AS Policy_Year,
        COUNT(*) AS Total_Policies,
        ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium
    FROM policies
    GROUP BY YEAR(Start_Date)
),

Premium_Comparison AS (
    SELECT
        Policy_Year,
        Total_Policies,
        Avg_Annual_Premium,

        LAG(Avg_Annual_Premium) OVER (
            ORDER BY Policy_Year
        ) AS Previous_Year_Avg_Premium

    FROM Yearly_Avg_Premium
)

SELECT
    Policy_Year,
    Total_Policies,
    Avg_Annual_Premium,
    Previous_Year_Avg_Premium,

    ROUND(
        (Avg_Annual_Premium - Previous_Year_Avg_Premium)
        * 100.0 / NULLIF(Previous_Year_Avg_Premium, 0),
        2
    ) AS Avg_Premium_Growth_Pct

FROM Premium_Comparison
ORDER BY Policy_Year;


-- Step 6.20 — Monthly Policy Start Analysis

WITH Monthly_Policies AS (
    SELECT
        MONTH(Start_Date) AS Month_Number,
        MONTHNAME(Start_Date) AS Month_Name,
        COUNT(*) AS Total_Policies,
        ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium
    FROM policies
    GROUP BY
        MONTH(Start_Date),
        MONTHNAME(Start_Date)
)

SELECT
    Month_Number,
    Month_Name,
    Total_Policies,
    Total_Annual_Premium,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (),
        2
    ) AS Policy_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Total_Policies DESC
    ) AS Monthly_Rank

FROM Monthly_Policies
ORDER BY Month_Number;

-- Step 6.21 — Highest Policy Start Month per Year

WITH Monthly_Policies AS (
    SELECT
        YEAR(Start_Date) AS Policy_Year,
        MONTH(Start_Date) AS Month_Number,
        MONTHNAME(Start_Date) AS Month_Name,
        COUNT(*) AS Total_Policies
    FROM policies
    GROUP BY
        YEAR(Start_Date),
        MONTH(Start_Date),
        MONTHNAME(Start_Date)
),

Ranked_Months AS (
    SELECT
        Policy_Year,
        Month_Name,
        Total_Policies,

        ROW_NUMBER() OVER (
            PARTITION BY Policy_Year
            ORDER BY Total_Policies DESC, Month_Number
        ) AS Month_Rank

    FROM Monthly_Policies
)

SELECT
    Policy_Year,
    Month_Name AS Peak_Month,
    Total_Policies AS Peak_Month_Policies

FROM Ranked_Months
WHERE Month_Rank = 1
ORDER BY Policy_Year;


-- Step 6.22 — Coverage-to-Premium Ratio by Policy Type

WITH Coverage_Analysis AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Total_Policies,
        ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium,
        ROUND(AVG(Coverage_Amount), 2) AS Avg_Coverage,

        ROUND(
            SUM(Coverage_Amount) /
            NULLIF(SUM(Annual_Premium), 0),
            2
        ) AS Coverage_Premium_Ratio

    FROM policies
    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,
    Avg_Annual_Premium,
    Avg_Coverage,
    Coverage_Premium_Ratio,

    DENSE_RANK() OVER (
        ORDER BY Coverage_Premium_Ratio DESC
    ) AS Coverage_Rank

FROM Coverage_Analysis
ORDER BY Coverage_Rank;


-- Step 6.23 — Insurance Portfolio Premium Segmentation

WITH Premium_Segments AS (
    SELECT
        Policy_ID,
        Annual_Premium,

        CASE
            WHEN Annual_Premium < 10000 THEN 'Below 10K'
            WHEN Annual_Premium < 20000 THEN '10K-20K'
            WHEN Annual_Premium < 30000 THEN '20K-30K'
            WHEN Annual_Premium < 40000 THEN '30K-40K'
            ELSE '40K and Above'
        END AS Premium_Band

    FROM policies
)

SELECT
    Premium_Band,
    COUNT(*) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,

    ROUND(
        SUM(Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Annual_Premium), 2
    ) AS Avg_Annual_Premium

FROM Premium_Segments

GROUP BY Premium_Band

ORDER BY MIN(Annual_Premium);


-- Step 6.24 — Cancellation Rate by Premium Band

WITH Premium_Segments AS (
    SELECT
        Policy_Status,

        CASE
            WHEN Annual_Premium < 10000 THEN 'Below 10K'
            WHEN Annual_Premium < 20000 THEN '10K-20K'
            WHEN Annual_Premium < 30000 THEN '20K-30K'
            WHEN Annual_Premium < 40000 THEN '30K-40K'
            ELSE '40K and Above'
        END AS Premium_Band

    FROM policies
)

SELECT
    Premium_Band,
    COUNT(*) AS Total_Policies,

    SUM(
        CASE
            WHEN Policy_Status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS Cancelled_Policies,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Cancellation_Rate_Pct

FROM Premium_Segments
GROUP BY Premium_Band

ORDER BY
    CASE Premium_Band
        WHEN 'Below 10K' THEN 1
        WHEN '10K-20K' THEN 2
        WHEN '20K-30K' THEN 3
        WHEN '30K-40K' THEN 4
        ELSE 5
    END;
    
    
-- Step 6.25 — Customer Premium-to-Income Ratio Analysis

WITH Customer_Premiums AS (
    SELECT
        c.Customer_ID,
        c.Annual_Income,
        COUNT(p.Policy_ID) AS Total_Policies,
        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Annual_Income
),

Income_Analysis AS (
    SELECT
        Customer_ID,
        Total_Policies,

        ROUND(
            Total_Annual_Premium * 100.0 /
            NULLIF(Annual_Income, 0),
            2
        ) AS Premium_Income_Ratio_Pct

    FROM Customer_Premiums
)

SELECT
    CASE
        WHEN Premium_Income_Ratio_Pct < 5 THEN 'Below 5%'
        WHEN Premium_Income_Ratio_Pct < 10 THEN '5%-10%'
        WHEN Premium_Income_Ratio_Pct < 20 THEN '10%-20%'
        ELSE '20% and Above'
    END AS Income_Ratio_Band,

    COUNT(*) AS Total_Customers,

    ROUND(
        AVG(Premium_Income_Ratio_Pct),
        2
    ) AS Avg_Premium_Income_Ratio_Pct

FROM Income_Analysis

GROUP BY Income_Ratio_Band

ORDER BY Avg_Premium_Income_Ratio_Pct;

-- Step 6.26 — Top 10 Customers by Premium-to-Income Ratio

WITH Customer_Premium_Analysis AS (
    SELECT
        c.Customer_ID,
        c.Region,
        c.Annual_Income,
        COUNT(p.Policy_ID) AS Total_Policies,
        ROUND(SUM(p.Annual_Premium), 2) AS Total_Annual_Premium,

        ROUND(
            SUM(p.Annual_Premium) * 100.0 /
            NULLIF(c.Annual_Income, 0),
            2
        ) AS Premium_Income_Ratio_Pct

    FROM customers c
    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    WHERE c.Annual_Income > 0

    GROUP BY
        c.Customer_ID,
        c.Region,
        c.Annual_Income
)

SELECT
    Customer_ID,
    Region,
    Annual_Income,
    Total_Policies,
    Total_Annual_Premium,
    Premium_Income_Ratio_Pct,

    DENSE_RANK() OVER (
        ORDER BY Premium_Income_Ratio_Pct DESC
    ) AS Ratio_Rank

FROM Customer_Premium_Analysis

ORDER BY Premium_Income_Ratio_Pct DESC, Customer_ID

LIMIT 10;


-- Step 6.27 — Average Policy Duration by Insurance Type

WITH Policy_Duration AS (
    SELECT
        Policy_ID,
        Policy_Type,
        DATEDIFF(End_Date, Start_Date) AS Duration_Days
    FROM policies
    WHERE End_Date >= Start_Date
)

SELECT
    Policy_Type,
    COUNT(*) AS Total_Policies,

    ROUND(AVG(Duration_Days), 2) AS Avg_Duration_Days,

    ROUND(AVG(Duration_Days) / 365.25, 2) AS Avg_Duration_Years,

    MIN(Duration_Days) AS Min_Duration_Days,
    MAX(Duration_Days) AS Max_Duration_Days,

    DENSE_RANK() OVER (
        ORDER BY AVG(Duration_Days) DESC
    ) AS Duration_Rank

FROM Policy_Duration

GROUP BY Policy_Type

ORDER BY Duration_Rank;


-- Step 6.28 — Insurance Policy Duration Segmentation

WITH Policy_Duration AS (
    SELECT
        Policy_ID,
        Annual_Premium,
        DATEDIFF(End_Date, Start_Date) AS Duration_Days
    FROM policies
    WHERE End_Date >= Start_Date
),

Duration_Segments AS (
    SELECT
        Policy_ID,
        Annual_Premium,

        CASE
            WHEN Duration_Days <= 365 THEN 'Up to 1 Year'
            WHEN Duration_Days <= 730 THEN 'Over 1 to 2 Years'
            ELSE 'Over 2 Years'
        END AS Duration_Category

    FROM Policy_Duration
)

SELECT
    Duration_Category,
    COUNT(*) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,

    ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium

FROM Duration_Segments

GROUP BY Duration_Category

ORDER BY
    CASE Duration_Category
        WHEN 'Up to 1 Year' THEN 1
        WHEN 'Over 1 to 2 Years' THEN 2
        ELSE 3
    END;
    

-- =====================================================
-- SECTION 2: CLAIMS & SEVERITY ANALYSIS
-- =====================================================

-- Step 6.29 — Claim Frequency by Insurance Type

SELECT
    p.Policy_Type,
    COUNT(DISTINCT p.Policy_ID) AS Total_Policies,
    COUNT(c.Claim_ID) AS Total_Claims,

    ROUND(
        COUNT(c.Claim_ID) * 100.0 /
        NULLIF(COUNT(DISTINCT p.Policy_ID), 0),
        2
    ) AS Claims_Per_100_Policies

FROM policies p
LEFT JOIN claims c
    ON p.Policy_ID = c.Policy_ID

GROUP BY p.Policy_Type
ORDER BY Claims_Per_100_Policies DESC;
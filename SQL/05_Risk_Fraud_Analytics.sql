-- =====================================================
-- INSURANCE CLAIMS & RISK ANALYTICS
-- 05_Risk_Fraud_Analytics.sql
-- =====================================================

USE insurance_claims_analytics;

-- SECTION 1: Risk Profile Analysis


-- Step 7.2 — Customer Risk Category Distribution

SELECT
    Risk_Category,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Risk_Score), 2
    ) AS Avg_Risk_Score,

    MIN(Risk_Score) AS Min_Risk_Score,

    MAX(Risk_Score) AS Max_Risk_Score

FROM risk_assessment

GROUP BY Risk_Category

ORDER BY Avg_Risk_Score DESC;



-- Step 7.3 — Customer Risk Score Distribution by Region

WITH Regional_Risk AS (
    SELECT
        c.Region,

        COUNT(*) AS Total_Customers,

        ROUND(
            AVG(r.Risk_Score), 2
        ) AS Avg_Risk_Score,

        SUM(
            CASE
                WHEN r.Risk_Category = 'High'
                THEN 1 ELSE 0
            END
        ) AS High_Risk_Customers,

        SUM(
            CASE
                WHEN r.Risk_Category = 'Medium'
                THEN 1 ELSE 0
            END
        ) AS Medium_Risk_Customers,

        SUM(
            CASE
                WHEN r.Risk_Category = 'Low'
                THEN 1 ELSE 0
            END
        ) AS Low_Risk_Customers

    FROM customers c

    INNER JOIN risk_assessment r
        ON c.Customer_ID = r.Customer_ID

    GROUP BY c.Region
)

SELECT
    Region,
    Total_Customers,
    Avg_Risk_Score,
    High_Risk_Customers,
    Medium_Risk_Customers,
    Low_Risk_Customers,

    ROUND(
        High_Risk_Customers * 100.0 /
        NULLIF(Total_Customers, 0),
        2
    ) AS High_Risk_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Risk_Customers * 1.0 /
                 NULLIF(Total_Customers, 0) DESC
    ) AS Risk_Rank

FROM Regional_Risk

ORDER BY Risk_Rank;




-- Step 7.4 — Risk Category Distribution by Customer Age Group

WITH Age_Risk_Summary AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(*) AS Total_Customers,

        ROUND(AVG(r.Risk_Score), 2) AS Avg_Risk_Score,

        SUM(
            CASE WHEN r.Risk_Category = 'High'
            THEN 1 ELSE 0 END
        ) AS High_Risk_Customers,

        SUM(
            CASE WHEN r.Risk_Category = 'Medium'
            THEN 1 ELSE 0 END
        ) AS Medium_Risk_Customers,

        SUM(
            CASE WHEN r.Risk_Category = 'Low'
            THEN 1 ELSE 0 END
        ) AS Low_Risk_Customers

    FROM customers c

    INNER JOIN risk_assessment r
        ON c.Customer_ID = r.Customer_ID

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Customers,
    Avg_Risk_Score,
    High_Risk_Customers,
    Medium_Risk_Customers,
    Low_Risk_Customers,

    ROUND(
        High_Risk_Customers * 100.0 /
        NULLIF(Total_Customers, 0), 2
    ) AS High_Risk_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Risk_Customers * 1.0 /
                 NULLIF(Total_Customers, 0) DESC
    ) AS Risk_Rank

FROM Age_Risk_Summary

ORDER BY Risk_Rank;



-- Step 7.5 — Customer Risk Distribution by Income Group

WITH Income_Risk_Summary AS (
    SELECT
        CASE
            WHEN c.Annual_Income < 300000 THEN 'Below 3L'
            WHEN c.Annual_Income < 600000 THEN '3L-6L'
            WHEN c.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(*) AS Total_Customers,

        ROUND(AVG(r.Risk_Score), 2) AS Avg_Risk_Score,

        SUM(
            CASE WHEN r.Risk_Category = 'High'
            THEN 1 ELSE 0 END
        ) AS High_Risk_Customers,

        SUM(
            CASE WHEN r.Risk_Category = 'Medium'
            THEN 1 ELSE 0 END
        ) AS Medium_Risk_Customers,

        SUM(
            CASE WHEN r.Risk_Category = 'Low'
            THEN 1 ELSE 0 END
        ) AS Low_Risk_Customers

    FROM customers c

    INNER JOIN risk_assessment r
        ON c.Customer_ID = r.Customer_ID

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Customers,
    Avg_Risk_Score,
    High_Risk_Customers,
    Medium_Risk_Customers,
    Low_Risk_Customers,

    ROUND(
        High_Risk_Customers * 100.0 /
        NULLIF(Total_Customers, 0), 2
    ) AS High_Risk_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Risk_Customers * 1.0 /
                 NULLIF(Total_Customers, 0) DESC
    ) AS Risk_Rank

FROM Income_Risk_Summary

ORDER BY Risk_Rank;




-- Step 7.6 — Fraud-Flagged Claims by Customer Risk Category

WITH Risk_Fraud_Summary AS (
    SELECT
        r.Risk_Category,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Fraud_Flag = 1
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Fraud_Summary

ORDER BY Fraud_Flag_Rank;



-- Step 7.7 — Fraud-Flagged Claim Amount Contribution by Risk Category

WITH Risk_Fraud_Amounts AS (
    SELECT
        r.Risk_Category,

        COUNT(*) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN c.Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    ROUND(
        Flagged_Claim_Amount * 100.0 /
        NULLIF(Total_Claim_Amount, 0),
        2
    ) AS Flagged_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY Flagged_Claim_Amount * 1.0 /
                 NULLIF(Total_Claim_Amount, 0) DESC
    ) AS Contribution_Rank

FROM Risk_Fraud_Amounts

ORDER BY Contribution_Rank;



-- Step 7.8 — Fraud-Flagged Claims by Insurance Type

WITH Policy_Fraud_Summary AS (
    SELECT
        p.Policy_Type,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Fraud_Flag = 1
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    Policy_Type,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Policy_Fraud_Summary

ORDER BY Fraud_Flag_Rank;


-- Step 7.9 — Fraud-Flagged Claims by Region

WITH Regional_Fraud AS (
    SELECT
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY cu.Region
)

SELECT
    Region,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Regional_Fraud

ORDER BY Fraud_Flag_Rank;



-- Step 7.10 — Fraud-Flagged Claims by Claim Status

WITH Claim_Status_Fraud AS (
    SELECT
        Claim_Status,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN Fraud_Flag = 1 THEN Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims

    GROUP BY Claim_Status
)

SELECT
    Claim_Status,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Claim_Status_Fraud

ORDER BY Fraud_Flag_Rank;


-- Step 7.11 — Fraud-Flagged Claims by Customer Age Group

WITH Age_Fraud_Summary AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN c.Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Age_Fraud_Summary

ORDER BY Fraud_Flag_Rank;



-- Step 7.12 — Fraud-Flagged Claims by Customer Income Group

WITH Income_Fraud_Summary AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN c.Fraud_Flag = 1
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Income_Fraud_Summary

ORDER BY Fraud_Flag_Rank;



-- Step 7.13 — Fraud-Flagged Claims by Risk Score Band

WITH Risk_Score_Claims AS (
    SELECT
        CASE
            WHEN r.Risk_Score BETWEEN 0 AND 19 THEN '0-19'
            WHEN r.Risk_Score BETWEEN 20 AND 39 THEN '20-39'
            WHEN r.Risk_Score BETWEEN 40 AND 59 THEN '40-59'
            WHEN r.Risk_Score BETWEEN 60 AND 79 THEN '60-79'
            ELSE '80-100'
        END AS Risk_Score_Band,

        c.Claim_ID,
        c.Fraud_Flag,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID
)

SELECT
    Risk_Score_Band,

    COUNT(*) AS Total_Claims,

    SUM(
        CASE WHEN Fraud_Flag = 1
        THEN 1 ELSE 0 END
    ) AS Fraud_Flagged_Claims,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ), 2
    ) AS Flagged_Claim_Amount

FROM Risk_Score_Claims

GROUP BY Risk_Score_Band

ORDER BY MIN(
    CASE Risk_Score_Band
        WHEN '0-19' THEN 1
        WHEN '20-39' THEN 2
        WHEN '40-59' THEN 3
        WHEN '60-79' THEN 4
        ELSE 5
    END
);



-- Step 7.14 — Fraud-Flagged Claims by Claim Amount Band

WITH Claim_Amount_Bands AS (
    SELECT
        CASE
            WHEN Claim_Amount < 10000 THEN 'Below 10K'
            WHEN Claim_Amount < 25000 THEN '10K-25K'
            WHEN Claim_Amount < 50000 THEN '25K-50K'
            WHEN Claim_Amount < 100000 THEN '50K-100K'
            ELSE '100K and Above'
        END AS Amount_Band,

        Fraud_Flag,
        Claim_Amount

    FROM claims
)

SELECT
    Amount_Band,

    COUNT(*) AS Total_Claims,

    SUM(
        CASE WHEN Fraud_Flag = 1
        THEN 1 ELSE 0 END
    ) AS Fraud_Flagged_Claims,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ), 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Fraud_Flag = 1 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Fraud_Flag_Rank

FROM Claim_Amount_Bands

GROUP BY Amount_Band

ORDER BY Fraud_Flag_Rank;



-- Step 7.15 — Fraud Flag Rate by Claim Frequency

WITH Policy_Claim_Frequency AS (
    SELECT
        Policy_ID,
        COUNT(*) AS Claim_Count
    FROM claims
    GROUP BY Policy_ID
),

Claim_Frequency_Summary AS (
    SELECT
        CASE
            WHEN f.Claim_Count = 1 THEN '1 Claim'
            WHEN f.Claim_Count = 2 THEN '2 Claims'
            WHEN f.Claim_Count = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Frequency_Band,

        c.Claim_ID,
        c.Fraud_Flag,
        c.Claim_Amount

    FROM claims c

    INNER JOIN Policy_Claim_Frequency f
        ON c.Policy_ID = f.Policy_ID
)

SELECT
    Frequency_Band,

    COUNT(*) AS Total_Claims,

    SUM(
        CASE WHEN Fraud_Flag = 1
        THEN 1 ELSE 0 END
    ) AS Fraud_Flagged_Claims,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ), 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Fraud_Flag = 1 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Fraud_Flag_Rank

FROM Claim_Frequency_Summary

GROUP BY Frequency_Band

ORDER BY Fraud_Flag_Rank;



-- Step 7.16 — Fraud-Flagged Claims by Policy Status

WITH Policy_Status_Fraud AS (
    SELECT
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    Policy_Status,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Policy_Status_Fraud

ORDER BY Fraud_Flag_Rank;



-- Step 7.17 — Fraud Flags by Risk Category and Policy Type

WITH Risk_Policy_Fraud AS (
    SELECT
        r.Risk_Category,
        p.Policy_Type,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, p.Policy_Type
)

SELECT
    Risk_Category,
    Policy_Type,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Policy_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    
    

-- Step 7.18 — Fraud Flags by Risk Category and Claim Status

WITH Risk_Status_Fraud AS (
    SELECT
        r.Risk_Category,
        c.Claim_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, c.Claim_Status
)

SELECT
    Risk_Category,
    Claim_Status,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Status_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;



-- Step 7.19 — Fraud Flag Rate by Claim Year

WITH Yearly_Fraud AS (
    SELECT
        YEAR(Claim_Date) AS Claim_Year,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims

    GROUP BY YEAR(Claim_Date)
)

SELECT
    Claim_Year,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    LAG(Fraud_Flagged_Claims) OVER (
        ORDER BY Claim_Year
    ) AS Previous_Year_Flagged_Claims,

    ROUND(
        (
            Fraud_Flagged_Claims -
            LAG(Fraud_Flagged_Claims) OVER (
                ORDER BY Claim_Year
            )
        ) * 100.0 /
        NULLIF(
            LAG(Fraud_Flagged_Claims) OVER (
                ORDER BY Claim_Year
            ), 0
        ), 2
    ) AS YoY_Flagged_Claims_Growth_Pct

FROM Yearly_Fraud

ORDER BY Claim_Year;



-- Step 7.20 — Monthly Fraud Flag Trend

WITH Monthly_Fraud AS (
    SELECT
        DATE_FORMAT(Claim_Date, '%Y-%m') AS Claim_Month,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims

    GROUP BY DATE_FORMAT(Claim_Date, '%Y-%m')
)

SELECT
    Claim_Month,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    LAG(Fraud_Flagged_Claims) OVER (
        ORDER BY Claim_Month
    ) AS Previous_Month_Flagged_Claims,

    ROUND(
        (
            Fraud_Flagged_Claims -
            LAG(Fraud_Flagged_Claims) OVER (
                ORDER BY Claim_Month
            )
        ) * 100.0 /
        NULLIF(
            LAG(Fraud_Flagged_Claims) OVER (
                ORDER BY Claim_Month
            ), 0
        ), 2
    ) AS MoM_Flagged_Claims_Growth_Pct

FROM Monthly_Fraud

ORDER BY Claim_Month;



-- Step 7.21 — Fraud Flag Rate by Claim Type

WITH Claim_Type_Fraud AS (
    SELECT
        Claim_Type,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Fraud_Flag = 1 THEN 1
                ELSE 0
            END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE
                WHEN Fraud_Flag = 1 THEN Claim_Amount
                ELSE 0
            END
        ) AS Flagged_Claim_Amount

    FROM claims

    GROUP BY Claim_Type
)

SELECT
    Claim_Type,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Claim_Type_Fraud

ORDER BY Fraud_Flag_Rank;



-- Step 7.22 — High-Value vs Other Claims: Fraud Flag Comparison

WITH Claim_Value_Fraud AS (
    SELECT
        CASE
            WHEN Claim_Amount >= 100000
                THEN 'High Value'
            ELSE 'Other Claims'
        END AS Claim_Value_Category,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims

    GROUP BY Claim_Value_Category
)

SELECT
    Claim_Value_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount

FROM Claim_Value_Fraud

ORDER BY Fraud_Flag_Rate_Pct DESC;




-- Step 7.23 — Fraud-Flagged Claims Exceeding Policy Coverage

WITH Coverage_Fraud AS (
    SELECT
        CASE
            WHEN c.Claim_Amount > p.Coverage_Amount
                THEN 'Exceeds Coverage'
            ELSE 'Within Coverage'
        END AS Coverage_Category,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY Coverage_Category
)

SELECT
    Coverage_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Coverage_Fraud

ORDER BY Fraud_Flag_Rank;


-- Step 7.24 — Fraud-Flagged Claims by Customer Gender

WITH Gender_Fraud AS (
    SELECT
        cu.Gender,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY cu.Gender
)

SELECT
    Gender,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount

FROM Gender_Fraud

ORDER BY Fraud_Flag_Rate_Pct DESC;



-- Step 7.25 — Fraud-Flagged Claim Amount Contribution by Risk Category

WITH Risk_Flagged_Amount AS (
    SELECT
        r.Risk_Category,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    ROUND(
        Flagged_Claim_Amount * 100.0 /
        NULLIF(
            SUM(Flagged_Claim_Amount) OVER (), 0
        ), 2
    ) AS Flagged_Amount_Share_Pct

FROM Risk_Flagged_Amount

ORDER BY Flagged_Amount_Share_Pct DESC;



-- Step 7.26 — Fraud Flag Rate by Risk Category and Region

WITH Regional_Risk_Fraud AS (
    SELECT
        r.Risk_Category,
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    INNER JOIN risk_assessment r
        ON cu.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, cu.Region
)

SELECT
    Risk_Category,
    Region,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Regional_Risk_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    
    

-- Step 7.27 — Fraud Flag Rate by Risk Category and Claim Frequency

WITH Policy_Claim_Count AS (
    SELECT
        Policy_ID,
        COUNT(*) AS Claim_Count
    FROM claims
    GROUP BY Policy_ID
),

Risk_Frequency_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN f.Claim_Count = 1 THEN '1 Claim'
            WHEN f.Claim_Count = 2 THEN '2 Claims'
            WHEN f.Claim_Count = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Frequency_Band,

        c.Claim_ID,
        c.Fraud_Flag,
        c.Claim_Amount

    FROM claims c

    INNER JOIN Policy_Claim_Count f
        ON c.Policy_ID = f.Policy_ID

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID
),

Risk_Frequency_Summary AS (
    SELECT
        Risk_Category,
        Frequency_Band,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM Risk_Frequency_Fraud

    GROUP BY Risk_Category, Frequency_Band
)

SELECT
    Risk_Category,
    Frequency_Band,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Frequency_Summary

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    
    
    
-- Step 7.28 — Fraud Flags by Risk Category and Claim Amount Band

WITH Risk_Amount_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN c.Claim_Amount < 10000 THEN 'Below 10K'
            WHEN c.Claim_Amount < 25000 THEN '10K-25K'
            WHEN c.Claim_Amount < 50000 THEN '25K-50K'
            WHEN c.Claim_Amount < 100000 THEN '50K-100K'
            ELSE '100K and Above'
        END AS Amount_Band,

        c.Fraud_Flag,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID
),

Risk_Amount_Summary AS (
    SELECT
        Risk_Category,
        Amount_Band,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM Risk_Amount_Fraud

    GROUP BY Risk_Category, Amount_Band
)

SELECT
    Risk_Category,
    Amount_Band,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(Flagged_Claim_Amount, 2) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Amount_Summary

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    

-- Step 7.29 — Fraud Flags by Risk Category and Policy Status

WITH Risk_Policy_Status AS (
    SELECT
        r.Risk_Category,
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, p.Policy_Status
)

SELECT
    Risk_Category,
    Policy_Status,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Policy_Status

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    
    

-- Step 7.30 — Yearly Fraud Trends by Risk Category

WITH Yearly_Risk_Fraud AS (
    SELECT
        YEAR(c.Claim_Date) AS Claim_Year,
        r.Risk_Category,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY YEAR(c.Claim_Date), r.Risk_Category
)

SELECT
    Claim_Year,
    Risk_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Claim_Year
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Yearly_Risk_Fraud

ORDER BY
    Claim_Year,
    Fraud_Flag_Rank;
    
    

-- Step 7.31 — Fraud Flags by Risk Category and Coverage Exceedance

WITH Risk_Coverage_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN c.Claim_Amount > p.Coverage_Amount
                THEN 'Exceeds Coverage'
            ELSE 'Within Coverage'
        END AS Coverage_Category,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN c.Claim_Amount ELSE 0 END
        ) AS Flagged_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, Coverage_Category
)

SELECT
    Risk_Category,
    Coverage_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        Flagged_Claim_Amount, 2
    ) AS Flagged_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Risk_Category
        ORDER BY Fraud_Flagged_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Fraud_Flag_Rank

FROM Risk_Coverage_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rank;
    
    


-- Step 7.32 — Fraud Flags Among Settled Claims Without Payments

WITH Settled_Claims AS (
    SELECT
        c.Claim_ID,
        c.Fraud_Flag,
        c.Claim_Amount,

        CASE
            WHEN EXISTS (
                SELECT 1
                FROM payments p
                WHERE p.Claim_ID = c.Claim_ID
            ) THEN 'With Payment'
            ELSE 'Without Payment'
        END AS Payment_Category

    FROM claims c

    WHERE c.Claim_Status = 'Settled'
)

SELECT
    Payment_Category,

    COUNT(*) AS Total_Settled_Claims,

    SUM(
        CASE WHEN Fraud_Flag = 1
        THEN 1 ELSE 0 END
    ) AS Fraud_Flagged_Claims,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Fraud_Flag_Rate_Pct,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN Claim_Amount ELSE 0 END
        ), 2
    ) AS Flagged_Claim_Amount

FROM Settled_Claims

GROUP BY Payment_Category

ORDER BY Fraud_Flag_Rate_Pct DESC;




-- Step 7.33 — Fraud Flags by Payment Coverage Exceedance

WITH Payment_Coverage AS (
    SELECT
        c.Claim_ID,
        c.Fraud_Flag,

        CASE
            WHEN SUM(py.Payment_Amount) > p.Coverage_Amount
                THEN 'Exceeds Coverage'
            ELSE 'Within Coverage'
        END AS Payment_Coverage_Category

    FROM payments py

    INNER JOIN claims c
        ON py.Claim_ID = c.Claim_ID

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        c.Claim_ID,
        c.Fraud_Flag,
        p.Coverage_Amount
)

SELECT
    Payment_Coverage_Category,

    COUNT(*) AS Claims_With_Payments,

    SUM(
        CASE WHEN Fraud_Flag = 1
        THEN 1 ELSE 0 END
    ) AS Fraud_Flagged_Claims,

    ROUND(
        SUM(
            CASE WHEN Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Fraud_Flag_Rate_Pct

FROM Payment_Coverage

GROUP BY Payment_Coverage_Category

ORDER BY Fraud_Flag_Rate_Pct DESC;




-- Step 7.34 — Fraud Flag Rate by Risk Category and Gender

WITH Risk_Gender_Fraud AS (
    SELECT
        r.Risk_Category,
        cu.Gender,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    INNER JOIN risk_assessment r
        ON cu.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, cu.Gender
)

SELECT
    Risk_Category,
    Gender,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Risk_Gender_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rate_Pct DESC;
    
    

-- Step 7.35 — Fraud Flag Rate by Risk Category and Age Group

WITH Risk_Age_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    INNER JOIN risk_assessment r
        ON cu.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, Age_Group
)

SELECT
    Risk_Category,
    Age_Group,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Risk_Age_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rate_Pct DESC;
    


-- Step 7.36 — Fraud Flag Rate by Risk Category and Income Group

WITH Risk_Income_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    INNER JOIN risk_assessment r
        ON cu.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, Income_Group
)

SELECT
    Risk_Category,
    Income_Group,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Risk_Income_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rate_Pct DESC;
    
    
    
    
    -- Step 7.36 — Fraud Flag Rate by Risk Category and Income Group

WITH Risk_Income_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    INNER JOIN risk_assessment r
        ON cu.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, Income_Group
)

SELECT
    Risk_Category,
    Income_Group,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Risk_Income_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rate_Pct DESC;


-- Step 7.37 — Fraud Flag Rate by Risk Category and Claim Severity

WITH Risk_Severity_Fraud AS (
    SELECT
        r.Risk_Category,

        CASE
            WHEN c.Claim_Amount < 25000 THEN 'Low Severity'
            WHEN c.Claim_Amount < 100000 THEN 'Medium Severity'
            ELSE 'High Severity'
        END AS Severity_Category,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category, Severity_Category
)

SELECT
    Risk_Category,
    Severity_Category,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Risk_Severity_Fraud

ORDER BY
    CASE Risk_Category
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        ELSE 3
    END,
    Fraud_Flag_Rate_Pct DESC;
    
    

-- Step 7.38 — Fraud Flag Rate by Risk Score Band and Claim Year

WITH Yearly_Risk_Bands AS (
    SELECT
        YEAR(c.Claim_Date) AS Claim_Year,

        CASE
            WHEN r.Risk_Score < 20 THEN '0-19'
            WHEN r.Risk_Score < 40 THEN '20-39'
            WHEN r.Risk_Score < 60 THEN '40-59'
            WHEN r.Risk_Score < 80 THEN '60-79'
            ELSE '80-100'
        END AS Risk_Score_Band,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN c.Fraud_Flag = 1
            THEN 1 ELSE 0 END
        ) AS Fraud_Flagged_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        YEAR(c.Claim_Date),
        Risk_Score_Band
)

SELECT
    Claim_Year,
    Risk_Score_Band,
    Total_Claims,
    Fraud_Flagged_Claims,

    ROUND(
        Fraud_Flagged_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Fraud_Flag_Rate_Pct

FROM Yearly_Risk_Bands

ORDER BY
    Claim_Year,
    Risk_Score_Band;
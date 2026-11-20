-- Step 6.30 — Claims Severity by Insurance Type

SELECT
    p.Policy_Type,

    COUNT(c.Claim_ID) AS Total_Claims,

    ROUND(
        SUM(c.Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(c.Claim_Amount), 2
    ) AS Avg_Claim_Severity,

    ROUND(
        MAX(c.Claim_Amount), 2
    ) AS Max_Claim_Amount,

    ROUND(
        SUM(c.Claim_Amount) * 100.0 /
        SUM(SUM(c.Claim_Amount)) OVER (),
        2
    ) AS Claim_Amount_Share_Pct

FROM claims c
INNER JOIN policies p
    ON c.Policy_ID = p.Policy_ID

GROUP BY p.Policy_Type

ORDER BY Total_Claim_Amount DESC;


-- Step 6.31 — Claims Distribution by Status

SELECT
    Claim_Status,

    COUNT(*) AS Total_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Amount

FROM claims

GROUP BY Claim_Status

ORDER BY Total_Claims DESC;


-- Step 6.32 — Claim Processing Status KPIs

SELECT
    COUNT(*) AS Total_Claims,

    SUM(
        CASE
            WHEN Claim_Status IN ('Approved', 'Settled')
            THEN 1 ELSE 0
        END
    ) AS Approved_Or_Settled_Claims,

    ROUND(
        SUM(
            CASE
                WHEN Claim_Status IN ('Approved', 'Settled')
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Approved_Or_Settled_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Claim_Status = 'Rejected'
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Rejection_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Claim_Status = 'Pending'
                THEN 1 ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Pending_Rate_Pct

FROM claims;


-- Step 6.33 — Claim Rejection Rate by Insurance Type

WITH Claim_Rejections AS (
    SELECT
        p.Policy_Type,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Rejected' THEN 1
                ELSE 0
            END
        ) AS Rejected_Claims

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    Policy_Type,
    Total_Claims,
    Rejected_Claims,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Rejection_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY Rejected_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Rejection_Rank

FROM Claim_Rejections

ORDER BY Rejection_Rank;


-- Step 6.34 — Pending Claims by Insurance Type

WITH Pending_Analysis AS (
    SELECT
        p.Policy_Type,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Pending' THEN 1
                ELSE 0
            END
        ) AS Pending_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Pending'
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS Pending_Claim_Amount

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    Policy_Type,
    Total_Claims,
    Pending_Claims,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Pending_Rate_Pct,

    ROUND(Pending_Claim_Amount, 2) AS Pending_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Pending_Claims DESC
    ) AS Pending_Volume_Rank

FROM Pending_Analysis

ORDER BY Pending_Volume_Rank;


-- Step 6.35 — Claim Severity by Insurance Type and Status

WITH Claim_Severity AS (
    SELECT
        p.Policy_Type,
        c.Claim_Status,

        COUNT(*) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        p.Policy_Type,
        c.Claim_Status
)

SELECT
    Policy_Type,
    Claim_Status,
    Total_Claims,
    Total_Claim_Amount,
    Avg_Claim_Severity,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Claim_Severity

ORDER BY
    Policy_Type,
    Severity_Rank;
    
    
-- Step 6.36 — Identify High-Severity Claims Using IQR

WITH Ranked_Claims AS (
    SELECT
        Claim_ID,
        Claim_Amount,
        ROW_NUMBER() OVER (
            ORDER BY Claim_Amount
        ) AS Row_Num,
        COUNT(*) OVER () AS Total_Rows
    FROM claims
),

Quartiles AS (
    SELECT
        AVG(
            CASE
                WHEN Row_Num IN (
                    FLOOR((Total_Rows - 1) * 0.25) + 1,
                    CEIL((Total_Rows - 1) * 0.25) + 1
                )
                THEN Claim_Amount
            END
        ) AS Q1,

        AVG(
            CASE
                WHEN Row_Num IN (
                    FLOOR((Total_Rows - 1) * 0.75) + 1,
                    CEIL((Total_Rows - 1) * 0.75) + 1
                )
                THEN Claim_Amount
            END
        ) AS Q3
    FROM Ranked_Claims
)

SELECT
    ROUND(Q1, 2) AS Q1,
    ROUND(Q3, 2) AS Q3,
    ROUND(Q3 + 1.5 * (Q3 - Q1), 2) AS Upper_Bound,

    (
        SELECT COUNT(*)
        FROM claims c
        WHERE c.Claim_Amount >
              Q3 + 1.5 * (Q3 - Q1)
    ) AS High_Severity_Claims

FROM Quartiles;


-- Step 6.37 — High-Severity Claims by Insurance Type

WITH Severity_Analysis AS (
    SELECT
        p.Policy_Type,
        c.Claim_ID,
        c.Claim_Amount,

        CASE
            WHEN c.Claim_Amount > 106275.45
                THEN 1
            ELSE 0
        END AS High_Severity_Flag

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID
)

SELECT
    Policy_Type,

    COUNT(*) AS Total_Claims,

    SUM(High_Severity_Flag) AS High_Severity_Claims,

    ROUND(
        SUM(High_Severity_Flag) * 100.0 / COUNT(*),
        2
    ) AS High_Severity_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN High_Severity_Flag = 1
                    THEN Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS High_Severity_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY SUM(High_Severity_Flag) DESC
    ) AS Severity_Rank

FROM Severity_Analysis

GROUP BY Policy_Type

ORDER BY Severity_Rank;


-- Step 6.38 — High-Severity Claims by Claim Status

WITH Severity_Classification AS (
    SELECT
        Claim_ID,
        Claim_Status,
        Claim_Amount,

        CASE
            WHEN Claim_Amount > 106275.45 THEN 1
            ELSE 0
        END AS High_Severity_Flag

    FROM claims
)

SELECT
    Claim_Status,

    COUNT(*) AS Total_Claims,

    SUM(High_Severity_Flag) AS High_Severity_Claims,

    ROUND(
        SUM(High_Severity_Flag) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS High_Severity_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN High_Severity_Flag = 1
                THEN Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS High_Severity_Claim_Amount,

    ROUND(
        SUM(High_Severity_Flag) * 100.0 /
        NULLIF(SUM(SUM(High_Severity_Flag)) OVER (), 0),
        2
    ) AS Share_Of_High_Severity_Claims_Pct

FROM Severity_Classification

GROUP BY Claim_Status

ORDER BY High_Severity_Claims DESC;


-- Step 6.39 — Monthly Claims Volume and Amount Trend

WITH Monthly_Claims AS (
    SELECT
        DATE_FORMAT(Claim_Date, '%Y-%m') AS Claim_Month,
        COUNT(*) AS Total_Claims,
        ROUND(SUM(Claim_Amount), 2) AS Total_Claim_Amount

    FROM claims

    GROUP BY DATE_FORMAT(Claim_Date, '%Y-%m')
),

Claims_Trend AS (
    SELECT
        Claim_Month,
        Total_Claims,
        Total_Claim_Amount,

        LAG(Total_Claims) OVER (
            ORDER BY Claim_Month
        ) AS Previous_Month_Claims

    FROM Monthly_Claims
)

SELECT
    Claim_Month,
    Total_Claims,
    Total_Claim_Amount,
    Previous_Month_Claims,

    ROUND(
        (Total_Claims - Previous_Month_Claims) * 100.0 /
        NULLIF(Previous_Month_Claims, 0),
        2
    ) AS MoM_Claims_Growth_Pct

FROM Claims_Trend

ORDER BY Claim_Month;


-- Step 6.40 — Yearly Claims Volume and Severity Analysis

WITH Yearly_Claims AS (
    SELECT
        YEAR(Claim_Date) AS Claim_Year,
        COUNT(*) AS Total_Claims,
        ROUND(SUM(Claim_Amount), 2) AS Total_Claim_Amount,
        ROUND(AVG(Claim_Amount), 2) AS Avg_Claim_Severity

    FROM claims

    GROUP BY YEAR(Claim_Date)
),

Claims_Comparison AS (
    SELECT
        Claim_Year,
        Total_Claims,
        Total_Claim_Amount,
        Avg_Claim_Severity,

        LAG(Total_Claims) OVER (
            ORDER BY Claim_Year
        ) AS Previous_Year_Claims

    FROM Yearly_Claims
)

SELECT
    Claim_Year,
    Total_Claims,
    Total_Claim_Amount,
    Avg_Claim_Severity,
    Previous_Year_Claims,

    ROUND(
        (Total_Claims - Previous_Year_Claims) * 100.0 /
        NULLIF(Previous_Year_Claims, 0),
        2
    ) AS YoY_Claims_Growth_Pct

FROM Claims_Comparison

ORDER BY Claim_Year;


-- Step 6.41 — Year-over-Year Average Claim Severity Growth

WITH Yearly_Severity AS (
    SELECT
        YEAR(Claim_Date) AS Claim_Year,
        COUNT(*) AS Total_Claims,
        ROUND(AVG(Claim_Amount), 2) AS Avg_Claim_Severity

    FROM claims

    GROUP BY YEAR(Claim_Date)
),

Severity_Trend AS (
    SELECT
        Claim_Year,
        Total_Claims,
        Avg_Claim_Severity,

        LAG(Avg_Claim_Severity) OVER (
            ORDER BY Claim_Year
        ) AS Previous_Year_Severity

    FROM Yearly_Severity
)

SELECT
    Claim_Year,
    Total_Claims,
    Avg_Claim_Severity,
    Previous_Year_Severity,

    ROUND(
        (Avg_Claim_Severity - Previous_Year_Severity)
        * 100.0 / NULLIF(Previous_Year_Severity, 0),
        2
    ) AS Severity_Growth_Pct

FROM Severity_Trend

ORDER BY Claim_Year;



-- Step 6.42 — Claim Amount Distribution by Severity Band

WITH Claim_Bands AS (
    SELECT
        Claim_ID,
        Claim_Amount,

        CASE
            WHEN Claim_Amount < 10000 THEN 'Below 10K'
            WHEN Claim_Amount < 25000 THEN '10K-25K'
            WHEN Claim_Amount < 50000 THEN '25K-50K'
            WHEN Claim_Amount < 100000 THEN '50K-100K'
            ELSE '100K and Above'
        END AS Severity_Band

    FROM claims
)

SELECT
    Severity_Band,

    COUNT(*) AS Total_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        SUM(Claim_Amount) * 100.0 /
        SUM(SUM(Claim_Amount)) OVER (),
        2
    ) AS Claim_Amount_Share_Pct,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Amount

FROM Claim_Bands

GROUP BY Severity_Band

ORDER BY
    CASE Severity_Band
        WHEN 'Below 10K' THEN 1
        WHEN '10K-25K' THEN 2
        WHEN '25K-50K' THEN 3
        WHEN '50K-100K' THEN 4
        ELSE 5
    END;
    
-- Step 6.43 — Claim Severity Band by Insurance Type

WITH Claim_Segments AS (
    SELECT
        p.Policy_Type,

        CASE
            WHEN c.Claim_Amount < 10000 THEN 'Below 10K'
            WHEN c.Claim_Amount < 25000 THEN '10K-25K'
            WHEN c.Claim_Amount < 50000 THEN '25K-50K'
            WHEN c.Claim_Amount < 100000 THEN '50K-100K'
            ELSE '100K and Above'
        END AS Severity_Band

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID
),

Severity_Summary AS (
    SELECT
        Policy_Type,
        Severity_Band,
        COUNT(*) AS Total_Claims

    FROM Claim_Segments

    GROUP BY
        Policy_Type,
        Severity_Band
)

SELECT
    Policy_Type,
    Severity_Band,
    Total_Claims,

    ROUND(
        Total_Claims * 100.0 /
        SUM(Total_Claims) OVER (
            PARTITION BY Policy_Type
        ),
        2
    ) AS Policy_Type_Claim_Share_Pct

FROM Severity_Summary

ORDER BY
    Policy_Type,
    CASE Severity_Band
        WHEN 'Below 10K' THEN 1
        WHEN '10K-25K' THEN 2
        WHEN '25K-50K' THEN 3
        WHEN '50K-100K' THEN 4
        ELSE 5
    END;
    
    
-- Step 6.44 — High-Value Claims by Status

WITH High_Value_Claims AS (
    SELECT
        Claim_ID,
        Claim_Status,
        Claim_Amount
    FROM claims
    WHERE Claim_Amount >= 100000
)

SELECT
    Claim_Status,

    COUNT(*) AS Total_High_Value_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Amount

FROM High_Value_Claims

GROUP BY Claim_Status

ORDER BY Total_High_Value_Claims DESC;



-- Step 6.45 — Claims Exceeding Policy Coverage

WITH Coverage_Validation AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,
        c.Claim_Status,
        p.Policy_Type,
        p.Coverage_Amount,

        CASE
            WHEN c.Claim_Amount > p.Coverage_Amount
            THEN 1
            ELSE 0
        END AS Exceeds_Coverage_Flag

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID
)

SELECT
    Policy_Type,

    COUNT(*) AS Total_Claims,

    SUM(Exceeds_Coverage_Flag) AS Claims_Exceeding_Coverage,

    ROUND(
        SUM(Exceeds_Coverage_Flag) * 100.0 /
        COUNT(*),
        2
    ) AS Exceeding_Coverage_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Exceeds_Coverage_Flag = 1
                THEN Claim_Amount - Coverage_Amount
                ELSE 0
            END
        ), 2
    ) AS Total_Excess_Amount

FROM Coverage_Validation

GROUP BY Policy_Type

ORDER BY Claims_Exceeding_Coverage DESC;

-- Step 6.46 — Claims Exceeding Coverage by Claim Status

WITH Coverage_Exceptions AS (
    SELECT
        c.Claim_ID,
        c.Claim_Status,
        c.Claim_Amount,
        p.Coverage_Amount,

        c.Claim_Amount - p.Coverage_Amount
            AS Excess_Amount

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    WHERE c.Claim_Amount > p.Coverage_Amount
)

SELECT
    Claim_Status,

    COUNT(*) AS Flagged_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Flagged_Claims_Share_Pct,

    ROUND(
        SUM(Excess_Amount), 2
    ) AS Total_Excess_Amount,

    ROUND(
        AVG(Excess_Amount), 2
    ) AS Avg_Excess_Amount

FROM Coverage_Exceptions

GROUP BY Claim_Status

ORDER BY Flagged_Claims DESC;


-- Step 6.47 — Settled Claims Without Payment Records

SELECT
    COUNT(*) AS Settled_Claims_Without_Payment,

    ROUND(
        SUM(c.Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(c.Claim_Amount), 2
    ) AS Avg_Claim_Amount

FROM claims c

LEFT JOIN payments p
    ON c.Claim_ID = p.Claim_ID

WHERE c.Claim_Status = 'Settled'
  AND p.Payment_ID IS NULL;
  
  
-- Step 6.48 — Settled Claims Without Payments by Insurance Type

WITH Settlement_Analysis AS (
    SELECT
        p.Policy_Type,
        c.Claim_ID,
        c.Claim_Amount,

        CASE
            WHEN pay.Payment_ID IS NULL THEN 1
            ELSE 0
        END AS Missing_Payment_Flag

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    LEFT JOIN payments pay
        ON c.Claim_ID = pay.Claim_ID

    WHERE c.Claim_Status = 'Settled'
)

SELECT
    Policy_Type,

    COUNT(*) AS Total_Settled_Claims,

    SUM(Missing_Payment_Flag) AS Settled_Without_Payment,

    ROUND(
        SUM(Missing_Payment_Flag) * 100.0 /
        COUNT(*),
        2
    ) AS Missing_Payment_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Missing_Payment_Flag = 1
                THEN Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS Flagged_Claim_Amount

FROM Settlement_Analysis

GROUP BY Policy_Type

ORDER BY Settled_Without_Payment DESC;


-- Step 6.49 — Claim Type Distribution Analysis

SELECT
    Claim_Type,

    COUNT(*) AS Total_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Severity

FROM claims

GROUP BY Claim_Type

ORDER BY Total_Claims DESC;


-- Step 6.50 — Top 10 Policies by Total Claim Amount

WITH Policy_Claims AS (
    SELECT
        p.Policy_ID,
        p.Policy_Type,
        p.Coverage_Amount,

        COUNT(c.Claim_ID) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Amount

    FROM policies p
    INNER JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Policy_Type,
        p.Coverage_Amount
)

SELECT
    Policy_ID,
    Policy_Type,
    Total_Claims,
    Coverage_Amount,
    Total_Claim_Amount,
    Avg_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Total_Claim_Amount DESC
    ) AS Claim_Amount_Rank

FROM Policy_Claims

ORDER BY Total_Claim_Amount DESC, Policy_ID

LIMIT 10;


-- Step 6.51 — Single vs Multiple-Claim Policy Analysis

WITH Policy_Claims AS (
    SELECT
        Policy_ID,
        COUNT(*) AS Total_Claims,
        SUM(Claim_Amount) AS Total_Claim_Amount

    FROM claims

    GROUP BY Policy_ID
),

Claim_Segments AS (
    SELECT
        CASE
            WHEN Total_Claims = 1 THEN 'Single Claim'
            ELSE 'Multiple Claims'
        END AS Claim_Category,

        Total_Claims,
        Total_Claim_Amount

    FROM Policy_Claims
)

SELECT
    Claim_Category,

    COUNT(*) AS Total_Policies,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        SUM(Total_Claim_Amount) * 100.0 /
        SUM(SUM(Total_Claim_Amount)) OVER (),
        2
    ) AS Claim_Amount_Share_Pct

FROM Claim_Segments

GROUP BY Claim_Category

ORDER BY Total_Policies DESC;


-- Step 6.52 — Claim Frequency Distribution per Policy

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,
        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p
    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY p.Policy_ID
),

Claim_Frequency AS (
    SELECT
        CASE
            WHEN Total_Claims = 0 THEN '0 Claims'
            WHEN Total_Claims = 1 THEN '1 Claim'
            WHEN Total_Claims = 2 THEN '2 Claims'
            WHEN Total_Claims = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Claim_Frequency_Band

    FROM Policy_Claim_Counts
)

SELECT
    Claim_Frequency_Band,

    COUNT(*) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Policy_Share_Pct

FROM Claim_Frequency

GROUP BY Claim_Frequency_Band

ORDER BY
    CASE Claim_Frequency_Band
        WHEN '0 Claims' THEN 1
        WHEN '1 Claim' THEN 2
        WHEN '2 Claims' THEN 3
        WHEN '3 Claims' THEN 4
        ELSE 5
    END;
    
    
-- Step 6.53 — Repeat-Claim Rate by Insurance Type

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,
        p.Policy_Type,
        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p
    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Policy_Type
),

Repeat_Claim_Analysis AS (
    SELECT
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE
                WHEN Total_Claims >= 2 THEN 1
                ELSE 0
            END
        ) AS Repeat_Claim_Policies

    FROM Policy_Claim_Counts

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,
    Repeat_Claim_Policies,

    ROUND(
        Repeat_Claim_Policies * 100.0 /
        NULLIF(Total_Policies, 0),
        2
    ) AS Repeat_Claim_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY Repeat_Claim_Policies * 1.0 /
                 NULLIF(Total_Policies, 0) DESC
    ) AS Repeat_Claim_Rank

FROM Repeat_Claim_Analysis

ORDER BY Repeat_Claim_Rank;


-- Step 6.54 — Claims Concentration Among Top 10% of Policies

WITH Policy_Claims AS (
    SELECT
        p.Policy_ID,
        COALESCE(SUM(c.Claim_Amount), 0) AS Total_Claim_Amount

    FROM policies p
    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY p.Policy_ID
),

Ranked_Policies AS (
    SELECT
        Policy_ID,
        Total_Claim_Amount,

        ROW_NUMBER() OVER (
            ORDER BY Total_Claim_Amount DESC, Policy_ID
        ) AS Policy_Rank,

        COUNT(*) OVER () AS Total_Policies

    FROM Policy_Claims
)

SELECT
    COUNT(*) AS Total_Policies,

    SUM(
        CASE
            WHEN Policy_Rank <= CEIL(Total_Policies * 0.10)
            THEN 1 ELSE 0
        END
    ) AS Top_10_Pct_Policies,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Rank <= CEIL(Total_Policies * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS Top_10_Pct_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Rank <= CEIL(Total_Policies * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(SUM(Total_Claim_Amount), 0),
        2
    ) AS Claim_Amount_Contribution_Pct

FROM Ranked_Policies;


-- Step 6.55 — Claims-to-Annual-Premium Ratio by Insurance Type

WITH Premium_Summary AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Total_Policies,
        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY Policy_Type
),

Claims_Summary AS (
    SELECT
        p.Policy_Type,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    ps.Policy_Type,
    ps.Total_Policies,
    cs.Total_Claims,

    ROUND(
        ps.Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        cs.Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        cs.Total_Claim_Amount * 100.0 /
        NULLIF(ps.Total_Annual_Premium, 0),
        2
    ) AS Claims_To_Premium_Ratio_Pct

FROM Premium_Summary ps

INNER JOIN Claims_Summary cs
    ON ps.Policy_Type = cs.Policy_Type

ORDER BY Claims_To_Premium_Ratio_Pct DESC;


-- Step 6.56 — Yearly Claim Amount Contribution by Insurance Type

WITH Yearly_Claims AS (
    SELECT
        YEAR(c.Claim_Date) AS Claim_Year,
        p.Policy_Type,

        COUNT(*) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        YEAR(c.Claim_Date),
        p.Policy_Type
)

SELECT
    Claim_Year,
    Policy_Type,
    Total_Claims,
    Total_Claim_Amount,

    ROUND(
        Total_Claim_Amount * 100.0 /
        NULLIF(
            SUM(Total_Claim_Amount) OVER (
                PARTITION BY Claim_Year
            ), 0
        ),
        2
    ) AS Yearly_Claim_Amount_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Claim_Year
        ORDER BY Total_Claim_Amount DESC
    ) AS Yearly_Claim_Rank

FROM Yearly_Claims

ORDER BY
    Claim_Year,
    Yearly_Claim_Rank;


-- Step 6.57 — Monthly Claim Status Trend

WITH Monthly_Status AS (
    SELECT
        DATE_FORMAT(Claim_Date, '%Y-%m') AS Claim_Month,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Claim_Status = 'Settled'
            THEN 1 ELSE 0 END
        ) AS Settled_Claims,

        SUM(
            CASE WHEN Claim_Status = 'Approved'
            THEN 1 ELSE 0 END
        ) AS Approved_Claims,

        SUM(
            CASE WHEN Claim_Status = 'Rejected'
            THEN 1 ELSE 0 END
        ) AS Rejected_Claims,

        SUM(
            CASE WHEN Claim_Status = 'Pending'
            THEN 1 ELSE 0 END
        ) AS Pending_Claims

    FROM claims

    GROUP BY DATE_FORMAT(Claim_Date, '%Y-%m')
)

SELECT
    Claim_Month,
    Total_Claims,
    Settled_Claims,
    Approved_Claims,
    Rejected_Claims,
    Pending_Claims,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Pending_Rate_Pct

FROM Monthly_Status

ORDER BY Claim_Month;


-- Step 6.58 — Yearly Claim Status Performance

SELECT
    YEAR(Claim_Date) AS Claim_Year,

    COUNT(*) AS Total_Claims,

    SUM(
        CASE WHEN Claim_Status = 'Settled'
        THEN 1 ELSE 0 END
    ) AS Settled_Claims,

    SUM(
        CASE WHEN Claim_Status = 'Approved'
        THEN 1 ELSE 0 END
    ) AS Approved_Claims,

    SUM(
        CASE WHEN Claim_Status = 'Rejected'
        THEN 1 ELSE 0 END
    ) AS Rejected_Claims,

    SUM(
        CASE WHEN Claim_Status = 'Pending'
        THEN 1 ELSE 0 END
    ) AS Pending_Claims,

    ROUND(
        SUM(
            CASE WHEN Claim_Status = 'Settled'
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS Settled_Rate_Pct,

    ROUND(
        SUM(
            CASE WHEN Claim_Status = 'Pending'
            THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*),
        2
    ) AS Pending_Rate_Pct

FROM claims

GROUP BY YEAR(Claim_Date)

ORDER BY Claim_Year;


-- Step 6.59 — Yearly Claim Severity by Insurance Type

WITH Yearly_Severity AS (
    SELECT
        YEAR(c.Claim_Date) AS Claim_Year,
        p.Policy_Type,

        COUNT(*) AS Total_Claims,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        YEAR(c.Claim_Date),
        p.Policy_Type
)

SELECT
    Claim_Year,
    Policy_Type,
    Total_Claims,
    Avg_Claim_Severity,
    Total_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Claim_Year
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Yearly_Severity

ORDER BY
    Claim_Year,
    Severity_Rank;


-- Step 6.60 — Claims Exceeding Coverage by Year

WITH Coverage_Analysis AS (
    SELECT
        YEAR(c.Claim_Date) AS Claim_Year,
        c.Claim_Amount,
        p.Coverage_Amount,

        CASE
            WHEN c.Claim_Amount > p.Coverage_Amount
            THEN 1
            ELSE 0
        END AS Exceeds_Coverage_Flag

    FROM claims c
    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID
)

SELECT
    Claim_Year,

    COUNT(*) AS Total_Claims,

    SUM(Exceeds_Coverage_Flag) AS Claims_Exceeding_Coverage,

    ROUND(
        SUM(Exceeds_Coverage_Flag) * 100.0 /
        NULLIF(COUNT(*), 0),
        2
    ) AS Exceedance_Rate_Pct,

    ROUND(
        SUM(
            CASE
                WHEN Exceeds_Coverage_Flag = 1
                THEN Claim_Amount - Coverage_Amount
                ELSE 0
            END
        ), 2
    ) AS Total_Excess_Amount

FROM Coverage_Analysis

GROUP BY Claim_Year

ORDER BY Claim_Year;


-- Step 6.61 — Claim Rejection Rate by Region

WITH Regional_Claims AS (
    SELECT
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Rejected'
                THEN 1 ELSE 0
            END
        ) AS Rejected_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount

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
    Rejected_Claims,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Rejection_Rate_Pct,

    Total_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Rejected_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Rejection_Rank

FROM Regional_Claims

ORDER BY Rejection_Rank;



-- Step 6.62 — Regional Claim Severity Analysis

WITH Regional_Severity AS (
    SELECT
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity

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
    Total_Claim_Amount,
    Avg_Claim_Severity,

    ROUND(
        Total_Claim_Amount * 100.0 /
        NULLIF(
            SUM(Total_Claim_Amount) OVER (), 0
        ),
        2
    ) AS Claim_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Regional_Severity

ORDER BY Severity_Rank;



-- Step 6.63 — High-Value Claim Rate by Region

WITH Regional_High_Value AS (
    SELECT
        cu.Region,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Amount >= 100000
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS High_Value_Claim_Amount

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
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS High_Value_Rate_Pct,

    High_Value_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS High_Value_Rank

FROM Regional_High_Value

ORDER BY High_Value_Rank;




-- Step 6.64 — Claim Severity by Customer Age Group

WITH Age_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        c.Claim_ID,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Claims,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Severity,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct

FROM Age_Group_Claims

GROUP BY Age_Group

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;



-- Step 6.65 — Claim Frequency per Policy by Customer Age Group

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,

        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        Age_Group
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Policies,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE
            WHEN Total_Claims >= 2 THEN 1
            ELSE 0
        END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE
                WHEN Total_Claims >= 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Counts

GROUP BY Age_Group

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;



-- Step 6.66 — Claim Rejection Rate by Customer Age Group

WITH Age_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        c.Claim_Status

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

Rejection_Summary AS (
    SELECT
        Age_Group,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Claim_Status = 'Rejected'
                THEN 1 ELSE 0
            END
        ) AS Rejected_Claims

    FROM Age_Group_Claims

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Claims,
    Rejected_Claims,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Rejection_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY Rejected_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Rejection_Rank

FROM Rejection_Summary

ORDER BY Rejection_Rank;



-- Step 6.67 — High-Value Claim Rate by Customer Age Group

WITH Age_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

High_Value_Summary AS (
    SELECT
        Age_Group,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN Claim_Amount >= 100000
                    THEN Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS High_Value_Claim_Amount

    FROM Age_Group_Claims

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Claims,
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS High_Value_Rate_Pct,

    High_Value_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS High_Value_Rank

FROM High_Value_Summary

ORDER BY High_Value_Rank;



-- Step 6.68 — Claim Status Distribution by Customer Age Group

WITH Age_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        c.Claim_Status

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Claims,

    SUM(CASE WHEN Claim_Status = 'Settled'
        THEN 1 ELSE 0 END) AS Settled_Claims,

    SUM(CASE WHEN Claim_Status = 'Approved'
        THEN 1 ELSE 0 END) AS Approved_Claims,

    SUM(CASE WHEN Claim_Status = 'Rejected'
        THEN 1 ELSE 0 END) AS Rejected_Claims,

    SUM(CASE WHEN Claim_Status = 'Pending'
        THEN 1 ELSE 0 END) AS Pending_Claims,

    ROUND(
        SUM(CASE WHEN Claim_Status = 'Settled'
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS Settled_Rate_Pct,

    ROUND(
        SUM(CASE WHEN Claim_Status = 'Pending'
            THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
        2
    ) AS Pending_Rate_Pct

FROM Age_Group_Claims

GROUP BY Age_Group

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;
    
    
    
-- Step 6.69 — Pending Claim Amount by Insurance Type

WITH Pending_Claims AS (
    SELECT
        p.Policy_Type,
        c.Claim_ID,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    WHERE c.Claim_Status = 'Pending'
),

Pending_Summary AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Pending_Claims,
        ROUND(SUM(Claim_Amount), 2) AS Pending_Claim_Amount,
        ROUND(AVG(Claim_Amount), 2) AS Avg_Pending_Claim

    FROM Pending_Claims

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Pending_Claims,
    Pending_Claim_Amount,
    Avg_Pending_Claim,

    ROUND(
        Pending_Claim_Amount * 100.0 /
        NULLIF(SUM(Pending_Claim_Amount) OVER (), 0),
        2
    ) AS Pending_Amount_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Pending_Claim_Amount DESC
    ) AS Pending_Amount_Rank

FROM Pending_Summary

ORDER BY Pending_Amount_Rank;


-- Step 6.70 — Pending Claim Rate by Region

WITH Regional_Pending AS (
    SELECT
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Pending'
                THEN 1 ELSE 0
            END
        ) AS Pending_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Status = 'Pending'
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS Pending_Claim_Amount

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
    Pending_Claims,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Pending_Rate_Pct,

    Pending_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Pending_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Pending_Rank

FROM Regional_Pending

ORDER BY Pending_Rank;


-- Step 6.71 — Claim Amount Distribution by Customer Gender

WITH Gender_Claims AS (
    SELECT
        cu.Gender,

        COUNT(c.Claim_ID) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity

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
    Total_Claim_Amount,
    Avg_Claim_Severity,

    ROUND(
        Total_Claims * 100.0 /
        NULLIF(SUM(Total_Claims) OVER (), 0),
        2
    ) AS Claim_Share_Pct,

    ROUND(
        Total_Claim_Amount * 100.0 /
        NULLIF(SUM(Total_Claim_Amount) OVER (), 0),
        2
    ) AS Claim_Amount_Share_Pct

FROM Gender_Claims

ORDER BY Total_Claims DESC;




-- Step 6.72 — Claim Frequency per Policy by Customer Gender

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,
        cu.Gender,

        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        cu.Gender
)

SELECT
    Gender,

    COUNT(*) AS Total_Policies,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE
            WHEN Total_Claims >= 2 THEN 1
            ELSE 0
        END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE
                WHEN Total_Claims >= 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Counts

GROUP BY Gender

ORDER BY Total_Policies DESC;



-- Step 6.73 — Claim Severity by Customer Income Group

WITH Income_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        c.Claim_ID,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

Income_Summary AS (
    SELECT
        Income_Group,

        COUNT(*) AS Total_Claims,

        ROUND(
            AVG(Claim_Amount), 2
        ) AS Avg_Claim_Severity,

        ROUND(
            SUM(Claim_Amount), 2
        ) AS Total_Claim_Amount

    FROM Income_Group_Claims

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Claims,
    Avg_Claim_Severity,
    Total_Claim_Amount,

    ROUND(
        Total_Claims * 100.0 /
        NULLIF(SUM(Total_Claims) OVER (), 0),
        2
    ) AS Claim_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Income_Summary

ORDER BY Severity_Rank;


-- Step 6.74 — Claim Frequency per Policy by Customer Income Group

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,

        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        Income_Group
)

SELECT
    Income_Group,

    COUNT(*) AS Total_Policies,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE
            WHEN Total_Claims >= 2 THEN 1
            ELSE 0
        END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE
                WHEN Total_Claims >= 2 THEN 1
                ELSE 0
            END
        ) * 100.0 / NULLIF(COUNT(*), 0),
        2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Counts

GROUP BY Income_Group

ORDER BY
    CASE Income_Group
        WHEN 'Below 3L' THEN 1
        WHEN '3L-6L' THEN 2
        WHEN '6L-10L' THEN 3
        ELSE 4
    END;
    
    

-- Step 6.75 — High-Value Claim Rate by Customer Income Group

WITH Income_Group_Claims AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

High_Value_Summary AS (
    SELECT
        Income_Group,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN Claim_Amount >= 100000
                    THEN Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS High_Value_Claim_Amount

    FROM Income_Group_Claims

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Claims,
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS High_Value_Rate_Pct,

    High_Value_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS High_Value_Rank

FROM High_Value_Summary

ORDER BY High_Value_Rank;


-- Step 6.76 — Claim Rejection Rate by Customer Income Group

WITH Income_Rejections AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        c.Claim_Status

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

Rejection_Summary AS (
    SELECT
        Income_Group,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN Claim_Status = 'Rejected'
                THEN 1 ELSE 0
            END
        ) AS Rejected_Claims

    FROM Income_Rejections

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Claims,
    Rejected_Claims,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Rejection_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY Rejected_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Rejection_Rank

FROM Rejection_Summary

ORDER BY Rejection_Rank;



-- Step 6.77 — Pending Claim Rate by Customer Income Group

WITH Income_Pending AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        c.Claim_Status,
        c.Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID
),

Pending_Summary AS (
    SELECT
        Income_Group,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE WHEN Claim_Status = 'Pending'
            THEN 1 ELSE 0 END
        ) AS Pending_Claims,

        ROUND(
            SUM(
                CASE WHEN Claim_Status = 'Pending'
                THEN Claim_Amount ELSE 0 END
            ), 2
        ) AS Pending_Claim_Amount

    FROM Income_Pending

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Claims,
    Pending_Claims,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Pending_Rate_Pct,

    Pending_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Pending_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Pending_Rank

FROM Pending_Summary

ORDER BY Pending_Rank;



-- Step 6.78 — Claim Severity by Policy Status

WITH Policy_Status_Claims AS (
    SELECT
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    Policy_Status,
    Total_Claims,
    Total_Claim_Amount,
    Avg_Claim_Severity,

    ROUND(
        Total_Claims * 100.0 /
        NULLIF(SUM(Total_Claims) OVER (), 0),
        2
    ) AS Claim_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Policy_Status_Claims

ORDER BY Severity_Rank;



-- Step 6.79 — Claim Submission Date vs Policy Coverage Period

WITH Claim_Coverage_Validation AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,

        CASE
            WHEN c.Claim_Date < p.Start_Date
                THEN 'Before Policy Start'

            WHEN c.Claim_Date > p.End_Date
                THEN 'After Policy End'

            ELSE 'Within Coverage Period'
        END AS Coverage_Category

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID
),

Coverage_Summary AS (
    SELECT
        Coverage_Category,

        COUNT(*) AS Total_Claims,

        ROUND(
            SUM(Claim_Amount), 2
        ) AS Total_Claim_Amount

    FROM Claim_Coverage_Validation

    GROUP BY Coverage_Category
)

SELECT
    Coverage_Category,
    Total_Claims,
    Total_Claim_Amount,

    ROUND(
        Total_Claims * 100.0 /
        NULLIF(SUM(Total_Claims) OVER (), 0),
        2
    ) AS Claim_Share_Pct

FROM Coverage_Summary

ORDER BY
    CASE Coverage_Category
        WHEN 'Before Policy Start' THEN 1
        WHEN 'Within Coverage Period' THEN 2
        ELSE 3
    END;
    
    

-- Step 6.80 — Claim Status Distribution by Insurance Type

WITH Policy_Claim_Status AS (
    SELECT
        p.Policy_Type,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE WHEN c.Claim_Status = 'Settled'
            THEN 1 ELSE 0 END
        ) AS Settled_Claims,

        SUM(
            CASE WHEN c.Claim_Status = 'Approved'
            THEN 1 ELSE 0 END
        ) AS Approved_Claims,

        SUM(
            CASE WHEN c.Claim_Status = 'Rejected'
            THEN 1 ELSE 0 END
        ) AS Rejected_Claims,

        SUM(
            CASE WHEN c.Claim_Status = 'Pending'
            THEN 1 ELSE 0 END
        ) AS Pending_Claims

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    Policy_Type,
    Total_Claims,
    Settled_Claims,
    Approved_Claims,
    Rejected_Claims,
    Pending_Claims,

    ROUND(
        Settled_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Settled_Rate_Pct,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Rejection_Rate_Pct,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS Pending_Rate_Pct

FROM Policy_Claim_Status

ORDER BY Total_Claims DESC;



-- Step 6.81 — Claim Severity by Repeat-Claim Category

WITH Policy_Claims AS (
    SELECT
        p.Policy_ID,
        COUNT(c.Claim_ID) AS Total_Claims

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY p.Policy_ID
),

Claim_Categories AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,

        CASE
            WHEN pc.Total_Claims = 1 THEN 'Single Claim'
            WHEN pc.Total_Claims >= 2 THEN 'Repeat Claims'
        END AS Claim_Category

    FROM claims c

    INNER JOIN Policy_Claims pc
        ON c.Policy_ID = pc.Policy_ID
)

SELECT
    Claim_Category,

    COUNT(*) AS Total_Claims,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Severity,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct

FROM Claim_Categories

GROUP BY Claim_Category

ORDER BY Avg_Claim_Severity DESC;



-- Step 6.82 — Claim Severity by Claim Frequency Band

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY p.Policy_ID
),

Claim_Frequency AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,

        CASE
            WHEN pc.Claim_Count = 1 THEN '1 Claim'
            WHEN pc.Claim_Count = 2 THEN '2 Claims'
            WHEN pc.Claim_Count = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Frequency_Band

    FROM claims c

    INNER JOIN Policy_Claim_Counts pc
        ON c.Policy_ID = pc.Policy_ID
)

SELECT
    Frequency_Band,

    COUNT(*) AS Total_Claims,

    ROUND(
        AVG(Claim_Amount), 2
    ) AS Avg_Claim_Severity,

    ROUND(
        SUM(Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (),
        2
    ) AS Claim_Share_Pct

FROM Claim_Frequency

GROUP BY Frequency_Band

ORDER BY
    CASE Frequency_Band
        WHEN '1 Claim' THEN 1
        WHEN '2 Claims' THEN 2
        WHEN '3 Claims' THEN 3
        ELSE 4
    END;
    

-- Step 6.83 — Claim Severity by Insurance Type and Claim Frequency

WITH Policy_Claim_Counts AS (
    SELECT
        p.Policy_ID,
        p.Policy_Type,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Policy_Type
),

Claim_Frequency AS (
    SELECT
        pc.Policy_Type,
        c.Claim_Amount,

        CASE
            WHEN pc.Claim_Count = 1 THEN '1 Claim'
            WHEN pc.Claim_Count = 2 THEN '2 Claims'
            WHEN pc.Claim_Count = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Frequency_Band

    FROM claims c

    INNER JOIN Policy_Claim_Counts pc
        ON c.Policy_ID = pc.Policy_ID
),

Severity_Summary AS (
    SELECT
        Policy_Type,
        Frequency_Band,

        COUNT(*) AS Total_Claims,

        ROUND(
            AVG(Claim_Amount), 2
        ) AS Avg_Claim_Severity,

        ROUND(
            SUM(Claim_Amount), 2
        ) AS Total_Claim_Amount

    FROM Claim_Frequency

    GROUP BY
        Policy_Type,
        Frequency_Band
)

SELECT
    Policy_Type,
    Frequency_Band,
    Total_Claims,
    Avg_Claim_Severity,
    Total_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Severity_Summary

ORDER BY
    Policy_Type,
    Severity_Rank;
    


-- Step 6.84 — Claim Amount Concentration by Customer

WITH Customer_Claims AS (
    SELECT
        p.Customer_ID,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Customer_ID
),

Customer_Ranking AS (
    SELECT
        Customer_ID,
        Total_Claims,
        Total_Claim_Amount,

        ROW_NUMBER() OVER (
            ORDER BY Total_Claim_Amount DESC, Customer_ID
        ) AS Claim_Rank,

        COUNT(*) OVER () AS Total_Customers

    FROM Customer_Claims
)

SELECT
    MAX(Total_Customers) AS Customers_With_Claims,

    SUM(
        CASE
            WHEN Claim_Rank <= CEIL(Total_Customers * 0.10)
            THEN 1 ELSE 0
        END
    ) AS Top_10_Pct_Customers,

    ROUND(
        SUM(
            CASE
                WHEN Claim_Rank <= CEIL(Total_Customers * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS Top_10_Pct_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Claim_Rank <= CEIL(Total_Customers * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(SUM(Total_Claim_Amount), 0),
        2
    ) AS Claim_Amount_Contribution_Pct

FROM Customer_Ranking;


-- Step 6.85 — Top 10% Customer Claim Concentration by Region

WITH Customer_Claims AS (
    SELECT
        cu.Region,
        cu.Customer_ID,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM customers cu

    INNER JOIN policies p
        ON cu.Customer_ID = p.Customer_ID

    INNER JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        cu.Region,
        cu.Customer_ID
),

Regional_Ranking AS (
    SELECT
        Region,
        Customer_ID,
        Total_Claim_Amount,

        ROW_NUMBER() OVER (
            PARTITION BY Region
            ORDER BY Total_Claim_Amount DESC, Customer_ID
        ) AS Customer_Rank,

        COUNT(*) OVER (
            PARTITION BY Region
        ) AS Regional_Customers

    FROM Customer_Claims
)

SELECT
    Region,

    COUNT(*) AS Customers_With_Claims,

    SUM(
        CASE
            WHEN Customer_Rank <= CEIL(Regional_Customers * 0.10)
            THEN 1 ELSE 0
        END
    ) AS Top_10_Pct_Customers,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Customer_Rank <= CEIL(Regional_Customers * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS Top_10_Pct_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Customer_Rank <= CEIL(Regional_Customers * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(SUM(Total_Claim_Amount), 0),
        2
    ) AS Concentration_Pct

FROM Regional_Ranking

GROUP BY Region

ORDER BY Concentration_Pct DESC;



-- Step 6.86 — Claim Amount Concentration by Insurance Type

WITH Policy_Claims AS (
    SELECT
        p.Policy_Type,
        p.Policy_ID,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM policies p

    INNER JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_Type,
        p.Policy_ID
),

Policy_Ranking AS (
    SELECT
        Policy_Type,
        Policy_ID,
        Total_Claim_Amount,

        ROW_NUMBER() OVER (
            PARTITION BY Policy_Type
            ORDER BY Total_Claim_Amount DESC, Policy_ID
        ) AS Policy_Rank,

        COUNT(*) OVER (
            PARTITION BY Policy_Type
        ) AS Policies_With_Claims

    FROM Policy_Claims
)

SELECT
    Policy_Type,

    COUNT(*) AS Policies_With_Claims,

    SUM(
        CASE
            WHEN Policy_Rank <= CEIL(Policies_With_Claims * 0.10)
            THEN 1 ELSE 0
        END
    ) AS Top_10_Pct_Policies,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Rank <= CEIL(Policies_With_Claims * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ), 2
    ) AS Top_10_Pct_Claim_Amount,

    ROUND(
        SUM(
            CASE
                WHEN Policy_Rank <= CEIL(Policies_With_Claims * 0.10)
                THEN Total_Claim_Amount
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(SUM(Total_Claim_Amount), 0),
        2
    ) AS Concentration_Pct

FROM Policy_Ranking

GROUP BY Policy_Type

ORDER BY Concentration_Pct DESC;




-- Step 6.87 — High-Value Claim Rate by Policy Status

WITH Policy_Status_Claims AS (
    SELECT
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Amount >= 100000
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS High_Value_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    Policy_Status,
    Total_Claims,
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS High_Value_Rate_Pct,

    High_Value_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS High_Value_Rank

FROM Policy_Status_Claims

ORDER BY High_Value_Rank;


-- Step 6.88 — Claim Rejection Rate by Policy Status

WITH Policy_Rejections AS (
    SELECT
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Rejected'
                THEN 1 ELSE 0
            END
        ) AS Rejected_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Status = 'Rejected'
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS Rejected_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    Policy_Status,
    Total_Claims,
    Rejected_Claims,

    ROUND(
        Rejected_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Rejection_Rate_Pct,

    Rejected_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Rejected_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Rejection_Rank

FROM Policy_Rejections

ORDER BY Rejection_Rank;


-- Step 6.89 — Pending Claim Rate by Policy Status

WITH Policy_Pending AS (
    SELECT
        p.Policy_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Status = 'Pending'
                THEN 1 ELSE 0
            END
        ) AS Pending_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Status = 'Pending'
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS Pending_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    Policy_Status,
    Total_Claims,
    Pending_Claims,

    ROUND(
        Pending_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS Pending_Rate_Pct,

    Pending_Claim_Amount,

    DENSE_RANK() OVER (
        ORDER BY Pending_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS Pending_Rank

FROM Policy_Pending

ORDER BY Pending_Rank;


-- Step 6.90 — Claim Amount Distribution by Claim Status and Policy Status

WITH Claim_Status_Summary AS (
    SELECT
        p.Policy_Status,
        c.Claim_Status,

        COUNT(c.Claim_ID) AS Total_Claims,

        ROUND(
            SUM(c.Claim_Amount), 2
        ) AS Total_Claim_Amount,

        ROUND(
            AVG(c.Claim_Amount), 2
        ) AS Avg_Claim_Severity

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        p.Policy_Status,
        c.Claim_Status
)

SELECT
    Policy_Status,
    Claim_Status,
    Total_Claims,
    Total_Claim_Amount,
    Avg_Claim_Severity,

    ROUND(
        Total_Claims * 100.0 /
        NULLIF(
            SUM(Total_Claims) OVER (
                PARTITION BY Policy_Status
            ), 0
        ),
        2
    ) AS Status_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Status
        ORDER BY Avg_Claim_Severity DESC
    ) AS Severity_Rank

FROM Claim_Status_Summary

ORDER BY
    Policy_Status,
    Severity_Rank;
    
-- Step 6.91 — High-Value Claim Distribution by Claim Status and Policy Status

WITH High_Value_Summary AS (
    SELECT
        p.Policy_Status,
        c.Claim_Status,

        COUNT(*) AS Total_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        ROUND(
            SUM(
                CASE
                    WHEN c.Claim_Amount >= 100000
                    THEN c.Claim_Amount
                    ELSE 0
                END
            ), 2
        ) AS High_Value_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY
        p.Policy_Status,
        c.Claim_Status
)

SELECT
    Policy_Status,
    Claim_Status,
    Total_Claims,
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0),
        2
    ) AS High_Value_Rate_Pct,

    High_Value_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Status
        ORDER BY High_Value_Claims * 1.0 /
                 NULLIF(Total_Claims, 0) DESC
    ) AS High_Value_Rank

FROM High_Value_Summary

ORDER BY
    Policy_Status,
    High_Value_Rank;
    

-- Step 6.92 — High-Value Claim Amount Contribution by Insurance Type

WITH Policy_Severity AS (
    SELECT
        p.Policy_Type,

        COUNT(*) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS High_Value_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    GROUP BY p.Policy_Type
)

SELECT
    Policy_Type,
    Total_Claims,
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS High_Value_Rate_Pct,

    ROUND(
        High_Value_Claim_Amount, 2
    ) AS High_Value_Claim_Amount,

    ROUND(
        High_Value_Claim_Amount * 100.0 /
        NULLIF(Total_Claim_Amount, 0), 2
    ) AS High_Value_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claim_Amount * 1.0 /
                 NULLIF(Total_Claim_Amount, 0) DESC
    ) AS Contribution_Rank

FROM Policy_Severity

ORDER BY Contribution_Rank;


-- Step 6.93 — High-Value Claim Amount Contribution by Region

WITH Regional_Severity AS (
    SELECT
        cu.Region,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS High_Value_Claim_Amount

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
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS High_Value_Rate_Pct,

    ROUND(
        High_Value_Claim_Amount, 2
    ) AS High_Value_Claim_Amount,

    ROUND(
        High_Value_Claim_Amount * 100.0 /
        NULLIF(Total_Claim_Amount, 0), 2
    ) AS High_Value_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claim_Amount * 1.0 /
                 NULLIF(Total_Claim_Amount, 0) DESC
    ) AS Contribution_Rank

FROM Regional_Severity

ORDER BY Contribution_Rank;



-- Step 6.94 — High-Value Claim Amount Contribution by Customer Age Group

WITH Age_Group_Severity AS (
    SELECT
        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS High_Value_Claim_Amount

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
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS High_Value_Rate_Pct,

    ROUND(
        High_Value_Claim_Amount, 2
    ) AS High_Value_Claim_Amount,

    ROUND(
        High_Value_Claim_Amount * 100.0 /
        NULLIF(Total_Claim_Amount, 0), 2
    ) AS High_Value_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claim_Amount * 1.0 /
                 NULLIF(Total_Claim_Amount, 0) DESC
    ) AS Contribution_Rank

FROM Age_Group_Severity

ORDER BY Contribution_Rank;


-- Step 6.95 — High-Value Claim Amount Contribution by Customer Income Group

WITH Income_Group_Severity AS (
    SELECT
        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Total_Claims,

        SUM(c.Claim_Amount) AS Total_Claim_Amount,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN 1 ELSE 0
            END
        ) AS High_Value_Claims,

        SUM(
            CASE
                WHEN c.Claim_Amount >= 100000
                THEN c.Claim_Amount
                ELSE 0
            END
        ) AS High_Value_Claim_Amount

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
    High_Value_Claims,

    ROUND(
        High_Value_Claims * 100.0 /
        NULLIF(Total_Claims, 0), 2
    ) AS High_Value_Rate_Pct,

    ROUND(
        High_Value_Claim_Amount, 2
    ) AS High_Value_Claim_Amount,

    ROUND(
        High_Value_Claim_Amount * 100.0 /
        NULLIF(Total_Claim_Amount, 0), 2
    ) AS High_Value_Amount_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY High_Value_Claim_Amount * 1.0 /
                 NULLIF(Total_Claim_Amount, 0) DESC
    ) AS Contribution_Rank

FROM Income_Group_Severity

ORDER BY Contribution_Rank;
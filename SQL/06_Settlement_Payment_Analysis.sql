
-- 06. Settlement & Payment Analysis


-- 06. Settlement & Payment Analysis
-- Step 1: Verify payment table structure

SHOW TABLES LIKE '%payment%';


-- Step 2: Check payments table columns and data types

DESCRIBE payments;


-- 01. Payment Overview & Financial KPIs
-- Measure payment volume, total payout and average payment

SELECT
    COUNT(*) AS Total_Payments,
    COUNT(DISTINCT Claim_ID) AS Paid_Claims,

    ROUND(SUM(Payment_Amount), 2) AS Total_Payout,

    ROUND(AVG(Payment_Amount), 2) AS Average_Payment,

    ROUND(MIN(Payment_Amount), 2) AS Minimum_Payment,

    ROUND(MAX(Payment_Amount), 2) AS Maximum_Payment

FROM payments;



-- 02. Payment Method Performance Analysis
-- Analyze payment volume and payout distribution

SELECT
    Payment_Method,

    COUNT(*) AS Total_Payments,

    ROUND(SUM(Payment_Amount), 2) AS Total_Payout,

    ROUND(AVG(Payment_Amount), 2) AS Average_Payment,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS Payment_Share_Pct,

    ROUND(
        100.0 * SUM(Payment_Amount) /
        NULLIF(SUM(SUM(Payment_Amount)) OVER (), 0),
        2
    ) AS Payout_Contribution_Pct

FROM payments

GROUP BY Payment_Method

ORDER BY Total_Payout DESC;




-- 03. Monthly Payment Trends
-- Analyze monthly payout performance and growth

WITH Monthly_Payments AS (
    SELECT
        DATE_FORMAT(Payment_Date, '%Y-%m') AS Payment_Month,
        COUNT(*) AS Total_Payments,
        SUM(Payment_Amount) AS Total_Payout,
        AVG(Payment_Amount) AS Average_Payment

    FROM payments

    WHERE Payment_Date IS NOT NULL

    GROUP BY DATE_FORMAT(Payment_Date, '%Y-%m')
),

Payment_Growth AS (
    SELECT
        Payment_Month,
        Total_Payments,
        Total_Payout,
        Average_Payment,

        LAG(Total_Payout) OVER (
            ORDER BY Payment_Month
        ) AS Previous_Month_Payout,

        LAG(Payment_Month) OVER (
            ORDER BY Payment_Month
        ) AS Previous_Payment_Month

    FROM Monthly_Payments
)

SELECT
    Payment_Month,
    Total_Payments,

    ROUND(Total_Payout, 2) AS Total_Payout,
    ROUND(Average_Payment, 2) AS Average_Payment,

    ROUND(Previous_Month_Payout, 2)
        AS Previous_Month_Payout,

    CASE
        WHEN PERIOD_DIFF(
            REPLACE(Payment_Month, '-', ''),
            REPLACE(Previous_Payment_Month, '-', '')
        ) = 1

        THEN ROUND(
            100.0 * (Total_Payout - Previous_Month_Payout)
            / NULLIF(Previous_Month_Payout, 0),
            2
        )

        ELSE NULL
    END AS MoM_Payout_Growth_Pct

FROM Payment_Growth

ORDER BY Payment_Month;




-- 04. Yearly Payment Performance Analysis
-- Analyze annual payout trends and YoY growth

WITH Yearly_Payments AS (
    SELECT
        YEAR(Payment_Date) AS Payment_Year,
        COUNT(*) AS Total_Payments,
        SUM(Payment_Amount) AS Total_Payout,
        AVG(Payment_Amount) AS Average_Payment

    FROM payments

    WHERE Payment_Date IS NOT NULL

    GROUP BY YEAR(Payment_Date)
),

Yearly_Growth AS (
    SELECT
        Payment_Year,
        Total_Payments,
        Total_Payout,
        Average_Payment,

        LAG(Total_Payout) OVER (
            ORDER BY Payment_Year
        ) AS Previous_Year_Payout

    FROM Yearly_Payments
)

SELECT
    Payment_Year,
    Total_Payments,

    ROUND(Total_Payout, 2) AS Total_Payout,
    ROUND(Average_Payment, 2) AS Average_Payment,

    ROUND(Previous_Year_Payout, 2)
        AS Previous_Year_Payout,

    ROUND(
        100.0 * (Total_Payout - Previous_Year_Payout)
        / NULLIF(Previous_Year_Payout, 0),
        2
    ) AS YoY_Payout_Growth_Pct

FROM Yearly_Growth

ORDER BY Payment_Year;



-- 05. Inspect Claims Table Structure
-- Identify fields needed for settlement delay analysis

DESCRIBE claims;




-- 06. Claim Payment Turnaround Analysis
-- Measure days between claim submission and payment

WITH Payment_Turnaround AS (
    SELECT
        c.Claim_ID,
        c.Claim_Date,
        p.Payment_Date,
        p.Payment_Amount,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Date IS NOT NULL
      AND p.Payment_Date IS NOT NULL
)

SELECT
    COUNT(*) AS Total_Paid_Claims,

    ROUND(AVG(Turnaround_Days), 2)
        AS Average_Turnaround_Days,

    MIN(Turnaround_Days)
        AS Minimum_Turnaround_Days,

    MAX(Turnaround_Days)
        AS Maximum_Turnaround_Days,

    SUM(CASE
        WHEN Turnaround_Days <= 30
         AND Turnaround_Days >= 0
        THEN 1 ELSE 0
    END) AS Paid_Within_30_Days,

    SUM(CASE
        WHEN Turnaround_Days > 30
        THEN 1 ELSE 0
    END) AS Paid_After_30_Days,

    SUM(CASE
        WHEN Turnaround_Days < 0
        THEN 1 ELSE 0
    END) AS Invalid_Payment_Chronology,

    ROUND(
        100.0 * SUM(CASE
            WHEN Turnaround_Days BETWEEN 0 AND 30
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS Within_30_Days_Pct

FROM Payment_Turnaround;




-- 07. Payment Turnaround Distribution
-- Categorize claims based on payment turnaround days

WITH Payment_Turnaround AS (
    SELECT
        c.Claim_ID,
        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Date IS NOT NULL
      AND p.Payment_Date IS NOT NULL
),

Turnaround_Buckets AS (
    SELECT
        Claim_ID,

        CASE
            WHEN Turnaround_Days < 0
                THEN 'Invalid Chronology'
            WHEN Turnaround_Days <= 15
                THEN '0-15 Days'
            WHEN Turnaround_Days <= 30
                THEN '16-30 Days'
            WHEN Turnaround_Days <= 60
                THEN '31-60 Days'
            ELSE '61+ Days'
        END AS Turnaround_Category

    FROM Payment_Turnaround
)

SELECT
    Turnaround_Category,

    COUNT(*) AS Total_Claims,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS Claim_Share_Pct

FROM Turnaround_Buckets

GROUP BY Turnaround_Category

ORDER BY
    CASE Turnaround_Category
        WHEN '0-15 Days' THEN 1
        WHEN '16-30 Days' THEN 2
        WHEN '31-60 Days' THEN 3
        WHEN '61+ Days' THEN 4
        ELSE 5
    END;
    
    


-- 08. Payment Delay Analysis by Claim Type
-- Compare payment turnaround across claim types

WITH Claim_Payments AS (
    SELECT
        c.Claim_ID,
        c.Claim_Type,
        p.Payment_Amount,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Date IS NOT NULL
      AND p.Payment_Date IS NOT NULL
),

Claim_Type_Performance AS (
    SELECT
        Claim_Type,

        COUNT(*) AS Paid_Claims,

        ROUND(AVG(Turnaround_Days), 2)
            AS Average_Turnaround_Days,

        SUM(CASE
            WHEN Turnaround_Days > 30
            THEN 1 ELSE 0
        END) AS Payments_After_30_Days,

        ROUND(
            100.0 * SUM(CASE
                WHEN Turnaround_Days > 30
                THEN 1 ELSE 0
            END) / NULLIF(COUNT(*), 0),
            2
        ) AS Delay_Rate_Pct,

        ROUND(SUM(Payment_Amount), 2)
            AS Total_Payout

    FROM Claim_Payments

    GROUP BY Claim_Type
)

SELECT
    *,

    DENSE_RANK() OVER (
        ORDER BY Delay_Rate_Pct DESC
    ) AS Delay_Rank

FROM Claim_Type_Performance

ORDER BY Delay_Rank, Claim_Type;




-- 09. Payment Turnaround by Payment Method
-- Compare turnaround performance across payment methods

WITH Payment_Delays AS (
    SELECT
        p.Payment_ID,
        p.Payment_Method,
        p.Payment_Amount,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM payments AS p

    INNER JOIN claims AS c
        ON p.Claim_ID = c.Claim_ID

    WHERE p.Payment_Date IS NOT NULL
      AND c.Claim_Date IS NOT NULL
)

SELECT
    Payment_Method,

    COUNT(*) AS Total_Payments,

    ROUND(AVG(Turnaround_Days), 2)
        AS Average_Turnaround_Days,

    SUM(CASE
        WHEN Turnaround_Days BETWEEN 0 AND 30
        THEN 1 ELSE 0
    END) AS Paid_Within_30_Days,

    SUM(CASE
        WHEN Turnaround_Days > 30
        THEN 1 ELSE 0
    END) AS Paid_After_30_Days,

    ROUND(
        100.0 * SUM(CASE
            WHEN Turnaround_Days > 30
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS Delay_Rate_Pct,

    ROUND(AVG(CASE
        WHEN Turnaround_Days > 30
        THEN Payment_Amount
    END), 2) AS Average_Delayed_Payment

FROM Payment_Delays

GROUP BY Payment_Method

ORDER BY Delay_Rate_Pct DESC;




-- 10. Delayed Payment Financial Exposure
-- Analyze payout value by payment turnaround category

WITH Payment_Details AS (
    SELECT
        p.Payment_ID,
        p.Payment_Amount,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM payments AS p

    INNER JOIN claims AS c
        ON p.Claim_ID = c.Claim_ID

    WHERE p.Payment_Date IS NOT NULL
      AND c.Claim_Date IS NOT NULL
),

Payment_Categories AS (
    SELECT
        Payment_ID,
        Payment_Amount,

        CASE
            WHEN Turnaround_Days < 0
                THEN 'Invalid Chronology'
            WHEN Turnaround_Days <= 30
                THEN 'Within 30 Days'
            ELSE 'After 30 Days'
        END AS Payment_Category

    FROM Payment_Details
)

SELECT
    Payment_Category,

    COUNT(*) AS Total_Payments,

    ROUND(SUM(Payment_Amount), 2)
        AS Total_Payout,

    ROUND(AVG(Payment_Amount), 2)
        AS Average_Payment,

    ROUND(
        100.0 * SUM(Payment_Amount) /
        NULLIF(SUM(SUM(Payment_Amount)) OVER (), 0),
        2
    ) AS Payout_Contribution_Pct

FROM Payment_Categories

GROUP BY Payment_Category

ORDER BY Total_Payout DESC;



-- 11. Payment Turnaround by Claim Amount Band
-- Compare turnaround performance across claim value segments

WITH Claim_Payment_Details AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,
        p.Payment_Amount,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Amount IS NOT NULL
      AND c.Claim_Date IS NOT NULL
      AND p.Payment_Date IS NOT NULL
),

Claim_Bands AS (
    SELECT
        Claim_ID,
        Payment_Amount,
        Turnaround_Days,

        CASE
            WHEN Claim_Amount < 10000
                THEN 'Below 10K'
            WHEN Claim_Amount < 50000
                THEN '10K-50K'
            WHEN Claim_Amount < 100000
                THEN '50K-100K'
            WHEN Claim_Amount < 250000
                THEN '100K-250K'
            ELSE '250K+'
        END AS Claim_Amount_Band

    FROM Claim_Payment_Details
)

SELECT
    Claim_Amount_Band,

    COUNT(*) AS Paid_Claims,

    ROUND(AVG(Turnaround_Days), 2)
        AS Average_Turnaround_Days,

    ROUND(
        100.0 * SUM(CASE
            WHEN Turnaround_Days > 30
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS Delay_Rate_Pct,

    ROUND(AVG(Payment_Amount), 2)
        AS Average_Payment,

    ROUND(SUM(Payment_Amount), 2)
        AS Total_Payout

FROM Claim_Bands

GROUP BY Claim_Amount_Band

ORDER BY
    CASE Claim_Amount_Band
        WHEN 'Below 10K' THEN 1
        WHEN '10K-50K' THEN 2
        WHEN '50K-100K' THEN 3
        WHEN '100K-250K' THEN 4
        ELSE 5
    END;
    

-- 12. Claim Payment Coverage Analysis
-- Compare payment amounts against original claim amounts

WITH Claim_Payment_Coverage AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,
        p.Payment_Amount,

        100.0 * p.Payment_Amount /
            NULLIF(c.Claim_Amount, 0)
            AS Payment_Coverage_Pct

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Amount > 0
      AND p.Payment_Amount IS NOT NULL
),

Coverage_Classification AS (
    SELECT
        Claim_ID,
        Claim_Amount,
        Payment_Amount,
        Payment_Coverage_Pct,

        CASE
            WHEN Payment_Coverage_Pct < 50
                THEN 'Below 50%'
            WHEN Payment_Coverage_Pct < 80
                THEN '50%-79.99%'
            WHEN Payment_Coverage_Pct < 100
                THEN '80%-99.99%'
            WHEN Payment_Coverage_Pct = 100
                THEN 'Fully Covered'
            ELSE 'Above 100%'
        END AS Coverage_Category

    FROM Claim_Payment_Coverage
)

SELECT
    Coverage_Category,

    COUNT(*) AS Paid_Claims,

    ROUND(AVG(Payment_Coverage_Pct), 2)
        AS Average_Coverage_Pct,

    ROUND(SUM(Claim_Amount), 2)
        AS Total_Claimed_Amount,

    ROUND(SUM(Payment_Amount), 2)
        AS Total_Paid_Amount,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS Claim_Share_Pct

FROM Coverage_Classification

GROUP BY Coverage_Category

ORDER BY
    CASE Coverage_Category
        WHEN 'Below 50%' THEN 1
        WHEN '50%-79.99%' THEN 2
        WHEN '80%-99.99%' THEN 3
        WHEN 'Fully Covered' THEN 4
        ELSE 5
    END;



-- 13. Payment Coverage by Claim Type
-- Compare settlement coverage across insurance claim types

WITH Claim_Coverage AS (
    SELECT
        c.Claim_ID,
        c.Claim_Type,
        c.Claim_Amount,
        p.Payment_Amount,

        100.0 * p.Payment_Amount /
            NULLIF(c.Claim_Amount, 0)
            AS Coverage_Pct

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Amount > 0
      AND p.Payment_Amount IS NOT NULL
),

Claim_Type_Coverage AS (
    SELECT
        Claim_Type,

        COUNT(*) AS Paid_Claims,

        ROUND(AVG(Coverage_Pct), 2)
            AS Average_Coverage_Pct,

        ROUND(
            100.0 * SUM(Payment_Amount) /
            NULLIF(SUM(Claim_Amount), 0),
            2
        ) AS Weighted_Coverage_Pct,

        ROUND(SUM(Claim_Amount), 2)
            AS Total_Claimed_Amount,

        ROUND(SUM(Payment_Amount), 2)
            AS Total_Paid_Amount

    FROM Claim_Coverage

    GROUP BY Claim_Type
)

SELECT
    *,

    DENSE_RANK() OVER (
        ORDER BY Weighted_Coverage_Pct DESC
    ) AS Coverage_Rank

FROM Claim_Type_Coverage

ORDER BY Coverage_Rank, Claim_Type;



-- 14. Payment Coverage vs. Settlement Turnaround
-- Compare turnaround performance across coverage categories

WITH Claim_Payment_Details AS (
    SELECT
        c.Claim_ID,
        c.Claim_Amount,
        p.Payment_Amount,

        100.0 * p.Payment_Amount /
            NULLIF(c.Claim_Amount, 0) AS Coverage_Pct,

        DATEDIFF(
            p.Payment_Date,
            c.Claim_Date
        ) AS Turnaround_Days

    FROM claims AS c

    INNER JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE c.Claim_Amount > 0
      AND p.Payment_Amount IS NOT NULL
      AND c.Claim_Date IS NOT NULL
      AND p.Payment_Date IS NOT NULL
),

Coverage_Groups AS (
    SELECT
        Claim_ID,
        Payment_Amount,
        Turnaround_Days,

        CASE
            WHEN Coverage_Pct < 80
                THEN 'Below 80% Coverage'
            ELSE '80% or Higher Coverage'
        END AS Coverage_Group

    FROM Claim_Payment_Details
)

SELECT
    Coverage_Group,

    COUNT(*) AS Paid_Claims,

    ROUND(AVG(Turnaround_Days), 2)
        AS Average_Turnaround_Days,

    SUM(CASE
        WHEN Turnaround_Days > 30
        THEN 1 ELSE 0
    END) AS Delayed_Payments,

    ROUND(
        100.0 * SUM(CASE
            WHEN Turnaround_Days > 30
            THEN 1 ELSE 0
        END) / NULLIF(COUNT(*), 0),
        2
    ) AS Delay_Rate_Pct,

    ROUND(AVG(Payment_Amount), 2)
        AS Average_Payment,

    ROUND(SUM(Payment_Amount), 2)
        AS Total_Payout

FROM Coverage_Groups

GROUP BY Coverage_Group

ORDER BY Delay_Rate_Pct DESC;



-- 15. Unpaid Claims by Claim Status
-- Identify claims with no recorded payment

WITH Unpaid_Claims AS (
    SELECT
        c.Claim_ID,
        c.Claim_Status,
        c.Claim_Amount,
        c.Claim_Date

    FROM claims AS c

    LEFT JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE p.Payment_ID IS NULL
)

SELECT
    Claim_Status,

    COUNT(*) AS Unpaid_Claims,

    ROUND(SUM(Claim_Amount), 2)
        AS Total_Claimed_Amount,

    ROUND(AVG(Claim_Amount), 2)
        AS Average_Claim_Amount,

    MIN(Claim_Date) AS Earliest_Claim_Date,

    MAX(Claim_Date) AS Latest_Claim_Date,

    ROUND(
        100.0 * COUNT(*) /
        NULLIF(SUM(COUNT(*)) OVER (), 0),
        2
    ) AS Unpaid_Claim_Share_Pct

FROM Unpaid_Claims

GROUP BY Claim_Status

ORDER BY Unpaid_Claims DESC;





-- 16. Approved and Settled Claims Without Payment
-- Identify payment-record gaps requiring investigation

WITH Payment_Exceptions AS (
    SELECT
        c.Claim_ID,
        c.Claim_Status,
        c.Claim_Date,
        c.Claim_Amount,

        DATEDIFF(
            '2026-09-30',
            c.Claim_Date
        ) AS Days_Since_Claim

    FROM claims AS c

    LEFT JOIN payments AS p
        ON c.Claim_ID = p.Claim_ID

    WHERE p.Payment_ID IS NULL
      AND c.Claim_Status IN ('Approved', 'Settled')
      AND c.Claim_Date <= '2026-09-30'
),

Exception_Buckets AS (
    SELECT
        Claim_Status,
        Claim_Amount,

        CASE
            WHEN Days_Since_Claim <= 30
                THEN '0-30 Days'
            WHEN Days_Since_Claim <= 60
                THEN '31-60 Days'
            WHEN Days_Since_Claim <= 90
                THEN '61-90 Days'
            ELSE '90+ Days'
        END AS Claim_Age_Band

    FROM Payment_Exceptions
)

SELECT
    Claim_Status,
    Claim_Age_Band,

    COUNT(*) AS Claims_Without_Payment,

    ROUND(SUM(Claim_Amount), 2)
        AS Total_Claimed_Amount,

    ROUND(AVG(Claim_Amount), 2)
        AS Average_Claim_Amount

FROM Exception_Buckets

GROUP BY
    Claim_Status,
    Claim_Age_Band

ORDER BY
    Claim_Status,
    CASE Claim_Age_Band
        WHEN '0-30 Days' THEN 1
        WHEN '31-60 Days' THEN 2
        WHEN '61-90 Days' THEN 3
        ELSE 4
    END;







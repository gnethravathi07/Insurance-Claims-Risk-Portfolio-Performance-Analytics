-- Step 8.1 — Insurance Portfolio Financial Overview

SELECT
    COUNT(*) AS Total_Policies,

    COUNT(DISTINCT Customer_ID) AS Total_Policyholders,

    ROUND(
        SUM(Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Annual_Premium), 2
    ) AS Avg_Annual_Premium,

    ROUND(
        SUM(Coverage_Amount), 2
    ) AS Total_Coverage_Amount,

    ROUND(
        AVG(Coverage_Amount), 2
    ) AS Avg_Coverage_Per_Policy,

    ROUND(
        SUM(Coverage_Amount) /
        NULLIF(SUM(Annual_Premium), 0), 2
    ) AS Coverage_To_Premium_Ratio

FROM policies;


-- Step 8.2 — Policy Portfolio Distribution by Insurance Type

WITH Policy_Type_Summary AS (
    SELECT
        Policy_Type,

        COUNT(*) AS Total_Policies,

        ROUND(SUM(Annual_Premium), 2) AS Total_Annual_Premium,

        ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium,

        ROUND(SUM(Coverage_Amount), 2) AS Total_Coverage_Amount

    FROM policies

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (), 2
    ) AS Policy_Share_Pct,

    Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Share_Pct,

    Avg_Annual_Premium,
    Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount * 100.0 /
        NULLIF(SUM(Total_Coverage_Amount) OVER (), 0), 2
    ) AS Coverage_Share_Pct

FROM Policy_Type_Summary

ORDER BY Total_Annual_Premium DESC;


-- Step 8.3 — Policy Portfolio Distribution by Status

WITH Policy_Status_Summary AS (
    SELECT
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM policies

    GROUP BY Policy_Status
)

SELECT
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (), 2
    ) AS Policy_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Share_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount * 100.0 /
        NULLIF(SUM(Total_Coverage_Amount) OVER (), 0), 2
    ) AS Coverage_Share_Pct

FROM Policy_Status_Summary

ORDER BY Total_Annual_Premium DESC;



-- Step 8.4 — Policy Type and Status Financial Performance

WITH Policy_Financial_Summary AS (
    SELECT
        Policy_Type,
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM policies

    GROUP BY
        Policy_Type,
        Policy_Status
)

SELECT
    Policy_Type,
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (
            PARTITION BY Policy_Type
        ), 2
    ) AS Status_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Policy_Type
            ), 0
        ), 2
    ) AS Premium_Share_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount

FROM Policy_Financial_Summary

ORDER BY
    Policy_Type,
    CASE Policy_Status
        WHEN 'Active' THEN 1
        WHEN 'Expired' THEN 2
        WHEN 'Cancelled' THEN 3
    END;
    
    

-- Step 8.5 — Annual Premium Analysis by Region

WITH Regional_Policy_Summary AS (
    SELECT
        c.Region,

        COUNT(p.Policy_ID) AS Total_Policies,

        COUNT(DISTINCT p.Customer_ID) AS Total_Policyholders,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY c.Region
)

SELECT
    Region,
    Total_Policies,
    Total_Policyholders,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    DENSE_RANK() OVER (
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Regional_Policy_Summary

ORDER BY Premium_Rank;



-- Step 8.6 — Regional Financial Performance by Insurance Type

WITH Regional_Type_Summary AS (
    SELECT
        c.Region,
        p.Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY
        c.Region,
        p.Policy_Type
)

SELECT
    Region,
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Region
            ), 0
        ), 2
    ) AS Regional_Premium_Share_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Regional_Type_Summary

ORDER BY
    Region,
    Premium_Rank;
    
    

-- Step 8.7 — Annual Premium Analysis by Customer Age Group

WITH Age_Group_Summary AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(p.Policy_ID) AS Total_Policies,

        COUNT(DISTINCT p.Customer_ID) AS Total_Policyholders,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Policies,
    Total_Policyholders,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount

FROM Age_Group_Summary

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;
    
    

-- Step 8.8 — Annual Premium Analysis by Customer Income Group

WITH Income_Group_Summary AS (
    SELECT
        CASE
            WHEN c.Annual_Income < 300000 THEN 'Below 3L'
            WHEN c.Annual_Income < 600000 THEN '3L-6L'
            WHEN c.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(p.Policy_ID) AS Total_Policies,

        COUNT(DISTINCT p.Customer_ID) AS Total_Policyholders,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Policies,
    Total_Policyholders,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount

FROM Income_Group_Summary

ORDER BY
    CASE Income_Group
        WHEN 'Below 3L' THEN 1
        WHEN '3L-6L' THEN 2
        WHEN '6L-10L' THEN 3
        ELSE 4
    END;
    
    

-- Step 8.9 — Coverage-to-Premium Ratio by Insurance Type

WITH Policy_Coverage_Summary AS (
    SELECT
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        AVG(Coverage_Amount) AS Avg_Coverage_Amount

    FROM policies

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Coverage_To_Premium_Ratio,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Avg_Coverage_Amount, 2
    ) AS Avg_Coverage_Amount,

    DENSE_RANK() OVER (
        ORDER BY
            Total_Coverage_Amount /
            NULLIF(Total_Annual_Premium, 0) DESC
    ) AS Coverage_Ratio_Rank

FROM Policy_Coverage_Summary

ORDER BY Coverage_Ratio_Rank;



-- Step 8.10 — Coverage-to-Premium Ratio by Policy Status

WITH Status_Financial_Summary AS (
    SELECT
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        AVG(Coverage_Amount) AS Avg_Coverage_Amount

    FROM policies

    GROUP BY Policy_Status
)

SELECT
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Coverage_To_Premium_Ratio,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Avg_Coverage_Amount, 2
    ) AS Avg_Coverage_Amount,

    DENSE_RANK() OVER (
        ORDER BY
            Total_Coverage_Amount /
            NULLIF(Total_Annual_Premium, 0) DESC
    ) AS Coverage_Ratio_Rank

FROM Status_Financial_Summary

ORDER BY Coverage_Ratio_Rank;



-- Step 8.11 — Premium-to-Income Ratio by Customer Income Group

WITH Customer_Premium AS (
    SELECT
        c.Customer_ID,
        c.Annual_Income,

        CASE
            WHEN c.Annual_Income < 300000 THEN 'Below 3L'
            WHEN c.Annual_Income < 600000 THEN '3L-6L'
            WHEN c.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM customers c

    INNER JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Annual_Income,
        Income_Group
),

Premium_Burden AS (
    SELECT
        Income_Group,
        COUNT(*) AS Total_Policyholders,
        SUM(Total_Policies) AS Total_Policies,

        AVG(
            Total_Annual_Premium * 100.0 /
            NULLIF(Annual_Income, 0)
        ) AS Avg_Premium_To_Income_Pct

    FROM Customer_Premium

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Policyholders,
    Total_Policies,

    ROUND(
        Avg_Premium_To_Income_Pct, 2
    ) AS Avg_Premium_To_Income_Pct,

    DENSE_RANK() OVER (
        ORDER BY Avg_Premium_To_Income_Pct DESC
    ) AS Premium_Burden_Rank

FROM Premium_Burden

ORDER BY Premium_Burden_Rank;



-- Step 8.12 — Premium-to-Income Ratio by Insurance Type

WITH Customer_Type_Premium AS (
    SELECT
        p.Policy_Type,
        p.Customer_ID,
        c.Annual_Income,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY
        p.Policy_Type,
        p.Customer_ID,
        c.Annual_Income
),

Premium_Burden AS (
    SELECT
        Policy_Type,

        COUNT(*) AS Total_Policyholders,

        SUM(Total_Policies) AS Total_Policies,

        AVG(
            Total_Annual_Premium * 100.0 /
            NULLIF(Annual_Income, 0)
        ) AS Avg_Premium_To_Income_Pct

    FROM Customer_Type_Premium

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policyholders,
    Total_Policies,

    ROUND(
        Avg_Premium_To_Income_Pct, 2
    ) AS Avg_Premium_To_Income_Pct,

    DENSE_RANK() OVER (
        ORDER BY Avg_Premium_To_Income_Pct DESC
    ) AS Premium_Burden_Rank

FROM Premium_Burden

ORDER BY Premium_Burden_Rank;




-- Step 8.13 — Policy Coverage Distribution by Coverage Band

WITH Coverage_Band_Summary AS (
    SELECT
        CASE
            WHEN Coverage_Amount < 500000 THEN 'Below 5L'
            WHEN Coverage_Amount < 1000000 THEN '5L-10L'
            WHEN Coverage_Amount < 2500000 THEN '10L-25L'
            ELSE '25L and Above'
        END AS Coverage_Band,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM policies

    GROUP BY Coverage_Band
)

SELECT
    Coverage_Band,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (), 2
    ) AS Policy_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount * 100.0 /
        NULLIF(SUM(Total_Coverage_Amount) OVER (), 0), 2
    ) AS Coverage_Share_Pct

FROM Coverage_Band_Summary

ORDER BY
    CASE Coverage_Band
        WHEN 'Below 5L' THEN 1
        WHEN '5L-10L' THEN 2
        WHEN '10L-25L' THEN 3
        ELSE 4
    END;
    
    
-- Step 8.14 — Policy Type and Coverage Band Financial Analysis

WITH Coverage_Analysis AS (
    SELECT
        Policy_Type,

        CASE
            WHEN Coverage_Amount < 500000 THEN 'Below 5L'
            WHEN Coverage_Amount < 1000000 THEN '5L-10L'
            WHEN Coverage_Amount < 2500000 THEN '10L-25L'
            ELSE '25L and Above'
        END AS Coverage_Band,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM policies

    GROUP BY Policy_Type, Coverage_Band
)

SELECT
    Policy_Type,
    Coverage_Band,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (
            PARTITION BY Policy_Type
        ), 2
    ) AS Policy_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount * 100.0 /
        NULLIF(
            SUM(Total_Coverage_Amount) OVER (
                PARTITION BY Policy_Type
            ), 0
        ), 2
    ) AS Coverage_Share_Pct

FROM Coverage_Analysis

ORDER BY
    Policy_Type,
    CASE Coverage_Band
        WHEN 'Below 5L' THEN 1
        WHEN '5L-10L' THEN 2
        WHEN '10L-25L' THEN 3
        ELSE 4
    END;
    
    

-- Step 8.15 — Claim-to-Premium Ratio by Insurance Type

WITH Premium_Summary AS (
    SELECT
        Policy_Type,
        COUNT(*) AS Total_Policies,
        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY Policy_Type
),

Claim_Summary AS (
    SELECT
        p.Policy_Type,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM policies p

    INNER JOIN claims c
        ON p.Policy_ID = c.Policy_ID

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
        NULLIF(ps.Total_Annual_Premium, 0), 2
    ) AS Claim_To_Premium_Ratio_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            cs.Total_Claim_Amount /
            NULLIF(ps.Total_Annual_Premium, 0) DESC
    ) AS Claim_Ratio_Rank

FROM Premium_Summary ps

INNER JOIN Claim_Summary cs
    ON ps.Policy_Type = cs.Policy_Type

ORDER BY Claim_Ratio_Rank;



-- Step 8.16 — Claim-to-Premium Ratio by Region

WITH Regional_Premiums AS (
    SELECT
        cu.Region,
        COUNT(p.Policy_ID) AS Total_Policies,
        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM policies p

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY cu.Region
),

Regional_Claims AS (
    SELECT
        cu.Region,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN customers cu
        ON p.Customer_ID = cu.Customer_ID

    GROUP BY cu.Region
)

SELECT
    rp.Region,
    rp.Total_Policies,
    rc.Total_Claims,

    ROUND(
        rp.Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        rc.Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        rc.Total_Claim_Amount * 100.0 /
        NULLIF(rp.Total_Annual_Premium, 0), 2
    ) AS Claim_To_Premium_Ratio_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            rc.Total_Claim_Amount /
            NULLIF(rp.Total_Annual_Premium, 0) DESC
    ) AS Claim_Ratio_Rank

FROM Regional_Premiums rp

INNER JOIN Regional_Claims rc
    ON rp.Region = rc.Region

ORDER BY Claim_Ratio_Rank;



-- Step 8.17 — Claim-to-Premium Ratio by Policy Status

WITH Status_Premiums AS (
    SELECT
        Policy_Status,
        COUNT(*) AS Total_Policies,
        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY Policy_Status
),

Status_Claims AS (
    SELECT
        p.Policy_Status,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM policies p

    INNER JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY p.Policy_Status
)

SELECT
    sp.Policy_Status,
    sp.Total_Policies,
    sc.Total_Claims,

    ROUND(
        sp.Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        sc.Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        sc.Total_Claim_Amount * 100.0 /
        NULLIF(sp.Total_Annual_Premium, 0), 2
    ) AS Claim_To_Premium_Ratio_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            sc.Total_Claim_Amount /
            NULLIF(sp.Total_Annual_Premium, 0) DESC
    ) AS Claim_Ratio_Rank

FROM Status_Premiums sp

INNER JOIN Status_Claims sc
    ON sp.Policy_Status = sc.Policy_Status

ORDER BY Claim_Ratio_Rank;



-- Step 8.18 — Claims Frequency by Insurance Type

WITH Policy_Claim_Count AS (
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
)

SELECT
    Policy_Type,

    COUNT(*) AS Total_Policies,

    SUM(Claim_Count) AS Total_Claims,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE WHEN Claim_Count = 0
        THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    SUM(
        CASE WHEN Claim_Count = 1
        THEN 1 ELSE 0 END
    ) AS Single_Claim_Policies,

    SUM(
        CASE WHEN Claim_Count >= 2
        THEN 1 ELSE 0 END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE WHEN Claim_Count >= 2
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Count

GROUP BY Policy_Type

ORDER BY Avg_Claims_Per_Policy DESC;


-- Step 8.19 — Claims Frequency by Policy Status

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,
        p.Policy_Status,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Policy_Status
)

SELECT
    Policy_Status,

    COUNT(*) AS Total_Policies,

    SUM(Claim_Count) AS Total_Claims,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE WHEN Claim_Count = 0
        THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    SUM(
        CASE WHEN Claim_Count = 1
        THEN 1 ELSE 0 END
    ) AS Single_Claim_Policies,

    SUM(
        CASE WHEN Claim_Count >= 2
        THEN 1 ELSE 0 END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE WHEN Claim_Count >= 2
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Count

GROUP BY Policy_Status

ORDER BY Avg_Claims_Per_Policy DESC;



-- Step 8.20 — Claims Frequency by Customer Age Group

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,

        CASE
            WHEN cu.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN cu.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN cu.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(c.Claim_ID) AS Claim_Count

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

    SUM(Claim_Count) AS Total_Claims,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    SUM(
        CASE WHEN Claim_Count = 1 THEN 1 ELSE 0 END
    ) AS Single_Claim_Policies,

    SUM(
        CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Count

GROUP BY Age_Group

ORDER BY
    CASE Age_Group
        WHEN '18-30' THEN 1
        WHEN '31-45' THEN 2
        WHEN '46-60' THEN 3
        ELSE 4
    END;
    


-- Step 8.21 — Claims Frequency by Customer Income Group

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,

        CASE
            WHEN cu.Annual_Income < 300000 THEN 'Below 3L'
            WHEN cu.Annual_Income < 600000 THEN '3L-6L'
            WHEN cu.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(c.Claim_ID) AS Claim_Count

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

    SUM(Claim_Count) AS Total_Claims,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    SUM(
        CASE WHEN Claim_Count = 1 THEN 1 ELSE 0 END
    ) AS Single_Claim_Policies,

    SUM(
        CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Repeat_Claim_Rate_Pct

FROM Policy_Claim_Count

GROUP BY Income_Group

ORDER BY
    CASE Income_Group
        WHEN 'Below 3L' THEN 1
        WHEN '3L-6L' THEN 2
        WHEN '6L-10L' THEN 3
        ELSE 4
    END;
    
    
    
-- Step 8.22 — Premium and Coverage by Claim Frequency

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,
        p.Annual_Premium,
        p.Coverage_Amount,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Annual_Premium,
        p.Coverage_Amount
),

Frequency_Summary AS (
    SELECT
        CASE
            WHEN Claim_Count = 0 THEN '0 Claims'
            WHEN Claim_Count = 1 THEN '1 Claim'
            WHEN Claim_Count = 2 THEN '2 Claims'
            WHEN Claim_Count = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Frequency_Band,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM Policy_Claim_Count

    GROUP BY Frequency_Band
)

SELECT
    Frequency_Band,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (), 2
    ) AS Policy_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct

FROM Frequency_Summary

ORDER BY
    CASE Frequency_Band
        WHEN '0 Claims' THEN 1
        WHEN '1 Claim' THEN 2
        WHEN '2 Claims' THEN 3
        WHEN '3 Claims' THEN 4
        ELSE 5
    END;
    


-- Step 8.23 — Policy Claim Incidence by Insurance Type

WITH Policy_Claim_Count AS (
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
)

SELECT
    Policy_Type,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
    ) AS Policies_With_Claims,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    ROUND(
        SUM(
            CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Claim_Incidence_Pct,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Incidence_Rank

FROM Policy_Claim_Count

GROUP BY Policy_Type

ORDER BY Incidence_Rank;



-- Step 8.24 — Claim Incidence by Policy Status

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,
        p.Policy_Status,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        p.Policy_Status
)

SELECT
    Policy_Status,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
    ) AS Policies_With_Claims,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    ROUND(
        SUM(
            CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Claim_Incidence_Pct,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Incidence_Rank

FROM Policy_Claim_Count

GROUP BY Policy_Status

ORDER BY Incidence_Rank;




-- Step 8.25 — Policyholder Claim History and Premium Contribution

WITH Customer_Premium AS (
    SELECT
        Customer_ID,
        COUNT(*) AS Total_Policies,
        SUM(Annual_Premium) AS Total_Annual_Premium
    FROM policies
    GROUP BY Customer_ID
),

Customer_Claims AS (
    SELECT
        p.Customer_ID,
        COUNT(c.Claim_ID) AS Total_Claims
    FROM policies p
    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID
    GROUP BY p.Customer_ID
),

Customer_Summary AS (
    SELECT
        CASE
            WHEN cc.Total_Claims = 0 THEN '0 Claims'
            WHEN cc.Total_Claims = 1 THEN '1 Claim'
            WHEN cc.Total_Claims = 2 THEN '2 Claims'
            WHEN cc.Total_Claims = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Claim_Frequency_Band,

        COUNT(*) AS Total_Policyholders,
        SUM(cp.Total_Policies) AS Total_Policies,
        SUM(cp.Total_Annual_Premium) AS Total_Annual_Premium,
        AVG(cp.Total_Annual_Premium) AS Avg_Premium_Per_Policyholder

    FROM Customer_Premium cp
    INNER JOIN Customer_Claims cc
        ON cp.Customer_ID = cc.Customer_ID

    GROUP BY Claim_Frequency_Band
)

SELECT
    Claim_Frequency_Band,
    Total_Policyholders,
    Total_Policies,

    ROUND(Total_Annual_Premium, 2) AS Total_Annual_Premium,

    ROUND(Avg_Premium_Per_Policyholder, 2)
        AS Avg_Premium_Per_Policyholder,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct

FROM Customer_Summary

ORDER BY
    CASE Claim_Frequency_Band
        WHEN '0 Claims' THEN 1
        WHEN '1 Claim' THEN 2
        WHEN '2 Claims' THEN 3
        WHEN '3 Claims' THEN 4
        ELSE 5
    END;
    
    


-- Step 8.26 — Annual Premium Analysis by Customer Risk Category

WITH Risk_Premium_Summary AS (
    SELECT
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        COUNT(DISTINCT p.Customer_ID) AS Total_Policyholders,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Policies,
    Total_Policyholders,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    DENSE_RANK() OVER (
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Risk_Premium_Summary

ORDER BY Premium_Rank;



-- Step 8.27 — Coverage-to-Premium Ratio by Risk Category

WITH Risk_Financial_Summary AS (
    SELECT
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        SUM(p.Coverage_Amount) AS Total_Coverage_Amount,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium,

        AVG(p.Coverage_Amount) AS Avg_Coverage_Amount

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Coverage_Amount /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Coverage_To_Premium_Ratio,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Avg_Coverage_Amount, 2
    ) AS Avg_Coverage_Amount,

    DENSE_RANK() OVER (
        ORDER BY
            Total_Coverage_Amount /
            NULLIF(Total_Annual_Premium, 0) DESC
    ) AS Coverage_Ratio_Rank

FROM Risk_Financial_Summary

ORDER BY Coverage_Ratio_Rank;



-- Step 8.28 — Claim-to-Premium Ratio by Risk Category

WITH Risk_Premiums AS (
    SELECT
        r.Risk_Category,
        COUNT(p.Policy_ID) AS Total_Policies,
        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
),

Risk_Claims AS (
    SELECT
        r.Risk_Category,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    rp.Risk_Category,
    rp.Total_Policies,
    rc.Total_Claims,

    ROUND(
        rp.Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        rc.Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        rc.Total_Claim_Amount * 100.0 /
        NULLIF(rp.Total_Annual_Premium, 0), 2
    ) AS Claim_To_Premium_Ratio_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            rc.Total_Claim_Amount /
            NULLIF(rp.Total_Annual_Premium, 0) DESC
    ) AS Claim_Ratio_Rank

FROM Risk_Premiums rp

INNER JOIN Risk_Claims rc
    ON rp.Risk_Category = rc.Risk_Category

ORDER BY Claim_Ratio_Rank;



-- Step 8.29 — Claim Incidence by Customer Risk Category

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,
        r.Risk_Category,

        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        r.Risk_Category
)

SELECT
    Risk_Category,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
    ) AS Policies_With_Claims,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    ROUND(
        SUM(
            CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Claim_Incidence_Pct,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Claim_Count > 0 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Incidence_Rank

FROM Policy_Claim_Count

GROUP BY Risk_Category

ORDER BY Incidence_Rank;



-- Step 8.30 — Claims Frequency by Customer Risk Category

WITH Policy_Claim_Count AS (
    SELECT
        p.Policy_ID,
        r.Risk_Category,
        COUNT(c.Claim_ID) AS Claim_Count

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        p.Policy_ID,
        r.Risk_Category
)

SELECT
    Risk_Category,

    COUNT(*) AS Total_Policies,

    SUM(Claim_Count) AS Total_Claims,

    ROUND(
        AVG(Claim_Count), 2
    ) AS Avg_Claims_Per_Policy,

    SUM(
        CASE WHEN Claim_Count = 0 THEN 1 ELSE 0 END
    ) AS Policies_Without_Claims,

    SUM(
        CASE WHEN Claim_Count = 1 THEN 1 ELSE 0 END
    ) AS Single_Claim_Policies,

    SUM(
        CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
    ) AS Repeat_Claim_Policies,

    ROUND(
        SUM(
            CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Repeat_Claim_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Claim_Count >= 2 THEN 1 ELSE 0 END)
            * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Repeat_Claim_Rank

FROM Policy_Claim_Count

GROUP BY Risk_Category

ORDER BY Repeat_Claim_Rank;




-- Step 8.31 — Claim-to-Premium Ratio by Insurance Type and Risk Category

WITH Segment_Premiums AS (
    SELECT
        p.Policy_Type,
        r.Risk_Category,
        COUNT(*) AS Total_Policies,
        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        p.Policy_Type,
        r.Risk_Category
),

Segment_Claims AS (
    SELECT
        p.Policy_Type,
        r.Risk_Category,
        COUNT(c.Claim_ID) AS Total_Claims,
        SUM(c.Claim_Amount) AS Total_Claim_Amount

    FROM claims c

    INNER JOIN policies p
        ON c.Policy_ID = p.Policy_ID

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        p.Policy_Type,
        r.Risk_Category
)

SELECT
    sp.Policy_Type,
    sp.Risk_Category,
    sp.Total_Policies,
    sc.Total_Claims,

    ROUND(
        sp.Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        sc.Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        sc.Total_Claim_Amount * 100.0 /
        NULLIF(sp.Total_Annual_Premium, 0), 2
    ) AS Claim_To_Premium_Ratio_Pct,

    DENSE_RANK() OVER (
        PARTITION BY sp.Policy_Type
        ORDER BY
            sc.Total_Claim_Amount /
            NULLIF(sp.Total_Annual_Premium, 0) DESC
    ) AS Risk_Rank

FROM Segment_Premiums sp

INNER JOIN Segment_Claims sc
    ON sp.Policy_Type = sc.Policy_Type
    AND sp.Risk_Category = sc.Risk_Category

ORDER BY
    sp.Policy_Type,
    Risk_Rank;
    


-- Step 8.32 — Annual Premium Analysis by Policy Start Year

WITH Yearly_Premium AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium,

        SUM(Coverage_Amount) AS Total_Coverage_Amount

    FROM policies

    GROUP BY YEAR(Start_Date)
)

SELECT
    Policy_Start_Year,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Coverage_Amount, 2
    ) AS Total_Coverage_Amount,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(SUM(Total_Annual_Premium) OVER (), 0), 2
    ) AS Premium_Contribution_Pct,

    ROUND(
        Total_Coverage_Amount /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Coverage_To_Premium_Ratio

FROM Yearly_Premium

ORDER BY Policy_Start_Year;




-- Step 8.33 — Policy Status Distribution by Start Year

WITH Yearly_Status AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Status
)

SELECT
    Policy_Start_Year,
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (
            PARTITION BY Policy_Start_Year
        ), 2
    ) AS Status_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Policy_Start_Year
            ), 0
        ), 2
    ) AS Premium_Share_Pct

FROM Yearly_Status

ORDER BY
    Policy_Start_Year,
    CASE Policy_Status
        WHEN 'Active' THEN 1
        WHEN 'Expired' THEN 2
        WHEN 'Cancelled' THEN 3
    END;
    
    
-- Step 8.34 — Year-over-Year Policy Issuance Analysis

WITH Yearly_Policies AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        COUNT(*) AS Total_Policies,
        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY YEAR(Start_Date)
),

Yearly_Comparison AS (
    SELECT
        Policy_Start_Year,
        Total_Policies,
        Total_Annual_Premium,

        LAG(Total_Policies) OVER (
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Policies,

        LAG(Total_Annual_Premium) OVER (
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Premium

    FROM Yearly_Policies
)

SELECT
    Policy_Start_Year,
    Total_Policies,
    Previous_Year_Policies,

    ROUND(
        (Total_Policies - Previous_Year_Policies)
        * 100.0 / NULLIF(Previous_Year_Policies, 0), 2
    ) AS YoY_Policy_Growth_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        (Total_Annual_Premium - Previous_Year_Premium)
        * 100.0 / NULLIF(Previous_Year_Premium, 0), 2
    ) AS YoY_Premium_Growth_Pct

FROM Yearly_Comparison

ORDER BY Policy_Start_Year;



-- Step 8.35 — Year-over-Year Average Annual Premium Analysis

WITH Yearly_Premium AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        COUNT(*) AS Total_Policies,
        ROUND(AVG(Annual_Premium), 2) AS Avg_Annual_Premium

    FROM policies

    GROUP BY YEAR(Start_Date)
),

Premium_Comparison AS (
    SELECT
        Policy_Start_Year,
        Total_Policies,
        Avg_Annual_Premium,

        LAG(Avg_Annual_Premium) OVER (
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Avg_Premium

    FROM Yearly_Premium
)

SELECT
    Policy_Start_Year,
    Total_Policies,
    Avg_Annual_Premium,
    Previous_Year_Avg_Premium,

    ROUND(
        (Avg_Annual_Premium - Previous_Year_Avg_Premium)
        * 100.0 / NULLIF(Previous_Year_Avg_Premium, 0), 2
    ) AS YoY_Avg_Premium_Growth_Pct

FROM Premium_Comparison

ORDER BY Policy_Start_Year;


-- Step 8.36 — Policy Cancellation Analysis by Insurance Type

SELECT
    Policy_Type,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Cancelled'
        THEN 1 ELSE 0 END
    ) AS Cancelled_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Active'
        THEN 1 ELSE 0 END
    ) AS Active_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Expired'
        THEN 1 ELSE 0 END
    ) AS Expired_Policies,

    ROUND(
        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END) * 1.0
            / NULLIF(COUNT(*), 0) DESC
    ) AS Cancellation_Rank

FROM policies

GROUP BY Policy_Type

ORDER BY Cancellation_Rank;



-- Step 8.37 — Policy Cancellation Analysis by Risk Category

SELECT
    r.Risk_Category,

    COUNT(p.Policy_ID) AS Total_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Cancelled'
        THEN 1 ELSE 0 END
    ) AS Cancelled_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Active'
        THEN 1 ELSE 0 END
    ) AS Active_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Expired'
        THEN 1 ELSE 0 END
    ) AS Expired_Policies,

    ROUND(
        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
            ) * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Cancellation_Rank

FROM policies p

INNER JOIN risk_assessment r
    ON p.Customer_ID = r.Customer_ID

GROUP BY r.Risk_Category

ORDER BY Cancellation_Rank;



-- Step 8.38 — Policy Cancellation Analysis by Region

SELECT
    c.Region,

    COUNT(p.Policy_ID) AS Total_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Cancelled'
        THEN 1 ELSE 0 END
    ) AS Cancelled_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Active'
        THEN 1 ELSE 0 END
    ) AS Active_Policies,

    SUM(
        CASE WHEN p.Policy_Status = 'Expired'
        THEN 1 ELSE 0 END
    ) AS Expired_Policies,

    ROUND(
        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
            ) * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Cancellation_Rank

FROM policies p

INNER JOIN customers c
    ON p.Customer_ID = c.Customer_ID

GROUP BY c.Region

ORDER BY Cancellation_Rank;



-- Step 8.39 — Policy Cancellation Analysis by Customer Age Group

WITH Age_Status_Summary AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        p.Policy_Status

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Cancelled'
        THEN 1 ELSE 0 END
    ) AS Cancelled_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Active'
        THEN 1 ELSE 0 END
    ) AS Active_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Expired'
        THEN 1 ELSE 0 END
    ) AS Expired_Policies,

    ROUND(
        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
            ) * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Cancellation_Rank

FROM Age_Status_Summary

GROUP BY Age_Group

ORDER BY Cancellation_Rank;



-- Step 8.40 — Policy Cancellation Analysis by Income Group

WITH Income_Status_Summary AS (
    SELECT
        CASE
            WHEN c.Annual_Income < 300000 THEN 'Below 3L'
            WHEN c.Annual_Income < 600000 THEN '3L-6L'
            WHEN c.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        p.Policy_Status

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID
)

SELECT
    Income_Group,

    COUNT(*) AS Total_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Cancelled'
        THEN 1 ELSE 0 END
    ) AS Cancelled_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Active'
        THEN 1 ELSE 0 END
    ) AS Active_Policies,

    SUM(
        CASE WHEN Policy_Status = 'Expired'
        THEN 1 ELSE 0 END
    ) AS Expired_Policies,

    ROUND(
        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) * 100.0 / NULLIF(COUNT(*), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
            ) * 1.0 / NULLIF(COUNT(*), 0) DESC
    ) AS Cancellation_Rank

FROM Income_Status_Summary

GROUP BY Income_Group

ORDER BY Cancellation_Rank;



-- Step 8.41 — Policy Cancellation by Insurance Type and Risk Category

WITH Cancellation_Summary AS (
    SELECT
        p.Policy_Type,
        r.Risk_Category,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Active'
            THEN 1 ELSE 0 END
        ) AS Active_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Expired'
            THEN 1 ELSE 0 END
        ) AS Expired_Policies

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        p.Policy_Type,
        r.Risk_Category
)

SELECT
    Policy_Type,
    Risk_Category,
    Total_Policies,
    Cancelled_Policies,
    Active_Policies,
    Expired_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY
    Policy_Type,
    Cancellation_Rank;
    
-- Step 8.41 — Policy Cancellation by Insurance Type and Risk Category

WITH Cancellation_Summary AS (
    SELECT
        p.Policy_Type,
        r.Risk_Category,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Active'
            THEN 1 ELSE 0 END
        ) AS Active_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Expired'
            THEN 1 ELSE 0 END
        ) AS Expired_Policies

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        p.Policy_Type,
        r.Risk_Category
)

SELECT
    Policy_Type,
    Risk_Category,
    Total_Policies,
    Cancelled_Policies,
    Active_Policies,
    Expired_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY
    Policy_Type,
    Cancellation_Rank;
    
 
-- Step 8.42 — Annual Premium Contribution by Policy Type and Start Year

WITH Yearly_Type_Premiums AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Type
)

SELECT
    Policy_Start_Year,
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Policy_Start_Year
            ), 0
        ), 2
    ) AS Yearly_Premium_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Start_Year
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Yearly_Type_Premiums

ORDER BY
    Policy_Start_Year,
    Premium_Rank;
    
 
-- Step 8.43 — Year-over-Year Policy Issuance Growth by Insurance Type

WITH Yearly_Policies AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Type,
        COUNT(*) AS Total_Policies

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Type
),

Policy_Comparison AS (
    SELECT
        Policy_Start_Year,
        Policy_Type,
        Total_Policies,

        LAG(Total_Policies) OVER (
            PARTITION BY Policy_Type
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Policies

    FROM Yearly_Policies
)

SELECT
    Policy_Start_Year,
    Policy_Type,
    Total_Policies,
    Previous_Year_Policies,

    ROUND(
        (Total_Policies - Previous_Year_Policies)
        * 100.0 / NULLIF(Previous_Year_Policies, 0), 2
    ) AS YoY_Policy_Growth_Pct

FROM Policy_Comparison

ORDER BY
    Policy_Type,
    Policy_Start_Year;
    

-- Step 8.44 — Year-over-Year Annual Premium Growth by Insurance Type

WITH Yearly_Premiums AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Type
),

Premium_Comparison AS (
    SELECT
        Policy_Start_Year,
        Policy_Type,
        Total_Policies,
        Total_Annual_Premium,

        LAG(Total_Annual_Premium) OVER (
            PARTITION BY Policy_Type
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Premium

    FROM Yearly_Premiums
)

SELECT
    Policy_Start_Year,
    Policy_Type,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Previous_Year_Premium, 2
    ) AS Previous_Year_Premium,

    ROUND(
        (Total_Annual_Premium - Previous_Year_Premium)
        * 100.0 / NULLIF(Previous_Year_Premium, 0), 2
    ) AS YoY_Premium_Growth_Pct

FROM Premium_Comparison

ORDER BY
    Policy_Type,
    Policy_Start_Year;
    


-- Step 8.45 — Average Annual Premium Growth by Insurance Type

WITH Yearly_Averages AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Type,
        COUNT(*) AS Total_Policies,
        AVG(Annual_Premium) AS Avg_Annual_Premium

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Type
),

Premium_Comparison AS (
    SELECT
        Policy_Start_Year,
        Policy_Type,
        Total_Policies,
        Avg_Annual_Premium,

        LAG(Avg_Annual_Premium) OVER (
            PARTITION BY Policy_Type
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Avg_Premium

    FROM Yearly_Averages
)

SELECT
    Policy_Start_Year,
    Policy_Type,
    Total_Policies,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Previous_Year_Avg_Premium, 2
    ) AS Previous_Year_Avg_Premium,

    ROUND(
        (Avg_Annual_Premium - Previous_Year_Avg_Premium)
        * 100.0 / NULLIF(Previous_Year_Avg_Premium, 0), 2
    ) AS YoY_Avg_Premium_Growth_Pct

FROM Premium_Comparison

ORDER BY
    Policy_Type,
    Policy_Start_Year;
    

-- Step 8.46 — Premium Contribution by Risk Category and Start Year

WITH Yearly_Risk_Premiums AS (
    SELECT
        YEAR(p.Start_Date) AS Policy_Start_Year,
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        YEAR(p.Start_Date),
        r.Risk_Category
)

SELECT
    Policy_Start_Year,
    Risk_Category,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Policy_Start_Year
            ), 0
        ), 2
    ) AS Yearly_Premium_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Start_Year
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Yearly_Risk_Premiums

ORDER BY
    Policy_Start_Year,
    Premium_Rank;
    

-- Step 8.47 — Year-over-Year Annualized Premium Growth by Risk Category

WITH Yearly_Risk_Premiums AS (
    SELECT
        YEAR(p.Start_Date) AS Policy_Start_Year,
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        YEAR(p.Start_Date),
        r.Risk_Category
),

Premium_Comparison AS (
    SELECT
        Policy_Start_Year,
        Risk_Category,
        Total_Policies,
        Total_Annual_Premium,

        LAG(Total_Annual_Premium) OVER (
            PARTITION BY Risk_Category
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Premium

    FROM Yearly_Risk_Premiums
)

SELECT
    Policy_Start_Year,
    Risk_Category,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Previous_Year_Premium, 2
    ) AS Previous_Year_Premium,

    ROUND(
        (Total_Annual_Premium - Previous_Year_Premium)
        * 100.0 / NULLIF(Previous_Year_Premium, 0), 2
    ) AS YoY_Premium_Growth_Pct

FROM Premium_Comparison

ORDER BY
    Risk_Category,
    Policy_Start_Year;
    


-- Step 8.48 — Year-over-Year Average Annual Premium Growth by Risk Category

WITH Yearly_Risk_Averages AS (
    SELECT
        YEAR(p.Start_Date) AS Policy_Start_Year,
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        AVG(p.Annual_Premium) AS Avg_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        YEAR(p.Start_Date),
        r.Risk_Category
),

Premium_Comparison AS (
    SELECT
        Policy_Start_Year,
        Risk_Category,
        Total_Policies,
        Avg_Annual_Premium,

        LAG(Avg_Annual_Premium) OVER (
            PARTITION BY Risk_Category
            ORDER BY Policy_Start_Year
        ) AS Previous_Year_Avg_Premium

    FROM Yearly_Risk_Averages
)

SELECT
    Policy_Start_Year,
    Risk_Category,
    Total_Policies,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Previous_Year_Avg_Premium, 2
    ) AS Previous_Year_Avg_Premium,

    ROUND(
        (Avg_Annual_Premium - Previous_Year_Avg_Premium)
        * 100.0 / NULLIF(Previous_Year_Avg_Premium, 0), 2
    ) AS YoY_Avg_Premium_Growth_Pct

FROM Premium_Comparison

ORDER BY
    Risk_Category,
    Policy_Start_Year;
    

-- Step 8.49 — Annual Premium Analysis by Policy Duration

WITH Policy_Duration AS (
    SELECT
        Policy_ID,
        Annual_Premium,
        Coverage_Amount,

        DATEDIFF(End_Date, Start_Date) AS Duration_Days,

        CASE
            WHEN DATEDIFF(End_Date, Start_Date) < 365
                THEN 'Below 1 Year'
            WHEN DATEDIFF(End_Date, Start_Date) < 730
                THEN '1-2 Years'
            WHEN DATEDIFF(End_Date, Start_Date) < 1095
                THEN '2-3 Years'
            ELSE '3+ Years'
        END AS Duration_Band

    FROM policies
)

SELECT
    Duration_Band,

    COUNT(*) AS Total_Policies,

    ROUND(
        AVG(Duration_Days), 2
    ) AS Avg_Duration_Days,

    ROUND(
        SUM(Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Annual_Premium), 2
    ) AS Avg_Annual_Premium,

    ROUND(
        SUM(Coverage_Amount), 2
    ) AS Total_Coverage_Amount,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Policy_Share_Pct

FROM Policy_Duration

GROUP BY Duration_Band

ORDER BY Avg_Duration_Days;


-- Step 8.50 — Policy Duration Distribution by Insurance Type

WITH Policy_Duration AS (
    SELECT
        Policy_Type,
        Annual_Premium,

        CASE
            WHEN DATEDIFF(End_Date, Start_Date) < 365
                THEN 'Below 1 Year'
            WHEN DATEDIFF(End_Date, Start_Date) < 730
                THEN '1-2 Years'
            WHEN DATEDIFF(End_Date, Start_Date) < 1095
                THEN '2-3 Years'
            ELSE '3+ Years'
        END AS Duration_Band

    FROM policies
),

Duration_Summary AS (
    SELECT
        Policy_Type,
        Duration_Band,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium

    FROM Policy_Duration

    GROUP BY
        Policy_Type,
        Duration_Band
)

SELECT
    Policy_Type,
    Duration_Band,
    Total_Policies,

    ROUND(
        Total_Policies * 100.0 /
        SUM(Total_Policies) OVER (
            PARTITION BY Policy_Type
        ), 2
    ) AS Duration_Share_Pct,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Policy_Type
            ), 0
        ), 2
    ) AS Premium_Share_Pct

FROM Duration_Summary

ORDER BY
    Policy_Type,
    Duration_Band;
    


-- Step 8.51 — Policy Cancellation Analysis by Contractual Duration

WITH Policy_Duration AS (
    SELECT
        Policy_ID,
        Policy_Status,

        CASE
            WHEN DATEDIFF(End_Date, Start_Date) < 365
                THEN 'Below 1 Year'
            WHEN DATEDIFF(End_Date, Start_Date) < 730
                THEN '1-2 Years'
            WHEN DATEDIFF(End_Date, Start_Date) < 1095
                THEN '2-3 Years'
            ELSE '3+ Years'
        END AS Duration_Band

    FROM policies
),

Cancellation_Summary AS (
    SELECT
        Duration_Band,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Active'
                THEN 1 ELSE 0 END
        ) AS Active_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Expired'
                THEN 1 ELSE 0 END
        ) AS Expired_Policies

    FROM Policy_Duration

    GROUP BY Duration_Band
)

SELECT
    Duration_Band,
    Total_Policies,
    Cancelled_Policies,
    Active_Policies,
    Expired_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY Cancellation_Rank;


-- Step 8.52 — Policy Cancellation by Insurance Type and Duration

WITH Policy_Duration AS (
    SELECT
        Policy_Type,
        Policy_Status,

        CASE
            WHEN DATEDIFF(End_Date, Start_Date) < 730
                THEN '1-2 Years'
            WHEN DATEDIFF(End_Date, Start_Date) < 1095
                THEN '2-3 Years'
            ELSE '3+ Years'
        END AS Duration_Band

    FROM policies
),

Cancellation_Summary AS (
    SELECT
        Policy_Type,
        Duration_Band,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies

    FROM Policy_Duration

    GROUP BY
        Policy_Type,
        Duration_Band
)

SELECT
    Policy_Type,
    Duration_Band,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY
    Policy_Type,
    Cancellation_Rank;
    

-- Step 8.53 — Policy Cancellation Analysis by Start Year

WITH Yearly_Cancellations AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Active'
                THEN 1 ELSE 0 END
        ) AS Active_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Expired'
                THEN 1 ELSE 0 END
        ) AS Expired_Policies

    FROM policies

    GROUP BY YEAR(Start_Date)
)

SELECT
    Policy_Start_Year,
    Total_Policies,
    Cancelled_Policies,
    Active_Policies,
    Expired_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Yearly_Cancellations

ORDER BY Policy_Start_Year;



-- Step 8.54 — Policy Cancellation by Start Year and Insurance Type

WITH Cancellation_Summary AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies

    FROM policies

    GROUP BY
        YEAR(Start_Date),
        Policy_Type
)

SELECT
    Policy_Start_Year,
    Policy_Type,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Start_Year
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY
    Policy_Start_Year,
    Cancellation_Rank;
    

-- Step 8.55 — Policy Cancellation by Start Year and Risk Category

WITH Cancellation_Summary AS (
    SELECT
        YEAR(p.Start_Date) AS Policy_Start_Year,
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY
        YEAR(p.Start_Date),
        r.Risk_Category
)

SELECT
    Policy_Start_Year,
    Risk_Category,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Start_Year
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Cancellation_Summary

ORDER BY
    Policy_Start_Year,
    Cancellation_Rank;
    

-- Step 8.56 — Annual Premium Exposure from Cancelled Policies

WITH Premium_Summary AS (
    SELECT
        Policy_Type,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies

    GROUP BY Policy_Type
)

SELECT
    Policy_Type,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Premium_Summary

ORDER BY Premium_Exposure_Rank;



-- Step 8.57 — Cancelled Premium Exposure by Customer Risk Category

WITH Risk_Premium_Summary AS (
    SELECT
        r.Risk_Category,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN p.Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies p

    INNER JOIN risk_assessment r
        ON p.Customer_ID = r.Customer_ID

    GROUP BY r.Risk_Category
)

SELECT
    Risk_Category,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Risk_Premium_Summary

ORDER BY Premium_Exposure_Rank;



-- Step 8.58 — Cancelled Premium Exposure by Region

WITH Regional_Premium_Summary AS (
    SELECT
        c.Region,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN p.Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY c.Region
)

SELECT
    Region,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Regional_Premium_Summary

ORDER BY Premium_Exposure_Rank;


-- Step 8.59 — Cancelled Premium Exposure by Customer Age Group

WITH Age_Premium_Summary AS (
    SELECT
        CASE
            WHEN c.Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN c.Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN c.Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN p.Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Age_Premium_Summary

ORDER BY Premium_Exposure_Rank;



-- Step 8.60 — Cancelled Premium Exposure by Income Group

WITH Income_Premium_Summary AS (
    SELECT
        CASE
            WHEN c.Annual_Income < 300000 THEN 'Below 3L'
            WHEN c.Annual_Income < 600000 THEN '3L-6L'
            WHEN c.Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(p.Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
                THEN p.Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies p

    INNER JOIN customers c
        ON p.Customer_ID = c.Customer_ID

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Income_Premium_Summary

ORDER BY Premium_Exposure_Rank;



-- Step 8.61 — Cancelled Premium Exposure by Policy Start Year

WITH Yearly_Premium_Summary AS (
    SELECT
        YEAR(Start_Date) AS Policy_Start_Year,

        COUNT(*) AS Total_Policies,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN 1 ELSE 0 END
        ) AS Cancelled_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        SUM(
            CASE WHEN Policy_Status = 'Cancelled'
                THEN Annual_Premium ELSE 0 END
        ) AS Cancelled_Annual_Premium

    FROM policies

    GROUP BY YEAR(Start_Date)
)

SELECT
    Policy_Start_Year,
    Total_Policies,
    Cancelled_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium, 2
    ) AS Cancelled_Annual_Premium,

    ROUND(
        Cancelled_Annual_Premium * 100.0 /
        NULLIF(Total_Annual_Premium, 0), 2
    ) AS Cancelled_Premium_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY Cancelled_Annual_Premium DESC
    ) AS Premium_Exposure_Rank

FROM Yearly_Premium_Summary

ORDER BY Policy_Start_Year;


-- Step 8.62 — Average Annual Premium Comparison by Policy Status

WITH Premium_Summary AS (
    SELECT
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium

    FROM policies

    GROUP BY Policy_Status
)

SELECT
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Avg_Annual_Premium -
        AVG(Avg_Annual_Premium) OVER (), 2
    ) AS Difference_From_Status_Avg,

    DENSE_RANK() OVER (
        ORDER BY Avg_Annual_Premium DESC
    ) AS Premium_Rank

FROM Premium_Summary

ORDER BY Premium_Rank;



-- Step 8.63 — Average Annual Premium by Policy Type and Status

WITH Premium_Summary AS (
    SELECT
        Policy_Type,
        Policy_Status,

        COUNT(*) AS Total_Policies,

        SUM(Annual_Premium) AS Total_Annual_Premium,

        AVG(Annual_Premium) AS Avg_Annual_Premium

    FROM policies

    GROUP BY
        Policy_Type,
        Policy_Status
)

SELECT
    Policy_Type,
    Policy_Status,
    Total_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Avg_Annual_Premium, 2
    ) AS Avg_Annual_Premium,

    ROUND(
        Avg_Annual_Premium -
        AVG(Avg_Annual_Premium) OVER (
            PARTITION BY Policy_Type
        ), 2
    ) AS Difference_From_Type_Status_Avg,

    DENSE_RANK() OVER (
        PARTITION BY Policy_Type
        ORDER BY Avg_Annual_Premium DESC
    ) AS Premium_Rank

FROM Premium_Summary

ORDER BY
    Policy_Type,
    Premium_Rank;
    
    


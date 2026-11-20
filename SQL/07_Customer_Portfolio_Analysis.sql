-- Step 9.1 — Customer Portfolio Overview

SELECT
    COUNT(*) AS Total_Customers,

    COUNT(DISTINCT Region) AS Total_Regions,

    ROUND(AVG(Age), 2) AS Avg_Customer_Age,

    MIN(Age) AS Youngest_Customer,

    MAX(Age) AS Oldest_Customer,

    ROUND(AVG(Annual_Income), 2) AS Avg_Annual_Income,

    ROUND(SUM(Annual_Income), 2) AS Total_Annual_Income,

    MIN(Join_Date) AS First_Customer_Join_Date,

    MAX(Join_Date) AS Latest_Customer_Join_Date

FROM customers;


-- Step 9.2 — Customer Distribution by Region

SELECT
    Region,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Age), 2
    ) AS Avg_Customer_Age,

    ROUND(
        AVG(Annual_Income), 2
    ) AS Avg_Annual_Income,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Customer_Rank

FROM customers

GROUP BY Region

ORDER BY Customer_Rank;



-- Step 9.3 — Customer Distribution by Age Group

WITH Customer_Age_Groups AS (
    SELECT
        Customer_ID,
        Annual_Income,

        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group

    FROM customers
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Annual_Income), 2
    ) AS Avg_Annual_Income,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Customer_Rank

FROM Customer_Age_Groups

GROUP BY Age_Group

ORDER BY Customer_Rank;



-- Step 9.4 — Customer Distribution by Gender

SELECT
    Gender,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Age), 2
    ) AS Avg_Customer_Age,

    ROUND(
        AVG(Annual_Income), 2
    ) AS Avg_Annual_Income,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Customer_Rank

FROM customers

GROUP BY Gender

ORDER BY Customer_Rank;



-- Step 9.5 — Customer Distribution by Income Group

WITH Customer_Income_Groups AS (
    SELECT
        Customer_ID,
        Age,
        Annual_Income,

        CASE
            WHEN Annual_Income < 300000 THEN 'Below 3L'
            WHEN Annual_Income < 600000 THEN '3L-6L'
            WHEN Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group

    FROM customers
)

SELECT
    Income_Group,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Annual_Income), 2
    ) AS Avg_Annual_Income,

    ROUND(
        AVG(Age), 2
    ) AS Avg_Customer_Age,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Customer_Rank

FROM Customer_Income_Groups

GROUP BY Income_Group

ORDER BY Customer_Rank;


-- Step 9.6 — Customer Acquisition Trend by Join Year

WITH Yearly_Customers AS (
    SELECT
        YEAR(Join_Date) AS Join_Year,

        COUNT(*) AS New_Customers

    FROM customers

    GROUP BY YEAR(Join_Date)
),

Acquisition_Trend AS (
    SELECT
        Join_Year,
        New_Customers,

        SUM(New_Customers) OVER (
            ORDER BY Join_Year
        ) AS Cumulative_Customers,

        LAG(New_Customers) OVER (
            ORDER BY Join_Year
        ) AS Previous_Year_Customers

    FROM Yearly_Customers
)

SELECT
    Join_Year,
    New_Customers,
    Cumulative_Customers,
    Previous_Year_Customers,

    ROUND(
        (New_Customers - Previous_Year_Customers) * 100.0 /
        NULLIF(Previous_Year_Customers, 0), 2
    ) AS YoY_Customer_Growth_Pct

FROM Acquisition_Trend

ORDER BY Join_Year;



-- Step 9.7 — Customer Acquisition by Region and Join Year

WITH Regional_Acquisition AS (
    SELECT
        YEAR(Join_Date) AS Join_Year,
        Region,

        COUNT(*) AS New_Customers

    FROM customers

    GROUP BY
        YEAR(Join_Date),
        Region
)

SELECT
    Join_Year,
    Region,
    New_Customers,

    ROUND(
        New_Customers * 100.0 /
        SUM(New_Customers) OVER (
            PARTITION BY Join_Year
        ), 2
    ) AS Yearly_Customer_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Join_Year
        ORDER BY New_Customers DESC
    ) AS Acquisition_Rank

FROM Regional_Acquisition

ORDER BY
    Join_Year,
    Acquisition_Rank;
    
    
-- Step 9.8 — Customer Policy Ownership Distribution

WITH Customer_Policies AS (
    SELECT
        c.Customer_ID,

        COUNT(p.Policy_ID) AS Total_Policies

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Customer_ID
),

Ownership_Groups AS (
    SELECT
        Customer_ID,
        Total_Policies,

        CASE
            WHEN Total_Policies = 0 THEN '0 Policies'
            WHEN Total_Policies = 1 THEN '1 Policy'
            WHEN Total_Policies = 2 THEN '2 Policies'
            WHEN Total_Policies = 3 THEN '3 Policies'
            ELSE '4+ Policies'
        END AS Ownership_Band

    FROM Customer_Policies
)

SELECT
    Ownership_Band,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Total_Policies), 2
    ) AS Avg_Policies_Per_Customer

FROM Ownership_Groups

GROUP BY Ownership_Band

ORDER BY MIN(Total_Policies);


-- Step 9.9 — Customer Portfolio Value by Policy Ownership

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Customer_ID
),

Ownership_Groups AS (
    SELECT
        Customer_ID,
        Total_Policies,
        Total_Annual_Premium,

        CASE
            WHEN Total_Policies = 0 THEN '0 Policies'
            WHEN Total_Policies = 1 THEN '1 Policy'
            WHEN Total_Policies = 2 THEN '2 Policies'
            WHEN Total_Policies = 3 THEN '3 Policies'
            ELSE '4+ Policies'
        END AS Ownership_Band

    FROM Customer_Portfolio
)

SELECT
    Ownership_Band,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct

FROM Ownership_Groups

GROUP BY Ownership_Band

ORDER BY MIN(Total_Policies);


-- Step 9.10 — Customer Portfolio Concentration Analysis

WITH Customer_Premiums AS (
    SELECT
        c.Customer_ID,
        COALESCE(SUM(p.Annual_Premium), 0) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Customer_ID
),

Ranked_Customers AS (
    SELECT
        Customer_ID,
        Total_Annual_Premium,

        ROW_NUMBER() OVER (
            ORDER BY Total_Annual_Premium DESC, Customer_ID
        ) AS Customer_Rank

    FROM Customer_Premiums
)

SELECT
    CASE
        WHEN Customer_Rank <= 100 THEN 'Top 1%'
        WHEN Customer_Rank <= 500 THEN 'Next 4%'
        WHEN Customer_Rank <= 1000 THEN 'Next 5%'
        ELSE 'Remaining 90%'
    END AS Customer_Segment,

    COUNT(*) AS Total_Customers,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct

FROM Ranked_Customers

GROUP BY
    CASE
        WHEN Customer_Rank <= 100 THEN 'Top 1%'
        WHEN Customer_Rank <= 500 THEN 'Next 4%'
        WHEN Customer_Rank <= 1000 THEN 'Next 5%'
        ELSE 'Remaining 90%'
    END

ORDER BY MIN(Customer_Rank);


-- Step 9.11 — Customer Policy Type Diversification

WITH Customer_Products AS (
    SELECT
        c.Customer_ID,

        COUNT(p.Policy_ID) AS Total_Policies,

        COUNT(DISTINCT p.Policy_Type) AS Distinct_Policy_Types,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Customer_ID
)

SELECT
    Distinct_Policy_Types,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        AVG(Total_Policies), 2
    ) AS Avg_Policies_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct

FROM Customer_Products

GROUP BY Distinct_Policy_Types

ORDER BY Distinct_Policy_Types;



-- Step 9.12 — Most Common Insurance Product Combinations

WITH Customer_Product_Types AS (
    SELECT DISTINCT
        Customer_ID,
        Policy_Type

    FROM policies
),

Customer_Combinations AS (
    SELECT
        Customer_ID,

        GROUP_CONCAT(
            Policy_Type
            ORDER BY Policy_Type
            SEPARATOR ' + '
        ) AS Product_Combination,

        COUNT(*) AS Distinct_Policy_Types

    FROM Customer_Product_Types

    GROUP BY Customer_ID
)

SELECT
    Product_Combination,

    Distinct_Policy_Types,

    COUNT(*) AS Total_Customers,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Combination_Rank

FROM Customer_Combinations

GROUP BY
    Product_Combination,
    Distinct_Policy_Types

ORDER BY
    Combination_Rank,
    Product_Combination;



-- Step 9.13 — Customer Policy Ownership by Age Group

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Age,

        COUNT(p.Policy_ID) AS Total_Policies

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Age
),

Age_Summary AS (
    SELECT
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        COUNT(*) AS Total_Customers,

        SUM(
            CASE WHEN Total_Policies > 0
                THEN 1 ELSE 0 END
        ) AS Customers_With_Policies,

        SUM(
            CASE WHEN Total_Policies = 0
                THEN 1 ELSE 0 END
        ) AS Customers_Without_Policies,

        SUM(Total_Policies) AS Total_Policies,

        ROUND(
            AVG(Total_Policies), 2
        ) AS Avg_Policies_Per_Customer

    FROM Customer_Portfolio

    GROUP BY Age_Group
)

SELECT
    Age_Group,
    Total_Customers,
    Customers_With_Policies,
    Customers_Without_Policies,
    Total_Policies,
    Avg_Policies_Per_Customer,

    ROUND(
        Customers_With_Policies * 100.0 /
        NULLIF(Total_Customers, 0), 2
    ) AS Policy_Ownership_Rate_Pct

FROM Age_Summary

ORDER BY Policy_Ownership_Rate_Pct DESC;



-- Step 9.14 — Customer Policy Ownership by Income Group

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Annual_Income,

        COUNT(p.Policy_ID) AS Total_Policies

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Annual_Income
),

Income_Summary AS (
    SELECT
        CASE
            WHEN Annual_Income < 300000 THEN 'Below 3L'
            WHEN Annual_Income < 600000 THEN '3L-6L'
            WHEN Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        COUNT(*) AS Total_Customers,

        SUM(
            CASE WHEN Total_Policies > 0
                THEN 1 ELSE 0 END
        ) AS Customers_With_Policies,

        SUM(
            CASE WHEN Total_Policies = 0
                THEN 1 ELSE 0 END
        ) AS Customers_Without_Policies,

        SUM(Total_Policies) AS Total_Policies,

        ROUND(
            AVG(Total_Policies), 2
        ) AS Avg_Policies_Per_Customer

    FROM Customer_Portfolio

    GROUP BY Income_Group
)

SELECT
    Income_Group,
    Total_Customers,
    Customers_With_Policies,
    Customers_Without_Policies,
    Total_Policies,
    Avg_Policies_Per_Customer,

    ROUND(
        Customers_With_Policies * 100.0 /
        NULLIF(Total_Customers, 0), 2
    ) AS Policy_Ownership_Rate_Pct

FROM Income_Summary

ORDER BY Policy_Ownership_Rate_Pct DESC;



-- Step 9.15 — Customer Policy Ownership by Region

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Region,

        COUNT(p.Policy_ID) AS Total_Policies

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
        CASE WHEN Total_Policies > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Policies,

    SUM(
        CASE WHEN Total_Policies = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Policies,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        AVG(Total_Policies), 2
    ) AS Avg_Policies_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Policies > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Policy_Ownership_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Total_Policies > 0
                    THEN 1 ELSE 0 END
            ) * 1.0 / COUNT(*) DESC
    ) AS Ownership_Rank

FROM Customer_Portfolio

GROUP BY Region

ORDER BY Ownership_Rank;



-- Step 9.16 — Customer Policy Ownership by Gender

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Gender,

        COUNT(p.Policy_ID) AS Total_Policies

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Gender
)

SELECT
    Gender,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Policies > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Policies,

    SUM(
        CASE WHEN Total_Policies = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Policies,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        AVG(Total_Policies), 2
    ) AS Avg_Policies_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Policies > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Policy_Ownership_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Total_Policies > 0
                    THEN 1 ELSE 0 END
            ) * 1.0 / COUNT(*) DESC
    ) AS Ownership_Rank

FROM Customer_Portfolio

GROUP BY Gender

ORDER BY Ownership_Rank;


-- Step 9.17 — Customer Policy Portfolio by Join-Year Cohort

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        YEAR(c.Join_Date) AS Join_Year,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        YEAR(c.Join_Date)
)

SELECT
    Join_Year,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Policies > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Policies,

    SUM(
        CASE WHEN Total_Policies = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Policies,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        AVG(Total_Policies), 2
    ) AS Avg_Policies_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        SUM(
            CASE WHEN Total_Policies > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Policy_Ownership_Rate_Pct

FROM Customer_Portfolio

GROUP BY Join_Year

ORDER BY Join_Year;


-- Step 9.18 — Customer Claim Participation Analysis

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,

        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,

        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
)

SELECT
    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Customer_Claim_Participation_Pct,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer

FROM Customer_Claims;



-- Step 9.19 — Customer Claim Frequency Distribution

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
),

Claim_Frequency AS (
    SELECT
        Customer_ID,
        Total_Claims,

        CASE
            WHEN Total_Claims = 0 THEN '0 Claims'
            WHEN Total_Claims = 1 THEN '1 Claim'
            WHEN Total_Claims = 2 THEN '2 Claims'
            WHEN Total_Claims = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Claim_Frequency_Band

    FROM Customer_Claims
)

SELECT
    Claim_Frequency_Band,

    COUNT(*) AS Total_Customers,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Customer_Share_Pct,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer

FROM Claim_Frequency

GROUP BY Claim_Frequency_Band

ORDER BY MIN(Total_Claims);



-- Step 9.20 — Customer Claim Amount Concentration

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,

        COALESCE(
            SUM(cl.Claim_Amount), 0
        ) AS Total_Claim_Amount

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
),

Ranked_Customers AS (
    SELECT
        Customer_ID,
        Total_Claim_Amount,

        ROW_NUMBER() OVER (
            ORDER BY Total_Claim_Amount DESC, Customer_ID
        ) AS Customer_Rank

    FROM Customer_Claims
),

Customer_Segments AS (
    SELECT
        Customer_Rank,
        Total_Claim_Amount,

        CASE
            WHEN Customer_Rank <= 100 THEN 'Top 1%'
            WHEN Customer_Rank <= 500 THEN 'Next 4%'
            WHEN Customer_Rank <= 1000 THEN 'Next 5%'
            ELSE 'Remaining 90%'
        END AS Customer_Segment

    FROM Ranked_Customers
)

SELECT
    Customer_Segment,

    COUNT(*) AS Total_Customers,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        SUM(Total_Claim_Amount) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Claim_Amount)) OVER (), 0
        ), 2
    ) AS Claim_Amount_Share_Pct

FROM Customer_Segments

GROUP BY Customer_Segment

ORDER BY MIN(Customer_Rank);



-- Step 9.21 — Customer Claim Frequency vs Claim Amount

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,

        COUNT(cl.Claim_ID) AS Total_Claims,

        COALESCE(
            SUM(cl.Claim_Amount), 0
        ) AS Total_Claim_Amount

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
),

Claim_Groups AS (
    SELECT
        Customer_ID,
        Total_Claims,
        Total_Claim_Amount,

        CASE
            WHEN Total_Claims = 0 THEN '0 Claims'
            WHEN Total_Claims = 1 THEN '1 Claim'
            WHEN Total_Claims = 2 THEN '2 Claims'
            WHEN Total_Claims = 3 THEN '3 Claims'
            ELSE '4+ Claims'
        END AS Claim_Frequency_Band

    FROM Customer_Claims
)

SELECT
    Claim_Frequency_Band,

    COUNT(*) AS Total_Customers,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(Total_Claim_Amount), 2
    ) AS Avg_Claim_Amount_Per_Customer,

    ROUND(
        SUM(Total_Claim_Amount) /
        NULLIF(SUM(Total_Claims), 0), 2
    ) AS Avg_Amount_Per_Claim,

    ROUND(
        SUM(Total_Claim_Amount) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Claim_Amount)) OVER (), 0
        ), 2
    ) AS Claim_Amount_Share_Pct

FROM Claim_Groups

GROUP BY Claim_Frequency_Band

ORDER BY MIN(Total_Claims);


-- Step 9.22 — Customer Claim Participation by Income Group

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        c.Annual_Income,

        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY
        c.Customer_ID,
        c.Annual_Income
),

Income_Groups AS (
    SELECT
        Customer_ID,
        Total_Claims,

        CASE
            WHEN Annual_Income < 300000 THEN 'Below 3L'
            WHEN Annual_Income < 600000 THEN '3L-6L'
            WHEN Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group

    FROM Customer_Claims
)

SELECT
    Income_Group,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct

FROM Income_Groups

GROUP BY Income_Group

ORDER BY Claim_Participation_Rate_Pct DESC;



-- Step 9.23 — Customer Claim Participation by Age Group

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        c.Age,
        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY
        c.Customer_ID,
        c.Age
),

Age_Groups AS (
    SELECT
        Customer_ID,
        Total_Claims,

        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group

    FROM Customer_Claims
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct

FROM Age_Groups

GROUP BY Age_Group

ORDER BY Claim_Participation_Rate_Pct DESC;



-- Step 9.24 — Customer Claim Participation by Region

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        c.Region,
        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY
        c.Customer_ID,
        c.Region
)

SELECT
    Region,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Total_Claims > 0
                    THEN 1 ELSE 0 END
            ) * 1.0 / COUNT(*) DESC
    ) AS Participation_Rank

FROM Customer_Claims

GROUP BY Region

ORDER BY Participation_Rank;



-- Step 9.25 — Customer Claim Participation by Gender

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        c.Gender,
        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY
        c.Customer_ID,
        c.Gender
)

SELECT
    Gender,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE WHEN Total_Claims > 0
                    THEN 1 ELSE 0 END
            ) * 1.0 / COUNT(*) DESC
    ) AS Participation_Rank

FROM Customer_Claims

GROUP BY Gender

ORDER BY Participation_Rank;



-- Step 9.26 — Customer Claim Participation by Join-Year Cohort

WITH Customer_Claims AS (
    SELECT
        c.Customer_ID,
        YEAR(c.Join_Date) AS Join_Year,

        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY
        c.Customer_ID,
        YEAR(c.Join_Date)
)

SELECT
    Join_Year,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct

FROM Customer_Claims

GROUP BY Join_Year

ORDER BY Join_Year;



-- Step 9.27 — Customer Claim Activity by Policy Ownership

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,
        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
),

Ownership_Groups AS (
    SELECT
        Total_Policies,
        Total_Claims,

        CASE
            WHEN Total_Policies = 0 THEN '0 Policies'
            WHEN Total_Policies = 1 THEN '1 Policy'
            WHEN Total_Policies = 2 THEN '2 Policies'
            WHEN Total_Policies = 3 THEN '3 Policies'
            ELSE '4+ Policies'
        END AS Ownership_Band

    FROM Customer_Portfolio
)

SELECT
    Ownership_Band,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct,

    ROUND(
        SUM(Total_Claims) * 1.0 /
        NULLIF(SUM(Total_Policies), 0), 2
    ) AS Claims_Per_Policy

FROM Ownership_Groups

GROUP BY Ownership_Band

ORDER BY MIN(Total_Policies);


-- Step 9.28 — Customer Claim Amount by Policy Ownership

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,
        COUNT(cl.Claim_ID) AS Total_Claims,
        COALESCE(SUM(cl.Claim_Amount), 0) AS Total_Claim_Amount

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
),

Ownership_Groups AS (
    SELECT
        Total_Policies,
        Total_Claims,
        Total_Claim_Amount,

        CASE
            WHEN Total_Policies = 0 THEN '0 Policies'
            WHEN Total_Policies = 1 THEN '1 Policy'
            WHEN Total_Policies = 2 THEN '2 Policies'
            WHEN Total_Policies = 3 THEN '3 Policies'
            ELSE '4+ Policies'
        END AS Ownership_Band

    FROM Customer_Portfolio
)

SELECT
    Ownership_Band,

    COUNT(*) AS Total_Customers,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        SUM(Total_Claim_Amount), 2
    ) AS Total_Claim_Amount,

    ROUND(
        AVG(Total_Claim_Amount), 2
    ) AS Avg_Claim_Amount_Per_Customer,

    ROUND(
        SUM(Total_Claim_Amount) /
        NULLIF(SUM(Total_Claims), 0), 2
    ) AS Avg_Amount_Per_Claim,

    ROUND(
        SUM(Total_Claim_Amount) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Claim_Amount)) OVER (), 0
        ), 2
    ) AS Claim_Amount_Share_Pct

FROM Ownership_Groups

GROUP BY Ownership_Band

ORDER BY MIN(Total_Policies);


-- Step 9.29 — Customer Claim Participation by Product Diversification

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,

        COUNT(DISTINCT p.Policy_Type) AS Distinct_Policy_Types,

        COUNT(cl.Claim_ID) AS Total_Claims

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    LEFT JOIN claims cl
        ON p.Policy_ID = cl.Policy_ID

    GROUP BY c.Customer_ID
)

SELECT
    Distinct_Policy_Types,

    COUNT(*) AS Total_Customers,

    SUM(
        CASE WHEN Total_Claims > 0
            THEN 1 ELSE 0 END
    ) AS Customers_With_Claims,

    SUM(
        CASE WHEN Total_Claims = 0
            THEN 1 ELSE 0 END
    ) AS Customers_Without_Claims,

    SUM(Total_Claims) AS Total_Claims,

    ROUND(
        AVG(Total_Claims), 2
    ) AS Avg_Claims_Per_Customer,

    ROUND(
        SUM(
            CASE WHEN Total_Claims > 0
                THEN 1 ELSE 0 END
        ) * 100.0 / COUNT(*), 2
    ) AS Claim_Participation_Rate_Pct

FROM Customer_Portfolio

GROUP BY Distinct_Policy_Types

ORDER BY Distinct_Policy_Types;



-- Step 9.30 — Customer Premium Contribution by Product Diversification

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,

        COUNT(DISTINCT p.Policy_Type) AS Distinct_Policy_Types,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY c.Customer_ID
)

SELECT
    Distinct_Policy_Types,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct

FROM Customer_Portfolio

GROUP BY Distinct_Policy_Types

ORDER BY Distinct_Policy_Types;



-- Step 9.31 — Customer Portfolio Value by Region

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Region,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

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

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Customer_Value_Rank

FROM Customer_Portfolio

GROUP BY Region

ORDER BY Customer_Value_Rank;


-- Step 9.32 — Customer Portfolio Value by Age Group

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Age,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Age
),

Age_Groups AS (
    SELECT
        CASE
            WHEN Age BETWEEN 18 AND 30 THEN '18-30'
            WHEN Age BETWEEN 31 AND 45 THEN '31-45'
            WHEN Age BETWEEN 46 AND 60 THEN '46-60'
            ELSE 'Above 60'
        END AS Age_Group,

        Total_Policies,
        Total_Annual_Premium

    FROM Customer_Portfolio
)

SELECT
    Age_Group,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Customer_Value_Rank

FROM Age_Groups

GROUP BY Age_Group

ORDER BY Customer_Value_Rank;


-- Step 9.33 — Customer Portfolio Value by Income Group

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Annual_Income,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Annual_Income
),

Income_Groups AS (
    SELECT
        CASE
            WHEN Annual_Income < 300000 THEN 'Below 3L'
            WHEN Annual_Income < 600000 THEN '3L-6L'
            WHEN Annual_Income < 1000000 THEN '6L-10L'
            ELSE '10L and Above'
        END AS Income_Group,

        Total_Policies,
        Total_Annual_Premium

    FROM Customer_Portfolio
)

SELECT
    Income_Group,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Customer_Value_Rank

FROM Income_Groups

GROUP BY Income_Group

ORDER BY Customer_Value_Rank;


-- Step 9.34 — Customer Portfolio Value by Gender

WITH Customer_Portfolio AS (
    SELECT
        c.Customer_ID,
        c.Gender,

        COUNT(p.Policy_ID) AS Total_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM customers c

    LEFT JOIN policies p
        ON c.Customer_ID = p.Customer_ID

    GROUP BY
        c.Customer_ID,
        c.Gender
)

SELECT
    Gender,

    COUNT(*) AS Total_Customers,

    SUM(Total_Policies) AS Total_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Customer,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Customer_Value_Rank

FROM Customer_Portfolio

GROUP BY Gender

ORDER BY Customer_Value_Rank;



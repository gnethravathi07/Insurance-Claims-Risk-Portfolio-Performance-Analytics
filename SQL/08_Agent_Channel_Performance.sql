
-- Step 10.1 — Agent Workforce Overview

SELECT
    COUNT(*) AS Total_Agents,

    COUNT(DISTINCT Region) AS Total_Regions,

    COUNT(DISTINCT Channel) AS Total_Channels,

    MIN(Experience_Years) AS Min_Experience_Years,

    MAX(Experience_Years) AS Max_Experience_Years,

    ROUND(
        AVG(Experience_Years), 2
    ) AS Avg_Experience_Years

FROM agents;




-- Step 10.2 — Agent Distribution by Region

SELECT
    Region,

    COUNT(*) AS Total_Agents,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Agent_Share_Pct,

    ROUND(
        AVG(Experience_Years), 2
    ) AS Avg_Experience_Years,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Agent_Count_Rank

FROM agents

GROUP BY Region

ORDER BY Agent_Count_Rank;





-- Step 10.3 — Agent Distribution by Channel

SELECT
    Channel,

    COUNT(*) AS Total_Agents,

    ROUND(
        COUNT(*) * 100.0 /
        SUM(COUNT(*)) OVER (), 2
    ) AS Agent_Share_Pct,

    ROUND(
        AVG(Experience_Years), 2
    ) AS Avg_Experience_Years,

    MIN(Experience_Years) AS Min_Experience_Years,

    MAX(Experience_Years) AS Max_Experience_Years,

    DENSE_RANK() OVER (
        ORDER BY COUNT(*) DESC
    ) AS Agent_Count_Rank

FROM agents

GROUP BY Channel

ORDER BY Agent_Count_Rank;



-- Step 10.4 — Agent Distribution by Region and Channel

WITH Channel_Distribution AS (
    SELECT
        Region,
        Channel,

        COUNT(*) AS Total_Agents,

        ROUND(
            AVG(Experience_Years), 2
        ) AS Avg_Experience_Years

    FROM agents

    GROUP BY
        Region,
        Channel
)

SELECT
    Region,
    Channel,
    Total_Agents,

    ROUND(
        Total_Agents * 100.0 /
        SUM(Total_Agents) OVER (
            PARTITION BY Region
        ), 2
    ) AS Regional_Agent_Share_Pct,

    Avg_Experience_Years,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY Total_Agents DESC
    ) AS Channel_Rank

FROM Channel_Distribution

ORDER BY
    Region,
    Channel_Rank;



-- Step 10.5 — Policy Assignment Performance by Agent

SELECT
    a.Agent_ID,
    a.Region,
    a.Channel,
    a.Experience_Years,

    COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

    ROUND(
        COUNT(pa.Policy_ID) * 100.0 /
        NULLIF(
            SUM(COUNT(pa.Policy_ID)) OVER (), 0
        ), 2
    ) AS Policy_Assignment_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY COUNT(pa.Policy_ID) DESC
    ) AS Assignment_Rank

FROM agents a

LEFT JOIN policy_agents pa
    ON a.Agent_ID = pa.Agent_ID

GROUP BY
    a.Agent_ID,
    a.Region,
    a.Channel,
    a.Experience_Years

ORDER BY
    Assignment_Rank,
    a.Agent_ID;



-- Step 10.6 — Policy Assignment Performance by Channel

WITH Agent_Workload AS (
    SELECT
        a.Agent_ID,
        a.Channel,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    GROUP BY
        a.Agent_ID,
        a.Channel
)

SELECT
    Channel,

    COUNT(*) AS Total_Agents,

    SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

    ROUND(
        AVG(Total_Assigned_Policies), 2
    ) AS Avg_Policies_Per_Agent,

    ROUND(
        SUM(Total_Assigned_Policies) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Assigned_Policies)) OVER (), 0
        ), 2
    ) AS Policy_Assignment_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Assigned_Policies) DESC
    ) AS Workload_Rank

FROM Agent_Workload

GROUP BY Channel

ORDER BY Workload_Rank;




-- Step 10.7 — Policy Assignment Performance by Region

WITH Agent_Workload AS (
    SELECT
        a.Agent_ID,
        a.Region,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    GROUP BY
        a.Agent_ID,
        a.Region
)

SELECT
    Region,

    COUNT(*) AS Total_Agents,

    SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

    ROUND(
        AVG(Total_Assigned_Policies), 2
    ) AS Avg_Policies_Per_Agent,

    ROUND(
        SUM(Total_Assigned_Policies) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Assigned_Policies)) OVER (), 0
        ), 2
    ) AS Policy_Assignment_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Assigned_Policies) DESC
    ) AS Workload_Rank

FROM Agent_Workload

GROUP BY Region

ORDER BY Workload_Rank;




-- Step 10.8 — Policy Assignment Performance by Region and Channel

WITH Agent_Workload AS (
    SELECT
        a.Agent_ID,
        a.Region,
        a.Channel,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    GROUP BY
        a.Agent_ID,
        a.Region,
        a.Channel
),

Region_Channel_Summary AS (
    SELECT
        Region,
        Channel,

        COUNT(*) AS Total_Agents,

        SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

        ROUND(
            AVG(Total_Assigned_Policies), 2
        ) AS Avg_Policies_Per_Agent

    FROM Agent_Workload

    GROUP BY
        Region,
        Channel
)

SELECT
    Region,
    Channel,
    Total_Agents,
    Total_Assigned_Policies,
    Avg_Policies_Per_Agent,

    ROUND(
        Total_Assigned_Policies * 100.0 /
        SUM(Total_Assigned_Policies) OVER (
            PARTITION BY Region
        ), 2
    ) AS Regional_Assignment_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY Avg_Policies_Per_Agent DESC
    ) AS Workload_Rank

FROM Region_Channel_Summary

ORDER BY
    Region,
    Workload_Rank;




-- Step 10.9 — Annual Premium Contribution by Channel

WITH Agent_Premiums AS (
    SELECT
        a.Agent_ID,
        a.Channel,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Agent_ID,
        a.Channel
)

SELECT
    Channel,

    COUNT(*) AS Total_Agents,

    SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Agent,

    ROUND(
        SUM(Total_Annual_Premium) /
        NULLIF(SUM(Total_Assigned_Policies), 0), 2
    ) AS Avg_Premium_Per_Policy,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY SUM(Total_Annual_Premium) DESC
    ) AS Premium_Rank

FROM Agent_Premiums

GROUP BY Channel

ORDER BY Premium_Rank;




-- Step 10.10 — Annual Premium Contribution by Agent Region

WITH Agent_Premiums AS (
    SELECT
        a.Agent_ID,
        a.Region,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Agent_ID,
        a.Region
)

SELECT
    Region,

    COUNT(*) AS Total_Agents,

    SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Agent,

    ROUND(
        SUM(Total_Annual_Premium) /
        NULLIF(SUM(Total_Assigned_Policies), 0), 2
    ) AS Avg_Premium_Per_Policy,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Premium_Per_Agent_Rank

FROM Agent_Premiums

GROUP BY Region

ORDER BY Premium_Per_Agent_Rank;




-- Step 10.11 — Annual Premium Contribution by Region and Channel

WITH Region_Channel_Premiums AS (
    SELECT
        a.Region,
        a.Channel,

        COUNT(DISTINCT a.Agent_ID) AS Total_Agents,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Region,
        a.Channel
)

SELECT
    Region,
    Channel,
    Total_Agents,
    Total_Assigned_Policies,

    ROUND(
        Total_Annual_Premium, 2
    ) AS Total_Annual_Premium,

    ROUND(
        Total_Annual_Premium /
        NULLIF(Total_Agents, 0), 2
    ) AS Avg_Premium_Per_Agent,

    ROUND(
        Total_Annual_Premium * 100.0 /
        NULLIF(
            SUM(Total_Annual_Premium) OVER (
                PARTITION BY Region
            ), 0
        ), 2
    ) AS Regional_Premium_Share_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY Total_Annual_Premium DESC
    ) AS Premium_Rank

FROM Region_Channel_Premiums

ORDER BY
    Region,
    Premium_Rank;




-- Step 10.12 — Agent Performance by Experience Group

WITH Agent_Performance AS (
    SELECT
        a.Agent_ID,

        CASE
            WHEN a.Experience_Years <= 5 THEN '1-5 Years'
            WHEN a.Experience_Years <= 10 THEN '6-10 Years'
            WHEN a.Experience_Years <= 15 THEN '11-15 Years'
            ELSE '16-20 Years'
        END AS Experience_Group,

        COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

        COALESCE(
            SUM(p.Annual_Premium), 0
        ) AS Total_Annual_Premium

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Agent_ID,
        a.Experience_Years
)

SELECT
    Experience_Group,

    COUNT(*) AS Total_Agents,

    SUM(Total_Assigned_Policies) AS Total_Assigned_Policies,

    ROUND(
        AVG(Total_Assigned_Policies), 2
    ) AS Avg_Policies_Per_Agent,

    ROUND(
        SUM(Total_Annual_Premium), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(Total_Annual_Premium), 2
    ) AS Avg_Premium_Per_Agent,

    ROUND(
        SUM(Total_Annual_Premium) * 100.0 /
        NULLIF(
            SUM(SUM(Total_Annual_Premium)) OVER (), 0
        ), 2
    ) AS Premium_Contribution_Pct,

    DENSE_RANK() OVER (
        ORDER BY AVG(Total_Annual_Premium) DESC
    ) AS Performance_Rank

FROM Agent_Performance

GROUP BY Experience_Group

ORDER BY Performance_Rank;



-- Step 10.13 — Top 10 Agents by Annual Premium Portfolio

SELECT
    a.Agent_ID,
    a.Region,
    a.Channel,
    a.Experience_Years,

    COUNT(pa.Policy_ID) AS Total_Assigned_Policies,

    ROUND(
        COALESCE(SUM(p.Annual_Premium), 0), 2
    ) AS Total_Annual_Premium,

    ROUND(
        AVG(p.Annual_Premium), 2
    ) AS Avg_Premium_Per_Policy,

    DENSE_RANK() OVER (
        ORDER BY COALESCE(SUM(p.Annual_Premium), 0) DESC
    ) AS Premium_Rank

FROM agents a

LEFT JOIN policy_agents pa
    ON a.Agent_ID = pa.Agent_ID

LEFT JOIN policies p
    ON pa.Policy_ID = p.Policy_ID

GROUP BY
    a.Agent_ID,
    a.Region,
    a.Channel,
    a.Experience_Years

ORDER BY
    Total_Annual_Premium DESC,
    a.Agent_ID

LIMIT 10;



-- Step 10.14 — Agent Policy Status Performance

WITH Agent_Status AS (
    SELECT
        a.Agent_ID,
        a.Region,
        a.Channel,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Active'
            THEN 1 ELSE 0 END
        ) AS Active_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Expired'
            THEN 1 ELSE 0 END
        ) AS Expired_Policies,

        SUM(
            CASE WHEN p.Policy_Status = 'Cancelled'
            THEN 1 ELSE 0 END
        ) AS Cancelled_Policies

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Agent_ID,
        a.Region,
        a.Channel
)

SELECT
    Agent_ID,
    Region,
    Channel,
    Total_Policies,
    Active_Policies,
    Expired_Policies,
    Cancelled_Policies,

    ROUND(
        Cancelled_Policies * 100.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            Cancelled_Policies * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Cancellation_Rank

FROM Agent_Status

WHERE Total_Policies > 0

ORDER BY
    Cancellation_Rank,
    Agent_ID

LIMIT 10;




-- Step 10.15 — Policy Cancellation Rate by Distribution Channel

SELECT
    a.Channel,

    COUNT(DISTINCT a.Agent_ID) AS Total_Agents,

    COUNT(p.Policy_ID) AS Total_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Active' THEN 1
            ELSE 0
        END
    ) AS Active_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Expired' THEN 1
            ELSE 0
        END
    ) AS Expired_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS Cancelled_Policies,

    ROUND(
        SUM(
            CASE
                WHEN p.Policy_Status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(COUNT(p.Policy_ID), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE
                    WHEN p.Policy_Status = 'Cancelled' THEN 1
                    ELSE 0
                END
            ) * 1.0 /
            NULLIF(COUNT(p.Policy_ID), 0) DESC
    ) AS Cancellation_Rank

FROM agents a

LEFT JOIN policy_agents pa
    ON a.Agent_ID = pa.Agent_ID

LEFT JOIN policies p
    ON pa.Policy_ID = p.Policy_ID

GROUP BY a.Channel

ORDER BY Cancellation_Rank;



-- Step 10.16 — Policy Cancellation Rate by Agent Region

SELECT
    a.Region,

    COUNT(DISTINCT a.Agent_ID) AS Total_Agents,

    COUNT(p.Policy_ID) AS Total_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Active' THEN 1
            ELSE 0
        END
    ) AS Active_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Expired' THEN 1
            ELSE 0
        END
    ) AS Expired_Policies,

    SUM(
        CASE
            WHEN p.Policy_Status = 'Cancelled' THEN 1
            ELSE 0
        END
    ) AS Cancelled_Policies,

    ROUND(
        SUM(
            CASE
                WHEN p.Policy_Status = 'Cancelled' THEN 1
                ELSE 0
            END
        ) * 100.0 /
        NULLIF(COUNT(p.Policy_ID), 0), 2
    ) AS Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            SUM(
                CASE
                    WHEN p.Policy_Status = 'Cancelled' THEN 1
                    ELSE 0
                END
            ) * 1.0 /
            NULLIF(COUNT(p.Policy_ID), 0) DESC
    ) AS Cancellation_Rank

FROM agents a

LEFT JOIN policy_agents pa
    ON a.Agent_ID = pa.Agent_ID

LEFT JOIN policies p
    ON pa.Policy_ID = p.Policy_ID

GROUP BY a.Region

ORDER BY Cancellation_Rank;




-- Step 10.17 — Policy Cancellation Rate by Region and Channel

WITH Region_Channel_Status AS (
    SELECT
        a.Region,
        a.Channel,

        COUNT(p.Policy_ID) AS Total_Policies,

        SUM(
            CASE
                WHEN p.Policy_Status = 'Cancelled'
                THEN 1 ELSE 0
            END
        ) AS Cancelled_Policies

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    GROUP BY
        a.Region,
        a.Channel
),

Cancellation_Analysis AS (
    SELECT
        Region,
        Channel,
        Total_Policies,
        Cancelled_Policies,

        ROUND(
            Cancelled_Policies * 100.0 /
            NULLIF(Total_Policies, 0), 2
        ) AS Cancellation_Rate_Pct

    FROM Region_Channel_Status
)

SELECT
    Region,
    Channel,
    Total_Policies,
    Cancelled_Policies,
    Cancellation_Rate_Pct,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY Cancellation_Rate_Pct DESC
    ) AS Cancellation_Rank

FROM Cancellation_Analysis

ORDER BY
    Region,
    Cancellation_Rank;
    



-- Step 10.18 — Claims Performance by Agent Channel

WITH Channel_Claims AS (
    SELECT
        a.Channel,

        COUNT(DISTINCT a.Agent_ID) AS Total_Agents,

        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,

        COUNT(c.Claim_ID) AS Total_Claims,

        COALESCE(
            SUM(c.Claim_Amount), 0
        ) AS Total_Claim_Amount

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY a.Channel
)

SELECT
    Channel,
    Total_Agents,
    Total_Policies,
    Total_Claims,

    ROUND(
        Total_Claims * 1.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Claims_Per_Policy,

    ROUND(
        Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        Total_Claim_Amount /
        NULLIF(Total_Claims, 0), 2
    ) AS Avg_Claim_Amount,

    ROUND(
        Total_Claim_Amount * 100.0 /
        NULLIF(
            SUM(Total_Claim_Amount) OVER (), 0
        ), 2
    ) AS Claim_Amount_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            Total_Claims * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Claim_Frequency_Rank

FROM Channel_Claims

ORDER BY Claim_Frequency_Rank;




-- Step 10.19 — Claims Performance by Agent Region

WITH Region_Claims AS (
    SELECT
        a.Region,

        COUNT(DISTINCT a.Agent_ID) AS Total_Agents,

        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,

        COUNT(c.Claim_ID) AS Total_Claims,

        COALESCE(
            SUM(c.Claim_Amount), 0
        ) AS Total_Claim_Amount

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY a.Region
)

SELECT
    Region,
    Total_Agents,
    Total_Policies,
    Total_Claims,

    ROUND(
        Total_Claims * 1.0 /
        NULLIF(Total_Policies, 0), 2
    ) AS Claims_Per_Policy,

    ROUND(
        Total_Claim_Amount, 2
    ) AS Total_Claim_Amount,

    ROUND(
        Total_Claim_Amount /
        NULLIF(Total_Claims, 0), 2
    ) AS Avg_Claim_Amount,

    ROUND(
        Total_Claim_Amount * 100.0 /
        NULLIF(
            SUM(Total_Claim_Amount) OVER (), 0
        ), 2
    ) AS Claim_Amount_Share_Pct,

    DENSE_RANK() OVER (
        ORDER BY
            Total_Claims * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Claim_Frequency_Rank

FROM Region_Claims

ORDER BY Claim_Frequency_Rank;




-- Step 10.20 — Claims Performance by Region and Channel

WITH Region_Channel_Claims AS (
    SELECT
        a.Region,
        a.Channel,

        COUNT(DISTINCT p.Policy_ID) AS Total_Policies,

        COUNT(c.Claim_ID) AS Total_Claims,

        COALESCE(
            SUM(c.Claim_Amount), 0
        ) AS Total_Claim_Amount

    FROM agents a

    LEFT JOIN policy_agents pa
        ON a.Agent_ID = pa.Agent_ID

    LEFT JOIN policies p
        ON pa.Policy_ID = p.Policy_ID

    LEFT JOIN claims c
        ON p.Policy_ID = c.Policy_ID

    GROUP BY
        a.Region,
        a.Channel
),

Claims_Analysis AS (
    SELECT
        Region,
        Channel,
        Total_Policies,
        Total_Claims,

        ROUND(
            Total_Claims * 1.0 /
            NULLIF(Total_Policies, 0), 2
        ) AS Claims_Per_Policy,

        ROUND(
            Total_Claim_Amount, 2
        ) AS Total_Claim_Amount,

        ROUND(
            Total_Claim_Amount /
            NULLIF(Total_Claims, 0), 2
        ) AS Avg_Claim_Amount

    FROM Region_Channel_Claims
)

SELECT
    Region,
    Channel,
    Total_Policies,
    Total_Claims,
    Claims_Per_Policy,
    Total_Claim_Amount,
    Avg_Claim_Amount,

    DENSE_RANK() OVER (
        PARTITION BY Region
        ORDER BY
            Total_Claims * 1.0 /
            NULLIF(Total_Policies, 0) DESC
    ) AS Claim_Frequency_Rank

FROM Claims_Analysis

ORDER BY
    Region,
    Claim_Frequency_Rank;
    
    








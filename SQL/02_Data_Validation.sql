-- Step 5.1 — Validate Policy-Customer Relationships

USE insurance_claims_analytics;

SELECT
    COUNT(*) AS Invalid_Customer_References
FROM policies p
LEFT JOIN customers c
    ON p.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;


-- Step 5.2 — Validate Claim-Policy Relationships

SELECT
    COUNT(*) AS Invalid_Policy_References
FROM claims c
LEFT JOIN policies p
    ON c.Policy_ID = p.Policy_ID
WHERE p.Policy_ID IS NULL;

-- Step 5.3 — Validate Payment-Claim Relationships

SELECT
    COUNT(*) AS Invalid_Claim_References
FROM payments p
LEFT JOIN claims c
    ON p.Claim_ID = c.Claim_ID
WHERE c.Claim_ID IS NULL;


-- Step 5.4 — Validate Risk Assessment-Customer Relationships

SELECT
    COUNT(*) AS Invalid_Risk_Customer_References
FROM risk_assessment r
LEFT JOIN customers c
    ON r.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;


-- Step 5.5 — Validate Policy-Agent Relationships

SELECT
    COUNT(*) AS Invalid_Agent_References
FROM policy_agents pa
LEFT JOIN agents a
    ON pa.Agent_ID = a.Agent_ID
WHERE a.Agent_ID IS NULL;

-- Step 5.6 — Validate Policy-Agent Policy References

SELECT
    COUNT(*) AS Invalid_Assigned_Policy_References
FROM policy_agents pa
LEFT JOIN policies p
    ON pa.Policy_ID = p.Policy_ID
WHERE p.Policy_ID IS NULL;


-- Step 5.7 — Validate Vehicle-Customer Relationships

SELECT
    COUNT(*) AS Invalid_Vehicle_Customer_References
FROM vehicles v
LEFT JOIN customers c
    ON v.Customer_ID = c.Customer_ID
WHERE c.Customer_ID IS NULL;

-- Step 5.8 — Validate Duplicate Customer IDs

SELECT
    Customer_ID,
    COUNT(*) AS Duplicate_Count
FROM customers
GROUP BY Customer_ID
HAVING COUNT(*) > 1;

-- Step 5.9 — Validate Customer Age Range

SELECT
    COUNT(*) AS Invalid_Age_Records
FROM customers
WHERE Age IS NULL
   OR Age < 18
   OR Age > 100;
   
-- Step 5.10 — Validate Customer Annual Income

SELECT
    COUNT(*) AS Invalid_Income_Records
FROM customers
WHERE Annual_Income IS NULL
   OR Annual_Income < 0;
   
-- Step 5.11 — Validate Insurance Policy Financial Values

SELECT
    COUNT(*) AS Invalid_Policy_Financial_Records
FROM policies
WHERE Annual_Premium IS NULL
   OR Annual_Premium <= 0
   OR Coverage_Amount IS NULL
   OR Coverage_Amount <= 0;
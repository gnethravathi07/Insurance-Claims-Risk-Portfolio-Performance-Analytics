-- Step 4.1 — Create Insurance Analytics Database

CREATE DATABASE IF NOT EXISTS insurance_claims_analytics;

USE insurance_claims_analytics;

SELECT DATABASE() AS Current_Database;


-- Step 4.2 — Create Customers Table

CREATE TABLE IF NOT EXISTS customers (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Age INT,
    Gender VARCHAR(20),
    Region VARCHAR(50),
    Join_Date DATE,
    Annual_Income DECIMAL(15,2)
);

DESCRIBE customers;

-- Step 4.3 — Create Policies Table

CREATE TABLE IF NOT EXISTS policies (
    Policy_ID VARCHAR(20) PRIMARY KEY,
    Customer_ID VARCHAR(20),
    Policy_Type VARCHAR(30),
    Start_Date DATE,
    End_Date DATE,
    Annual_Premium DECIMAL(15,2),
    Coverage_Amount DECIMAL(15,2),
    Policy_Status VARCHAR(20),

    FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);

DESCRIBE policies;

-- Step 4.4 — Create Claims Table

CREATE TABLE IF NOT EXISTS claims (
    Claim_ID VARCHAR(20) PRIMARY KEY,
    Policy_ID VARCHAR(20),
    Claim_Date DATE,
    Claim_Amount DECIMAL(15,2),
    Claim_Status VARCHAR(20),
    Fraud_Flag INT,
    Claim_Type VARCHAR(30),

    FOREIGN KEY (Policy_ID)
        REFERENCES policies(Policy_ID)
);

-- Verify Claims Table Structure

DESCRIBE claims;


-- Step 4.5 — Create Payments Table

CREATE TABLE IF NOT EXISTS payments (
    Payment_ID VARCHAR(20) PRIMARY KEY,
    Claim_ID VARCHAR(20),
    Payment_Date DATE,
    Payment_Amount DECIMAL(15,2),
    Payment_Method VARCHAR(30),

    FOREIGN KEY (Claim_ID)
        REFERENCES claims(Claim_ID)
);

-- Verify Payments Table Structure

DESCRIBE payments;

-- Step 4.6 — Create Risk Assessment Table

CREATE TABLE IF NOT EXISTS risk_assessment (
    Customer_ID VARCHAR(20) PRIMARY KEY,
    Risk_Score INT,
    Risk_Category VARCHAR(20),
    Assessment_Date DATE,

    FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);

-- Verify Risk Assessment Table Structure

DESCRIBE risk_assessment;


-- Step 4.7 — Create Agents Table

CREATE TABLE IF NOT EXISTS agents (
    Agent_ID VARCHAR(20) PRIMARY KEY,
    Region VARCHAR(50),
    Experience_Years INT,
    Channel VARCHAR(30)
);

-- Verify Agents Table Structure

DESCRIBE agents;

-- Step 4.8 — Create Policy Agents Table

CREATE TABLE IF NOT EXISTS policy_agents (
    Policy_ID VARCHAR(20) PRIMARY KEY,
    Agent_ID VARCHAR(20),

    FOREIGN KEY (Policy_ID)
        REFERENCES policies(Policy_ID),

    FOREIGN KEY (Agent_ID)
        REFERENCES agents(Agent_ID)
);

-- Verify Policy Agents Table Structure

DESCRIBE policy_agents;


-- Step 4.9 — Create Vehicles Table

CREATE TABLE IF NOT EXISTS vehicles (
    Vehicle_ID VARCHAR(20) PRIMARY KEY,
    Customer_ID VARCHAR(20),
    Vehicle_Type VARCHAR(30),
    Vehicle_Age INT,
    Insured_Value DECIMAL(15,2),

    FOREIGN KEY (Customer_ID)
        REFERENCES customers(Customer_ID)
);

-- Verify Vehicles Table Structure

DESCRIBE vehicles;

-- Step 4.10 — Verify All Insurance Database Tables

USE insurance_claims_analytics;

SHOW TABLES;



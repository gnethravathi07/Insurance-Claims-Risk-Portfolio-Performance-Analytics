# Data Dictionary

## Insurance Claims, Risk & Portfolio Performance Analytics

This document describes the eight source tables used in the
`insurance_claims_analytics` MySQL database. Table names, column names,
SQL data types, primary keys, and foreign keys are based on the uploaded
`Database_setup.sql` script. Business descriptions are based on the
uploaded notebooks and SQL analysis scripts.

## 1. Database Summary

| Property                                       | Value                        |
|------------------------------------------------|------------------------------|
| Database                                       | `insurance_claims_analytics` |
| Tables                                         | 8                            |
| Source records                                 | 96,791                       |
| Source columns                                 | 41                           |
| Reporting cutoff used in consolidated analysis | September 30, 2026           |

### Source table sizes

| Table             |       Rows | Columns |
|-------------------|-----------:|--------:|
| `customers`       |     10,000 |       6 |
| `policies`        |     15,000 |       8 |
| `claims`          |     25,000 |       7 |
| `payments`        |     15,541 |       5 |
| `risk_assessment` |     10,000 |       4 |
| `agents`          |        250 |       4 |
| `policy_agents`   |     15,000 |       2 |
| `vehicles`        |      6,000 |       5 |
| **Total**         | **96,791** |  **41** |

## 2. Table Definitions

### 2.1 `customers`

**Purpose:** Stores customer identifiers and descriptive information
used for customer segmentation and portfolio analysis.

| Column          | MySQL type      | Key | Description                       |
|-----------------|-----------------|-----|-----------------------------------|
| `Customer_ID`   | `VARCHAR(20)`   | PK  | Unique customer identifier        |
| `Age`           | `INT`           | —   | Customer age in years             |
| `Gender`        | `VARCHAR(20)`   | —   | Recorded customer gender category |
| `Region`        | `VARCHAR(50)`   | —   | Customer region                   |
| `Join_Date`     | `DATE`          | —   | Recorded customer joining date    |
| `Annual_Income` | `DECIMAL(15,2)` | —   | Recorded annual customer income   |

**Rows:** 10,000 · **Columns:** 6

### 2.2 `policies`

**Purpose:** Stores insurance policy details, policy dates, annualized
premium, coverage amount, and recorded policy status.

| Column            | MySQL type      | Key                          | Description                                                    |
|-------------------|-----------------|------------------------------|----------------------------------------------------------------|
| `Policy_ID`       | `VARCHAR(20)`   | PK                           | Unique policy identifier                                       |
| `Customer_ID`     | `VARCHAR(20)`   | FK → `customers.Customer_ID` | Customer associated with the policy                            |
| `Policy_Type`     | `VARCHAR(30)`   | —                            | Insurance category; analysis uses Auto, Health, Home, and Life |
| `Start_Date`      | `DATE`          | —                            | Recorded policy start date                                     |
| `End_Date`        | `DATE`          | —                            | Recorded policy end date                                       |
| `Annual_Premium`  | `DECIMAL(15,2)` | —                            | Recorded annualized policy premium                             |
| `Coverage_Amount` | `DECIMAL(15,2)` | —                            | Recorded policy coverage limit                                 |
| `Policy_Status`   | `VARCHAR(20)`   | —                            | Recorded policy status                                         |

**Rows:** 15,000 · **Columns:** 8

### 2.3 `claims`

**Purpose:** Stores claim records linked to insurance policies,
including amounts, status, claim category, and the dataset’s existing
fraud flag.

| Column         | MySQL type      | Key                       | Description                                                              |
|----------------|-----------------|---------------------------|--------------------------------------------------------------------------|
| `Claim_ID`     | `VARCHAR(20)`   | PK                        | Unique claim identifier                                                  |
| `Policy_ID`    | `VARCHAR(20)`   | FK → `policies.Policy_ID` | Policy associated with the claim                                         |
| `Claim_Date`   | `DATE`          | —                         | Recorded claim date                                                      |
| `Claim_Amount` | `DECIMAL(15,2)` | —                         | Recorded requested claim amount                                          |
| `Claim_Status` | `VARCHAR(20)`   | —                         | Recorded claim processing status                                         |
| `Fraud_Flag`   | `INT`           | —                         | Existing binary fraud-review indicator; audit checks validate its values |
| `Claim_Type`   | `VARCHAR(30)`   | —                         | Claim insurance category                                                 |

**Rows:** 25,000 · **Columns:** 7

### 2.4 `payments`

**Purpose:** Stores payment records associated with claims.

| Column           | MySQL type      | Key                    | Description                       |
|------------------|-----------------|------------------------|-----------------------------------|
| `Payment_ID`     | `VARCHAR(20)`   | PK                     | Unique payment identifier         |
| `Claim_ID`       | `VARCHAR(20)`   | FK → `claims.Claim_ID` | Claim associated with the payment |
| `Payment_Date`   | `DATE`          | —                      | Recorded payment date             |
| `Payment_Amount` | `DECIMAL(15,2)` | —                      | Recorded payment amount           |
| `Payment_Method` | `VARCHAR(30)`   | —                      | Recorded payment method           |

**Rows:** 15,541 · **Columns:** 5

### 2.5 `risk_assessment`

**Purpose:** Stores the customer risk score and risk category used in
risk segmentation and fraud-flag analysis.

| Column            | MySQL type    | Key                              | Description                                                         |
|-------------------|---------------|----------------------------------|---------------------------------------------------------------------|
| `Customer_ID`     | `VARCHAR(20)` | PK, FK → `customers.Customer_ID` | Customer assessed; one row per customer in this schema              |
| `Risk_Score`      | `INT`         | —                                | Recorded numerical risk score; notebook analysis uses a 0–100 scale |
| `Risk_Category`   | `VARCHAR(20)` | —                                | Recorded customer risk category                                     |
| `Assessment_Date` | `DATE`        | —                                | Recorded risk assessment date                                       |

**Rows:** 10,000 · **Columns:** 4

### 2.6 `agents`

**Purpose:** Stores agent information used for distribution-channel and
agent-performance analysis.

| Column             | MySQL type    | Key | Description                   |
|--------------------|---------------|-----|-------------------------------|
| `Agent_ID`         | `VARCHAR(20)` | PK  | Unique agent identifier       |
| `Region`           | `VARCHAR(50)` | —   | Agent region                  |
| `Experience_Years` | `INT`         | —   | Agent experience in years     |
| `Channel`          | `VARCHAR(30)` | —   | Recorded distribution channel |

**Rows:** 250 · **Columns:** 4

### 2.7 `policy_agents`

**Purpose:** Links policies to their assigned agents.

| Column      | MySQL type    | Key                           | Description                                                                |
|-------------|---------------|-------------------------------|----------------------------------------------------------------------------|
| `Policy_ID` | `VARCHAR(20)` | PK, FK → `policies.Policy_ID` | Policy assigned to an agent; primary key allows at most one row per policy |
| `Agent_ID`  | `VARCHAR(20)` | FK → `agents.Agent_ID`        | Agent assigned to the policy                                               |

**Rows:** 15,000 · **Columns:** 2

### 2.8 `vehicles`

**Purpose:** Stores vehicle details associated with customers for
vehicle and auto-policy analysis.

| Column          | MySQL type      | Key                          | Description                          |
|-----------------|-----------------|------------------------------|--------------------------------------|
| `Vehicle_ID`    | `VARCHAR(20)`   | PK                           | Unique vehicle identifier            |
| `Customer_ID`   | `VARCHAR(20)`   | FK → `customers.Customer_ID` | Customer associated with the vehicle |
| `Vehicle_Type`  | `VARCHAR(30)`   | —                            | Recorded vehicle category            |
| `Vehicle_Age`   | `INT`           | —                            | Vehicle age in years                 |
| `Insured_Value` | `DECIMAL(15,2)` | —                            | Recorded insured vehicle value       |

**Rows:** 6,000 · **Columns:** 5

## 3. Database Relationships

The following relationships are defined explicitly in
`Database_setup.sql`.

| Parent table | Parent key    | Child table       | Child key     | Relationship implied by DDL              |
|--------------|---------------|-------------------|---------------|------------------------------------------|
| `customers`  | `Customer_ID` | `policies`        | `Customer_ID` | One customer to many policies            |
| `policies`   | `Policy_ID`   | `claims`          | `Policy_ID`   | One policy to many claims                |
| `claims`     | `Claim_ID`    | `payments`        | `Claim_ID`    | One claim to many payment records        |
| `customers`  | `Customer_ID` | `risk_assessment` | `Customer_ID` | One-to-one key structure in this schema  |
| `policies`   | `Policy_ID`   | `policy_agents`   | `Policy_ID`   | One policy to zero or one assignment row |
| `agents`     | `Agent_ID`    | `policy_agents`   | `Agent_ID`    | One agent to many policy assignments     |
| `customers`  | `Customer_ID` | `vehicles`        | `Customer_ID` | One customer to many vehicles            |

### Relationship diagram

``` mermaid
erDiagram
    CUSTOMERS ||--o{ POLICIES : owns
    POLICIES ||--o{ CLAIMS : has
    CLAIMS ||--o{ PAYMENTS : receives
    CUSTOMERS ||--|| RISK_ASSESSMENT : assessed_by
    POLICIES ||--o| POLICY_AGENTS : assigned
    AGENTS ||--o{ POLICY_AGENTS : handles
    CUSTOMERS ||--o{ VEHICLES : owns
```

The diagram represents the key structure declared in the SQL DDL. Actual
business participation and row-level completeness are assessed
separately in the audit notebooks and SQL validation scripts.

## 4. Categorical Values and Analytical Conventions

The following labels are referenced in the uploaded analysis notebooks:

| Field                   | Categories or convention observed    |
|-------------------------|--------------------------------------|
| `Policy_Type`           | Auto, Health, Home, Life             |
| `Claim_Type`            | Auto, Health, Home, Life             |
| `Policy_Status`         | Active, Expired, Cancelled           |
| `Claim_Status`          | Settled, Approved, Rejected, Pending |
| `Risk_Category`         | Low, Medium, High                    |
| `Fraud_Flag`            | Audited as a binary indicator        |
| `Risk_Score`            | Analyzed on a 0–100 scale            |
| Analysis reference date | September 30, 2026                   |

These are observed analysis conventions, not additional database
constraints. The SQL table definitions use `VARCHAR` and `INT` fields
and do not declare enumerated-value constraints.

## 5. Notebook-Derived Analytical Fields

The Data Cleaning notebook creates additional columns in working
DataFrames for validation and analysis. These are **derived notebook
fields**, not columns in the original eight-table DDL shown above.

| Working table | Derived field                   | Purpose                                                             |
|---------------|---------------------------------|---------------------------------------------------------------------|
| `policies`    | `Customer_Join_Date`            | Maps each policy to the customer’s recorded join date               |
| `policies`    | `Flag_Start_Before_Join`        | Flags policies starting before the customer’s join date             |
| `policies`    | `Coverage_Status_As_Of`         | Derives a date-based coverage status at the reference date          |
| `policies`    | `Flag_Active_After_Expiry`      | Flags Active-labelled policies whose end date has passed            |
| `policies`    | `Flag_Expired_Before_End`       | Flags Expired-labelled policies whose end date has not passed       |
| `claims`      | `Policy_Coverage_Amount`        | Maps the related policy’s coverage amount                           |
| `claims`      | `Flag_Claim_Exceeds_Coverage`   | Flags claim amounts above linked policy coverage                    |
| `claims`      | `Flag_Settled_Without_Payment`  | Flags Settled claims without a matching payment record              |
| `claims`      | `Flag_Claim_Amount_Outlier`     | Flags claim amounts outside IQR boundaries                          |
| `claims`      | `Flag_Requires_Review`          | Combines selected claim coverage, payment-record, and outlier flags |
| `payments`    | `Policy_ID`                     | Maps the policy through the linked claim                            |
| `payments`    | `Policy_Coverage_Amount`        | Maps the related policy coverage amount                             |
| `payments`    | `Flag_Payment_Exceeds_Coverage` | Flags payment amounts above linked policy coverage                  |
| `payments`    | `Flag_Payment_After_Cutoff`     | Flags payments after September 30, 2026                             |
| `payments`    | `Flag_Payment_Amount_Outlier`   | Flags payment amounts outside IQR boundaries                        |

The cleaning notebook preserves original policy statuses and financial
values. Outliers and business-rule exceptions are retained for
investigation rather than automatically removed or rewritten.

## 6. Data Quality and Validation Notes

The Data Understanding and Data Quality Audit notebooks report:

- No missing values in the eight source tables at the initial profiling
  stage.
- No duplicate source records or duplicate primary-key values identified
  in the initial audit.
- Seven foreign-key relationships validated with no invalid references.
- Seven date columns parsed without invalid dates during initial data
  understanding.
- Policy start dates, recorded policy statuses, claim coverage, payment
  coverage, payment chronology, and reporting-cutoff conditions were
  investigated separately.
- Statistical outliers were retained because an unusual claim or payment
  value is not automatically invalid.

The audit and cleaning notebooks contain some different outlier counts.
These differences are documented for reconciliation in [Business
Insights](Business_Insights.md).

## 7. Important Interpretation Notes

- ID fields are defined as `VARCHAR(20)` in MySQL. The original CSV
  files were read by Pandas with numeric ID columns in integer form; the
  database schema uses character-based identifiers.
- Financial fields are defined with `DECIMAL(15,2)` in MySQL where
  specified in the DDL.
- `Annual_Premium` represents an annualized policy premium, not verified
  cash received.
- `Coverage_Amount` and `Insured_Value` are recorded coverage/insured
  values, not expected losses.
- `Claim_Amount` is the recorded claim amount, not necessarily an
  approved payable amount.
- `Fraud_Flag` is an existing data indicator; it does not confirm fraud.
- Payment date is not a claim settlement date. A formal settlement date
  is not present in the source schema.

## 8. Source Files

The dictionary is based primarily on:

- `Database_setup.sql`
- `02_Data_Validation.sql`
- `01_Data_Understanding.ipynb`
- `02_Data_Quality_Audit.ipynb`
- `03_Data_Cleaning.ipynb`
- Supporting analysis notebooks and SQL scripts

------------------------------------------------------------------------

[Back to Project Overview](Project_Overview.md) · [Business
Insights](Business_Insights.md)

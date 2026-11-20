# Project Overview

## Insurance Claims, Risk & Portfolio Performance Analytics

An end-to-end insurance analytics project using **MySQL, Python, SQL,
and Power BI** to examine customer portfolios, policies, claims, risk
indicators, financial exposure, and payment performance.

The project uses eight connected insurance datasets containing **96,791
records and 41 source columns**. It combines database design,
data-quality validation, SQL analysis, Python exploration and
statistical investigation, and an interactive six-page Power BI report.

## 1. Project Snapshot

| Item                                             | Details                                |
|--------------------------------------------------|----------------------------------------|
| Project domain                                   | Insurance analytics                    |
| Database                                         | MySQL                                  |
| Database name                                    | `insurance_claims_analytics`           |
| Source tables                                    | 8                                      |
| Total source records                             | 96,791                                 |
| Total source columns                             | 41                                     |
| SQL scripts                                      | 9, including database setup            |
| Python notebooks                                 | 11                                     |
| BI report                                        | Power BI, 6 pages                      |
| Python–MySQL connection                          | SQLAlchemy + PyMySQL                   |
| Power BI–MySQL connection                        | ODBC, DSN `Insurance_Claims_Analytics` |
| Reporting cutoff used in final business analysis | September 30, 2026                     |

## 2. Business Context

Insurance operations generate connected records about customers,
policies, claims, payments, risk assessments, agents, and insured
vehicles. Reviewing these records separately can make it difficult to
understand the overall portfolio, identify data-quality issues, compare
claim severity, investigate risk indicators, and monitor payment
activity.

This project brings the datasets together in a relational MySQL database
and applies SQL, Python, and Power BI analysis to support a more
complete view of insurance portfolio performance.

## 3. Project Objectives

- Understand the structure, volume, data types, and relationships of the
  eight source datasets.
- Create a relational MySQL database with primary-key and foreign-key
  definitions.
- Audit missing values, duplicates, referential integrity, date
  consistency, numerical ranges, and business rules.
- Standardize date, categorical, and numerical fields while preserving
  original records and values.
- Analyze customer participation, policy composition, claim frequency
  and severity, risk indicators, financial exposure, and payment
  timelines.
- Use statistical tests to investigate relationships between customer
  risk indicators and existing fraud flags.
- Build a Power BI report that presents key metrics and analysis across
  six business areas.
- Translate analytical findings into practical recommendations while
  documenting limitations.

## 4. Dataset Summary

| Source table      |       Rows | Columns | Main subject                                              |
|-------------------|-----------:|--------:|-----------------------------------------------------------|
| `customers`       |     10,000 |       6 | Customer details, demographics, region, and income        |
| `policies`        |     15,000 |       8 | Insurance policies, dates, premiums, coverage, and status |
| `claims`          |     25,000 |       7 | Claim dates, amounts, types, statuses, and fraud flags    |
| `payments`        |     15,541 |       5 | Claim-related payments, dates, amounts, and methods       |
| `risk_assessment` |     10,000 |       4 | Customer risk scores, categories, and assessment dates    |
| `agents`          |        250 |       4 | Agent region, experience, and channel                     |
| `policy_agents`   |     15,000 |       2 | Policy-to-agent assignments                               |
| `vehicles`        |      6,000 |       5 | Customer-linked vehicle information and insured value     |
| **Total**         | **96,791** |  **41** | **8 related source tables**                               |

For field-level definitions, SQL data types, keys, and relationships,
see [Data Dictionary](Data_Dictionary.md).

## 5. Technology Stack

| Layer                          | Tools and technologies                                                 |
|--------------------------------|------------------------------------------------------------------------|
| Database                       | MySQL                                                                  |
| SQL analysis                   | MySQL SQL, joins, CTEs, aggregations, subqueries, and window functions |
| Programming                    | Python                                                                 |
| Data manipulation              | Pandas, NumPy                                                          |
| Statistical analysis           | SciPy                                                                  |
| Visualization                  | Matplotlib, Seaborn                                                    |
| Python database connectivity   | SQLAlchemy, PyMySQL                                                    |
| BI and reporting               | Power BI, Power Query, DAX                                             |
| Power BI database connectivity | ODBC                                                                   |
| Development environment        | Jupyter Notebook, MySQL Workbench, Power BI Desktop                    |

## 6. End-to-End Workflow

``` mermaid
flowchart TD
    A["8 Source CSV Datasets"] --> B["01 Data Understanding"]
    B --> C["02 Data Quality Audit"]
    C --> D["03 Data Cleaning & Preparation"]
    D --> E["MySQL Database<br/>insurance_claims_analytics"]
    E --> F["MySQL SQL Analysis"]
    E --> G["Python Analytics<br/>SQLAlchemy + PyMySQL"]
    E --> H["Power BI via ODBC<br/>DSN: Insurance_Claims_Analytics"]
    F --> I["Business Metrics & Findings"]
    G --> I
    H --> J["Power Query, Data Model & DAX"]
    J --> K["Six-Page Power BI Report"]
    I --> L["Business Insights & Recommendations"]
    K --> L
```

### 6.1 Data Understanding and Preparation

The first notebooks profile the eight datasets, review their dimensions
and data types, inspect categories, validate identifiers and
relationships, and audit data quality. The cleaning notebook
standardizes dates, categorical values, and numerical data types. It
also creates analytical flags for selected policy, claim, and payment
exceptions without deleting the original records.

### 6.2 MySQL Database

The database is named `insurance_claims_analytics`. The
`Database_setup.sql` script creates the eight tables and defines their
primary-key and foreign-key relationships.

The MySQL loading notebook reads the source CSV files and loads records
into the database. The analysis notebooks then retrieve data from MySQL
for further investigation.

### 6.3 Python–MySQL Connection

Python notebooks connect to the local MySQL database through SQLAlchemy
and PyMySQL. The connection uses `localhost`, port `3306`, and database
`insurance_claims_analytics`. The password is requested interactively
using `getpass`; credentials are not included in the notebook connection
code.

### 6.4 Power BI–MySQL Connection

Power BI Desktop connects to MySQL through **ODBC** using the configured
Data Source Name:

- **ODBC DSN:** `Insurance_Claims_Analytics`
- **Database:** `insurance_claims_analytics`
- **Power Query connector:** `Odbc.DataSource`

The confirmed Power Query source expression is:

``` powerquery
Source = Odbc.DataSource(
    "dsn=Insurance_Claims_Analytics",
    [HierarchicalNavigation=true]
)
```

Power Query navigates to the MySQL database and prepares the data used
by the Power BI model. DAX measures support the report KPIs and
calculations. The ODBC driver and DSN must be configured on any computer
used to refresh the report. The PBIX storage mode is not specified in
this documentation.

## 7. SQL Analysis Scope

The SQL scripts cover:

- Database and table setup.
- Relationship, key, and business-rule validation.
- Insurance portfolio and policy performance.
- Claims volume, severity, concentration, and coverage checks.
- Risk profiles and fraud-flag patterns.
- Policy financial performance.
- Payment trends, turnaround, and payment-record exceptions.
- Customer portfolio and claims participation.
- Agent, channel, and regional performance.

### SQL files

| File                                  | Purpose                                                       |
|---------------------------------------|---------------------------------------------------------------|
| `Database_setup.sql`                  | Creates the database, eight tables, and key relationships     |
| `02_Data_Validation.sql`              | Validates database relationships and selected business rules  |
| `03_Insurance_Portfolio_Analysis.sql` | Portfolio and policy analysis                                 |
| `04_Claims_Severity_Analysis.sql`     | Claims frequency, amounts, severity, and exposure             |
| `05_Risk_Fraud_Analytics.sql`         | Customer risk and fraud-flag analysis                         |
| `06_Policy_Financial_Performance.sql` | Premium, coverage, and policy financial analysis              |
| `06_Settlement_Payment_Analysis.sql`  | Payment trends, turnaround, and reconciliation checks         |
| `07_Customer_Portfolio_Analysis.sql`  | Customer portfolio, policy ownership, and claim participation |
| `08_Agent_Channel_Performance.sql`    | Agent, region, and channel performance                        |

## 8. Python Notebook Scope

The project contains 11 notebooks:

| Notebook                                   | Main work                                                                          |
|--------------------------------------------|------------------------------------------------------------------------------------|
| `01_Data_Understanding.ipynb`              | Dataset profiling, dimensions, data types, and relationships                       |
| `02_Data_Quality_Audit.ipynb`              | Completeness, uniqueness, referential integrity, dates, ranges, and rule checks    |
| `03_Data_Cleaning.ipynb`                   | Date and type standardization plus analytical quality flags                        |
| `04_MySQL_Data_Loading.ipynb`              | MySQL connection, table creation checks, and source-data loading                   |
| `05_Exploratory_Data_Analysis.ipynb`       | Demographics, distributions, acquisition, policy, and claim trends                 |
| `06_Customer_Analysis.ipynb`               | Customer ownership, diversification, claim participation, and premium contribution |
| `07_Claims_Severity_Analytics.ipynb`       | Claim severity, high-value claims, outliers, and exposure                          |
| `08_Risk_Fraud_Statistical_Analysis.ipynb` | Risk scores, fraud flags, statistical tests, and investigation prioritization      |
| `09_Policy_Financial_Performance.ipynb`    | Policy mix, premiums, coverage, and financial relationships                        |
| `10_Settlement_Payment_Performance.ipynb`  | Payment coverage, payment methods, and claim-to-payment elapsed time               |
| `11_Business_Insights.ipynb`               | Consolidated findings, recommendations, and limitations                            |

## 9. Power BI Report

The Power BI report contains six pages:

1.  **Executive Overview** — portfolio-level customer, policy, claims,
    risk, and payment indicators.
2.  **Claims & Severity Analysis** — claims volume, claim amounts,
    severity bands, and high-value claims.
3.  **Risk & Fraud Analytics** — risk scores, risk categories, and
    fraud-flag patterns.
4.  **Policy & Financial Performance** — policy composition, annualized
    premiums, coverage, and financial exposure.
5.  **Settlement & Payment Performance** — payment amounts, methods,
    turnaround, and payment-record exceptions.
6.  **Customer Analysis** — customer demographics, policy ownership,
    claims participation, and portfolio contribution.

## 10. Selected Project Outputs

- A relational MySQL database containing eight insurance tables.
- SQL scripts for database setup, validation, and business analysis.
- Eleven Jupyter notebooks covering data profiling, cleaning, EDA,
  statistical analysis, and business insights.
- A Power BI report connected to MySQL through ODBC.
- Three supporting documentation files: project overview, data
  dictionary, and business insights.

## 11. Reproduction Guide

1.  Install MySQL Server and MySQL Workbench.
2.  Install Python and the libraries used by the notebooks.
3.  Place the eight original CSV files in the project `data/` folder.
4.  Execute `Database_setup.sql` in MySQL Workbench.
5.  Run the data-understanding, audit, cleaning, and MySQL-loading
    notebooks in sequence.
6.  Execute the SQL analysis scripts against
    `insurance_claims_analytics`.
7.  Run the remaining Python analysis notebooks.
8.  Install a compatible MySQL ODBC driver and configure the DSN
    `Insurance_Claims_Analytics` to point to
    `insurance_claims_analytics`.
9.  Open the PBIX report in Power BI Desktop and refresh it after the
    ODBC setup is complete.

**Important:** The MySQL loading notebook appends records to destination
tables. Before rerunning the load, prepare or clear the destination
tables in a controlled manner to avoid duplicate rows or primary-key
conflicts. Do not commit database passwords, private credentials, or
local environment folders to GitHub.

## 12. Analytical Scope and Limitations

- The reporting cutoff used in the consolidated business analysis is
  **September 30, 2026**.
- Customer acquisition history includes records earlier than the claims
  analysis period; the customer join-date range should not be confused
  with the claim reporting period.
- Annualized premiums are not verified premium collections or recognized
  revenue.
- Coverage amounts are policy limits, not expected losses.
- Fraud flags are indicators requiring investigation, not confirmed
  fraud outcomes.
- Claim-to-payment elapsed time is not the same as formal
  approval-to-settlement turnaround; settlement dates are not available.
- A claim with no payment recorded within the reporting period is not
  necessarily unpaid or overdue.
- Statistical associations do not establish causation.
- Data-quality exceptions and differences between notebook outputs are
  documented in [Business Insights](Business_Insights.md).

## 13. Related Documentation

- [Data Dictionary](Data_Dictionary.md)
- [Business Insights & Recommendations](Business_Insights.md)
- [Repository README](../README.md)

------------------------------------------------------------------------

**Project:** Insurance Claims, Risk & Portfolio Performance Analytics  
**Author:** Nethravathi
G  
**GitHub:** [gnethravathi07](https://github.com/gnethravathi07)  
**LinkedIn:** [Nethra
G](https://www.linkedin.com/in/nethravathi-g-2309772b6/)

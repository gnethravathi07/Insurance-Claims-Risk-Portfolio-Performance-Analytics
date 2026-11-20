<div align="center">

# Insurance Claims, Risk & Portfolio Performance Analytics

**An end-to-end insurance analytics project powered by MySQL, Python and
Power BI.**

[![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](#mysql-database)
[![Python](https://img.shields.io/badge/Python-Analytics-3776AB?style=for-the-badge&logo=python&logoColor=white)](#python-analysis)
[![Power
BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](#power-bi-dashboard)
[![ODBC](https://img.shields.io/badge/ODBC-Connectivity-5865F2?style=for-the-badge)](#mysql--power-bi-connection)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebooks-F37626?style=for-the-badge&logo=jupyter&logoColor=white)](#python-analysis)

**8 datasets · 96,791 records · 11 Python notebooks · SQL analysis · 6
Power BI pages**

</div>

------------------------------------------------------------------------

## Project Overview

This project explores an insurance portfolio through customer, policy,
claims, risk, financial and payment analytics. It combines relational
database querying, Python-based investigation, statistical analysis and
interactive Power BI reporting to turn raw insurance records into
meaningful business insights.

## Project Navigation

<p align="center">
<a href="#business-objectives"><img src="https://img.shields.io/badge/01-Business_Objectives-345995?style=for-the-badge" alt="Business objectives"></a>
<a href="#dataset-overview"><img src="https://img.shields.io/badge/02-Datasets-03A678?style=for-the-badge" alt="Datasets"></a>
<a href="#sql-analysis"><img src="https://img.shields.io/badge/03-SQL_Analysis-4479A1?style=for-the-badge" alt="SQL analysis"></a>
<a href="#python-analysis"><img src="https://img.shields.io/badge/04-Python_Analysis-3776AB?style=for-the-badge" alt="Python analysis"></a>
<a href="#power-bi-dashboard"><img src="https://img.shields.io/badge/05-Power_BI_Report-F2C811?style=for-the-badge" alt="Power BI report"></a>
<a href="#key-findings"><img src="https://img.shields.io/badge/06-Key_Findings-7952B3?style=for-the-badge" alt="Key findings"></a>
</p>

## Business Objectives

- Create and validate a relational MySQL database for insurance data.
- Examine data quality, table relationships, date logic and
  business-rule consistency.
- Analyze customer portfolios, policy composition, claims severity and
  risk indicators.
- Investigate payment patterns and claim-to-payment turnaround.
- Present findings through interactive dashboards and evidence-based
  recommendations.

## Dataset Overview

The project uses eight related datasets:

| MySQL table       |    Records | Description                                         |
|-------------------|-----------:|-----------------------------------------------------|
| `customers`       |     10,000 | Customer profile, demographics, income and region   |
| `policies`        |     15,000 | Policy type, dates, premium, coverage and status    |
| `claims`          |     25,000 | Claim dates, amounts, types, status and fraud flags |
| `payments`        |     15,541 | Payment dates, amounts and payment methods          |
| `risk_assessment` |     10,000 | Customer risk scores and risk categories            |
| `agents`          |        250 | Agent details, experience, region and channel       |
| `policy_agents`   |     15,000 | Policy-to-agent assignments                         |
| `vehicles`        |      6,000 | Customer-linked vehicle details and insured value   |
| **Total**         | **96,791** | **8 datasets**                                      |

## Technology Stack

| Layer                        | Tools                                                         |
|------------------------------|---------------------------------------------------------------|
| Database                     | MySQL                                                         |
| SQL analysis                 | MySQL queries, joins, CTEs, aggregations and window functions |
| Python analysis              | Pandas, NumPy, SciPy                                          |
| Visualization                | Matplotlib, Seaborn                                           |
| Python database connection   | SQLAlchemy, PyMySQL                                           |
| Business intelligence        | Power BI, Power Query, DAX                                    |
| Power BI database connection | ODBC                                                          |

## End-to-End Project Workflow

``` mermaid
flowchart TD
    A["8 Source CSV Datasets"] --> B["Data Understanding & Quality Audit"]
    B --> C["MySQL Database<br/>insurance_claims_analytics"]
    C --> D["MySQL Analysis<br/>Validation & Business Queries"]
    C --> E["Python Notebooks<br/>SQLAlchemy + PyMySQL"]
    D --> F["Analytical Findings"]
    E --> F
    C --> G["Power BI via ODBC<br/>DSN: Insurance_Claims_Analytics"]
    G --> H["Power Query & Data Model"]
    H --> I["DAX Measures & KPIs"]
    I --> J["6-Page Interactive Dashboard"]
    F --> K["Business Insights & Recommendations"]
    J --> K
```

## SQL Analysis

The MySQL scripts cover:

- Database and table setup.
- Data validation and portfolio checks.
- Insurance portfolio and policy analysis.
- Claims severity and claim trends.
- Risk and fraud-flag analysis.
- Policy financial performance.
- Settlement and payment analysis.
- Customer portfolio analysis.
- Agent and channel performance.

## Python Analysis

The project contains 11 Jupyter notebooks:

| Notebook                                   | Focus                                              |
|--------------------------------------------|----------------------------------------------------|
| `01_Data_Understanding.ipynb`              | Dataset structure and initial profiling            |
| `02_Data_Quality_Audit.ipynb`              | Missing values, duplicates and validation checks   |
| `03_Data_Cleaning.ipynb`                   | Data preparation and cleaning                      |
| `04_MySQL_Data_Loading.ipynb`              | Loading the datasets into MySQL                    |
| `05_Exploratory_Data_Analysis.ipynb`       | Overall exploratory analysis                       |
| `06_Customer_Analysis.ipynb`               | Customer and portfolio patterns                    |
| `07_Claims_Severity_Analytics.ipynb`       | Claims amounts and severity                        |
| `08_Risk_Fraud_Statistical_Analysis.ipynb` | Risk indicators, fraud flags and statistical tests |
| `09_Policy_Financial_Performance.ipynb`    | Premiums, coverage and policy performance          |
| `10_Settlement_Payment_Performance.ipynb`  | Payment trends and turnaround                      |
| `11_Business_Insights.ipynb`               | Consolidated findings and recommendations          |

## Power BI Dashboard

The Power BI report has six analytical pages. Use the navigation badges
below to jump to each page’s purpose.

<p align="center">
<a href="#executive-overview"><img src="https://img.shields.io/badge/01-Executive_Overview-34495E?style=for-the-badge" alt="Executive Overview"></a>
<a href="#claims--severity-analysis"><img src="https://img.shields.io/badge/02-Claims_&_Severity-2E86AB?style=for-the-badge" alt="Claims and Severity"></a>
<a href="#risk--fraud-analytics"><img src="https://img.shields.io/badge/03-Risk_&_Fraud-8E5EA2?style=for-the-badge" alt="Risk and Fraud"></a>
<a href="#policy--financial-performance"><img src="https://img.shields.io/badge/04-Policy_&_Financial-168C75?style=for-the-badge" alt="Policy and Financial"></a>
<a href="#settlement--payment-performance"><img src="https://img.shields.io/badge/05-Settlement_&_Payment-C17C22?style=for-the-badge" alt="Settlement and Payment"></a>
<a href="#customer-analysis"><img src="https://img.shields.io/badge/06-Customer_Analysis-5661A8?style=for-the-badge" alt="Customer Analysis"></a>
</p>

### Executive Overview

Provides a high-level view of customers, policies, claims, risk and
payment KPIs.

### Claims & Severity Analysis

Explores claim volume, claim amounts, severity patterns and high-value
claims.

### Risk & Fraud Analytics

Examines customer risk scores, risk categories and existing fraud-flag
patterns.

### Policy & Financial Performance

Analyzes policy composition, annualized premiums, coverage amounts and
financial exposure.

### Settlement & Payment Performance

Reviews payment amounts, payment methods, claim-to-payment elapsed time
and payment-record exceptions.

### Customer Analysis

Explores customer profiles, policy ownership, customers with claims and
portfolio contribution.

### MySQL–Power BI Connection

Power BI Desktop connects to the MySQL database through **ODBC**. The
configured Data Source Name (DSN) is `Insurance_Claims_Analytics`, and
the database is `insurance_claims_analytics`.

The Power Query source step confirmed in the report is:

``` powerquery
Source = Odbc.DataSource(
    "dsn=Insurance_Claims_Analytics",
    [HierarchicalNavigation=true]
)
```

Python connects separately to the same MySQL database using SQLAlchemy
and PyMySQL. The ODBC DSN must also be configured on another computer
before refreshing the PBIX report.

## Key Findings

- **Claims:** 25,000 claims represented approximately **₹105.36 crore**
  in recorded claim amounts. Average claim severity was **₹42,145.98**.
- **Risk indicators:** 921 claims (**3.68%**) were fraud-flagged. The
  high-risk customer segment had a **9.72%** fraud-flag rate, compared
  with 2.58% for medium-risk and 2.46% for low-risk customers.
- **Policy portfolio:** 15,000 policies had approximately **₹33.25
  crore** in annualized premiums and **₹1,114.32 crore** in recorded
  coverage.
- **Payments:** by the **September 30, 2026** reporting cutoff, 15,352
  claims had an in-period payment record. Average claim-to-payment
  elapsed time was **44.91 days**.
- **Data quality:** policy status/date inconsistencies and claims
  without in-period payment records were identified for further review.

## Run the Project

1.  Install MySQL Server, Python, Jupyter Notebook, Power BI Desktop and
    a compatible MySQL ODBC driver.

2.  Install Python packages:

    ``` bash
    pip install pandas numpy scipy matplotlib seaborn sqlalchemy pymysql jupyter
    ```

3.  Run `Database_setup.sql` in MySQL Workbench.

4.  Keep the eight source CSV files in the project’s data folder.

5.  Run the data understanding, audit, cleaning and MySQL loading
    notebooks.

6.  Execute the SQL analysis scripts and remaining Python notebooks.

7.  Configure the `Insurance_Claims_Analytics` ODBC DSN and open the
    Power BI `.pbix` report.

> **Loading note:** The MySQL loading notebook appends records to
> existing tables. Prepare or clear destination tables before reloading
> to avoid duplicate records or key conflicts. Never commit database
> passwords or credentials.

## Analytical Notes

- Fraud flags indicate claims for further investigation; they are **not
  proof of confirmed fraud**.
- Annualized premiums are not verified premium collections or recognized
  revenue.
- Coverage amounts are policy limits, not expected losses.
- Claim-to-payment elapsed time is not necessarily formal settlement
  turnaround; settlement dates are not available.
- A missing in-period payment record does not by itself prove that a
  claim is unpaid or overdue.
- Statistical association does not establish causation or
  predictive-model performance.

## Detailed Documentation

- [Detailed Project Documentation](Reports/README.md)
- [Project Overview](Documentation/Project_Overview.md)
- [Data Dictionary](Documentation/Data_Dictionary.md)
- [Business Insights](Documentation/Business_Insights.md)

## Author

**Nethravathi G**
<div align="center">

# Insurance Claims, Risk & Portfolio Performance Analytics

**An end-to-end insurance analytics project powered by MySQL, Python and
Power BI.**

[![MySQL](https://img.shields.io/badge/MySQL-Database-4479A1?style=for-the-badge&logo=mysql&logoColor=white)](#mysql-database)
[![Python](https://img.shields.io/badge/Python-Analytics-3776AB?style=for-the-badge&logo=python&logoColor=white)](#python-analysis)
[![Power
BI](https://img.shields.io/badge/Power_BI-Dashboard-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)](#power-bi-dashboard)
[![ODBC](https://img.shields.io/badge/ODBC-Connectivity-5865F2?style=for-the-badge)](#mysql--power-bi-connection)
[![Jupyter](https://img.shields.io/badge/Jupyter-Notebooks-F37626?style=for-the-badge&logo=jupyter&logoColor=white)](#python-analysis)

**8 datasets · 96,791 records · 11 Python notebooks · SQL analysis · 6
Power BI pages**

</div>

------------------------------------------------------------------------

## Project Overview

This project explores an insurance portfolio through customer, policy,
claims, risk, financial and payment analytics. It combines relational
database querying, Python-based investigation, statistical analysis and
interactive Power BI reporting to turn raw insurance records into
meaningful business insights.

## Project Navigation

<p align="center">
<a href="#business-objectives"><img src="https://img.shields.io/badge/01-Business_Objectives-345995?style=for-the-badge" alt="Business objectives"></a>
<a href="#dataset-overview"><img src="https://img.shields.io/badge/02-Datasets-03A678?style=for-the-badge" alt="Datasets"></a>
<a href="#sql-analysis"><img src="https://img.shields.io/badge/03-SQL_Analysis-4479A1?style=for-the-badge" alt="SQL analysis"></a>
<a href="#python-analysis"><img src="https://img.shields.io/badge/04-Python_Analysis-3776AB?style=for-the-badge" alt="Python analysis"></a>
<a href="#power-bi-dashboard"><img src="https://img.shields.io/badge/05-Power_BI_Report-F2C811?style=for-the-badge" alt="Power BI report"></a>
<a href="#key-findings"><img src="https://img.shields.io/badge/06-Key_Findings-7952B3?style=for-the-badge" alt="Key findings"></a>
</p>

## Business Objectives

- Create and validate a relational MySQL database for insurance data.
- Examine data quality, table relationships, date logic and
  business-rule consistency.
- Analyze customer portfolios, policy composition, claims severity and
  risk indicators.
- Investigate payment patterns and claim-to-payment turnaround.
- Present findings through interactive dashboards and evidence-based
  recommendations.

## Dataset Overview

The project uses eight related datasets:

| MySQL table       |    Records | Description                                         |
|-------------------|-----------:|-----------------------------------------------------|
| `customers`       |     10,000 | Customer profile, demographics, income and region   |
| `policies`        |     15,000 | Policy type, dates, premium, coverage and status    |
| `claims`          |     25,000 | Claim dates, amounts, types, status and fraud flags |
| `payments`        |     15,541 | Payment dates, amounts and payment methods          |
| `risk_assessment` |     10,000 | Customer risk scores and risk categories            |
| `agents`          |        250 | Agent details, experience, region and channel       |
| `policy_agents`   |     15,000 | Policy-to-agent assignments                         |
| `vehicles`        |      6,000 | Customer-linked vehicle details and insured value   |
| **Total**         | **96,791** | **8 datasets**                                      |

## Technology Stack

| Layer                        | Tools                                                         |
|------------------------------|---------------------------------------------------------------|
| Database                     | MySQL                                                         |
| SQL analysis                 | MySQL queries, joins, CTEs, aggregations and window functions |
| Python analysis              | Pandas, NumPy, SciPy                                          |
| Visualization                | Matplotlib, Seaborn                                           |
| Python database connection   | SQLAlchemy, PyMySQL                                           |
| Business intelligence        | Power BI, Power Query, DAX                                    |
| Power BI database connection | ODBC                                                          |

## End-to-End Project Workflow

``` mermaid
flowchart TD
    A["8 Source CSV Datasets"] --> B["Data Understanding & Quality Audit"]
    B --> C["MySQL Database<br/>insurance_claims_analytics"]
    C --> D["MySQL Analysis<br/>Validation & Business Queries"]
    C --> E["Python Notebooks<br/>SQLAlchemy + PyMySQL"]
    D --> F["Analytical Findings"]
    E --> F
    C --> G["Power BI via ODBC<br/>DSN: Insurance_Claims_Analytics"]
    G --> H["Power Query & Data Model"]
    H --> I["DAX Measures & KPIs"]
    I --> J["6-Page Interactive Dashboard"]
    F --> K["Business Insights & Recommendations"]
    J --> K
```

## SQL Analysis

The MySQL scripts cover:

- Database and table setup.
- Data validation and portfolio checks.
- Insurance portfolio and policy analysis.
- Claims severity and claim trends.
- Risk and fraud-flag analysis.
- Policy financial performance.
- Settlement and payment analysis.
- Customer portfolio analysis.
- Agent and channel performance.

## Python Analysis

The project contains 11 Jupyter notebooks:

| Notebook                                   | Focus                                              |
|--------------------------------------------|----------------------------------------------------|
| `01_Data_Understanding.ipynb`              | Dataset structure and initial profiling            |
| `02_Data_Quality_Audit.ipynb`              | Missing values, duplicates and validation checks   |
| `03_Data_Cleaning.ipynb`                   | Data preparation and cleaning                      |
| `04_MySQL_Data_Loading.ipynb`              | Loading the datasets into MySQL                    |
| `05_Exploratory_Data_Analysis.ipynb`       | Overall exploratory analysis                       |
| `06_Customer_Analysis.ipynb`               | Customer and portfolio patterns                    |
| `07_Claims_Severity_Analytics.ipynb`       | Claims amounts and severity                        |
| `08_Risk_Fraud_Statistical_Analysis.ipynb` | Risk indicators, fraud flags and statistical tests |
| `09_Policy_Financial_Performance.ipynb`    | Premiums, coverage and policy performance          |
| `10_Settlement_Payment_Performance.ipynb`  | Payment trends and turnaround                      |
| `11_Business_Insights.ipynb`               | Consolidated findings and recommendations          |

## Power BI Dashboard

The Power BI report has six analytical pages. Use the navigation badges
below to jump to each page’s purpose.

<p align="center">
<a href="#executive-overview"><img src="https://img.shields.io/badge/01-Executive_Overview-34495E?style=for-the-badge" alt="Executive Overview"></a>
<a href="#claims--severity-analysis"><img src="https://img.shields.io/badge/02-Claims_&_Severity-2E86AB?style=for-the-badge" alt="Claims and Severity"></a>
<a href="#risk--fraud-analytics"><img src="https://img.shields.io/badge/03-Risk_&_Fraud-8E5EA2?style=for-the-badge" alt="Risk and Fraud"></a>
<a href="#policy--financial-performance"><img src="https://img.shields.io/badge/04-Policy_&_Financial-168C75?style=for-the-badge" alt="Policy and Financial"></a>
<a href="#settlement--payment-performance"><img src="https://img.shields.io/badge/05-Settlement_&_Payment-C17C22?style=for-the-badge" alt="Settlement and Payment"></a>
<a href="#customer-analysis"><img src="https://img.shields.io/badge/06-Customer_Analysis-5661A8?style=for-the-badge" alt="Customer Analysis"></a>
</p>

### Executive Overview

Provides a high-level view of customers, policies, claims, risk and
payment KPIs.

### Claims & Severity Analysis

Explores claim volume, claim amounts, severity patterns and high-value
claims.

### Risk & Fraud Analytics

Examines customer risk scores, risk categories and existing fraud-flag
patterns.

### Policy & Financial Performance

Analyzes policy composition, annualized premiums, coverage amounts and
financial exposure.

### Settlement & Payment Performance

Reviews payment amounts, payment methods, claim-to-payment elapsed time
and payment-record exceptions.

### Customer Analysis

Explores customer profiles, policy ownership, customers with claims and
portfolio contribution.

### MySQL–Power BI Connection

Power BI Desktop connects to the MySQL database through **ODBC**. The
configured Data Source Name (DSN) is `Insurance_Claims_Analytics`, and
the database is `insurance_claims_analytics`.

The Power Query source step confirmed in the report is:

``` powerquery
Source = Odbc.DataSource(
    "dsn=Insurance_Claims_Analytics",
    [HierarchicalNavigation=true]
)
```

Python connects separately to the same MySQL database using SQLAlchemy
and PyMySQL. The ODBC DSN must also be configured on another computer
before refreshing the PBIX report.

## Key Findings

- **Claims:** 25,000 claims represented approximately **₹105.36 crore**
  in recorded claim amounts. Average claim severity was **₹42,145.98**.
- **Risk indicators:** 921 claims (**3.68%**) were fraud-flagged. The
  high-risk customer segment had a **9.72%** fraud-flag rate, compared
  with 2.58% for medium-risk and 2.46% for low-risk customers.
- **Policy portfolio:** 15,000 policies had approximately **₹33.25
  crore** in annualized premiums and **₹1,114.32 crore** in recorded
  coverage.
- **Payments:** by the **September 30, 2026** reporting cutoff, 15,352
  claims had an in-period payment record. Average claim-to-payment
  elapsed time was **44.91 days**.
- **Data quality:** policy status/date inconsistencies and claims
  without in-period payment records were identified for further review.

## Run the Project

1.  Install MySQL Server, Python, Jupyter Notebook, Power BI Desktop and
    a compatible MySQL ODBC driver.

2.  Install Python packages:

    ``` bash
    pip install pandas numpy scipy matplotlib seaborn sqlalchemy pymysql jupyter
    ```

3.  Run `Database_setup.sql` in MySQL Workbench.

4.  Keep the eight source CSV files in the project’s data folder.

5.  Run the data understanding, audit, cleaning and MySQL loading
    notebooks.

6.  Execute the SQL analysis scripts and remaining Python notebooks.

7.  Configure the `Insurance_Claims_Analytics` ODBC DSN and open the
    Power BI `.pbix` report.

> **Loading note:** The MySQL loading notebook appends records to
> existing tables. Prepare or clear destination tables before reloading
> to avoid duplicate records or key conflicts. Never commit database
> passwords or credentials.

## Analytical Notes

- Fraud flags indicate claims for further investigation; they are **not
  proof of confirmed fraud**.
- Annualized premiums are not verified premium collections or recognized
  revenue.
- Coverage amounts are policy limits, not expected losses.
- Claim-to-payment elapsed time is not necessarily formal settlement
  turnaround; settlement dates are not available.
- A missing in-period payment record does not by itself prove that a
  claim is unpaid or overdue.
- Statistical association does not establish causation or
  predictive-model performance.

## Detailed Documentation

- [Detailed Project Documentation](Reports/README.md)
- [Project Overview](Documentation/Project_Overview.md)
- [Data Dictionary](Documentation/Data_Dictionary.md)
- [Business Insights](Documentation/Business_Insights.md)

## Author

**Nethra G**

[![GitHub](https://img.shields.io/badge/GitHub-gnethravathi07-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/gnethravathi07)
[![LinkedIn](https://img.shields.io/badge/LinkedIn-Nethra_G-0A66C2?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/nethravathi-g-2309772b6/)

------------------------------------------------------------------------

<div align="center">

**Insurance Data · SQL Analytics · Python Investigation · Power BI
Storytelling**

</div>


------------------------------------------------------------------------

<div align="center">

**Insurance Data · SQL Analytics · Python Investigation · Power BI
Storytelling**

</div>

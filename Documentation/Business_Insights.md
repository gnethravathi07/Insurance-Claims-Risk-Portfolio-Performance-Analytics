# Business Insights & Recommendations

## Insurance Claims, Risk & Portfolio Performance Analytics

This document consolidates findings recorded in the uploaded SQL scripts
and Python notebooks. The final business-analysis reporting cutoff is
**September 30, 2026**.

> **Interpretation principle:** These are findings from the supplied
> dataset and analysis. Fraud flags are not confirmed fraud, statistical
> associations do not establish causation, and data-record exceptions
> should be investigated before being treated as operational or
> financial liabilities.

## 1. Executive Summary

The project analyzes eight related insurance datasets containing 96,791
records across customers, policies, claims, payments, risk assessments,
agents, policy-agent assignments, and vehicles.

The analysis identified useful portfolio patterns and several
data-quality and reconciliation areas requiring business review. The
strongest operational follow-up themes are policy status/date
consistency, payment-record reconciliation, claim severity monitoring,
and risk-based investigation prioritization.

### Selected KPI Snapshot

| Area                                    | Finding                       |
|-----------------------------------------|-------------------------------|
| Customers                               | 10,000                        |
| Policies                                | 15,000                        |
| Claims                                  | 25,000                        |
| Payment records                         | 15,541                        |
| Fraud-flagged claims                    | 921 (3.68%)                   |
| Total recorded claim amount             | Approximately ₹105.36 crore   |
| Average claim amount                    | ₹42,145.98                    |
| Median claim amount                     | ₹29,979.78                    |
| Annualized policy premiums              | Approximately ₹33.25 crore    |
| Recorded policy coverage                | Approximately ₹1,114.32 crore |
| Claims with an in-period payment record | 15,352 (61.41%)               |
| In-period recorded payment amount       | Approximately ₹50.01 crore    |
| Average claim-to-payment elapsed time   | 44.91 days                    |

Payment KPIs above use the September 30, 2026 cutoff. They should not be
mixed with all-date totals that include later payment records.

## 2. Data Quality & Preparation Findings

### Findings

- Initial data understanding reported no missing values, duplicate
  records, or duplicate primary-key values across the eight source
  tables.
- Seven foreign-key relationships were validated without invalid
  references.
- Seven date columns were parsed without invalid dates during initial
  data understanding.
- The consolidated Data Quality Audit reported **20 checks: 9 PASS and
  11 REVIEW**.
- **3,512 policies** started before the associated customer’s recorded
  join date.
- **7,924 policies** had a mismatch between recorded policy status and
  date-derived coverage status:
  - 7,306 were labelled `Active` although their recorded end dates had
    passed the September 30, 2026 reference date.
  - 618 were labelled `Expired` although their end dates had not yet
    passed the reference date.
- Date-derived coverage analysis classified 13,224 policies as past
  their end date and 1,776 as within their coverage period at the
  reference date.
- **143 claims (0.57%)** exceeded associated policy coverage. The claims
  severity notebook reports approximately ₹42.66 lakh in aggregate
  excess claimed value.
- **34 payments** exceeded their associated policy coverage in the
  cleaning analysis.
- **189 payment records**, totalling ₹61,37,939.33, were dated after the
  reporting cutoff and were excluded from historical in-period payment
  KPIs.

### Business Implications

Policy status/date discrepancies can affect portfolio reporting and
renewal monitoring. Claims and payments above recorded coverage require
record-level review. Payments after the reporting cutoff must be
excluded from historical KPIs calculated as of that cutoff.

### Recommendations

1.  Reconcile recorded policy status with effective start and end dates.
2.  Review policies starting before customer join dates and confirm
    whether the recorded dates are correct.
3.  Investigate claims and payments exceeding linked policy coverage.
4.  Apply explicit reporting-date filters to historical financial and
    payment KPIs.
5.  Preserve original source values and retain validation flags for
    traceability.

## 3. Customer Portfolio Insights

### Findings

- **77.20%** of customers had at least one recorded policy; **22.80%**
  had no recorded policies.
- **43.92%** of customers held two or more policies.
- **35.35%** held two or more distinct insurance product types.
- **70.07%** of customers had at least one recorded claim.
- Average historical claim frequency was **2.50 claims per customer**,
  including customers with no claims; the maximum observed count was 18.
- **2,912 customers (29.12%)** submitted four or more claims. Together,
  they contributed **17,016 claims (68.06% of total claim volume)**.
- The top 10% of customers contributed approximately **32.80%** of
  recorded annual policy premiums.

### Business Implications

Policy ownership and premium contribution provide useful views of
customer portfolio participation. Claim activity is concentrated among a
subset of customers, but higher historical claim counts may reflect
greater policy exposure or longer coverage periods rather than higher
underlying risk.

### Recommendations

1.  Review customers without recorded policies to understand whether
    they are eligible prospects or simply outside the relevant
    portfolio.
2.  Identify suitable single-policy customers for needs-based product
    education and cross-sell opportunities.
3.  Monitor high-frequency claim customers using policy exposure,
    coverage duration, and claim circumstances.
4.  Use customer-level premium contribution to support retention and
    portfolio monitoring, without treating annualized premiums as
    collected revenue.

## 4. Claims & Severity Insights

### Findings

- The claims table contains **25,000 claims** recorded between January
  2020 and September 2026.
- Total recorded claim amounts are approximately **₹105.36 crore**.
- Average claim amount is **₹42,145.98**, while median claim amount is
  **₹29,979.78**, indicating a right-skewed distribution.
- Claims above ₹1 lakh represent **7.44% of claim volume** but account
  for **26.96% of total claimed amounts**.
- The claims severity notebook identified **1,583 claim amount outliers
  (6.33%)** using the IQR method. These outliers account for **24.24%**
  of total claimed amounts.
- **143 claims (0.57%)** exceeded their associated policy coverage, with
  approximately ₹42.66 lakh in aggregate excess claimed value.
- Pending and Approved claims together represented **10,175 claims** and
  approximately **₹42.39 crore** in requested claim amounts. These are
  not confirmed unpaid liabilities.
- The top 10% of claim-bearing policies contributed **29.62%** of total
  claimed amounts.

### Business Implications

A relatively small portion of claims contributes a substantial share of
financial exposure. Monitoring claim count alone would miss the impact
of high-severity claims and claim concentration.

### Recommendations

1.  Monitor claim frequency, average severity, and total claim amount
    together.
2.  Review claims above the selected high-value threshold and the IQR
    outlier boundary.
3.  Investigate claims exceeding recorded coverage without automatically
    treating them as invalid.
4.  Monitor claim concentration by policy and insurance category.
5.  Track pending and approved amounts as requested claim exposure, not
    as confirmed liabilities.

## 5. Risk & Fraud-Flag Insights

### Findings

- **921 of 25,000 claims (3.68%)** were fraud-flagged.
- The fraud-flag rate was **9.72%** among High-risk customers, compared
  with **2.58%** for Medium-risk and **2.46%** for Low-risk customers.
- A chi-square test found a statistically significant association
  between risk category and fraud flags (χ² = 483.17, p \< 0.001).
  **Cramér’s V = 0.139** indicates a weak association.
- Fraud-flagged claims had a higher average customer risk score
  (**59.21**) than non-flagged claims (**48.94**). A Mann–Whitney U test
  found a statistically significant difference (p \< 0.001).
- Risk-score bands also showed variation: the 81–100 score band had a
  **10.84%** fraud-flag rate, while the 0–20 band had a **2.23%** rate.
- High-risk claims represented **15.85%** of claim-review workload and
  accounted for **41.80%** of flagged claims. The notebook reports a
  capture-to-workload ratio of **2.64×**.
- The notebook notes that fraud-flag rates were broadly similar across
  several other claim and customer characteristics.

### Business Implications

Customer risk score and risk category were useful retrospective
indicators of existing fraud flags in this dataset. Statistical
significance should be considered alongside effect size, the repeated
appearance of customers across claims, and the absence of confirmed
fraud outcomes.

### Recommendations

1.  Use risk categories to help prioritize proportionate manual review.
2.  Combine customer risk indicators with claim details and
    coverage-rule checks.
3.  Monitor investigation outcomes to determine whether existing flags
    correspond to confirmed cases.
4.  Review screening effectiveness and fairness periodically.
5.  Do not reject claims or label customers fraudulent solely because of
    a risk score or fraud flag.

## 6. Policy & Financial Performance Insights

### Findings

- The portfolio contains **15,000 policies**.
- Auto insurance represents **39.69%** of policy count, followed by
  Health at **30.40%**.
- Total annualized policy premiums are approximately **₹33.25 crore**.
  Auto contributes **39.95%** of annualized premiums and Health
  contributes **30.33%**.
- Life insurance has the highest average annual premium at approximately
  **₹22,443.89**, despite being the smallest policy segment by count.
- Total recorded policy coverage is approximately **₹1,114.32 crore**.
- The overall annual premium-to-coverage ratio is **2.98%**.
- Annual premium and coverage amount show a strong positive association:
  Pearson correlation **0.85**, Spearman correlation **0.83**.
- The highest-premium 10% of policies contribute **26.70%** of
  annualized premiums.
- Regional premium contributions are relatively balanced, ranging from
  **19.72% to 20.31%** across five regions.
- The policy analysis reports that 81.20% of policies have at least one
  historical claim; Health policies have the highest incidence at
  82.74%.

### Business Implications

Auto and Health account for the largest policy and premium shares.
Premium and coverage are strongly associated, while policy status/date
inconsistencies limit the interpretation of current active exposure.
Historical claim incidence should be compared with policy duration and
exposure before being interpreted as underlying risk.

### Recommendations

1.  Monitor premium and coverage exposure by policy type, region, and
    premium band.
2.  Reconcile policy status/date discrepancies before using policy
    labels to determine current exposure.
3.  Compare claim frequency and severity with policy duration and
    exposure.
4.  Separate annualized premiums from actual premium collections in
    financial reporting.
5.  Reconcile claim amounts, payable amounts, and payments before
    drawing conclusions about outstanding financial obligations.

## 7. Settlement & Payment Performance Insights

### Findings

- By September 30, 2026, **15,352 claims (61.41%)** had an in-period
  payment record.
- Total in-period recorded payments amounted to approximately **₹50.01
  crore**.
- Average claim-to-payment elapsed time was **44.91 days**, with a
  median of **45 days**.
- **34.36%** of in-period payments occurred within 30 days of claim
  submission.
- **32.44%** of in-period payments occurred more than 60 days after
  claim submission.
- Recorded payments represented **77.76%** of original claimed amounts
  in the weighted payment-coverage calculation.
- **1,317 Approved or Settled claims** had no in-period payment record.
  Their associated claim amounts totalled approximately **₹5.70 crore**.
- Of those 1,317 claims, **1,102 (83.68%)** were more than 90 days old
  at the reporting cutoff.

### Business Implications

The elapsed time from claim submission to payment provides a useful
operational measure, but it does not measure the formal settlement
process because approval and settlement dates are not present. Claims
without an in-period payment record should be reconciled before being
classified as overdue or unpaid.

### Recommendations

1.  Monitor claim-to-payment elapsed time using 30-day and 60-day
    categories.
2.  Prioritize reconciliation of older Approved and Settled claims
    without in-period payment records.
3.  Investigate payment references, date cutoffs, and claim-status
    consistency.
4.  Compare payment coverage across claim status and insurance category.
5.  Introduce formal SLA monitoring only when approval dates, settlement
    dates, and contractual timelines are available.

## 8. Priority Recommendations

| Priority | Area                   | Recommended action                                                                                      | Expected benefit                                            |
|----------|------------------------|---------------------------------------------------------------------------------------------------------|-------------------------------------------------------------|
| 1        | Payment reconciliation | Reconcile Approved and Settled claims without an in-period payment record, beginning with older records | Better payment-record completeness and exception visibility |
| 2        | Payment monitoring     | Track claim-to-payment elapsed time and late-payment categories                                         | Earlier identification of potential process bottlenecks     |
| 3        | Policy data quality    | Review status/date inconsistencies and pre-join policy dates                                            | More reliable policy and exposure reporting                 |
| 4        | Risk review            | Use risk indicators to support human investigation, then validate against outcomes                      | More focused and evidence-based review                      |
| 5        | Financial monitoring   | Track premiums, coverage, claim severity, and payment values separately                                 | Clearer portfolio and financial exposure reporting          |

These are analytical recommendations, not proven interventions or
quantified savings. Operational teams should validate business
definitions, source completeness, implementation costs, and expected
benefits before acting.

## 9. Reconciliation Notes & Differences Between Notebook Outputs

A few figures differ across the supplied audit and cleaning notebooks.
They are recorded here transparently and should be reconciled before
being presented as one final audited measure.

| Measure                                                     | Notebook result A                                               | Notebook result B                                | Documentation treatment                                                                                             |
|-------------------------------------------------------------|-----------------------------------------------------------------|--------------------------------------------------|---------------------------------------------------------------------------------------------------------------------|
| Claim amount IQR outliers                                   | Data Quality Audit: 1,585 (6.34%)                               | Data Cleaning and Claims Severity: 1,583 (6.33%) | Use the Claims Severity result for its analysis summary; retain the audit difference as an open reconciliation item |
| Payment amount IQR outliers                                 | Data Quality Audit: 1,028 (6.61%)                               | Data Cleaning: 1,024 (6.59%)                     | Do not present a single reconciled figure until recalculated using one consistent quartile method and input set     |
| Settled claims with no matching payment record              | Data Cleaning: 732 claims, approximately ₹3.17 crore            | —                                                | This check is for `Settled` claims with no matching payment record in the payment table                             |
| Approved or Settled claims with no in-period payment record | Final Payment Analysis: 1,317 claims, approximately ₹5.70 crore | —                                                | This check includes `Approved` and `Settled` claims with no payment recorded by the September 30, 2026 cutoff       |

The 732 and 1,317 figures use different definitions and are not
interchangeable. They should not be added together.

## 10. Analytical Limitations

- Fraud flags are review indicators, not verified fraud outcomes.
- The statistical tests identify associations; they do not establish
  causation.
- Multiple claims may belong to the same customer, which can affect
  independence assumptions in statistical tests.
- Claim-to-payment elapsed time is measured from `Claim_Date` to
  `Payment_Date`, not from approval to settlement.
- The source schema does not contain a formal claim settlement date.
- Payment records after September 30, 2026 are outside the historical
  reporting cutoff used in final payment KPIs.
- Annualized premiums are not verified collections or earned premiums.
- Coverage amounts are limits, not expected losses.
- Requested claim amounts are not necessarily approved payable amounts
  or outstanding liabilities.
- Operational recommendations require validation against actual policy,
  claims, payment, and investigation processes.

## 11. Conclusion

The analysis provides an integrated view of the insurance portfolio and
identifies opportunities to improve policy data quality, claims severity
monitoring, risk-based investigation, financial exposure reporting, and
payment reconciliation.

Combining MySQL, SQL, Python, statistical analysis, and Power BI
produces a repeatable analytical workflow and a practical foundation for
insurance portfolio monitoring.

------------------------------------------------------------------------

[Project Overview](Project_Overview.md) · [Data
Dictionary](Data_Dictionary.md)

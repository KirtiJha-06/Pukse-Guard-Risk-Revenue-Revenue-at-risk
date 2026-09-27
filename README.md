# Pukse-Guard-Risk-Revenue-Revenue-at-risk
# PulseGuard: Risk Score & Revenue-at-Risk

## 📌 Project Overview

**PulseGuard** is a SQL-based customer risk and revenue analysis project built using **PostgreSQL**.

The project analyzes customer **payment behavior, support interactions, subscription information, engagement, tenure, and plan characteristics** to calculate a **0–100 customer risk score** and identify customers who may contribute to potential revenue-at-risk.

The goal is to transform raw customer data into actionable business insights using SQL and help businesses identify high-risk customer segments.

---

## 🎯 Business Problem

Businesses need to identify customers who may be at risk due to:

* Failed or unsuccessful payments
* High support ticket activity
* Low customer engagement
* Short customer tenure
* Subscription plan characteristics

PulseGuard combines these indicators into a single **customer risk score from 0 to 100**, making it easier to prioritize high-risk customers.

---

## 🛠️ Tech Stack

* **Database:** PostgreSQL
* **Language:** SQL
* **Tools:** pgAdmin
* **Analysis:** Advanced SQL, CTEs, JOINs, Aggregations, CASE Statements, Window Functions

---

## 📊 Risk Scoring Framework

The overall customer risk score is calculated using five major risk components:

| Risk Component  | Maximum Score |
| --------------- | ------------: |
| Payment Risk    |            30 |
| Support Risk    |            25 |
| Engagement Risk |            20 |
| Tenure Risk     |            15 |
| Plan Risk       |            10 |
| **Total**       |       **100** |

### Risk Components

**1. Payment Risk — 0–30**

Evaluates customer payment behavior, particularly failed payment activity.

**2. Support Risk — 0–25**

Considers support ticket volume and customer satisfaction indicators.

**3. Engagement Risk — 0–20**

Analyzes customer engagement using recency and frequency-related indicators.

**4. Tenure Risk — 0–15**

Identifies newer customers who may have comparatively higher risk.

**5. Plan Risk — 0–10**

Considers subscription plan characteristics and pricing.

---

## 🔍 SQL Analysis

The project uses advanced SQL techniques to transform raw data into customer-level analytics, including:

* Multi-table **JOINs**
* **CTEs (Common Table Expressions)**
* `CASE` statements for business rules
* `COUNT`, `SUM`, `AVG` and other aggregate functions
* Customer-level calculations
* Conditional aggregations
* Window functions
* Business KPI calculations
* Risk-score calculations

---

## 📁 Data Sources

The analysis uses three major datasets:

* **Payments**
* **Support Tickets**
* **Subscriptions**

These datasets are combined to create a consolidated view of customer behavior and risk.

---

## 📈 Key Business Questions

The project addresses questions such as:

1. Which customers have the highest risk scores?
2. Which customers have significant payment failures?
3. Which customers generate a high number of support tickets?
4. How does customer satisfaction relate to risk?
5. Which subscription plans contain higher-risk customers?
6. How does customer tenure affect risk?
7. Which customers may contribute to revenue-at-risk?
8. What are the major drivers of customer risk?
9. How does engagement vary across customer segments?
10. Which customer segments should businesses prioritize for retention?

---

## 💡 Business Value

PulseGuard demonstrates how SQL can be used to move beyond basic data extraction and perform **business-focused customer risk analysis**.

The resulting risk framework can help businesses:

* Identify high-risk customers
* Prioritize retention efforts
* Understand payment-related issues
* Monitor customer support patterns
* Analyze subscription performance
* Identify potential revenue-at-risk
* Support data-driven customer retention strategies

---

## 🚀 Skills Demonstrated

**SQL | PostgreSQL | Data Analysis | Business Analytics | Customer Analytics | Risk Scoring | CTEs | JOINs | Aggregations | Window Functions | Data Transformation**

---

## 👨‍💻 Author

**Kirti Jha**

Data Analyst | SQL | Python | Power BI | PostgreSQL

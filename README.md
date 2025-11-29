# paypal-sql-analytics-project
End-to-end SQL analytics project on PayPal-style transactions. Includes data cleaning, EDA, 16 business case studies, merchant scoring, user segmentation ; trend analysis using MySQL.


End-to-End Data Cleaning • EDA • 16 Business Insights Using Pure SQL

This project analyzes PayPal-style transaction data using MySQL.
It demonstrates advanced SQL skills using real business case studies, cleaning workflows, and optimized analytics.

Key Highlights

✔ Cleaned a messy SQL dump (BOM characters, datatype issues, missing values)
✔ Built a reusable SQL analytics pipeline
✔ Solved 16 real business problems for finance, sales & risk teams
✔ Performed EDA, segmentation, classification, trend analysis
✔ Added indexes for performance optimization
✔ Designed scalable SQL scripts for production-ready workflows

Tech Stack-

MySQL 8

SQL Workbench 

CTEs · Joins · Aggregations · Date Functions · CASE · Indexing

📁 Project Structure
paypal-sql-analytics-project/

data/
sql
│ 01_data_cleaning.sql
│ 02_exploration.sql
│ 03_business_analysis.sql
results
README.md

 1. Data Cleaning Summary

Renamed corrupted BOM column names

Converted string dates to DATETIME

Fixed missing currency codes

Added indexing on key columns

Validated duplicates

Standardized schema

 2. Exploratory Data Analysis

Total transaction count

Monthly transaction trends

Average transaction value

Currency distribution

User/merchant overview

 3. Business Case Studies (16 Problems Solved)

A few examples:

1️⃣ Top Countries by Transaction Amount (Q4 2023)

Sending & receiving countries separately.

2️⃣ High-Value Transactions (> $10,000)

Risk & fraud visibility.

3️⃣ Best Performing Merchants (Nov 2023 – Apr 2024)

Ranked by total and average received amounts.

4️⃣ Currency Exposure Risk

Identify highest-volume currencies.

5️⃣ Domestic vs International Classification
6️⃣ User Engagement Model (Active ≥ 6 Months)
7️⃣ Merchant Scoring System

Excellent · Good · Average · Below Average.

8️⃣ Monthly Financial Performance Reports


 Conclusion

This is a complete portfolio-ready SQL analytics project that demonstrates:

Data cleaning

ETL-style SQL scripting

Business thinking

Scenario-based problem solving

SQL optimization

📬 Connect With Me

Feel free to reach out for feedback, collaboration, or opportunities!

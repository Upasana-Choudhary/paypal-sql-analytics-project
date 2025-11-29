-- list tables
SHOW TABLES;

-- check counts
SELECT table_name, table_rows
FROM information_schema.tables
WHERE table_schema = 'paypal.db';

-- sample rows
SELECT * FROM transactions LIMIT 10;
SELECT * FROM users LIMIT 10;
SELECT * FROM merchants LIMIT 10;

-- Check distinct currencies and missing values:

SELECT currency_code, COUNT(*) AS cnt
FROM transactions
GROUP BY currency_code
ORDER BY cnt DESC;

SELECT COUNT(*) FROM transactions 
WHERE currency_code IS NULL OR TRIM(currency_code) = '';

-- DATA CLEANING

-- 1.Rename column name 

ALTER TABLE transactions
  CHANGE COLUMN `ï»¿transaction_id` transaction_id INT,
  CHANGE COLUMN `sender_id` sender_id INT,
  CHANGE COLUMN `recipient_id` recipient_id INT,
  CHANGE COLUMN `transaction_amount` transaction_amount DOUBLE,
  CHANGE COLUMN `transaction_date` transaction_date DATETIME,
  CHANGE COLUMN `currency_code` currency_code TEXT;
  
  select * from transactions;
  select * from users;
  
ALTER TABLE users
CHANGE COLUMN ï»¿user_id user_id INT,
CHANGE COLUMN email email VARCHAR(50),
CHANGE COLUMN name name VARCHAR(25),
CHANGE COLUMN country_id country_id INT,
CHANGE COLUMN account_creation_date account_creation_date DATE;

select * from users;
select * from merchants;

ALTER TABLE merchants
CHANGE COLUMN ï»¿merchant_id merchant_id INT,
CHANGE COLUMN business_name business_name VARCHAR(50),
CHANGE COLUMN country_id country_id INT;
select * from merchants;

select * from countries;

ALTER TABLE countries
CHANGE COLUMN ï»¿country_id country_id INT,
CHANGE COLUMN country_name country_name VARCHAR(55);
select * from countries;

select * from currencies;

ALTER TABLE currencies 
CHANGE COLUMN ï»¿currency_code currency_code CHAR(5),
CHANGE COLUMN currency_name currency_name VARCHAR(25);


SET SQL_SAFE_UPDATES = 0;

-- 2.Fix empty currency_code: 

UPDATE transactions
SET currency_code = 'UNKNOWN'
WHERE currency_code IS NULL OR TRIM(currency_code) = '';

-- 3.Check duplicates: 

SELECT transaction_id, COUNT(*) 
FROM transactions 
GROUP BY transaction_id 
HAVING COUNT(*)>1;

SELECT user_id, COUNT(*) 
FROM users
GROUP BY user_id 
HAVING COUNT(*)>1;

SELECT merchant_id, COUNT(*) 
FROM merchants
GROUP BY merchant_id
HAVING COUNT(*)>1;

-- check existing indexes:

SHOW INDEXES FROM transactions;

-- creating indexes 

ALTER TABLE transactions
ADD PRIMARY KEY (transaction_id);

CREATE INDEX idx_transaction_date 
ON transactions (transaction_date);

SELECT * FROM transactions;

CREATE INDEX idx_sender_id 
ON transactions (sender_id);

CREATE INDEX idx_recipient_id 
ON transactions (recipient_id);

CREATE INDEX idx_merchant_id 
ON merchants (merchant_id);

-- Exploratory analysis

-- Total transactions, total volume, average transaction amount.

SELECT 
COUNT(*) AS txn_count, 
SUM(transaction_amount) AS total_volume, 
AVG(transaction_amount) AS avg_amount
FROM transactions;


-- PROBLEM STATEMENTS 


-- 1. As a financial analyst at PayPal, you are tasked with analyzing transaction data to identify key markets.

-- Determine the top 5 countries by total transaction amount 
-- for both sending and receiving funds in the last quarter of 2023 (October to December 2023). 
-- Provide separate lists for the countries that sent the most funds and those that received the most funds. 
-- Additionally, round the totalsent and totalreceived amounts to 2 decimal places.

select c.country_name as country_name, 
round(sum(t.transaction_amount),2) as total_sent
from transactions t 
 join users u  
on t.sender_id = u.user_id
 join countries c 
on u.country_id = c.country_id
where transaction_date  >= '2023-10-01' AND transaction_date < '2024-01-01'
group by c.country_name
order by  total_sent desc
limit 5;

select c.country_name as country_name, 
round(sum(t.transaction_amount),2) as total_received
from transactions t 
join users u 
on t.recipient_id = u.user_id
join countries c 
on u.country_id = c.country_id
where transaction_date  >= '2023-10-01' AND transaction_date < '2024-01-01'
group by c.country_name
order by  total_received desc
limit 5;


-- 2. To effectively manage risk, it's crucial to identify and monitor high-value transactions.

-- Find transactions exceeding $10,000 in the year 2023
-- and include transaction ID, sender ID, recipient ID (if available), transaction amount, and currency used.

select transaction_id, 
sender_id,
recipient_id,
transaction_amount,
currency_code
from transactions
where transaction_amount > 10000 and year(transaction_date) = '2023' ;


-- 3. The sales team is interested in identifying the top-performing merchants based on the number of payments received. 
-- The analysis will help the sales team to better understand the performance of these key merchants during the specified timeframe.

-- Your task is to analyze the transaction data and determine the top 10 merchants, 
-- sorted by the total transaction amount they received, 
-- within the period from November 2023 to April 2024. 
-- For each of these top 10 merchants, provide the following details: 
-- merchant ID, business name, the total transaction amount received, and the average transaction amount.

select m.merchant_id,
m.business_name,
sum(t.transaction_amount) as total_received,
avg(t.transaction_amount) as average_transaction
from transactions t 
join merchants m 
on t.recipient_id = m.merchant_id
where transaction_date between '2023-11-01' and '2024-04-30'
group by m.merchant_id,
m.business_name
order by  total_received desc, average_transaction desc
limit 10;


-- 4. The finance team wants to analyze the company's exposure to currency risks.

-- Analyze currency conversion trends from 22 May 2023 to 22 May 2024. 
-- Calculate the total amount converted from each source currency to the top 3 most popular destination currencies.

select c.currency_code,
sum(t.transaction_amount) as total_converted
from transactions t 
left join currencies c 
on c.currency_code = t.currency_code 
where transaction_date between '2023-05-22' and '2024-05-22'
group by c.currency_code
order by total_converted desc 
limit 3;


-- 5. The finance team is evaluating transaction classifications.

-- Categorize transactions as 'High Value' (above $10,000) or 'Regular' (less than or equal to $10,000) 
-- and calculate the total amount for each category for the year 2023

select 
case 
      when transaction_amount > 10000 then 'High Value'
      else 'Regular'
      end as transaction_category,
sum(transaction_amount) as total_amount
from transactions
where year(transaction_date) = '2023'
group by transaction_category;


-- 6. To meet compliance requirements, the finance team needs to identify the nature of transactions conducted by the company. 
-- Specifically, you are required to analyze transaction data for the first quarter of 2024 (January to March).

-- Your task is to create a new column in the dataset that indicates 
-- whether each transaction is international (where the sender and recipient are from different countries) 
-- or domestic (where the sender and recipient are from the same country). 
-- Additionally, provide a count of the number of international and domestic transactions for this period.

-- This classification will assist in ensuring compliance with relevant regulations 
-- and provide insights into the distribution of transaction types. 
-- Please include a detailed summary of the counts for each type of transaction.


select 
case 
    when su.country_id = ru.country_id then 'Domestic'
    else 'International'
    end as transaction_type,
count(*) as transaction_count
from transactions t 
join users su 
on t.sender_id = su.user_id
join users ru 
on t.recipient_id = ru.user_id 
where t.transaction_date >= '2024-01-01' AND t.transaction_date < '2024-04-01'
group by transaction_type;


-- 7. To improve user segmentation, the finance team needs to analyze user transaction behavior.

-- Your task is to calculate the average transaction amount per user (Round up to 2 Decimal Places) 
-- for the past six months, covering the period from November 2023 to April 2024. 
-- Once you have the average transaction amount for each user, 
-- identify and list the users whose average transaction amount exceeds $5,000.

-- This analysis will help the finance team to better understand high-value users and tailor strategies to meet their needs.

select 
u.user_id as user_id,
u.email as email, 
round(avg(transaction_amount),2) as avg_amount
from users u
join  transactions t 
on t.sender_id = u.user_id
where transaction_date between '2023-11-01' and '2024-04-30'
group by u.user_id,
u.email
having round(avg(transaction_amount),2) > 5000
order by u.user_id asc;


-- 8. As part of the financial review, the finance team requires detailed monthly transaction reports for the year 2023.

-- Your task is to extract the month and year from each transaction date
-- and then calculate the total transaction amount for each month-year combination. 
-- This will involve summarizing the total transactions on a monthly basis 
-- to provide a clear view of financial activities throughout the year. 
-- Please ensure that your report includes a breakdown of the total transaction amounts 
-- for each month and year combination for 2023, 
-- helping the finance team to review and analyze the company's monthly financial performance comprehensively.

select 
year(transaction_date) as transaction_year,
month(transaction_date) as transaction_month,
sum(transaction_amount) as total_amount
from transactions
where year(transaction_date) = '2023'
group by year(transaction_date),
month(transaction_date)
order by month(transaction_date) asc;


-- 9. As part of identifying top customers for a new loyalty program, 
-- the finance team needs to find the most valuable customer over the past year. 
-- Specifically, your task is to determine the user 
-- who has the highest total transaction amount from May 22, 2023, to May 22, 2024.

-- Please provide the details of this user, including their user ID, name, and total transaction amount. 
-- This information will help the finance team to select the most deserving customer 
-- for the loyalty program based on their transaction behavior over the specified period.

select 
u.user_id,
u.email, 
u.name,
round(sum(t.transaction_amount),2) as total_amount
from users u
join  transactions t 
on t.sender_id = u.user_id
where transaction_date between '2023-05-22' and '2024-05-22'
group by u.user_id,
u.email, 
u.name
order by total_amount desc
limit 1;


-- 10. The finance team is analyzing currency conversion trends 
-- to manage exposure to currency risks.
--  Which currency had the highest transaction amount from in the past one year up to today 
-- indicating the greatest exposure? (assume today is 22-05-2024)
 
 select currency_code, sum(transaction_amount) as total_conversion
 from transactions
 where transaction_date > '2023-05-22' and transaction_date <= '2024-05-22'
 group by currency_code
 order by total_conversion desc 
 limit 1;


-- 11. The sales team wants to identify top-performing merchants. 
-- Which merchant should be considered as the most successful 
-- in terms of total transaction amount received between November 2023 and April 2024?

select m.business_name, round(sum(t.transaction_amount),2) as total_sent
from transactions t
JOIN merchants m 
    ON t.recipient_id  = m.merchant_id
where transaction_date BETWEEN '2023-11-01' AND '2024-04-30'
group by m.business_name
order by total_sent desc
limit 1;


-- 12. As part of a financial analysis, 
-- the team needs to categorize transactions based on multiple criteria. 
-- Create a report that categorizes transactions into 'High Value International', 
-- 'High Value Domestic', 'Regular International', and 'Regular Domestic' 
-- based on the following criteria:

-- High Value: transaction amount > $10,000
-- International: sender and recipient from different countries

-- Write a query to categorize each transaction 
-- and count the number of transactions in each category for the year 2023.

select 
case 
 when transaction_amount > 10000 and ru.country_id = su.country_id then 'High Value Domestic'
  when transaction_amount > 10000 and ru.country_id != su.country_id then 'High Value International'
   when transaction_amount <= 10000 and ru.country_id = su.country_id then 'Regular Domestic'
   else 'Regular International'
   end as transaction_category,
count(*) as transaction_count
from transactions t 
join users ru
on t.recipient_id = ru.user_id
join users su 
on t.sender_id = su.user_id
where year(transaction_date) = '2023'
group by transaction_category
order by transaction_count desc;


-- 13. The finance department requires a comprehensive monthly report for the year 2023 
-- that segments transactions by type and nature. 
-- Specifically, the report should classify transactions into 
-- 'High Value' (above $10,000) and 'Regular' (below $10,000), 
-- and further differentiate them as either 'International' 
-- (sender and recipient from different countries) 
-- or 'Domestic' (sender and recipient from the same country).

-- Your task is to write a query that groups transactions 
-- by year, month, value_category, location_category, 
-- and then calculates both the total transaction amount 
-- and the average transaction amount for each group. 
-- This detailed analysis will provide valuable insights into transaction patterns 
-- and help the finance department in their review and planning processes.

select 
 year(transaction_date) as transaction_year,
month(transaction_date) as transaction_month,
case 
 when transaction_amount > 10000  then 'High Value'
    else 'Regular'
    end as value_category,
case when ru.country_id = su.country_id then 'Domestic'
else 'International'
end as location_category,
round(sum(transaction_amount),2) as total_amount,
round(avg(transaction_amount),2) as average_amount
from transactions t 
   join users ru
   on t.recipient_id = ru.user_id
   join users su 
   on t.sender_id = su.user_id
   where year(transaction_date) = '2023'
   group by  year(transaction_date),
month(transaction_date),value_category, location_category
order by  year(transaction_date) asc,
month(transaction_date) asc,
value_category asc,
 location_category asc;
 
 
 -- 14. The sales team wants to evaluate the performance of merchants by creating a score 
 -- based on their transaction amounts. The score is calculated as follows:

-- If total transactions exceed $50,000, the score is 'Excellent'
-- If total transactions are greater than $20,000 and lesser than or equal to $50,000, the score is 'Good'
-- If total transactions are greater than $10,000 and lesser than or equal to $20,000, the score is 'Average'
-- If total transactions are lesser than or equal to $10,000, the score is 'Below Average'

-- Write a query to assign a performance score to each merchant 
-- and calculate the average transaction amount for each performance category 
-- for the period from November 2023 to April 2024. 

with merchant_totals as 
(
select m.merchant_id,
m.business_name,
round(sum(transaction_amount),2) as total_received,
round(avg(transaction_amount),2) as average_transaction 
from transactions t 
join merchants m
   on t.recipient_id = m.merchant_id
WHERE transaction_date >= '2023-11-01' AND transaction_date < '2024-05-01'
group by  m.merchant_id,
m.business_name
),
merchant_scored as (
    select merchant_id,
    business_name,
    total_received,
    average_transaction,
 case 
 WHEN total_received > 50000  THEN 'Excellent'
 WHEN total_received > 20000 AND total_received <= 50000 THEN 'Good'
WHEN total_received > 10000 AND total_received <= 20000 THEN 'Average'
ELSE 'Below Average'
    end as performance_score
    from merchant_totals
)
select   merchant_id,
    business_name,
    total_received,
    performance_score,
    average_transaction
from merchant_scored
order by 
case performance_score 
when 'Excellent' then 1
when 'Good' then 2
when 'Average' then 3
when 'Below Average' then 4
end,
total_received desc;


-- 15. The marketing team wants to identify users who have been consistently engaged 
-- over the last year (from May 2023 to April 2024). 
-- A consistently engaged user is defined as one who has made at least one transaction 
-- in at least 6 out of the 12 months during this period.

-- Write a query to list user IDs and their email addresses for users 
-- who have made at least one transaction in at least 6 out of 12 months 
-- from May 2023 to April 2024.

WITH monthly_activity AS (
    SELECT 
    u.user_id, 
    u.email, 
    COUNT(DISTINCT DATE_FORMAT(t.transaction_date, '%Y-%m')) AS active_months
FROM users u
JOIN transactions t 
ON t.sender_id = u.user_id 
WHERE t.transaction_date >= '2023-05-01' AND t.transaction_date <= '2024-04-30'
 GROUP BY  user_id, 
    email
)
SELECT user_id, email
FROM monthly_activity
WHERE active_months >= 6
ORDER BY user_id ASC;

desc merchants;

-- 16. The sales team wants to analyze the performance of each merchant 
-- by tracking their monthly total transaction amounts 
-- and identifying months where their transactions exceeded $50,000.

-- Write a query that calculates the total transaction amount for each merchant by month, 
-- and then create a column to indicate whether the merchant exceeded $50,000 in that month. 
-- The transaction date range should be considered from 1st Nov 2023 to 1st May 2024. 
-- The new column should contain the values 'Exceeded $50,000' or 'Did Not Exceed $50,000'. 
-- Display the merchant ID, business name, transaction year, transaction month, 
-- total transaction amount, and the new column indicating performance status.
 
 
with monthly_total_transaction as (
    select 
    m.merchant_id,
    m.business_name,
    year(t.transaction_date) as transaction_year,
    month(t.transaction_date) as transaction_month,
    sum(t.transaction_amount) as total_transaction_amount
    from transactions t 
    join merchants m 
    on t.recipient_id = m.merchant_id 
   where t.transaction_date >= '2023-11-01' and t.transaction_date < '2024-05-01'
       group by  m.merchant_id,
    m.business_name,
    transaction_year,
 transaction_month
),
overall_performance as (
select 
 merchant_id,
 business_name,
 transaction_year,
 transaction_month,
 total_transaction_amount, 
 case 
      when total_transaction_amount > 50000 then  'Exceeded $50,000' 
      else  'Did Not Exceed $50,000' 
end as performance_status
from monthly_total_transaction
)
select * from overall_performance
ORDER BY 
    merchant_id ASC,
    transaction_year ASC,
    transaction_month ASC;
    
    
    
    -- THE END -- 




 
 
 
 
 
 
 
 






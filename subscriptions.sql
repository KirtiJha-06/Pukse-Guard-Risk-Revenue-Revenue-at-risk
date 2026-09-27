DROP TABLE IF EXISTs SUBSCRIPTIONS;

CREATE TABLE subscriptions (
    subscription_id INT,
    customer_id INT,
    plan VARCHAR(100),
    monthly_price NUMERIC(10,2),
    start_date DATE,
    end_date DATE,
    status VARCHAR(20)
);

SELECT*FROM subscriptions;

-- What is the current customer base health?
SELECT
    status,
	COUNT(*) AS customer_count
FROM subscriptions
GROUP BY status
ORDER BY customer_count DESC;

--How much recurring revenue are we generating from active customers?
SELECT
     COUNT(*) AS active_customers,
	 ROUND(SUM(monthly_price),2) AS monthly_recurring_revenue
FROM subscriptions
WHERE status = 'Active';

--Which plans are most important to the business?
SELECT
     plan,
	 COUNT(*) AS active_customers,
	 ROUND(SUM(monthly_price),2) AS monthly_revenue,
	 ROUND(AVG(monthly_price),2) AS avg_monthly_price
FROM subscriptions
WHERE status = 'Active'
GROUP BY plan
ORDER BY monthly_revenue DESC;


	 
--Which subscription plan has the highest customer churn?

SELECT
     plan,
	 COUNT(*) AS total_customers,
	 COUNT(*) FILTER(WHERE status = 'Churned') AS churned_customers,
	 ROUND(
           100.0 * COUNT(*) FILTER (WHERE status = 'churned')
		   / COUNT(*),
		   2
		   ) AS churn_rate_pct
FROM subscriptions
GROUP BY plan
ORDER BY churn_rate_pct DESC;

--Which plans have lost the most revenue due to churn?
SELECT
     plan,
	 COUNT(*) FILTER (WHERE status = 'Churned') AS churned_customers,
	 ROUND(
          SUM(monthly_price) FILTER (WHERE status = 'Churned'),
		  2
	 ) AS monthly_revenue_lost
FROM subscriptions
GROUP BY plan
ORDER BY monthly_revenue_lost DESC;

--Which customers contribute the most monthly revenue?
SELECT
     customer_id,
	 plan,
	 monthly_price,
	 start_date
FROM subscriptions
WHERE status = 'Active'
ORDER BY monthly_price DESC
LIMIT 20;

--How long are customers staying with us?
SELECT
     ROUND(
          AVG(CURRENT_DATE - start_date) / 30.44,
		  1
	 ) AS avg_tenure_months
FROM subscriptions
WHERE status = 'Active';

--How long are customers staying with us?
SELECT
     DATE_TRUNC('month', start_date) AS signup_month,
	 COUNT(*) AS new_customers
FROM subscriptions
GROUP BY DATE_TRUNC('month', start_date)
ORDER BY signup_month;


--What percentage of total active revenue comes from each customer?

SELECT
     customer_id,
	 plan,
	 monthly_price,
	 ROUND(
          100.0 * monthly_price /
		  SUM(monthly_price) over(),
		  2
	 ) AS revenue_share_pct
FROM subscriptions
WHERE status = 'Active'
ORDER BY monthly_price DESC;

 --Which customers should we prioritize for retention?

 SELECT 
      customer_id,
	  plan,
	  monthly_price,
	  start_date,
	  ROUND(
           (CURRENT_DATE - start_date) / 30.44,
		   1
	  ) AS tenure_months,
	  CASE
	      WHEN monthly_price >= 2000 THEN 'High Priority'
		  WHEN monthly_price >= 1000 THEN 'Medium Priority'
		  ELSE 'Standard Priority'
		END AS retention_priority
FROM subscriptions
WHERE status = 'Active'
ORDER BY monthly_price DESC;

CREATE TABLE payments(
       payment_id INT,
	   customer_id INT,
	   payment_date DATE,
	   amount NUMERIC(10,2),
	   payment_status VARCHAR(20)
);

SELECT*FROM payments;

--What is the overall distribution of successful and failed payments
SELECT
      payment_status,
	  COUNT(*) AS payment_count,
	  ROUND(SUM(amount),2) AS total_amount
FROM payments
GROUP BY payment_status
ORDER BY payment_count DESC;

--What percentage of all payments are failing
SELECT 
    COUNT(*) AS total_payments,
	COUNT(*) FILTER(
          WHERE payment_status = 'Failed'
	) AS failed_payments,
	ROUND(
         100.0 * COUNT(*) FILTER(
               WHERE payment_status = 'Failed'
		 )/COUNT(*),
		 2
	) AS failure_rate_pct
FROM payments;


--How much revenue has been associated with successful payments
SELECT
    COUNT(*) AS successful_payments,
	ROUND(SUM(amount),2) AS successful_payment_amount
FROM payments
WHERE payment_status = 'Success';

--How does payment volume change month by month
SELECT
    DATE_TRUNC('month', payment_date) AS payment_month,
	COUNT(*) AS total_payments,
	ROUND(SUM(amount), 2) AS total_payment_amount
FROM paymrnts
GROUP BY DATE_TRUNC('month' , payment_date)
ORDER BY payment_month;

--Which months experienced the highest payment failure rates

SELECT 
    DATE_TRUNC('month', payment_date) AS payment_month,
	COUNT(*) AS total_payment,
	COUNT(*) FILTER(
         WHERE payment_status = 'Failed'
	) AS failed_payments,
	ROUND(
         100.0 * COUNT(*) FILTER(
             WHERE payment_status = 'Failed'
		 ) / COUNT(*),
		 2
	) AS failure_rate_pct
	FROM payments
	GROUP BY DATE_TRUNC('month',payment_date)
	ORDER BY failure_rate_pct DESC;

--Which customers have experienced the most failed payments

SELECT
     customer_id,
	 COUNT(*) AS failed_payment_count,
	 ROUND(SUM(amount), 2) AS failed_payment_amount
FROM payments
WHERE payment_status = 'Failed'
GROUP BY customer_id
ORDER BY failed_payment_count DESC
LIMIT 25;

--Find customers whose payments are consistently failing

SELECT
     customer_id,
	 COUNT(*) AS failed_payments,
	 ROUND(SUM(amount),2) AS failed_payment_amount
FROM payments
WHERE payment_status = 'Failed'
GROUP BY customer_id
HAVING COUNT(*) >= 3
ORDER BY failed_payments DESC;

--Determine whether certain plans have more payment problems.
SELECT
    s.plan,
    COUNT(p.payment_id) AS total_payments,
    COUNT(*) FILTER (
        WHERE p.payment_status = 'Failed'
    ) AS failed_payments,
    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE p.payment_status = 'Failed'
        ) / COUNT(*),
        2
    ) AS failure_rate_pct
FROM subscriptions s
JOIN payments p
    ON s.customer_id = p.customer_id
GROUP BY s.plan
ORDER BY failure_rate_pct DESC;

--Which active high-value customers are experiencing payment failures

SELECT 
     s.customer_id,
	 s.plan,
	 s.monthly_price,
	 COUNT(p.payment_id) AS total_payments,
	 COUNT(*) FILTER (
          WHERE p.payment_status = 'Failed'
	 ) AS failed_payments,
	 ROUND(
        100.0 * COUNT(*) FILTER (
        WHERE p.payment_status = 'Failed'
		) / COUNT(*),
		2
	 )AS failure_rate_pct
FROM subscriptions s
JOIN payments p
     ON s.customer_id = p.customer_id
WHERE s.status = 'Active'
GROUP BY
       s.customer_id,
	   s.plan,
	   s.monthly_price
HAVING
      s.monthly_price >= 1500
	  AND COUNT(*) FILTER(
          WHERE p.payment_status = 'Failed'
	  ) > 0
ORDER BY s.monthly_price DESC;


--Identify which plans represent the largest payment-risk exposure.
SELECT
     s.plan,
	 COUNT(p.payment_id) AS failed_paymments,
	 ROUND(SUM(p.amount),2) AS failed_payment_amount
FROM subscriptions s
JOIN payments p
     ON s.customer_id = p.customer_id
WHERE p.payment_status = 'Failed'
GROUP BY s.plan
ORDER BY failed_payment_amount DESC;

--Find customers where payment risk has meaningful financial impact.
SELECT 
     customer_id,
	 COUNT(*) AS total_payments,
	 COUNT(*) FILTER(
          WHERE payment_status = 'Failed'
	 ) AS failed_payments,
	 ROUND(
         100.0 * COUNT(*) FILTER(
             WHERE payment_status = 'Failed'
		 ) / COUNT(*),
		 2
	 ) AS failure_rate_pct,
	 ROUND(SUM(amount),2) AS total_payment_amount,
	 ROUND(
        SUM(amount) FILTER(
           WHERE payment_status = 'Failed'
		),
		2
	 )AS failed_payment_amount
FROM payments
GROUP BY customer_id
HAVING
     COUNT(*) >= 3
	 AND
	 100.0* COUNT(*)FILTER(
     WHERE payment_status = 'Failed'
	 )/COUNT(*) >= 25
ORDER BY failed_payment_amount DESC;

--Convert raw payment data into an actionable risk category.

WITH payment_analysis AS (
    SELECT
        customer_id,
        COUNT(*) AS total_payments,
        COUNT(*) FILTER (
            WHERE payment_status = 'Failed'
        ) AS failed_payments
    FROM payments
    GROUP BY customer_id
)

SELECT
    customer_id,
    total_payments,
    failed_payments,
    ROUND(
        100.0 * failed_payments / total_payments,
        2
    ) AS failure_rate_pct,

    CASE
        WHEN 100.0 * failed_payments / total_payments >= 50
            THEN 'Critical'
        WHEN 100.0 * failed_payments / total_payments >= 25
            THEN 'High'
        WHEN 100.0 * failed_payments / total_payments >= 10
            THEN 'Medium'
        ELSE 'Low'
    END AS payment_risk_level

FROM payment_analysis
ORDER BY failure_rate_pct DESC;

--Which customers should PulseGuard prioritize based on payment risk

WITH payment_analysis AS (
    SELECT
        s.customer_id,
        s.plan,
        s.monthly_price,
        s.status,

        COUNT(p.payment_id) AS total_payments,

        COUNT(*) FILTER (
            WHERE p.payment_status = 'Failed'
        ) AS failed_payments,

        COALESCE(
            SUM(p.amount) FILTER (
                WHERE p.payment_status = 'Failed'
            ),
            0
        ) AS failed_payment_amount

    FROM subscriptions s

    LEFT JOIN payments p
        ON s.customer_id = p.customer_id

    GROUP BY
        s.customer_id,
        s.plan,
        s.monthly_price,
        s.status
)

SELECT
    customer_id,
    plan,
    monthly_price,
    status,
    total_payments,
    failed_payments,

    ROUND(
        100.0 * failed_payments
        / NULLIF(total_payments, 0),
        2
    ) AS failure_rate_pct,

    ROUND(failed_payment_amount, 2)
        AS failed_payment_amount,

    CASE
        WHEN total_payments = 0 THEN 15

        WHEN 100.0 * failed_payments
             / total_payments >= 50
            THEN 30

        WHEN 100.0 * failed_payments
             / total_payments >= 25
            THEN 20

        WHEN 100.0 * failed_payments
             / total_payments >= 10
            THEN 10

        ELSE 0
    END AS payment_risk_score

FROM payment_analysis

ORDER BY
    payment_risk_score DESC,
    failed_payment_amount DESC;

SELECT * FROM customer_activity

--What are the most common customer activities

SELECT
     activity_type,
	 COUNT(*) AS activity_count,
	 COUNT(DISTINCT customer_id) AS unique_customers
FROM customer_activity
GROUP BY activity_type
ORDER BY activity_count DESC;

--How many customer activities occur each month
SELECT
    DATE_TRUNC('month' , activity_date) AS activity_month,
	COUNT(*) AS total_activities,
	COUNT(DISTINCT customer_id) AS active_customers
FROM customer_activity
GROUP BY DATE_TRUNC('month', activity_date)
ORDER BY activity_month;

--When was customer engagement at its strongest
SELECT
     DATE_TRUNC('month', activity_date) AS activity_month,
	 COUNT(DISTINCT customer_id) AS active_customers
FROM customer_activity
GROUP BY DATE_TRUNC('month', activity_date)
ORDER BY active_customers DESC;


--Which customers show the strongest product engagement
SELECT
     customer_id,
	 COUNT(*) AS total_activities,
	 COUNT(DISTINCT activity_date) AS active_days,
	 COUNT(DISTINCT activity_type) AS activity_types_used
FROM customer_activity
GROUP BY customer_id
ORDER BY total_activities DESC
LIMIT 25;

--Which customers may need engagement or retention attention
SELECT
     customer_id,
	 COUNT(*) AS total_activities,
	 COUNT(DISTINCT activity_date) AS active_days
FROM customer_activity
GROUP BY customer_id
ORDER BY total_activities ASC
LIMIT 25;

--What is the average level of customer engagement
SELECT
     COUNT(*) AS total_activities,
	 COUNT(DISTINCT customer_id) AS total_customers,
	 ROUND(
           COUNT(*):: NUMERIC / COUNT(DISTINCT customer_id),
		   2
	 )AS avg_activities_per_customer
FROM customer_activity;


--Which customers are becoming inactive
SELECT
     customer_id,
	 MAX(activity_date) AS last_activity_date,
	 CURRENT_DATE - MAX(activity_date) AS days_since_last_activity
FROM customer_activity
GROUP BY customer_id
ORDER BY days_since_last_activity DESC
LIMIT 25;

--How many customers fall into different engagement-recency groups
WITH customer_recency AS (
    SELECT
        customer_id,
        CURRENT_DATE - MAX(activity_date) AS days_since_last_activity
    FROM customer_activity
    GROUP BY customer_id
)

SELECT
    CASE
        WHEN days_since_last_activity <= 7 THEN 'Active - Last 7 Days'
        WHEN days_since_last_activity <= 30 THEN 'Active - 8-30 Days'
        WHEN days_since_last_activity <= 60 THEN 'At Risk - 31-60 Days'
        WHEN days_since_last_activity <= 90 THEN 'At Risk - 61-90 Days'
        ELSE 'Inactive - 90+ Days'
    END AS engagement_group,
    COUNT(*) AS customer_count
FROM customer_recency
GROUP BY
    CASE
        WHEN days_since_last_activity <= 7 THEN 'Active - Last 7 Days'
        WHEN days_since_last_activity <= 30 THEN 'Active - 8-30 Days'
        WHEN days_since_last_activity <= 60 THEN 'At Risk - 31-60 Days'
        WHEN days_since_last_activity <= 90 THEN 'At Risk - 61-90 Days'
        ELSE 'Inactive - 90+ Days'
    END
ORDER BY customer_count DESC;

--Is customer engagement different between active and churned customers
SELECT
      s.status,
	  COUNT(DISTINCT s.customer_id) AS customers,
	  COUNT(ca.activity_id) AS total_activites,
	  ROUND(
         COUNT(ca.activity_id) :: NUMERIC
		 / COUNT(DISTINCT s.customer_id),
		 2
	  )AS avg_activities_per_customer
FROM subscriptions s
JOIN customer_activity ca
    ON s.customer_id = ca.customer_id
GROUP BY s.status
ORDER BY avg_activities_per_customer DESC;

--Which high-value active customers have low engagement
SELECT
      s.customer_id,
	  s.plan,
	  s.monthly_price,
	  COUNT(ca.activity_id) AS total_activities,
	  MAX(ca.activity_date) AS last_activity_date,
	  CURRENT_DATE - MAX(ca.activity_date) AS days_since_last_activity
FROM subscriptions s
JOIN customer_activity ca
     ON s.customer_id = ca.customer_id
WHERE s.status = 'Active'
GROUP BY
       s.customer_id,
	   s.plan,
	   s.monthly_price
HAVING
      s.monthly_price >= 1500
	  AND COUNT(ca.activity_id) <= 10
ORDER BY 
      s.monthly_price DESC;


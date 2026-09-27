CREATE TABLE support_tickets(
     ticket_id INT,
	 customer_id INT,
	 issue_type VARCHAR(100),
	 ticket_date DATE,
	 resolution_time_hrs NUMERIC(10,2),
	 satisfaction_score NUMERIC(3,1)
);

SELECT* FROM support_tickets

--What problems are customers contacting support about most?
SELECT
     issue_type,
	 COUNT(*) AS ticket_count
FROM support_tickets
GROUP BY issue_type
ORDER BY ticket_count DESC;

--Which issues take the longest to resolve?
SELECT
     issue_type,
	 COUNT(*) ticket_count,
	 ROUND(AVG(resolution_time_hrs),2) AS avg_resolution_hours
FROM support_tickets
GROUP BY issue_type
ORDER BY avg_resolution_hours DESC;

--Which issues have the lowest customer satisfaction?
SELECT 
     issue_type,
	 COUNT(satisfaction_score) AS rated_tickets,
	 ROUND(AVG(satisfaction_score),2) AS avg_satisfaction
FROM support_tickets
GROUP BY issue_type
ORDER BY avg_satisfaction ASC;


--How large is our customer-service dissatisfaction problem?
SELECT
     COUNT(*) AS total_tickets,
	 COUNT(*) FILTER (
         WHERE satisfaction_score <= 2
		 ) AS poor_satisfaction_tickets,
	ROUND(
        100.0 * COUNT(*) FILTER (
        WHERE satisfaction_score <= 2
		) / COUNT(*),
		2
	)AS poor_satisfaction_pct
FROM support_tickets;

--Which issues are causing the most dissatisfied customers?
SELECT
     issue_type,
	 COUNT(*) FILTER(
         WHERE satisfaction_score <= 2
	 ) AS dissatisfied_tickets,
	 ROUND(AVG(satisfaction_score),2) AS avg_satisfaction
FROM support_tickets
GROUP BY issue_type
ORDER BY dissatisfied_tickets DESC;

--Which customers contact support the most
SELECT
     customer_id,
	 COUNT(*) AS ticket_count,
	 ROUND(AVG(satisfaction_score),2) AS avg_satisfaction
FROM support_tickets
GROUP BY customer_id
ORDER BY ticket_count DESC
LIMIT 25;

--Which customers have both high ticket volume AND poor satisfaction?
SELECT
     customer_id,
	 COUNT(*) AS ticket_count,
	 ROUND(AVG(satisfaction_score),2) AS avg_satisfaction
FROM support_tickets
GROUP BY customer_id
HAVING COUNT(*) >= 5
   AND AVG(satisfaction_score) <= 2.5
ORDER BY ticket_count DESC;

--Which customer segment creates the greatest support workload
SELECT
    s.plan,
	COUNT(st.ticket_id) AS total_tickets,
	COUNT(DISTINCT st.customer_id) AS customers_using_support,
	ROUND(AVG(st.satisfaction_score),2) AS avg_satisfaction
FROM subscriptions s
JOIN support_tickets st
    ON s.customer_id = st.customer_id
GROUP BY s.plan
ORDER BY total_tickets DESC;

--Which plans have the longest support resolution times
SELECT
     s.plan,
	 COUNT(st.ticket_id) AS total_tickets,
	 ROUND(AVG(st.resolution_time_hrs),2) AS avg_resolution_hours,
	 ROUND(AVG(st.satisfaction_score),2) AS avg_satisfaction
FROM subscription s
JOIN support_tickets st
    ON s.customer_id = st.customer_id
GROUP BY s.plan
ORDER BY avg_resolution_hours DESC;

--How much support burden exists among active vs churned customers
SELECT
     s.status,
	 COUNT(st.ticket_id) AS total_tickets,
	 COUNT(DISTINCT st.customer_id) AS customers,
	 ROUND(AVG(st.resolution_time_hrs),2) AS avg_resolution_hours,
	 ROUND(AVG(st.satisfaction_score),2) AS avg_satisfaction
FROM subscriptions s
JOIN support_tickets st
    ON s.customer_id = st.customer_id
GROUP BY s.status
ORDER BY total_tickets DESC;

--Which churned customers had the biggest support burden
SELECT
     s.customer_id,
	 s.plan,
	 s.monthly_price,
	 COUNT(st.ticket_id) AS ticket_count,
	 ROUND(AVG(st.satisfaction_score),2) AS avg_satisfaction,
	 ROUND(AVG(st.resolution_time_hrs),2) AS avg_resolution_hours
FROM subscriptions s
JOIN support_tickets st
    ON s.customer_id = st.customer_id
WHERE s.status = 'Churned'
GROUP BY
    s.customer_id,
	s.plan,
	s.monthly_price
ORDER BY ticket_count DESC
LIMIT 25;

--Which active customers have high revenue AND support problems
SELECT 
     s.customer_id,
	 s.plan,
	 s.monthly_price,
	 COUNT(st.ticket_id) AS ticket_count,
	 ROUND(AVG(st.satisfaction_score),2) AS avg_satisfaction
FROM subscriptions s
JOIN support_tickets st
     ON s.customer_id = st.customer_id
WHERE s.status = 'Active'
GROUP BY
     s.customer_id,
	 s.plan,
	 s.monthly_price
HAVING s.monthly_price >= 1500
     AND COUNT(st.ticket_id) >= 3
	 AND AVG(st.satisfaction_score) <= 2.5
ORDER BY s.monthly_price DESC;

--Which plans have the highest support cost proxy
SELECT
     s.plan,
	 COUNT(st.ticket_id) AS tickets,
	 ROUND(SUM(st.resolution_time_hrs),2) AS total_resolution_hours,
	 ROUND(AVG(st.resolution_time_hrs),2) AS avg_resolution_hours
FROM subscriptions s
JOIN support_tickets st
    ON s.customer_id = st.customer_id
GROUP BY s.plan
ORDER BY total_resolution_hours DESC;

--What is the relationship between support problems and churn
WITH customer_support AS (
    SELECT
        s.customer_id,
        s.status,
        COUNT(st.ticket_id) AS ticket_count
    FROM subscriptions s
    LEFT JOIN support_tickets st
        ON s.customer_id = st.customer_id
    GROUP BY
        s.customer_id,
        s.status
),

customer_groups AS (
    SELECT
        customer_id,
        status,
        ticket_count,
        CASE
            WHEN ticket_count = 0 THEN 'No Tickets'
            WHEN ticket_count <= 2 THEN '1-2 Tickets'
            WHEN ticket_count <= 5 THEN '3-5 Tickets'
            ELSE '6+ Tickets'
        END AS support_volume_group
    FROM customer_support
)

SELECT
    support_volume_group,
    COUNT(*) AS customers,

    COUNT(*) FILTER (
        WHERE status = 'Churned'
    ) AS churned_customers,

    ROUND(
        100.0 * COUNT(*) FILTER (
            WHERE status = 'Churned'
        ) / COUNT(*),
        2
    ) AS churn_rate_pct

FROM customer_groups

GROUP BY support_volume_group

ORDER BY churn_rate_pct DESC;

--BUILD A SUPPORT RISK RANKING

WITH customer_support AS (
    SELECT
        s.customer_id,
        s.plan,
        s.monthly_price,
        s.status,
        COUNT(st.ticket_id) AS ticket_count,
        AVG(st.satisfaction_score) AS avg_satisfaction,
        AVG(st.resolution_time_hrs) AS avg_resolution_hours
    FROM subscriptions s
    LEFT JOIN support_tickets st
        ON s.customer_id = st.customer_id
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
    ticket_count,
    ROUND(avg_satisfaction, 2) AS avg_satisfaction,
    ROUND(avg_resolution_hours, 2) AS avg_resolution_hours,

    (
        LEAST(ticket_count * 3, 15)

        + CASE
            WHEN avg_satisfaction IS NULL THEN 0
            WHEN avg_satisfaction <= 2 THEN 10
            WHEN avg_satisfaction <= 3 THEN 7
            WHEN avg_satisfaction <= 4 THEN 3
            ELSE 0
          END

        + CASE
            WHEN avg_resolution_hours > 24 THEN 5
            WHEN avg_resolution_hours > 12 THEN 3
            ELSE 0
          END
    ) AS support_risk_score

FROM customer_support
ORDER BY support_risk_score DESC;




WITH customer_support AS (
    SELECT
        s.customer_id,
        s.plan,
        s.monthly_price,
        s.status,
        COUNT(st.ticket_id) AS ticket_count,
        AVG(st.satisfaction_score) AS avg_satisfaction,
        AVG(st.resolution_time_hrs) AS avg_resolution_hours
    FROM subscriptions s
    LEFT JOIN support_tickets st
        ON s.customer_id = st.customer_id
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
    ticket_count,
    ROUND(avg_satisfaction, 2) AS avg_satisfaction,
    ROUND(avg_resolution_hours, 2) AS avg_resolution_hours,

    (
        LEAST(ticket_count * 3, 15)

        + CASE
            WHEN avg_satisfaction IS NULL THEN 0
            WHEN avg_satisfaction <= 2 THEN 10
            WHEN avg_satisfaction <= 3 THEN 7
            WHEN avg_satisfaction <= 4 THEN 3
            ELSE 0
          END

        + CASE
            WHEN avg_resolution_hours > 24 THEN 5
            WHEN avg_resolution_hours > 12 THEN 3
            ELSE 0
          END
    ) AS support_risk_score

FROM customer_support
ORDER BY support_risk_score DESC;


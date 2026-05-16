-- SaaS Customer Churn & Retention Analysis
-- Author: Piyush | Tool: PostgreSQL


CREATE TABLE customers (
    customer_id        VARCHAR(20) PRIMARY KEY,
    gender             VARCHAR(10),
    senior_citizen     INTEGER,
    partner            VARCHAR(5),
    dependents         VARCHAR(5),
    tenure             INTEGER,
    phone_service      VARCHAR(5),
    multiple_lines     VARCHAR(20),
    internet_service   VARCHAR(20),
    online_security    VARCHAR(20),
    online_backup      VARCHAR(20),
    device_protection  VARCHAR(20),
    tech_support       VARCHAR(20),
    streaming_tv       VARCHAR(20),
    streaming_movies   VARCHAR(20),
    contract           VARCHAR(20),
    paperless_billing  VARCHAR(5),
    payment_method     VARCHAR(30),
    monthly_charges    DECIMAL(10,2),
    total_charges      VARCHAR(20),
    churn              VARCHAR(5)
);

SELECT 'Table created successfully!' AS status;

SELECT * FROM customers;

COPY customers
FROM 'C:/temp/WA_Fn-UseC_-Telco-Customer-Churn.csv'
DELIMITER ','
CSV HEADER;

SELECT COUNT(*) AS total_customers FROM customers;


-- DATA CLEANING

-- empty total_charges
SELECT COUNT(*) AS empty_total_charges
FROM customers
WHERE total_charges = ' ';

-- empty total_charges → replace with monthly_charges
UPDATE customers
SET total_charges = monthly_charges::TEXT
WHERE total_charges = ' ';

-- Added cleaned numeric column
ALTER TABLE customers ADD COLUMN IF NOT EXISTS total_charges_num DECIMAL(10,2);

UPDATE customers
SET total_charges_num = CAST(total_charges AS DECIMAL(10,2));

-- Added churn flag (1/0)
ALTER TABLE customers ADD COLUMN IF NOT EXISTS churn_flag INTEGER;

UPDATE customers
SET churn_flag = CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END;

-- Added tenure groups
ALTER TABLE customers ADD COLUMN IF NOT EXISTS tenure_group VARCHAR(20);

UPDATE customers
SET tenure_group = CASE
    WHEN tenure BETWEEN 0 AND 12 THEN '0-12 Months'
    WHEN tenure BETWEEN 13 AND 24 THEN '13-24 Months'
    WHEN tenure BETWEEN 25 AND 36 THEN '25-36 Months'
    WHEN tenure BETWEEN 37 AND 48 THEN '37-48 Months'
    WHEN tenure BETWEEN 49 AND 60 THEN '49-60 Months'
    ELSE '61+ Months'
END;

-- Verify cleaning
SELECT 
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned_customers,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers;



-- SECTION 1: BASIC EXPLORATION

-- Query 1: Overall churn summary
SELECT 
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    COUNT(*) - SUM(churn_flag) AS retained,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND((COUNT(*) - SUM(churn_flag)) * 100.0 / COUNT(*), 2) AS retention_rate_pct
FROM customers;

-- Query 2: Churn by gender
SELECT 
    gender,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY gender
ORDER BY churn_rate_pct DESC;

-- Query 3: Churn by senior citizen
SELECT 
    CASE WHEN senior_citizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS customer_type,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY senior_citizen
ORDER BY churn_rate_pct DESC;

-- Query 4: Churn by contract type
SELECT 
    contract,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- Query 5: Churn by internet service
SELECT 
    internet_service,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

-- Query 6: Churn by payment method
SELECT 
    payment_method,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- Query 7: Average monthly charges
SELECT 
    churn,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(MIN(monthly_charges), 2) AS min_charges,
    ROUND(MAX(monthly_charges), 2) AS max_charges,
    COUNT(*) AS total_customers
FROM customers
GROUP BY churn;

-- Query 8: Churn by tenure group
SELECT 
    tenure_group,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY tenure_group
ORDER BY churn_rate_pct DESC;


-- SECTION 2: MRR & REVENUE ANALYSIS


SELECT 
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(SUM(CASE WHEN churn = 'No' THEN monthly_charges ELSE 0 END), 2) AS active_mrr,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS churned_mrr,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END) * 100.0 / 
          SUM(monthly_charges), 2) AS mrr_churn_rate_pct
FROM customers;

-- Query 10: MRR by contract type
SELECT 
    contract,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(AVG(monthly_charges), 2) AS avg_mrr,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned_customers
FROM customers
GROUP BY contract
ORDER BY total_mrr DESC;

-- Query 11: Customer Lifetime Value (CLV)
SELECT 
    customer_id,
    tenure,
    monthly_charges,
    total_charges_num,
    churn,
    ROUND(monthly_charges * 
        CASE WHEN churn = 'No' THEN (tenure + 24) ELSE tenure END, 2) AS estimated_clv
FROM customers
ORDER BY estimated_clv DESC
LIMIT 20;

-- Query 12: Average CLV by contract type
SELECT 
    contract,
    ROUND(AVG(monthly_charges * 
        CASE WHEN churn = 'No' THEN (tenure + 24) ELSE tenure END), 2) AS avg_clv,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(tenure), 1) AS avg_tenure_months
FROM customers
GROUP BY contract
ORDER BY avg_clv DESC;

-- Query 13: Revenue at risk (churned MRR by segment)
SELECT 
    internet_service,
    contract,
    COUNT(*) AS churned_customers,
    ROUND(SUM(monthly_charges), 2) AS revenue_at_risk,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customers
WHERE churn = 'Yes'
GROUP BY internet_service, contract
ORDER BY revenue_at_risk DESC;

-- Query 14: MRR by payment method
SELECT 
    payment_method,
    ROUND(SUM(monthly_charges), 2) AS total_mrr,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END), 2) AS churned_mrr,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthly_charges ELSE 0 END) * 100.0 /
          SUM(monthly_charges), 2) AS mrr_churn_pct
FROM customers
GROUP BY payment_method
ORDER BY total_mrr DESC;

-- Query 15: High value churned customers
SELECT 
    customer_id,
    tenure,
    contract,
    monthly_charges,
    total_charges_num,
    payment_method,
    internet_service
FROM customers
WHERE churn = 'Yes'
AND monthly_charges > (SELECT AVG(monthly_charges) FROM customers WHERE churn = 'Yes')
ORDER BY monthly_charges DESC
LIMIT 20;

-- Query 16: Revenue recovery potential
SELECT 
    contract,
    COUNT(*) AS churned_customers,
    ROUND(SUM(monthly_charges), 2) AS monthly_revenue_lost,
    ROUND(SUM(monthly_charges) * 12, 2) AS annual_revenue_lost,
    ROUND(AVG(tenure), 1) AS avg_tenure_before_churn
FROM customers
WHERE churn = 'Yes'
GROUP BY contract
ORDER BY monthly_revenue_lost DESC;


-- SECTION 3: COHORT ANALYSIS 


-- Query 17: Cohort base — customers by tenure group
WITH cohort_base AS (
    SELECT 
        tenure_group,
        COUNT(*) AS total_customers,
        SUM(churn_flag) AS churned,
        COUNT(*) - SUM(churn_flag) AS retained
    FROM customers
    GROUP BY tenure_group
)
SELECT 
    tenure_group,
    total_customers,
    churned,
    retained,
    ROUND(retained * 100.0 / total_customers, 2) AS retention_rate_pct,
    ROUND(churned * 100.0 / total_customers, 2) AS churn_rate_pct
FROM cohort_base
ORDER BY tenure_group;

-- Query 18: Retention rate by contract and tenure
SELECT 
    tenure_group,
    contract,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND((COUNT(*) - SUM(churn_flag)) * 100.0 / COUNT(*), 2) AS retention_rate_pct
FROM customers
GROUP BY tenure_group, contract
ORDER BY tenure_group, retention_rate_pct DESC;

-- Query 19: Cohort retention heatmap data
SELECT 
    tenure_group,
    internet_service,
    COUNT(*) AS total_customers,
    ROUND((COUNT(*) - SUM(churn_flag)) * 100.0 / COUNT(*), 2) AS retention_rate_pct
FROM customers
GROUP BY tenure_group, internet_service
ORDER BY tenure_group, internet_service;

-- Query 20: Monthly cohort analysis simulation
SELECT 
    tenure,
    COUNT(*) AS customers_at_tenure,
    SUM(churn_flag) AS churned_at_tenure,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(SUM(SUM(churn_flag)) OVER (ORDER BY tenure) * 100.0 / 
          SUM(COUNT(*)) OVER (), 2) AS cumulative_churn_pct
FROM customers
GROUP BY tenure
ORDER BY tenure;

-- Query 21: Cohort survival analysis
WITH cohort_survival AS (
    SELECT 
        tenure_group,
        COUNT(*) AS cohort_size,
        COUNT(*) - SUM(churn_flag) AS survivors
    FROM customers
    GROUP BY tenure_group
)
SELECT 
    tenure_group,
    cohort_size,
    survivors,
    ROUND(survivors * 100.0 / cohort_size, 2) AS survival_rate_pct,
    ROUND(100 - (survivors * 100.0 / cohort_size), 2) AS attrition_rate_pct,
    ROUND(AVG(survivors * 100.0 / cohort_size) OVER (), 2) AS avg_survival_rate
FROM cohort_survival
ORDER BY tenure_group;

-- Query 22: Multi-dimensional cohort
SELECT 
    tenure_group,
    contract,
    internet_service,
    COUNT(*) AS customers,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customers
GROUP BY tenure_group, contract, internet_service
HAVING COUNT(*) > 10
ORDER BY churn_rate_pct DESC
LIMIT 20;

-- Query 23: Rank customers by monthly charges
SELECT 
    customer_id,
    monthly_charges,
    tenure,
    churn,
    RANK() OVER (ORDER BY monthly_charges DESC) AS charge_rank,
    NTILE(4) OVER (ORDER BY monthly_charges) AS charge_quartile
FROM customers
ORDER BY charge_rank
LIMIT 20;

-- Query 24: Running total of churned customers by tenure
SELECT 
    tenure,
    COUNT(*) AS customers,
    SUM(churn_flag) AS churned,
    SUM(SUM(churn_flag)) OVER (ORDER BY tenure) AS cumulative_churned,
    SUM(COUNT(*)) OVER (ORDER BY tenure) AS cumulative_customers
FROM customers
GROUP BY tenure
ORDER BY tenure;

-- Query 25: LAG — month over month churn comparison
WITH tenure_churn AS (
    SELECT 
        tenure,
        ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate
    FROM customers
    GROUP BY tenure
)
SELECT 
    tenure,
    churn_rate,
    LAG(churn_rate) OVER (ORDER BY tenure) AS prev_month_churn,
    ROUND(churn_rate - LAG(churn_rate) OVER (ORDER BY tenure), 2) AS churn_change
FROM tenure_churn
ORDER BY tenure;

-- Query 26: LEAD — predict next period churn
WITH tenure_churn AS (
    SELECT 
        tenure,
        COUNT(*) AS customers,
        SUM(churn_flag) AS churned,
        ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate
    FROM customers
    GROUP BY tenure
)
SELECT 
    tenure,
    churn_rate,
    LEAD(churn_rate) OVER (ORDER BY tenure) AS next_period_churn,
    LEAD(customers) OVER (ORDER BY tenure) AS next_period_customers
FROM tenure_churn
ORDER BY tenure;

-- Query 27: Moving average churn rate
WITH tenure_churn AS (
    SELECT 
        tenure,
        ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate
    FROM customers
    GROUP BY tenure
)
SELECT 
    tenure,
    churn_rate,
    ROUND(AVG(churn_rate) OVER (
        ORDER BY tenure
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS three_month_moving_avg
FROM tenure_churn
ORDER BY tenure;

-- Query 28: PERCENT_RANK of monthly charges
SELECT 
    customer_id,
    monthly_charges,
    churn,
    ROUND(CAST(PERCENT_RANK() OVER (ORDER BY monthly_charges) * 100 AS DECIMAL), 2) AS charge_percentile,
    ROUND(CAST(CUME_DIST() OVER (ORDER BY monthly_charges) * 100 AS DECIMAL), 2) AS cumulative_dist
FROM customers
ORDER BY monthly_charges DESC
LIMIT 20;

-- Query 29: ROW_NUMBER — top churned customers per contract
WITH ranked_churned AS (
    SELECT 
        customer_id,
        contract,
        monthly_charges,
        tenure,
        churn,
        ROW_NUMBER() OVER (
            PARTITION BY contract 
            ORDER BY monthly_charges DESC
        ) AS rn
    FROM customers
    WHERE churn = 'Yes'
)
SELECT * FROM ranked_churned
WHERE rn <= 5
ORDER BY contract, rn;

-- Query 30: DENSE_RANK customers by CLV per segment
SELECT 
    customer_id,
    internet_service,
    monthly_charges,
    tenure,
    ROUND(monthly_charges * tenure, 2) AS clv,
    DENSE_RANK() OVER (
        PARTITION BY internet_service 
        ORDER BY monthly_charges * tenure DESC
    ) AS clv_rank
FROM customers
ORDER BY internet_service, clv_rank
LIMIT 30;


-- SECTION 5: ADVANCED CTEs & SUBQUERIES

-- Query 31: Multi-CTE churn risk analysis
WITH base_metrics AS (
    SELECT 
        customer_id,
        tenure,
        monthly_charges,
        contract,
        internet_service,
        churn_flag,
        total_charges_num
    FROM customers
),
risk_scores AS (
    SELECT *,
        CASE 
            WHEN contract = 'Month-to-month' THEN 3
            WHEN contract = 'One year' THEN 2
            ELSE 1
        END +
        CASE 
            WHEN tenure < 12 THEN 3
            WHEN tenure < 24 THEN 2
            ELSE 1
        END +
        CASE 
            WHEN monthly_charges > 70 THEN 2
            ELSE 1
        END AS risk_score
    FROM base_metrics
	),
risk_labels AS (
    SELECT *,
        CASE 
            WHEN risk_score >= 7 THEN 'HIGH RISK '
            WHEN risk_score >= 5 THEN 'MEDIUM RISK '
            ELSE 'LOW RISK '
        END AS risk_label
    FROM risk_scores
)
SELECT 
    risk_label,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS actually_churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
	FROM risk_labels
GROUP BY risk_label
ORDER BY churn_rate_pct DESC;


-- Query 32: Customers above average charges who churned
SELECT 
    customer_id,
    monthly_charges,
    tenure,
    contract,
    internet_service
FROM customers
WHERE churn = 'Yes'
AND monthly_charges > (SELECT AVG(monthly_charges) FROM customers)
ORDER BY monthly_charges DESC
LIMIT 20;

-- Query 33: EXISTS — customers with no add-on services
SELECT 
    customer_id,
    tenure,
    monthly_charges,
    churn
FROM customers c
WHERE churn = 'Yes'
AND online_security = 'No'
AND online_backup = 'No'
AND tech_support = 'No'
ORDER BY monthly_charges DESC
LIMIT 20;

-- Query 34: Churn rate by number of services
WITH service_count AS (
    SELECT 
        customer_id,
        churn_flag,
        monthly_charges,
        (CASE WHEN phone_service = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN multiple_lines = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN online_security = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN online_backup = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN device_protection = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN tech_support = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN streaming_tv = 'Yes' THEN 1 ELSE 0 END +
         CASE WHEN streaming_movies = 'Yes' THEN 1 ELSE 0 END) AS service_count
    FROM customers
)
SELECT 
service_count,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM service_count
GROUP BY service_count
ORDER BY service_count;

-- Query 35: Recursive-style tenure progression
WITH tenure_buckets AS (
    SELECT 
        tenure_group,
        contract,
        COUNT(*) AS total,
        SUM(churn_flag) AS churned,
        ROUND(AVG(monthly_charges), 2) AS avg_charges
    FROM customers
    GROUP BY tenure_group, contract
),
cumulative AS (
    SELECT *,
        SUM(total) OVER (PARTITION BY contract ORDER BY tenure_group) AS running_customers,
        SUM(churned) OVER (PARTITION BY contract ORDER BY tenure_group) AS running_churned
    FROM tenure_buckets
)
SELECT 
    tenure_group,
    contract,
    total,
    churned,
    avg_charges,
    running_customers,
    ROUND(running_churned * 100.0 / running_customers, 2) AS cumulative_churn_rate
FROM cumulative
ORDER BY contract, tenure_group;

-- Query 36: NOT EXISTS — loyal customers (no churn risk factors)
SELECT 
    customer_id,
    tenure,
    contract,
    monthly_charges,
    internet_service
FROM customers
WHERE churn = 'No'
AND contract = 'Two year'
AND tenure > 24
AND monthly_charges < 70
ORDER BY tenure DESC
LIMIT 20;

-- Query 37: Churn prediction score
WITH churn_factors AS (
    SELECT 
        customer_id,
        churn,
        churn_flag,
        monthly_charges,
        tenure,
        CASE WHEN contract = 'Month-to-month' THEN 30 ELSE 0 END AS contract_score,
        CASE WHEN internet_service = 'Fiber optic' THEN 20 ELSE 0 END AS internet_score,
        CASE WHEN tenure < 12 THEN 25 ELSE 0 END AS tenure_score,
        CASE WHEN monthly_charges > 70 THEN 15 ELSE 0 END AS charge_score,
        CASE WHEN payment_method = 'Electronic check' THEN 10 ELSE 0 END AS payment_score
    FROM customers
)
SELECT 
    customer_id,
    churn,
    monthly_charges,
    tenure,
    contract_score + internet_score + tenure_score + 
    charge_score + payment_score AS churn_probability_score,
    CASE 
        WHEN contract_score + internet_score + tenure_score + 
             charge_score + payment_score >= 70 THEN 'VERY HIGH '
        WHEN contract_score + internet_score + tenure_score + 
             charge_score + payment_score >= 50 THEN 'HIGH '
        WHEN contract_score + internet_score + tenure_score + 
             charge_score + payment_score >= 30 THEN 'MEDIUM '
        ELSE 'LOW '
    END AS churn_risk
FROM churn_factors
ORDER BY churn_probability_score DESC
LIMIT 30;

-- Query 38: Customer segmentation
SELECT 
    CASE 
        WHEN tenure > 48 AND monthly_charges > 70 THEN 'Champions'
        WHEN tenure > 24 AND churn_flag = 0 THEN 'Loyal Customers'
        WHEN tenure < 12 AND churn_flag = 0 THEN 'New Customers'
        WHEN tenure < 12 AND churn_flag = 1 THEN 'Lost New Customers'
        WHEN tenure > 24 AND churn_flag = 1 THEN 'Lost Loyal Customers'
        ELSE 'At Risk'
    END AS customer_segment,
    COUNT(*) AS total_customers,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(tenure), 1) AS avg_tenure,
    ROUND(SUM(monthly_charges), 2) AS total_mrr
FROM customers
GROUP BY customer_segment
ORDER BY total_mrr DESC;



-- SECTION 6: BUSINESS INSIGHTS & EXPORT


-- Query 39: Churn by paperless billing
SELECT 
    paperless_billing,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM customers
GROUP BY paperless_billing
ORDER BY churn_rate_pct DESC;

-- Query 40: Partner and dependents impact on churn
SELECT 
    partner,
    dependents,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY partner, dependents
ORDER BY churn_rate_pct DESC;

-- Query 41: Service adoption vs churn
SELECT 
    streaming_tv,
    streaming_movies,
    COUNT(*) AS total_customers,
    SUM(churn_flag) AS churned,
    ROUND(SUM(churn_flag) * 100.0 / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_charges
FROM customers
GROUP BY streaming_tv, streaming_movies
ORDER BY churn_rate_pct DESC;

-- Query 42: Final churn summary report
SELECT 'SAAS CHURN ANALYSIS SUMMARY' AS metric, '' AS value
UNION ALL SELECT '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━', ''
UNION ALL SELECT 'Total Customers', COUNT(*)::TEXT FROM customers
UNION ALL SELECT 'Churned Customers', SUM(churn_flag)::TEXT FROM customers
UNION ALL SELECT 'Retained Customers', (COUNT(*) - SUM(churn_flag))::TEXT FROM customers
UNION ALL SELECT 'Overall Churn Rate', ROUND(SUM(churn_flag)*100.0/COUNT(*),2)::TEXT || '%' FROM customers
UNION ALL SELECT 'Total MRR', '$' || ROUND(SUM(monthly_charges),2)::TEXT FROM customers
UNION ALL SELECT 'Churned MRR', '$' || ROUND(SUM(CASE WHEN churn='Yes' THEN monthly_charges ELSE 0 END),2)::TEXT FROM customers
UNION ALL SELECT 'Avg Monthly Charges', '$' || ROUND(AVG(monthly_charges),2)::TEXT FROM customers
UNION ALL SELECT 'Avg Tenure (months)', ROUND(AVG(tenure),1)::TEXT FROM customers;

-- Query 43: Export churned customers
COPY (
    SELECT * FROM customers WHERE churn = 'Yes'
    ORDER BY monthly_charges DESC
)
TO 'C:/temp/churned_customers_export.csv'
DELIMITER ',' CSV HEADER;

COPY (
    SELECT 
        tenure_group,
        contract,
        COUNT(*) AS total_customers,
        SUM(churn_flag) AS churned,
        ROUND(SUM(churn_flag)*100.0/COUNT(*),2) AS churn_rate_pct,
        ROUND(AVG(monthly_charges),2) AS avg_monthly_charges
    FROM customers
    GROUP BY tenure_group, contract
    ORDER BY tenure_group, contract
)
TO 'C:/temp/cohort_analysis_export.csv'
DELIMITER ',' CSV HEADER;

SELECT 'All queries complete! Data exported successfully!' AS status;
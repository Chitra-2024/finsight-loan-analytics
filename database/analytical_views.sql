USE finsight_db;

-- 1. EXTENDED PORTFOLIO RISK & DPD BUCKETS
CREATE OR REPLACE VIEW view_portfolio_risk AS
SELECT 
    l.loan_id,
    c.customer_name,
    b.branch_name,
    b.region,
    l.product_type,
    l.loan_amount,
    MAX(r.dpd) AS max_dpd,
    CASE 
        WHEN MAX(r.dpd) = 0 THEN '0: Current'
        WHEN MAX(r.dpd) BETWEEN 1 AND 30 THEN '1: 1-30 DPD'
        WHEN MAX(r.dpd) BETWEEN 31 AND 60 THEN '2: 31-60 DPD'
        WHEN MAX(r.dpd) BETWEEN 61 AND 90 THEN '3: 61-90 DPD'
        ELSE '4: 90+ DPD (NPA)'
    END AS risk_bucket
FROM fact_loans l
JOIN dim_customers c ON l.customer_id = c.customer_id
JOIN dim_branches b ON l.branch_id = b.branch_id
JOIN fact_repayments r ON l.loan_id = r.loan_id
GROUP BY l.loan_id, c.customer_name, b.branch_name, b.region, l.product_type, l.loan_amount;

-- 2. EXECUTIVE KPI SCORECARD & HEALTH INDEX
CREATE OR REPLACE VIEW view_executive_summary AS
WITH Metrics AS (
    SELECT 
        SUM(loan_amount) AS total_aum,
        COUNT(DISTINCT loan_id) AS total_active_loans,
        ROUND((SUM(CASE WHEN risk_bucket LIKE '%NPA%' THEN loan_amount ELSE 0 END) / SUM(loan_amount)) * 100, 2) AS npa_percentage,
        (SELECT ROUND((SUM(amount_paid) / SUM(expected_amount)) * 100, 2) FROM fact_repayments) AS global_cei,
        (SELECT AVG(credit_score) FROM dim_customers) AS avg_credit_score
    FROM view_portfolio_risk
)
SELECT 
    total_aum,
    total_active_loans,
    npa_percentage,
    global_cei,
    ROUND(
        (global_cei * 0.40) + 
        ((100 - npa_percentage) * 0.40) + 
        ((avg_credit_score / 850) * 100 * 0.20), 
        1
    ) AS portfolio_health_score
FROM Metrics;

-- 3. PRODUCT PROFITABILITY & BRANCH RANKINGS
CREATE OR REPLACE VIEW view_branch_product_profitability AS
SELECT 
    b.branch_name,
    b.region,
    l.product_type,
    SUM(l.loan_amount) AS total_disbursed,
    -- Simulating interest yield generated
    ROUND(SUM(l.loan_amount * (l.interest_rate / 100)), 2) AS simulated_interest_revenue,
    -- Calculating Collection Efficiency for this specific node
    ROUND((SUM(r.amount_paid) / SUM(r.expected_amount)) * 100, 2) AS branch_product_cei,
    DENSE_RANK() OVER(PARTITION BY l.product_type ORDER BY SUM(r.amount_paid)/SUM(r.expected_amount) DESC) as branch_rank_in_product
FROM fact_loans l
JOIN dim_branches b ON l.branch_id = b.branch_id
JOIN fact_repayments r ON l.loan_id = r.loan_id
GROUP BY b.branch_name, b.region, l.product_type;

-- 4. AUTOMATED BUSINESS ACTION ENGINE
CREATE OR REPLACE VIEW view_business_insights_actions AS
SELECT 
    branch_name,
    'Collection Risk' AS operational_category,
    CONCAT('Branch Collection Index dropped to ', branch_product_cei, '% for ', product_type) AS observation,
    'Immediate Allocation of Senior Recovery Workforce Required.' AS strategic_recommendation
FROM view_branch_product_profitability
WHERE branch_product_cei < 85.00
UNION ALL
SELECT 
    branch_name,
    'Product Growth Opportunity' AS operational_category,
    CONCAT(product_type, ' maintains a pristine ', branch_product_cei, '% Collection Index.') AS observation,
    'Approve Higher Allocation of Marketing Spend to Accelerate Originations.' AS strategic_recommendation
FROM view_branch_product_profitability
WHERE branch_product_cei >= 95.00;

-- 5. DATA QUALITY & AUDIT DASHBOARD VIEW
CREATE OR REPLACE VIEW view_data_quality_audit AS
SELECT 
    'dim_customers' AS table_name,
    COUNT(CASE WHEN credit_score IS NULL THEN 1 END) AS missing_values,
    COUNT(CASE WHEN credit_score < 300 OR credit_score > 900 THEN 1 END) AS out_of_range_anomalies,
    COUNT(CASE WHEN monthly_income <= 0 THEN 1 END) AS negative_value_errors
FROM dim_customers
UNION ALL
SELECT 
    'fact_loans' AS table_name,
    COUNT(CASE WHEN loan_amount IS NULL THEN 1 END) AS missing_values,
    COUNT(CASE WHEN loan_amount <= 0 THEN 1 END) AS out_of_range_anomalies,
    COUNT(CASE WHEN disbursal_date > NOW() THEN 1 END) AS negative_value_errors
FROM fact_loans;

-- 6. TARGETED CROSS-SELL PROPENSITY
CREATE OR REPLACE VIEW view_cross_sell_opportunities AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.credit_score,
    c.monthly_income,
    l.product_type AS current_product,
    l.loan_amount AS current_loan_amount,
    CASE 
        WHEN l.product_type = 'HL' THEN 'Target for Top-Up Business Loan'
        WHEN l.product_type = 'LAP' THEN 'Target for Working Capital Loan'
        ELSE 'Target for Personal/Gold Loan'
    END AS recommended_cross_sell_product
FROM dim_customers c
JOIN fact_loans l ON c.customer_id = l.customer_id
JOIN fact_repayments r ON l.loan_id = r.loan_id
WHERE c.credit_score >= 750 
  AND c.customer_vintage_months >= 12
GROUP BY c.customer_id, c.customer_name, c.credit_score, c.monthly_income, l.product_type, l.loan_amount
HAVING MAX(r.dpd) = 0;
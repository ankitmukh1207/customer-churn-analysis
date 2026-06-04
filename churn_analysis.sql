-- ============================================================
-- CHURN DEEP DIVE ANALYSIS - SQL Queries
-- Dataset: Telco Customer Churn
-- Author: Your Name
-- ============================================================

-- ============================================================
-- 1. OVERVIEW: Overall Churn Rate
-- ============================================================
SELECT 
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned_customers,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers;


-- ============================================================
-- 2. MONTHLY CHURN TREND (by Tenure Buckets as proxy for months)
-- ============================================================
SELECT 
    CASE 
        WHEN tenure BETWEEN 0 AND 3   THEN '0-3 Months'
        WHEN tenure BETWEEN 4 AND 6   THEN '4-6 Months'
        WHEN tenure BETWEEN 7 AND 12  THEN '7-12 Months'
        WHEN tenure BETWEEN 13 AND 24 THEN '13-24 Months'
        WHEN tenure BETWEEN 25 AND 48 THEN '25-48 Months'
        ELSE '49+ Months'
    END AS tenure_bucket,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY tenure_bucket
ORDER BY MIN(tenure);


-- ============================================================
-- 3. CHURN BY CUSTOMER TYPE: New vs Old
-- ============================================================
SELECT 
    CASE WHEN tenure <= 12 THEN 'New Customer (<=1 yr)' ELSE 'Old Customer (>1 yr)' END AS customer_type,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY customer_type;


-- ============================================================
-- 4. CHURN BY CONTRACT TYPE
-- ============================================================
SELECT 
    Contract,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY Contract
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- 5. CHURN BY INTERNET SERVICE TYPE
-- ============================================================
SELECT 
    InternetService,
    COUNT(*) AS total_customers,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY InternetService
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- 6. FEATURE USAGE ANALYSIS (Leading Indicators)
-- ============================================================
SELECT 
    'OnlineSecurity' AS feature,
    AVG(CASE WHEN Churn = 'Yes' AND OnlineSecurity = 'Yes' THEN 1.0 ELSE 0.0 END) AS churned_with_feature,
    AVG(CASE WHEN Churn = 'Yes' AND OnlineSecurity = 'No' THEN 1.0 ELSE 0.0 END) AS churned_without_feature
FROM customers
UNION ALL
SELECT 
    'TechSupport',
    AVG(CASE WHEN Churn = 'Yes' AND TechSupport = 'Yes' THEN 1.0 ELSE 0.0 END),
    AVG(CASE WHEN Churn = 'Yes' AND TechSupport = 'No' THEN 1.0 ELSE 0.0 END)
FROM customers
UNION ALL
SELECT 
    'OnlineBackup',
    AVG(CASE WHEN Churn = 'Yes' AND OnlineBackup = 'Yes' THEN 1.0 ELSE 0.0 END),
    AVG(CASE WHEN Churn = 'Yes' AND OnlineBackup = 'No' THEN 1.0 ELSE 0.0 END)
FROM customers
UNION ALL
SELECT 
    'DeviceProtection',
    AVG(CASE WHEN Churn = 'Yes' AND DeviceProtection = 'Yes' THEN 1.0 ELSE 0.0 END),
    AVG(CASE WHEN Churn = 'Yes' AND DeviceProtection = 'No' THEN 1.0 ELSE 0.0 END)
FROM customers;


-- ============================================================
-- 7. PAYMENT METHOD vs CHURN
-- ============================================================
SELECT 
    PaymentMethod,
    COUNT(*) AS total,
    SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS churn_rate_pct
FROM customers
GROUP BY PaymentMethod
ORDER BY churn_rate_pct DESC;


-- ============================================================
-- 8. REVENUE AT RISK
-- ============================================================
SELECT 
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges ELSE 0 END), 2) AS monthly_revenue_lost,
    ROUND(SUM(CASE WHEN Churn = 'Yes' THEN MonthlyCharges * 12 ELSE 0 END), 2) AS annual_revenue_lost,
    ROUND(AVG(CASE WHEN Churn = 'Yes' THEN MonthlyCharges END), 2) AS avg_monthly_charge_churned
FROM customers;


-- ============================================================
-- 9. HIGH VALUE CUSTOMERS AT RISK (Senior + High Spend)
-- ============================================================
SELECT 
    customerID,
    SeniorCitizen,
    tenure,
    MonthlyCharges,
    Contract,
    TechSupport,
    Churn
FROM customers
WHERE Churn = 'Yes'
  AND MonthlyCharges > 70
ORDER BY MonthlyCharges DESC
LIMIT 20;


-- ============================================================
-- 10. CHURN PLAYBOOK TRIGGERS
-- ============================================================
-- Customers inactive/new (0-7 days = tenure < 1) + Month-to-month → Send reminder
SELECT customerID, tenure, Contract, MonthlyCharges, 'Send re-engagement email' AS recommended_action
FROM customers
WHERE Churn = 'No'
  AND tenure <= 3
  AND Contract = 'Month-to-month'

UNION ALL

-- High value at risk
SELECT customerID, tenure, Contract, MonthlyCharges, 'Assign dedicated support' AS recommended_action
FROM customers
WHERE Churn = 'No'
  AND MonthlyCharges > 80
  AND TechSupport = 'No'

UNION ALL

-- No security features → Proactive outreach
SELECT customerID, tenure, Contract, MonthlyCharges, 'Offer OnlineSecurity addon' AS recommended_action
FROM customers
WHERE Churn = 'No'
  AND OnlineSecurity = 'No'
  AND InternetService != 'No'

ORDER BY MonthlyCharges DESC;

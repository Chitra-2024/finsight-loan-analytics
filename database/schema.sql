CREATE DATABASE IF NOT EXISTS finsight_db;
USE finsight_db;

CREATE TABLE IF NOT EXISTS dim_branches (
    branch_id INT PRIMARY KEY,
    branch_name VARCHAR(50) NOT NULL,
    region VARCHAR(50) NOT NULL
);

CREATE TABLE IF NOT EXISTS dim_customers (
    customer_id INT PRIMARY KEY,
    customer_name VARCHAR(100),
    credit_score INT,
    monthly_income DECIMAL(12,2),
    customer_vintage_months INT
);

CREATE TABLE IF NOT EXISTS fact_loans (
    loan_id INT PRIMARY KEY,
    customer_id INT,
    branch_id INT,
    product_type VARCHAR(20), 
    disbursal_date DATE,
    loan_amount DECIMAL(15,2),
    interest_rate DECIMAL(5,2),
    tenure_months INT,
    loan_status VARCHAR(20), 
    FOREIGN KEY (customer_id) REFERENCES dim_customers(customer_id),
    FOREIGN KEY (branch_id) REFERENCES dim_branches(branch_id)
);

CREATE TABLE IF NOT EXISTS fact_repayments (
    repayment_id INT PRIMARY KEY AUTO_INCREMENT,
    loan_id INT,
    installment_number INT,
    due_date DATE,
    expected_amount DECIMAL(12,2),
    paid_date DATE,
    amount_paid DECIMAL(12,2),
    dpd INT DEFAULT 0, 
    FOREIGN KEY (loan_id) REFERENCES fact_loans(loan_id)
);
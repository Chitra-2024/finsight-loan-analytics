import mysql.connector
from datetime import datetime, timedelta
import random
import os
from dotenv import load_dotenv

load_dotenv()

conn = mysql.connector.connect(
    host=os.getenv("DB_HOST", "localhost"),
    user=os.getenv("DB_USER", "root"),         
    password=os.getenv("DB_PASSWORD", "password"),
    database=os.getenv("DB_NAME", "finsight_db")
)
cursor = conn.cursor()

branches = [
    (1, 'Mumbai', 'West'), (2, 'Delhi NCR', 'North'), 
    (3, 'Pune', 'West'), (4, 'Bengaluru', 'South')
]
cursor.executemany("INSERT IGNORE INTO dim_branches VALUES (%s, %s, %s)", branches)

customer_data = []
for c_id in range(1, 201):
    c_name = f"Customer_{c_id}"
    credit_score = random.choices([random.randint(750, 850), random.randint(600, 749), random.randint(300, 599)], weights=[60, 30, 10])[0]
    monthly_income = random.randint(40000, 250000)
    vintage = random.randint(6, 48)
    customer_data.append((c_id, c_name, credit_score, monthly_income, vintage))
cursor.executemany("INSERT IGNORE INTO dim_customers VALUES (%s, %s, %s, %s, %s)", customer_data)

products = ['HL', 'LAP', 'BL', 'BLAP']
for l_id in range(1, 101):
    cust_id = random.randint(1, 200)
    br_id = random.randint(1, 4)
    prod = random.choice(products)
    amt = random.randint(500000, 5000000)
    rate = round(random.uniform(8.5, 14.0), 2)
    tenure = random.choice([60, 120, 180, 240])
    cursor.execute("INSERT IGNORE INTO fact_loans VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)",
                   (l_id, cust_id, br_id, prod, '2025-01-01', amt, rate, tenure, 'Active'))

repayment_data = []
rep_id = 1
start_date = datetime.strptime('2025-02-01', '%Y-%m-%d')

for l_id in range(1, 101):
    behavior = random.choices(['clean', 'delayed', 'default'], weights=[80, 15, 5])[0]
    for month in range(1, 7):
        due = start_date + timedelta(days=(month-1)*30)
        expected = 25000.00
        if behavior == 'clean':
            paid, amt_paid, dpd = due, expected, 0
        elif behavior == 'delayed':
            dpd = random.randint(5, 45)
            paid, amt_paid = due + timedelta(days=dpd), expected
        else:
            dpd = month * 30
            paid, amt_paid = None, 0.00
        repayment_data.append((rep_id, l_id, month, due.strftime('%Y-%m-%d'), expected, 
                               paid.strftime('%Y-%m-%d') if paid else None, amt_paid, dpd))
        rep_id += 1

cursor.executemany("INSERT IGNORE INTO fact_repayments VALUES (%s, %s, %s, %s, %s, %s, %s, %s)", repayment_data)
conn.commit()
print("Data has been seeded")
cursor.close()
conn.close()
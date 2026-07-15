import os
import mysql.connector
import subprocess

DB_SETTINGS = {
    "host": "localhost",
    "user": "root",
    "password": "" 
}

def execute_sql_file(cursor, file_path):
    """Reads an SQL file and executes its commands sequentially."""
    print(f"Executing: {file_path}")
    if not os.path.exists(file_path):
        print(f"Error: File not found at {file_path}")
        return False
        
    with open(file_path, 'r') as f:
        sql_content = f.read()
        
    queries = sql_content.split(';')
    for query in queries:
        clean_query = query.strip()
        if clean_query and not clean_query.startswith('--'):
            cursor.execute(clean_query)
    return True

def main():
    print("Starting FinSight Enterprise Pipeline Initialization...\n")
    
    try:
        conn = mysql.connector.connect(**DB_SETTINGS)
        cursor = conn.cursor()
    except mysql.connector.Error as err:
        print(f"Connection failed: {err}")
        return

    schema_path = os.path.join("database", "schema.sql")
    if not execute_sql_file(cursor, schema_path):
        return
    print("Database Tables Initialization Complete.")

    views_path = os.path.join("database", "analytical_views.sql")
    if not execute_sql_file(cursor, views_path):
        return
    print("Analytical Views Built Successfully.")
    
    cursor.close()
    conn.close()

    print("\nSeeding live transactional data into Star Schema...")
    seeder_path = os.path.join("pipelines", "seed_data.py")
    
    try:
        result = subprocess.run(["python", seeder_path], capture_output=True, text=True, check=True)
        print(result.stdout)
    except subprocess.SubprocessError as e:
        print(f"Error running seeder script: {e}")
        return

    print("FinSight Data Infrastructure Deployment Completed")

if __name__ == "__main__":
    main()
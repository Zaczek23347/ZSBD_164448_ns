import oracledb
import csv
from datetime import datetime
from pathlib import Path

USER = "inf2ns_zaczekk"
PASSWORD = "kacper"
DSN = "213.184.8.44:1521/orcl"

# ====== PARAMETRY ======
DATE_FROM = "1900-01-01"
DATE_TO   = "2090-12-31"

OUTPUT_FILE = Path(r"C:\Users\HP\Desktop\StudiaMagisterka\sqldeveloper-24.3.1.347.1826-x64\invoices_export.csv")


sql = """
    SELECT
        *
    FROM processed_invoices
    WHERE invoice_date >= :date_from
      AND invoice_date <  :date_to + 1
    ORDER BY invoice_date
"""

try:
    conn = oracledb.connect(
        user=USER,
        password=PASSWORD,
        dsn=DSN
    )
    cursor = conn.cursor()

    date_from = datetime.strptime(DATE_FROM, "%Y-%m-%d")
    date_to   = datetime.strptime(DATE_TO, "%Y-%m-%d")

    cursor.execute(sql, {
        "date_from": date_from,
        "date_to": date_to
    })

    # nagłówki CSV z nazw kolumn
    columns = [col[0] for col in cursor.description]

    with open(OUTPUT_FILE, mode="w", newline="", encoding="utf-8") as csv_file:
        writer = csv.writer(csv_file, delimiter=';')

        writer.writerow(columns)  # nagłówki

        for row in cursor:
            # formatowanie DATE → YYYY-MM-DD
            formatted_row = [
                value.strftime("%Y-%m-%d") if isinstance(value, datetime) else value
                for value in row
            ]
            writer.writerow(formatted_row)

    print(f"Eksport zakończony sukcesem: {OUTPUT_FILE}")
    print(f"Liczba rekordów: {cursor.rowcount}")

except Exception as e:
    print(f"Błąd: {e}")

finally:
    if 'cursor' in locals():
        cursor.close()
    if 'conn' in locals():
        conn.close()

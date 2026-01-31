import oracledb
import pathlib
import shutil


USER = "inf2ns_zaczekk"
PASSWORD = "kacper"
DSN = "213.184.8.44:1521/orcl"

FOLDER_PATH = pathlib.Path(r"C:\Users\HP\Desktop\StudiaMagisterka\plikixml")
ARCH_PATH = FOLDER_PATH / "Arch"


ARCH_PATH.mkdir(exist_ok=True)

sql = """
    INSERT INTO faktury_xml (nazwa_pliku, xml_dokument, status_przetw)
    VALUES (:nazwa, :dokument, :status)
"""

truncate = """
    TRUNCATE TABLE faktury_xml
"""

try:
    conn = oracledb.connect(user=USER, password=PASSWORD, dsn=DSN)
    cursor = conn.cursor()

    cursor.execute(truncate)

    for file_path in FOLDER_PATH.glob("*.xml"):
        print(f"Processing: {file_path.name}")

        with open(file_path, 'r', encoding='utf-8') as f:
            xml_content = f.read()

        cursor.execute(sql, {
            "nazwa": file_path.name,
            "dokument": xml_content,
            "status": "0"
        })


        shutil.move(str(file_path), ARCH_PATH / file_path.name)

    conn.commit()
    print("All files uploaded and archived successfully!")

except Exception as e:
    print(f"An error occurred: {e}")

finally:
    if 'cursor' in locals():
        cursor.close()
    if 'conn' in locals():
        conn.close()

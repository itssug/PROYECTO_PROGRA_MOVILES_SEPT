import os
import django
import sys

# Set up Django environment
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "config.settings")
django.setup()

from django.db import connection

def run():
    with connection.cursor() as cursor:
        try:
            cursor.execute("ALTER TABLE analisis_glucosa ADD COLUMN medicamento_tomado INT DEFAULT 0;")
            print("Successfully added medicamento_tomado to analisis_glucosa")
        except Exception as e:
            print(f"Error or column already exists: {e}")

if __name__ == "__main__":
    run()

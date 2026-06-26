import os
import django
import sys

sys.path.append(os.path.dirname(os.path.abspath(__file__)))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')
django.setup()

from analitica_ia.services.train_model import entrenar_modelo_usuario

print("Entrenando modelo usuario 15...")
entrenar_modelo_usuario(15)

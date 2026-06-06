import joblib
import pandas as pd

from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_absolute_error

from .dataset_builder import DatasetBuilder


import os
from django.conf import settings

def entrenar_modelo_usuario(usuario_id):

    builder = DatasetBuilder()

    df = builder.construir_dataset(usuario_id)

    if df is None or len(df) < 5:
        print(f"No existen suficientes datos para el usuario {usuario_id}")
        return None

    # Limpiar nulos si existen
    df = df.dropna()

    if len(df) < 5:
        return None

    X = df[
        [
            "glucosa_antes",
            "carbohidratos",
            "carga_glucemica",
            "horas_sueno",
            "estres",
            "ejercicio"
        ]
    ]

    y = df["glucosa_despues"]

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42
    )

    modelo = RandomForestRegressor(
        n_estimators=100,
        random_state=42
    )

    modelo.fit(X_train, y_train)

    predicciones = modelo.predict(X_test)

    mae = mean_absolute_error(y_test, predicciones)

    print(f"Usuario {usuario_id} - MAE: {mae}")

    # Crear directorio de modelos si no existe
    models_dir = os.path.join(settings.BASE_DIR, 'media', 'models')
    os.makedirs(models_dir, exist_ok=True)
    
    ruta_modelo = os.path.join(models_dir, f"user_{usuario_id}_rf.joblib")

    joblib.dump(
        modelo,
        ruta_modelo
    )

    print(f"Modelo guardado en {ruta_modelo}")
    return {"mae": mae, "registros_usados": len(df)}
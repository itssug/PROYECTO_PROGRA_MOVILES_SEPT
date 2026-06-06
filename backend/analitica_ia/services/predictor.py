import joblib
import os


from django.conf import settings

class PredictorGlucosa:

    def __init__(self, usuario_id):

        ruta = os.path.join(
            settings.BASE_DIR,
            "media",
            "models",
            f"user_{usuario_id}_rf.joblib"
        )
        
        if not os.path.exists(ruta):
            raise FileNotFoundError(f"El modelo para el usuario {usuario_id} no está entrenado todavía.")

        self.modelo = joblib.load(ruta)

    def predecir(
        self,
        glucosa_antes,
        carbohidratos,
        carga_glucemica,
        horas_sueno,
        estres,
        ejercicio
    ):

        datos = [[
            glucosa_antes,
            carbohidratos,
            carga_glucemica,
            horas_sueno,
            estres,
            ejercicio
        ]]

        resultado = self.modelo.predict(datos)

        return round(float(resultado[0]), 2)
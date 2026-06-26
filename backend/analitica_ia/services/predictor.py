import joblib
import os


from django.conf import settings

class PredictorGlucosa:

    def __init__(self, usuario_id):

        ruta_usuario = os.path.join(
            settings.BASE_DIR,
            "media",
            "models",
            f"user_{usuario_id}_rf.joblib"
        )
        
        ruta_global = os.path.join(
            settings.BASE_DIR,
            "media",
            "models",
            "global_model.joblib"
        )

        if os.path.exists(ruta_usuario):
            self.modelo = joblib.load(ruta_usuario)
            self.modelo_usado = f"user_{usuario_id}_rf"
        elif os.path.exists(ruta_global):
            self.modelo = joblib.load(ruta_global)
            self.modelo_usado = "global_model"
        else:
            raise FileNotFoundError(f"El modelo para el usuario {usuario_id} no está entrenado y no existe modelo global.")

    def predecir(
        self,
        glucosa_antes,
        carbohidratos,
        carga_glucemica,
        horas_sueno,
        estres,
        ejercicio,
        medicamento_tomado
    ):

        datos = [[
            glucosa_antes,
            carbohidratos,
            carga_glucemica,
            horas_sueno,
            estres,
            ejercicio,
            medicamento_tomado
        ]]

        resultado = self.modelo.predict(datos)

        return {
            "valor": round(float(resultado[0]), 2),
            "modelo_usado": self.modelo_usado
        }
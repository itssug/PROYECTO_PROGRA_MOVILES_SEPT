from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAdminUser

from .serializers import PrediccionSerializer
from .services.predictor import PredictorGlucosa
from .services.train_model import entrenar_modelo_usuario, entrenar_modelo_global
from .services.pattern_discovery import generar_patrones_usuario

import os
from django.conf import settings
from datetime import datetime

class TrainModelView(APIView):
    def post(self, request, usuario_id):
        resultado = entrenar_modelo_usuario(usuario_id)
        if not resultado:
            return Response(
                {"error": "No hay suficientes datos para entrenar el modelo."},
                status=status.HTTP_400_BAD_REQUEST
            )
        return Response(
            {"status": "success", "metricas": resultado},
            status=status.HTTP_200_OK
        )

class GeneratePatternsView(APIView):
    def post(self, request, usuario_id):
        resultado = generar_patrones_usuario(usuario_id)
        if "error" in resultado:
            return Response(resultado, status=status.HTTP_400_BAD_REQUEST)
        return Response(resultado, status=status.HTTP_200_OK)


class PrediccionGlucosaView(APIView):
    """
    Predicción de glucosa post-comida con capa de validación clínica.

    Random Forest no puede extrapolar fuera del rango de entrenamiento,
    así que se aplican reglas clínicas para valores extremos y se clampean
    los inputs antes de pasarlos al modelo.
    """

    # Rangos del dataset de entrenamiento (ver generar_dataset_ml.py)
    RANGOS_ENTRENAMIENTO = {
        "glucosa_antes":   (70, 250),
        "carbohidratos":   (0, 60),     # Max en training: ~45g por comida
        "carga_glucemica": (0, 40),     # Max en training: ~30
        "horas_sueno":     (3, 12),
        "estres":          (1, 10),
        "ejercicio":       (0, 120),
    }

    # Umbrales clínicos para override del modelo
    UMBRAL_CARBOS_ALTO = 80       # > 80g es una comida alta en carbos
    UMBRAL_CARBOS_CRITICO = 150   # > 150g es extremo
    UMBRAL_CG_ALTO = 40           # Carga glucémica alta
    UMBRAL_CG_CRITICO = 80        # Carga glucémica extrema

    def post(self, request, usuario_id):
        serializer = PrediccionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            predictor = PredictorGlucosa(usuario_id)
        except FileNotFoundError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        # ── Valores originales
        glucosa_antes   = serializer.validated_data["glucosa_antes"]
        carbohidratos   = serializer.validated_data["carbohidratos"]
        carga_glucemica = serializer.validated_data["carga_glucemica"]
        horas_sueno     = serializer.validated_data["horas_sueno"]
        estres          = serializer.validated_data["estres"]
        ejercicio       = serializer.validated_data["ejercicio"]

        avisos = []
        fuera_de_rango = False

        # ── Detectar valores fuera del rango de entrenamiento
        if carbohidratos > self.RANGOS_ENTRENAMIENTO["carbohidratos"][1]:
            fuera_de_rango = True
            avisos.append(
                f"Carbohidratos ({carbohidratos:.0f}g) exceden el rango de entrenamiento del modelo. "
                f"Se aplica estimación clínica."
            )
        if carga_glucemica > self.RANGOS_ENTRENAMIENTO["carga_glucemica"][1]:
            fuera_de_rango = True
            avisos.append(
                f"Carga glucémica ({carga_glucemica:.0f}) excede el rango de entrenamiento. "
                f"Se aplica estimación clínica."
            )

        # ── Clampear inputs para el modelo (evitar predicción basura)
        inputs_clamped = {
            "glucosa_antes":   max(min(glucosa_antes, 250), 70),
            "carbohidratos":   max(min(carbohidratos, 60), 0),
            "carga_glucemica": max(min(carga_glucemica, 40), 0),
            "horas_sueno":     max(min(horas_sueno, 12), 3),
            "estres":          max(min(estres, 10), 1),
            "ejercicio":       max(min(ejercicio, 120), 0),
        }

        # ── Predicción del modelo (con inputs clampeados)
        resultado = predictor.predecir(
            inputs_clamped["glucosa_antes"],
            inputs_clamped["carbohidratos"],
            inputs_clamped["carga_glucemica"],
            inputs_clamped["horas_sueno"],
            inputs_clamped["estres"],
            inputs_clamped["ejercicio"]
        )

        glucosa_modelo = resultado["valor"]
        modelo_usado = resultado["modelo_usado"]

        # ── Ajuste clínico para valores fuera de rango
        # Fórmula simplificada: glucosa_base + (carbos_excedentes × factor_impacto)
        if fuera_de_rango:
            # Factor de impacto por gramo de carbohidrato adicional
            factor_carbs = 1.5 if glucosa_antes > 140 else 1.0
            excedente_carbos = max(0, carbohidratos - 60)

            # Factor de impacto por carga glucémica adicional
            factor_cg = 2.0
            excedente_cg = max(0, carga_glucemica - 40)

            # Ajustar la predicción del modelo con el excedente
            ajuste = (excedente_carbos * factor_carbs) + (excedente_cg * factor_cg)
            glucosa_final = glucosa_modelo + ajuste

            # Tope fisiológico razonable
            glucosa_final = min(glucosa_final, 500)
        else:
            glucosa_final = glucosa_modelo

        glucosa_final = round(glucosa_final, 2)

        # ── Clasificación de riesgo
        if glucosa_final < 140:
            riesgo = "BAJO"
        elif glucosa_final < 180:
            riesgo = "MEDIO"
        else:
            riesgo = "ALTO"

        # ── Override por reglas clínicas extremas
        if carbohidratos > self.UMBRAL_CARBOS_CRITICO or carga_glucemica > self.UMBRAL_CG_CRITICO:
            if riesgo == "BAJO":
                riesgo = "ALTO"
                avisos.append(
                    "La cantidad de carbohidratos/carga glucémica es extremadamente alta. "
                    "Riesgo reclasificado a ALTO por regla clínica."
                )
        elif carbohidratos > self.UMBRAL_CARBOS_ALTO or carga_glucemica > self.UMBRAL_CG_ALTO:
            if riesgo == "BAJO":
                riesgo = "MEDIO"
                avisos.append(
                    "La cantidad de carbohidratos/carga glucémica es alta. "
                    "Riesgo ajustado a MEDIO por regla clínica."
                )

        response_data = {
            "glucosa_predicha": glucosa_final,
            "riesgo": riesgo,
            "modelo_usado": modelo_usado,
        }

        if avisos:
            response_data["avisos"] = avisos
            response_data["fuera_de_rango"] = True

        return Response(response_data, status=status.HTTP_200_OK)

class GlobalModelStatusView(APIView):
    def get(self, request):
        ruta_global = os.path.join(
            settings.BASE_DIR,
            "media",
            "models",
            "global_model.joblib"
        )
        
        existe_modelo = os.path.exists(ruta_global)
        fecha_entrenamiento = None
        
        if existe_modelo:
            timestamp = os.path.getmtime(ruta_global)
            fecha_entrenamiento = datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')

        return Response(
            {
                "existe_modelo": existe_modelo,
                "fecha_entrenamiento": fecha_entrenamiento
            },
            status=status.HTTP_200_OK
        )

class GlobalModelTrainView(APIView):
    permission_classes = [IsAdminUser]

    def post(self, request):
        resultado = entrenar_modelo_global()
        if not resultado:
            return Response(
                {"error": "Insufficient global dataset"},
                status=status.HTTP_400_BAD_REQUEST
            )
        return Response(
            {"status": "success", "metricas": resultado},
            status=status.HTTP_200_OK
        )
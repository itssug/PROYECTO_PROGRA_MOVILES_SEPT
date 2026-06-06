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
    def post(self, request, usuario_id):
        serializer = PrediccionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        try:
            predictor = PredictorGlucosa(usuario_id)
        except FileNotFoundError as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)

        resultado = predictor.predecir(
            serializer.validated_data["glucosa_antes"],
            serializer.validated_data["carbohidratos"],
            serializer.validated_data["carga_glucemica"],
            serializer.validated_data["horas_sueno"],
            serializer.validated_data["estres"],
            serializer.validated_data["ejercicio"]
        )

        glucosa = resultado["valor"]
        modelo_usado = resultado["modelo_usado"]

        if glucosa < 140:
            riesgo = "BAJO"
        elif glucosa < 180:
            riesgo = "MEDIO"
        else:
            riesgo = "ALTO"

        return Response(
            {
                "glucosa_predicha": glucosa,
                "riesgo": riesgo,
                "modelo_usado": modelo_usado
            },
            status=status.HTTP_200_OK
        )

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